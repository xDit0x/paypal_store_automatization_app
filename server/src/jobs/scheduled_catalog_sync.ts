import { importCatalog } from '../application/catalog/import_catalog.js';
import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

interface JobLogger {
  info(obj: unknown, msg?: string): void;
  warn(obj: unknown, msg?: string): void;
  error(obj: unknown, msg?: string): void;
}

interface CatalogSourceRow {
  id: string;
  supplier_id: string;
  url: string;
  token_env: string | null;
  etag: string | null;
  suppliers: { code: string; name: string } | null;
}

/**
 * Sincroniza los catálogos activos desde las URLs configuradas en
 * `supplier_catalog_sources`.
 */
export async function syncAllCatalogs(logger: JobLogger): Promise<void> {
  const { data, error } = await supabaseAdmin
    .from('supplier_catalog_sources')
    .select('id, supplier_id, url, token_env, etag, suppliers!inner(code, name)')
    .eq('active', true);

  if (error) {
    throw new Error(`No se pudieron cargar las fuentes de catálogo: ${error.message}`);
  }

  const sources = (data ?? []) as unknown as CatalogSourceRow[];
  if (sources.length === 0) return;

  for (const source of sources) {
    const supplierInfo = Array.isArray(source.suppliers) ? source.suppliers[0] : source.suppliers;
    const supplierName = supplierInfo?.name ?? source.supplier_id;

    try {
      const headers: Record<string, string> = {
        'Accept': 'application/json',
      };
      if (source.etag) {
        headers['If-None-Match'] = source.etag;
      }
      if (source.token_env && process.env[source.token_env]) {
        headers['Authorization'] = `Bearer ${process.env[source.token_env]}`;
      }

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 20_000);

      const res = await fetch(source.url, {
        headers,
        signal: controller.signal,
      }).finally(() => clearTimeout(timeout));

      if (res.status === 304) {
        logger.info({ supplier: supplierName }, 'Catálogo sin cambios (304 Not Modified)');
        continue;
      }

      if (!res.ok) {
        throw new Error(`HTTP error status: ${res.status} ${res.statusText}`);
      }

      const newEtag = res.headers.get('etag');
      const text = await res.text();

      const result = await importCatalog({
        supplierId: source.supplier_id,
        type: 'json',
        content: text,
      });

      if (result.errors.length > 0) {
        throw new Error(`Errores de importación: ${result.errors.join('; ')}`);
      }

      await supabaseAdmin
        .from('supplier_catalog_sources')
        .update({
          etag: newEtag,
          last_sync_at: new Date().toISOString(),
          last_status: 'success',
          last_error: null,
        })
        .eq('id', source.id);

      logger.info(
        { supplier: supplierName, created: result.countCreated, updated: result.countUpdated },
        `Catálogo de "${supplierName}" sincronizado correctamente`,
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error({ supplier: supplierName, err: message }, `Error sincronizando catálogo de "${supplierName}"`);

      await supabaseAdmin
        .from('supplier_catalog_sources')
        .update({
          last_sync_at: new Date().toISOString(),
          last_status: 'failed',
          last_error: message,
        })
        .eq('id', source.id);
    }
  }
}

/**
 * Programa la sincronización periódica de catálogos (por defecto cada 6 horas).
 */
export function startCatalogSyncScheduler(logger: JobLogger): () => void {
  const enabled = (process.env.CATALOG_SYNC_ENABLED ?? 'true').toLowerCase() !== 'false';
  if (!enabled) {
    logger.info({}, 'Sincronización automática de catálogos desactivada (CATALOG_SYNC_ENABLED=false)');
    return () => {};
  }

  const intervalMinutes = Number(process.env.CATALOG_SYNC_INTERVAL_MINUTES ?? 360);
  const ms = Math.max(5, intervalMinutes) * 60 * 1000;

  logger.info({ intervalMinutes }, 'Planificador de sincronización de catálogos iniciado');

  const timer = setInterval(() => {
    void syncAllCatalogs(logger).catch((error) => {
      logger.error(error, 'Error en el ciclo de sincronización automática de catálogos');
    });
  }, ms);

  if (typeof timer.unref === 'function') timer.unref();

  return () => clearInterval(timer);
}
