import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const { data, error } = await supabaseAdmin
  .from('suppliers')
  .select('id, name, category')
  .limit(5);

if (error) {
  console.error('Error conectando con Supabase:', error.message);
  process.exit(1);
}

console.log(`Supabase conectado. Proveedores encontrados: ${data.length}`);
for (const supplier of data) {
  console.log(`- ${supplier.name} (${supplier.category ?? 'sin categoría'})`);
}
