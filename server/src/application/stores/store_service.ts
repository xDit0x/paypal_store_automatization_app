import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import {
  mapSpendingRules,
  type SpendingRules,
} from '../../domain/spending_rules.js';

export interface StoreContext {
  id: string;
  name: string;
  currency: string;
  paypalMerchantEmail: string | null;
  notificationEmail: string | null;
  rules: SpendingRules;
}

interface StoreRow {
  id: string;
  name: string;
  currency: string;
  paypal_merchant_email: string | null;
  notification_email: string | null;
}

export async function getStoreForOwner(
  storeId: string,
  ownerId: string,
): Promise<StoreContext> {
  const { data, error } = await supabaseAdmin
    .from('stores')
    .select('id, name, currency, paypal_merchant_email, notification_email')
    .eq('id', storeId)
    .eq('owner_id', ownerId)
    .maybeSingle();

  if (error) {
    throw new Error(`No se pudo cargar la tienda: ${error.message}`);
  }
  if (!data) {
    throw new Error('La tienda no existe o no pertenece al usuario.');
  }

  const store = data as StoreRow;
  const { data: rulesRow, error: rulesError } = await supabaseAdmin
    .from('spending_rules')
    .select('max_per_order, monthly_limit, require_approval_above, allowed_supplier_ids')
    .eq('store_id', storeId)
    .maybeSingle();

  if (rulesError) {
    throw new Error(`No se pudieron cargar las reglas: ${rulesError.message}`);
  }

  return {
    id: store.id,
    name: store.name,
    currency: store.currency,
    paypalMerchantEmail: store.paypal_merchant_email,
    notificationEmail: store.notification_email,
    rules: mapSpendingRules(rulesRow ?? {}),
  };
}
