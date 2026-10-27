import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import {
  evaluateSpendingRules,
  mapSpendingRules,
  type SpendingRules,
} from '../../domain/spending_rules.js';
import { getSpentThisMonth } from './spent_this_month.js';

export interface OrderAmountLine {
  productUid: string;
  qty: number;
}

export interface CatalogPrice {
  uid: string;
  name: string;
  price: number | string;
  active: boolean;
  supplierId: string;
}

export interface AmountCheck {
  ok: boolean;
  total: number;
  reason?: string;
}

/**
 * Calcula el importe real de un pedido a partir de los precios del catálogo.
 * Es la única fuente de verdad: el campo `orders.total` lo puede escribir el
 * cliente, así que no se usa para decidir cuánto se paga.
 */
export function computeOrderTotal(
  lines: OrderAmountLine[],
  products: CatalogPrice[],
): { total: number; reason?: string } {
  if (lines.length === 0) {
    return { total: 0, reason: 'El pedido no tiene líneas.' };
  }

  const catalog = new Map(products.map((product) => [product.uid, product]));
  let total = 0;

  for (const line of lines) {
    const product = catalog.get(line.productUid);
    if (!product) {
      return { total: 0, reason: `El producto ${line.productUid} no está en el catálogo.` };
    }
    if (!product.active) {
      return { total: 0, reason: `El producto ${product.name} no está activo.` };
    }
    if (!Number.isInteger(line.qty) || line.qty <= 0) {
      return { total: 0, reason: `Cantidad inválida para ${line.productUid}.` };
    }
    total += Number(product.price) * line.qty;
  }

  return { total: Number(total.toFixed(2)) };
}

/**
 * Comprueba que el importe guardado coincide con el del catálogo y que el
 * pedido sigue respetando las reglas de gasto vigentes.
 */
export function verifyOrderAmount(params: {
  orderTotal: number;
  orderSupplierId: string;
  lines: OrderAmountLine[];
  products: CatalogPrice[];
  rules: SpendingRules;
  spentThisMonth: number;
  tolerance?: number;
  /** El dueño ya aprobó el pedido: superar el umbral de aprobación no bloquea. */
  ownerApproved?: boolean;
}): AmountCheck {
  const tolerance = params.tolerance ?? 0.01;

  for (const line of params.lines) {
    const product = params.products.find((p) => p.uid === line.productUid);
    if (!product) {
      return {
        ok: false,
        total: 0,
        reason: `El producto ${line.productUid} no está en el catálogo.`,
      };
    }
    if (product.supplierId !== params.orderSupplierId) {
      return {
        ok: false,
        total: 0,
        reason: `El producto ${product.name} no pertenece al proveedor del pedido.`,
      };
    }
  }

  const computed = computeOrderTotal(params.lines, params.products);
  if (computed.reason) {
    return { ok: false, total: 0, reason: computed.reason };
  }

  if (Math.abs(computed.total - Number(params.orderTotal)) > tolerance) {
    return {
      ok: false,
      total: computed.total,
      reason:
        'El importe del pedido no coincide con el catálogo. ' +
        'Revísalo y vuelve a aprobarlo.',
    };
  }

  const decision = evaluateSpendingRules({
    rules: params.rules,
    orderTotal: computed.total,
    spentThisMonth: params.spentThisMonth,
    supplierId: params.orderSupplierId,
  });

  if (decision.status === 'blocked') {
    return {
      ok: false,
      total: computed.total,
      reason: decision.reason ?? 'El pedido está bloqueado por las reglas de gasto.',
    };
  }

  if (decision.status === 'requires_approval' && !params.ownerApproved) {
    return {
      ok: false,
      total: computed.total,
      reason: 'El pedido necesita tu aprobación antes de pagarlo.',
    };
  }

  return { ok: true, total: computed.total };
}

interface OrderAmountRow {
  id: string;
  store_id: string;
  supplier_id: string;
  total: number | string;
  order_items: { product_uid: string; qty: number }[] | null;
}

/**
 * Comprobación server-side antes de mover dinero: recalcula el importe desde
 * el catálogo y reevalúa las reglas de gasto de la tienda.
 */
export async function guardOrderAmount(
  orderId: string,
  options: { ownerApproved?: boolean } = {},
): Promise<{ total: number }> {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('id, store_id, supplier_id, total, order_items(product_uid, qty)')
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    throw new Error(`No se pudo comprobar el pedido: ${error.message}`);
  }
  if (!data) {
    throw new Error('El pedido no existe.');
  }

  const order = data as unknown as OrderAmountRow;
  const lines: OrderAmountLine[] = (order.order_items ?? []).map((item) => ({
    productUid: item.product_uid,
    qty: Number(item.qty),
  }));

  const uids = [...new Set(lines.map((line) => line.productUid))];
  const { data: productsData, error: productsError } = await supabaseAdmin
    .from('products')
    .select('uid, name, price, active, supplier_id')
    .in('uid', uids);

  if (productsError) {
    throw new Error(
      `No se pudo comprobar el catálogo: ${productsError.message}`,
    );
  }

  const products: CatalogPrice[] = (
    (productsData ?? []) as {
      uid: string;
      name: string;
      price: number | string;
      active: boolean;
      supplier_id: string;
    }[]
  ).map((product) => ({
    uid: product.uid,
    name: product.name,
    price: product.price,
    active: product.active,
    supplierId: product.supplier_id,
  }));

  const { data: rulesRow, error: rulesError } = await supabaseAdmin
    .from('spending_rules')
    .select('max_per_order, monthly_limit, require_approval_above, allowed_supplier_ids')
    .eq('store_id', order.store_id)
    .maybeSingle();

  if (rulesError) {
    throw new Error(`No se pudieron cargar las reglas: ${rulesError.message}`);
  }

  const spentThisMonth = await getSpentThisMonth(order.store_id);
  const check = verifyOrderAmount({
    orderTotal: Number(order.total),
    orderSupplierId: order.supplier_id,
    lines,
    products,
    rules: mapSpendingRules(rulesRow ?? {}),
    spentThisMonth,
    ownerApproved: options.ownerApproved ?? false,
  });

  if (!check.ok) {
    throw new Error(check.reason ?? 'El pedido no supera la comprobación de importe.');
  }

  return { total: check.total };
}
