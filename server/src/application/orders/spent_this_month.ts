import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

/**
 * Estados en los que el gasto ya está comprometido: autorizado (dinero
 * retenido), cobrado tras la entrega (total o parcial) o pagado.
 */
export const SPENT_STATUSES: string[] = [
  'authorized',
  'delivered',
  'partially_delivered',
  'paid',
  'invoiced',
  'completed',
];

/**
 * Un pedido recién aprobado aún no ha movido dinero, pero en cuanto el
 * servidor crea la orden de PayPal el importe queda comprometido (y la app
 * ya lo presenta como pagado). Se cuenta solo si existe esa orden.
 */
const APPROVED = 'approved';

export interface SpentOrderRow {
  status?: string | null;
  total: number | string;
  received_total?: number | string | null;
  payment_payout_id?: string | null;
  created_at?: string | null;
  approval_at?: string | null;
  authorized_at?: string | null;
  payment_at?: string | null;
}

export function isCommitted(row: SpentOrderRow): boolean {
  if (row.status !== APPROVED) return true;
  return typeof row.payment_payout_id === 'string' && row.payment_payout_id !== '';
}

/** Fecha con la que el pedido entra en el gasto del mes. */
function spentOn(row: SpentOrderRow): Date | null {
  for (const value of [
    row.payment_at,
    row.authorized_at,
    row.approval_at,
    row.created_at,
  ]) {
    if (!value) continue;
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return null;
}

/**
 * Suma el gasto real desde `since`. Puro para poder testearlo sin Supabase.
 * En entregas parciales cuenta solo lo cobrado (`received_total`); en el
 * resto, el total del pedido.
 */
export function sumSpent(rows: SpentOrderRow[], since: Date): number {
  const spent = rows.reduce((sum, row) => {
    if (!isCommitted(row)) return sum;

    const when = spentOn(row);
    if (!when || when.getTime() < since.getTime()) return sum;

    const captured =
      row.received_total == null ? null : Number(row.received_total);
    return sum + (captured ?? Number(row.total ?? 0));
  }, 0);

  return Number(spent.toFixed(2));
}

export async function getSpentThisMonth(storeId: string): Promise<number> {
  const now = new Date();
  const startOfMonth = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
  );

  const { data, error } = await supabaseAdmin
    .from('orders')
    .select(
      'status, total, received_total, payment_payout_id, created_at, approval_at, authorized_at, payment_at',
    )
    .eq('store_id', storeId)
    .in('status', [...SPENT_STATUSES, APPROVED]);

  if (error) {
    throw new Error(`No se pudo calcular el gasto mensual: ${error.message}`);
  }

  return sumSpent((data ?? []) as SpentOrderRow[], startOfMonth);
}
