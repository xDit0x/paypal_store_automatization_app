import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const { data, error } = await supabaseAdmin
  .from('products')
  .select('uid, name, stock, low_stock_threshold')
  .order('uid');

if (error) {
  console.error('No se pudo leer el stock:', error.message);
  process.exit(1);
}

for (const product of data ?? []) {
  const stock = Number(product.stock);
  const threshold = Number(product.low_stock_threshold);
  const marker = stock <= threshold ? 'BAJO' : 'ok';
  console.log(
    `${product.uid} ${product.name}: ${stock}/${threshold} [${marker}]`,
  );
}
