import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

export interface ImportResult {
  countCreated: number;
  countUpdated: number;
  countDeactivated: number;
  errors: string[];
}

export interface CatalogItem {
  sku: string;
  name: string;
  price: number;
}

function parseCsv(content: string): CatalogItem[] {
  const lines = content.trim().split(/\r?\n/).filter((l) => l.trim() !== '');
  if (lines.length === 0) return [];
  const first = lines.at(0);
  if (!first) return [];
  const header = first.split(',').map((h) => h.trim().toLowerCase());
  const items: CatalogItem[] = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines.at(i);
    if (!line) continue;
    const cols = line.split(',').map((c) => c.trim());
    if (cols.length < 3) continue;
    const sku = cols[0];
    const name = cols[1];
    const priceStr = cols[2];
    if (!sku || !name || priceStr === undefined) continue;
    const price = parseFloat(priceStr.replace(',', '.'));
    if (isNaN(price)) continue;
    items.push({ sku, name, price });
  }
  return items;
}

function parseJson(content: string): CatalogItem[] {
  try {
    const parsed = JSON.parse(content);
    const arr = Array.isArray(parsed) ? parsed : parsed?.items ?? parsed?.catalog ?? [];
    if (!Array.isArray(arr)) return [];
    const items: CatalogItem[] = [];
    for (const row of arr) {
      if (!row || typeof row !== 'object') continue;
      const sku = String(row.sku ?? row.uid ?? row.id ?? '').trim();
      const name = String(row.name ?? row.product ?? '').trim();
      const priceRaw = row.price ?? row.unit_price ?? row.cost ?? 0;
      const price = parseFloat(String(priceRaw).replace(',', '.'));
      if (!sku || !name || isNaN(price)) continue;
      items.push({ sku, name, price });
    }
    return items;
  } catch {
    return [];
  }
}

export async function importCatalog(options: {
  storeId: string;
  type: 'csv' | 'json';
  file?: string;
  content?: string;
}): Promise<ImportResult> {
  const result: ImportResult = {
    countCreated: 0,
    countUpdated: 0,
    countDeactivated: 0,
    errors: [],
  };

  if (!options.storeId) {
    result.errors.push('storeId es obligatorio');
    return result;
  }

  const content = options.content ?? (options.file ? await readFile(options.file) : '');
  if (!content || typeof content !== 'string') {
    result.errors.push('Contenido vacío o no es texto');
    return result;
  }

  let items: CatalogItem[] = [];
  if (options.type === 'csv') {
    items = parseCsv(content);
  } else if (options.type === 'json') {
    items = parseJson(content);
  } else {
    result.errors.push('Tipo no soportado: ' + options.type);
    return result;
  }

  if (items.length === 0) {
    result.errors.push('No se encontraron productos válidos');
    return result;
  }

  // Validaciones: SKU único, precio > 0
  const seen = new Set<string>();
  for (const item of items) {
    if (seen.has(item.sku)) {
      result.errors.push('SKU duplicado: ' + item.sku);
    }
    seen.add(item.sku);
    if (item.price <= 0) {
      result.errors.push('Precio debe ser > 0 para SKU: ' + item.sku);
    }
  }
  if (result.errors.length > 0) {
    return result;
  }

  // Buscar supplier por storeId (interpretamos storeId como supplier_id para importación)
  const supplierId = options.storeId;
  const { data: supplierData, error: supplierError } = await supabaseAdmin
    .from('suppliers')
    .select('id, code')
    .eq('id', supplierId)
    .single();

  if (supplierError || !supplierData) {
    result.errors.push('Proveedor no encontrado: ' + supplierId);
    return result;
  }

  // Actualizar suppliers.code — usamos el código derivado del proveedor o el que se pasa
  const supplierCode = supplierData.code ?? 'provider';
  await supabaseAdmin.from('suppliers').update({ code: supplierCode }).eq('id', supplierId);

  // Obtener productos actuales del proveedor para comparar
  const { data: existingProducts, error: existingError } = await supabaseAdmin
    .from('products')
    .select('uid, active')
    .eq('supplier_id', supplierId);

  if (existingError) {
    result.errors.push('Error leyendo productos existentes: ' + existingError.message);
  }

  const existingUids = new Set<string>((existingProducts ?? []).map((p) => p.uid));
  const importedUids = new Set<string>(items.map((i) => i.sku));

  // Upsert en products
  for (const item of items) {
    const { error: upsertError } = await supabaseAdmin.from('products').upsert({
      uid: item.sku,
      supplier_id: supplierId,
      name: item.name,
      price: item.price,
      currency: 'EUR',
      active: true,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'uid' });

    if (upsertError) {
      result.errors.push('Upsert fallido para ' + item.sku + ': ' + upsertError.message);
    } else if (existingUids.has(item.sku)) {
      result.countUpdated++;
    } else {
      result.countCreated++;
    }
  }

  // Desactivar productos que ya no vienen (importación completa)
  for (const uid of existingUids) {
    if (!importedUids.has(uid)) {
      const { error: deactError } = await supabaseAdmin
        .from('products')
        .update({ active: false, updated_at: new Date().toISOString() })
        .eq('uid', uid);
      if (deactError) {
        result.errors.push('Desactivación fallida para ' + uid + ': ' + deactError.message);
      } else {
        result.countDeactivated++;
      }
    }
  }

  // Registrar en catalog_imports
  await supabaseAdmin.from('catalog_imports').insert({
    supplier_id: supplierId,
    source: options.type,
    result_json: {
      count_created: result.countCreated,
      count_updated: result.countUpdated,
      count_deactivated: result.countDeactivated,
      errors: result.errors,
    },
    errors_json: result.errors,
    created_at: new Date().toISOString(),
  });

  return result;
}

async function readFile(filePath: string): Promise<string> {
  try {
    const { readFileSync } = await import('fs');
    return readFileSync(filePath, 'utf-8');
  } catch {
    return '';
  }
}
