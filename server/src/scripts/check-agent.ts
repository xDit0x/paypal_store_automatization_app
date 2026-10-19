import { runAgent } from '../application/agent/run_agent.js';
import { getStoreForOwner } from '../application/stores/store_service.js';
import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const storeId = process.env.STORE_ID;

let query = supabaseAdmin.from('stores').select('id, owner_id, name');
if (storeId) {
  query = query.eq('id', storeId);
}

const { data, error } = await query.limit(1).maybeSingle();

if (error) {
  console.error('No se pudo leer la tienda:', error.message);
  process.exit(1);
}

if (!data) {
  console.error(
    'No hay tiendas. Registra un usuario en la app o define STORE_ID.',
  );
  process.exit(1);
}

const store = await getStoreForOwner(data.id, data.owner_id);
console.log(`Tienda: ${store.name} (${store.id})`);

const result = await runAgent({ store, userId: data.owner_id });
console.log(JSON.stringify(result, null, 2));
