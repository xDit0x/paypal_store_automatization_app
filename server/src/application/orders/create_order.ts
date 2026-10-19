import { randomUUID } from 'node:crypto';

import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

export interface CreateOrderLine {
  productUid: string;
  qty: number;
}

export interface CreateOrderInput {
  storeId: string;
  supplierId: string;
  lines: CreateOrderLine[];
  status: 'draft' | 'pending_approval' | 'approved';
  createdByType: 'user' | 'agent';
  createdById?: string | null;
  agentRunId?: string | null;
}

export interface QuotedOrderItem {
  productUid: string;
  name: string;
  qty: number;
  unitPrice: number;
  lineTotal: number;
}

export interface OrderQuote {
  supplierId: string;
  items: QuotedOrderItem[];
  subtotal: number;
}

export interface CreatedOrder extends OrderQuote {
  id: string;
  storeId: string;
  status: string;
  total: number;
}

interface ProductRow {
  uid: string;
  name: string;
  price: number | string;
  supplier_id: string;
  active: boolean;
}

export async function quoteOrder(input: {
  supplierId: string;
  lines: CreateOrderLine[];
}): Promise<OrderQuote> {
  if (input.lines.length === 0) {
    throw new Error('El pedido no tiene líneas.');
  }

  const uids = [...new Set(input.lines.map((line) => line.productUid))];
  const { data, error } = await supabaseAdmin
    .from('products')
    .select('uid, name, price, supplier_id, active')
    .in('uid', uids);

  if (error) {
    throw new Error(`No se pudieron cargar los productos: ${error.message}`);
  }

  const products = new Map(
    ((data ?? []) as ProductRow[]).map((row) => [row.uid, row]),
  );

  const items: QuotedOrderItem[] = input.lines.map((line) => {
    if (!Number.isInteger(line.qty) || line.qty <= 0) {
      throw new Error(`Cantidad inválida para ${line.productUid}.`);
    }

    const product = products.get(line.productUid);
    if (!product) {
      throw new Error(`Producto no encontrado: ${line.productUid}.`);
    }
    if (!product.active) {
      throw new Error(`El producto ${product.name} no está activo.`);
    }
    if (product.supplier_id !== input.supplierId) {
      throw new Error(
        `El producto ${product.uid} no pertenece al proveedor indicado.`,
      );
    }

    const unitPrice = Number(product.price);
    return {
      productUid: product.uid,
      name: product.name,
      qty: line.qty,
      unitPrice,
      lineTotal: Number((unitPrice * line.qty).toFixed(2)),
    };
  });

  const subtotal = Number(
    items.reduce((sum, item) => sum + item.lineTotal, 0).toFixed(2),
  );

  return { supplierId: input.supplierId, items, subtotal };
}

export async function createOrder(
  input: CreateOrderInput,
  quote?: OrderQuote,
): Promise<CreatedOrder> {
  const resolved = quote ?? (await quoteOrder(input));

  const { data: order, error: orderError } = await supabaseAdmin
    .from('orders')
    .insert({
      store_id: input.storeId,
      supplier_id: input.supplierId,
      created_by_type: input.createdByType,
      created_by_id: input.createdById ?? null,
      subtotal: resolved.subtotal,
      total: resolved.subtotal,
      status: input.status,
      agent_run_id: input.agentRunId ?? null,
      idempotency_key: randomUUID(),
    })
    .select('id')
    .single();

  if (orderError || !order) {
    throw new Error(`No se pudo crear el pedido: ${orderError?.message}`);
  }

  const { error: itemsError } = await supabaseAdmin.from('order_items').insert(
    resolved.items.map((item) => ({
      order_id: order.id,
      product_uid: item.productUid,
      name: item.name,
      qty: item.qty,
      unit_price: item.unitPrice,
      line_total: item.lineTotal,
    })),
  );

  if (itemsError) {
    throw new Error(`No se pudieron guardar las líneas: ${itemsError.message}`);
  }

  return {
    id: order.id,
    storeId: input.storeId,
    supplierId: input.supplierId,
    status: input.status,
    items: resolved.items,
    subtotal: resolved.subtotal,
    total: resolved.subtotal,
  };
}
