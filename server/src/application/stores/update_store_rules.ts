import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import { mapSpendingRules, type SpendingRules } from '../../domain/spending_rules.js';

/**
 * Actualiza las reglas de gasto de una tienda (límite mensual, máximo por
 * pedido, umbral de aprobación). Lo escribe el servidor con service_role: la
 * app también lo hace desde la pestaña Reglas, pero el asistente de compras
 * necesita poder ajustarlas cuando el dueño lo pide por chat.
 */
export async function updateStoreRules(
  storeId: string,
  rules: SpendingRules,
): Promise<SpendingRules> {
  const { data, error } = await supabaseAdmin
    .from('spending_rules')
    .upsert(
      {
        store_id: storeId,
        max_per_order: rules.maxPerOrder,
        monthly_limit: rules.monthlyLimit,
        require_approval_above: rules.requireApprovalAbove,
        allowed_supplier_ids: rules.allowedSupplierIds,
      },
      { onConflict: 'store_id' },
    )
    .select(
      'store_id, max_per_order, monthly_limit, require_approval_above, allowed_supplier_ids',
    )
    .single();

  if (error) {
    throw new Error(`No se pudo actualizar las reglas: ${error.message}`);
  }

  return mapSpendingRules(
    (data ?? {}) as Parameters<typeof mapSpendingRules>[0],
  );
}
