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
  /** Total guardado antes de recalcular. */
  previousTotal: number;
  /** El total guardado no coincide con el del catálogo. */
  changed: boolean;
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
 * Recalcula el importe con el catálogo vigente y comprueba las reglas.
 *
 * El importe guardado en `orders.total` puede haberse quedado atrás porque el
 * proveedor cambió sus precios: no invalida el pedido, solo marca `changed`
 * para que el servidor actualice las líneas y la app avise antes de cobrar.
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
  const previousTotal = Number(params.orderTotal);
  const fail = (reason: string): AmountCheck => ({
    ok: false,
    total: 0,
    previousTotal,
    changed: false,
    reason,
  });

  for (const line of params.lines) {
    const product = params.products.find((p) => p.uid === line.productUid);
    if (!product) {
      return fail(`El producto ${line.productUid} no está en el catálogo.`);
    }
    if (product.supplierId !== params.orderSupplierId) {
      return fail(
        `El producto ${product.name} no pertenece al proveedor del pedido.`,
      );
    }
  }

  const computed = computeOrderTotal(params.lines, params.products);
  if (computed.reason) {
    return fail(computed.reason);
  }

  const changed = Math.abs(computed.total - previousTotal) > tolerance;

  const decision = evaluateSpendingRules({
    rules: params.rules,
    orderTotal: computed.total,
    spentThisMonth: params.spentThisMonth,
    supplierId: params.orderSupplierId,
  });

  if (decision.status === 'blocked') {
    return {
      ...fail(
        decision.reason ?? 'El pedido está bloqueado por las reglas de gasto.',
      ),
      total: computed.total,
      changed,
    };
  }

  if (decision.status === 'requires_approval' && !params.ownerApproved) {
    return {
      ...fail('El pedido necesita tu aprobación antes de pagarlo.'),
      total: computed.total,
      changed,
    };
  }

  return { ok: true, total: computed.total, previousTotal, changed };
}

interface OrderAmountRow {
  id: string;
  store_id: string;
  supplier_id: string;
  total: number | string;
  order_items: { product_uid: string; qty: number }[] | null;
}

interface OrderAmountData {
  order: OrderAmountRow;
  lines: OrderAmountLine[];
  products: CatalogPrice[];
  rules: SpendingRules;
  spentThisMonth: number;
}

export interface AmountReview {
  total: number;
  previousTotal: number;
  changed: boolean;
}

async function loadOrderAmountData(orderId: string): Promise<OrderAmountData> {
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

  return {
    order,
    lines,
    products,
    rules: mapSpendingRules(rulesRow ?? {}),
    spentThisMonth,
  };
}

/**
 * Actualiza las líneas y el total del pedido con los precios del catálogo del
 * momento del pago. Solo lo llama el servidor (service_role): el trigger
 * `protect_order_amount` bloquea estas escrituras desde el cliente.
 */
async function applyCurrentPrices(
  data: OrderAmountData,
): Promise<void> {
  const catalog = new Map(data.products.map((product) => [product.uid, product]));

  for (const line of data.lines) {
    const product = catalog.get(line.productUid);
    if (!product) continue;
    const { error } = await supabaseAdmin
      .from('order_items')
      .update({ name: product.name, unit_price: Number(product.price) })
      .eq('order_id', data.order.id)
      .eq('product_uid', line.productUid);
    if (error) {
      throw new Error(
        `No se pudo actualizar la línea ${line.productUid}: ${error.message}`,
      );
    }
  }

  const subtotal = data.lines.reduce((sum, line) => {
    const product = catalog.get(line.productUid);
    return sum + Number(product?.price ?? 0) * line.qty;
  }, 0);
  const total = Number(subtotal.toFixed(2));

  const { error } = await supabaseAdmin
    .from('orders')
    .update({ subtotal: total, total })
    .eq('id', data.order.id);
  if (error) {
    throw new Error(`No se pudo actualizar el importe del pedido: ${error.message}`);
  }
}

/**
 * Consulta el importe que se pagaría ahora mismo, sin mover dinero ni tocar el
 * pedido. La app lo usa para avisar si el proveedor cambió el precio.
 */
export async function previewOrderAmount(orderId: string): Promise<AmountReview> {
  const data = await loadOrderAmountData(orderId);
  const check = verifyOrderAmount({
    orderTotal: Number(data.order.total),
    orderSupplierId: data.order.supplier_id,
    lines: data.lines,
    products: data.products,
    rules: data.rules,
    spentThisMonth: data.spentThisMonth,
    ownerApproved: true,
  });

  if (!check.ok) {
    throw new Error(check.reason ?? 'El pedido no se puede pagar.');
  }

  return {
    total: check.total,
    previousTotal: check.previousTotal,
    changed: check.changed,
  };
}

/**
 * Comprobación server-side antes de mover dinero: recalcula el importe desde
 * el catálogo, actualiza las líneas si el precio cambió y reevalúa las reglas
 * de gasto de la tienda.
 */
export async function guardOrderAmount(
  orderId: string,
  options: { ownerApproved?: boolean } = {},
): Promise<AmountReview> {
  const data = await loadOrderAmountData(orderId);
  const check = verifyOrderAmount({
    orderTotal: Number(data.order.total),
    orderSupplierId: data.order.supplier_id,
    lines: data.lines,
    products: data.products,
    rules: data.rules,
    spentThisMonth: data.spentThisMonth,
    ownerApproved: options.ownerApproved ?? false,
  });

  if (!check.ok) {
    throw new Error(check.reason ?? 'El pedido no supera la comprobación de importe.');
  }

  if (check.changed) {
    await applyCurrentPrices(data);
  }

  return {
    total: check.total,
    previousTotal: check.previousTotal,
    changed: check.changed,
  };
}
