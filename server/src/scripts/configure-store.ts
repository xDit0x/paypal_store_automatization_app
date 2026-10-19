import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const merchantEmail = process.env.MERCHANT_EMAIL;
const storeId = process.env.STORE_ID;

if (!merchantEmail) {
  console.error('Define MERCHANT_EMAIL con el email de la cuenta Business.');
  process.exit(1);
}

let query = supabaseAdmin.from('stores').select('id, name');
if (storeId) {
  query = query.eq('id', storeId);
}

const { data, error } = await query.limit(1).maybeSingle();

if (error) {
  console.error('No se pudo leer la tienda:', error.message);
  process.exit(1);
}

if (!data) {
  console.error('No hay tiendas. Registra un usuario primero.');
  process.exit(1);
}

const { error: updateError } = await supabaseAdmin
  .from('stores')
  .update({ paypal_merchant_email: merchantEmail })
  .eq('id', data.id);

if (updateError) {
  console.error('No se pudo actualizar la tienda:', updateError.message);
  process.exit(1);
}

console.log(`Tienda ${data.name}: paypal_merchant_email = ${merchantEmail}`);
