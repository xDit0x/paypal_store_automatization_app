// Lanza ahora mismo la revisión automática para todas las tiendas.
// Sirve para probarla sin esperar a las 9:00 y como comando de un
// Cron Job (por ejemplo en Render): npm run job:restock
import { runRestockForAllStores } from '../jobs/scheduled_restock.js';

const logger = {
  info: (_obj: unknown, msg?: string) => console.log(msg ?? ''),
  warn: (_obj: unknown, msg?: string) => console.warn(msg ?? ''),
  error: (obj: unknown, msg?: string) => console.error(msg ?? '', obj),
};

try {
  const results = await runRestockForAllStores(logger);
  console.log(JSON.stringify(results, null, 2));
  process.exit(0);
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
