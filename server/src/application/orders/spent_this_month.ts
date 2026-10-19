import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

export async function getSpentThisMonth(storeId: string): Promise<number> {
  const now = new Date();
  const startOfMonth = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
  );

  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('total')
    .eq('store_id', storeId)
    .in('status', ['paid', 'invoiced', 'completed'])
    .gte('created_at', startOfMonth.toISOString());

  if (error) {
    throw new Error(`No se pudo calcular el gasto mensual: ${error.message}`);
  }

  return Number(
    ((data ?? []) as { total: number | string }[])
      .reduce((sum, row) => sum + Number(row.total), 0)
      .toFixed(2),
  );
}
