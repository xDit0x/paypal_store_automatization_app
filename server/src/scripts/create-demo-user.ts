import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

// Las credenciales de la cuenta demo vienen siempre del entorno: en un repo
// público, una contraseña por defecto es una puerta abierta.
const email = process.env.DEMO_EMAIL;
const password = process.env.DEMO_PASSWORD;

if (!email || !password) {
  console.error(
    'Define DEMO_EMAIL y DEMO_PASSWORD en el entorno (no hay valores por defecto).',
  );
  process.exit(1);
}

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
