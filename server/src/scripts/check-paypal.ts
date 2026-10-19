import {
  getPayPalAccessToken,
  paypalConfigured,
} from '../application/paypal/paypal_client.js';

if (!paypalConfigured()) {
  console.error('Faltan PAYPAL_CLIENT_ID o PAYPAL_CLIENT_SECRET.');
  process.exit(1);
}

try {
  await getPayPalAccessToken();
  console.log('PayPal conectado correctamente (sandbox).');
} catch (error) {
  console.error(
    'No se pudo conectar con PayPal:',
    error instanceof Error ? error.message : error,
  );
  process.exit(1);
}
