import { runAgent } from '../application/agent/run_agent.js';
import { getStoreForOwner } from '../application/stores/store_service.js';
import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';
import { dueSlot, parseSchedule, zonedTime } from './restock_schedule.js';

interface JobLogger {
  info(obj: unknown, msg?: string): void;
  warn(obj: unknown, msg?: string): void;
  error(obj: unknown, msg?: string): void;
}

export interface StoreRestockResult {
  storeId: string;
  storeName: string;
  decision: string;
  orderId: string | null;
  message: string;
}

/**
 * Lanza el agente de reposición para cada tienda, una detrás de otra.
 * Si una tienda falla, se registra y se sigue con las demás.
 */
export async function runRestockForAllStores(
  logger: JobLogger,
): Promise<StoreRestockResult[]> {
  // RESTOCK_STORE_IDS limita la revisión a ciertas tiendas (útil cuando cada
  // miembro del equipo tiene su propio servidor). Vacío = todas.
  const onlyStores = (process.env.RESTOCK_STORE_IDS ?? '')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);

  let query = supabaseAdmin.from('stores').select('id, owner_id, name');
  if (onlyStores.length > 0) {
    query = query.in('id', onlyStores);
  }
  const { data, error } = await query;

  if (error) {
    throw new Error(`No se pudieron cargar las tiendas: ${error.message}`);
  }

  const results: StoreRestockResult[] = [];
  for (const row of (data ?? []) as { id: string; owner_id: string; name: string }[]) {
    try {
      const store = await getStoreForOwner(row.id, row.owner_id);
      const result = await runAgent({ store, userId: row.owner_id });
      results.push({
        storeId: row.id,
        storeName: row.name,
        decision: result.decision,
        orderId: result.orderId,
        message: result.message,
      });
      logger.info(
        { storeId: row.id, decision: result.decision, orderId: result.orderId },
        `Revisión automática de "${row.name}": ${result.decision}`,
      );
    } catch (storeError) {
      const message = storeError instanceof Error ? storeError.message : String(storeError);
      results.push({
        storeId: row.id,
        storeName: row.name,
        decision: 'failed',
        orderId: null,
        message,
      });
      logger.error({ storeId: row.id, err: message }, `Revisión automática de "${row.name}" fallida`);
    }
  }
  return results;
}

/**
 * Programa la revisión automática dentro del servidor.
 *
 * Variables de entorno:
 * - RESTOCK_SCHEDULE: horas separadas por comas (por defecto "09:00,21:00").
 * - RESTOCK_TIMEZONE: zona horaria (por defecto "Europe/Madrid").
 * - RESTOCK_SCHEDULE_ENABLED: "false" para desactivarla.
 * - RESTOCK_STORE_IDS: ids de tienda separados por comas (vacío = todas).
 *
 * Devuelve una función para pararla.
 */
export function startRestockScheduler(logger: JobLogger): () => void {
  if ((process.env.RESTOCK_SCHEDULE_ENABLED ?? 'true').toLowerCase() === 'false') {
    logger.info({}, 'Revisión automática de stock desactivada (RESTOCK_SCHEDULE_ENABLED=false)');
    return () => {};
  }

  const timeZone = process.env.RESTOCK_TIMEZONE ?? 'Europe/Madrid';
  const slots = parseSchedule(process.env.RESTOCK_SCHEDULE ?? '09:00,21:00');
  if (slots.length === 0) {
    logger.warn({}, 'RESTOCK_SCHEDULE está vacío: no se programa ninguna revisión');
    return () => {};
  }

  // Comprueba que la zona horaria existe antes de programar nada.
  zonedTime(new Date(), timeZone);

  const alreadyRun = new Set<string>();
  let running = false;

  const tick = async (): Promise<void> => {
    if (running) return;
    const due = dueSlot({ now: zonedTime(new Date(), timeZone), slots, alreadyRun });
    if (!due) return;

    alreadyRun.add(due.key);
    running = true;
    logger.info({ slot: due.slot.label, timeZone }, 'Empieza la revisión automática de stock');
    try {
      const results = await runRestockForAllStores(logger);
      const ordered = results.filter((r) => r.orderId).length;
      logger.info(
        { slot: due.slot.label, stores: results.length, ordersCreated: ordered },
        'Revisión automática de stock terminada',
      );
    } catch (error) {
      logger.error(
        { err: error instanceof Error ? error.message : String(error) },
        'La revisión automática de stock falló',
      );
    } finally {
      running = false;
      // Las claves de días anteriores ya no sirven.
      const today = zonedTime(new Date(), timeZone).dateKey;
      for (const key of alreadyRun) {
        if (!key.startsWith(today)) alreadyRun.delete(key);
      }
    }
  };

  const timer = setInterval(() => void tick(), 30_000);
  void tick();

  logger.info(
    { schedule: slots.map((slot) => slot.label), timeZone },
    `Revisión automática de stock programada: ${slots.map((s) => s.label).join(' y ')} (${timeZone})`,
  );

  return () => clearInterval(timer);
}
