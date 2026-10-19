import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const email = process.env.DEMO_EMAIL ?? 'demo@restock.dev';
const password = process.env.DEMO_PASSWORD ?? 'Restock2026!';

const { data, error } = await supabaseAdmin.auth.admin.createUser({
  email,
  password,
  email_confirm: true,
  user_metadata: { store_name: 'Tienda Demo' },
});

if (error) {
  if (error.message.toLowerCase().includes('already')) {
    console.log(`El usuario ${email} ya existe.`);
    process.exit(0);
  }
  console.error('No se pudo crear el usuario demo:', error.message);
  process.exit(1);
}

console.log(`Usuario demo creado: ${data.user?.email}`);
console.log(`Contraseña: ${password}`);
