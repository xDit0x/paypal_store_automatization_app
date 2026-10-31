import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

export interface ImportResult {
  countCreated: number;
  countUpdated: number;
  countDeactivated: number;
  errors: string[];
}

export interface CatalogProductItem {
  id?: string;
  sku?: string;
  product?: string;
  name?: string;
  description?: string;
  price?: number;
  unit_price?: number;
  cost?: number;
  currency?: string;
  unit?: string;
  active?: boolean;
}

export interface CatalogPayload {
  supplier?: string;
  currency?: string;
  products?: CatalogProductItem[];
  items?: CatalogProductItem[];
  catalog?: CatalogProductItem[];
}

function parseJson(content: string): { currency: string; items: CatalogProductItem[] } {
  try {
    const parsed = JSON.parse(content) as CatalogPayload | CatalogProductItem[];
    const rootCurrency = !Array.isArray(parsed) && typeof parsed === 'object' && parsed.currency ? String(parsed.currency).trim().toUpperCase() : 'EUR';
    const rawList = Array.isArray(parsed)
      ? parsed
      : Array.isArray(parsed?.products)
      ? parsed.products
      : Array.isArray(parsed?.items)
      ? parsed.items
      : Array.isArray(parsed?.catalog)
      ? parsed.catalog
      : [];

    const items: CatalogProductItem[] = [];
    for (const row of rawList) {
      if (!row || typeof row !== 'object') continue;
      const sku = String(row.sku ?? row.id ?? '').trim();
      const name = String(row.name ?? row.product ?? '').trim();
      const description = row.description ? String(row.description).trim() : undefined;
      const priceRaw = row.price ?? row.unit_price ?? 0;
      const price = parseFloat(String(priceRaw).replace(',', '.'));
      const currency = row.currency ? String(row.currency).trim().toUpperCase() : rootCurrency;
      const unit = row.unit ? String(row.unit).trim() : 'unidad';
      const active = row.active !== false;

      if (!sku || !name || isNaN(price)) continue;
      items.push({ sku, name, description, price, currency, unit, active });
    }
    return { currency: rootCurrency, items };
  } catch {
    return { currency: 'EUR', items: [] };
  }
}

export async function importCatalog(options: {
  supplierId?: string;
  supplierCode?: string;
  type: 'json' | 'csv';
  content: string;
}): Promise<ImportResult> {
  const result: ImportResult = {
    countCreated: 0,
    countUpdated: 0,
    countDeactivated: 0,
    errors: [],
  };

  const content = options.content;
  if (!content || typeof content !== 'string') {
    result.errors.push('Contenido vacío o no es texto');
    return result;
  }

  const { items } = parseJson(content);
  if (items.length === 0) {
    result.errors.push('No se encontraron productos válidos en el JSON');
    return result;
  }

  // Resolver proveedor por id o por code
  let supplierId = options.supplierId;
  const supplierCode = options.supplierCode?.trim().toLowerCase();

  if (!supplierId && supplierCode) {
    const { data, error } = await supabaseAdmin
      .from('suppliers')
      .select('id')
      .eq('code', supplierCode)
      .maybeSingle();
    if (error || !data) {
      result.errors.push(`Proveedor con código "${supplierCode}" no encontrado`);
      return result;
    }
    supplierId = data.id;
  }

  if (!supplierId) {
    result.errors.push('Falta supplierId o supplierCode');
    return result;
  }

  // Validaciones
  const seen = new Set<string>();
  for (const item of items) {
    if (seen.has(item.sku!)) {
      result.errors.push('SKU duplicado en el feed: ' + (item.sku ?? ''));
    }
    seen.add(item.sku!);
    if ((item.price ?? 0) <= 0) {
      result.errors.push('El precio debe ser > 0 para SKU: ' + (item.sku ?? ''));
    }
  }
  if (result.errors.length > 0) {
    return result;
  }

  // Leer productos existentes del proveedor
  const { data: existingProducts, error: existingError } = await supabaseAdmin
    .from('products')
    .select('uid, active')
    .eq('supplier_id', supplierId);

  if (existingError) {
    result.errors.push('Error leyendo productos existentes: ' + existingError.message);
    return result;
  }

  const existingUids = new Set<string>((existingProducts ?? []).map((p) => p.uid));
  const importedUids = new Set<string>(items.map((i) => i.sku ?? ''));

  // Upsert en products
  for (const item of items) {
    const { error: upsertError } = await supabaseAdmin.from('products').upsert({
      uid: item.sku,
      supplier_id: supplierId,
      name: item.name,
      description: item.description ?? null,
      price: item.price,
      currency: item.currency ?? 'EUR',
      unit: item.unit ?? 'unidad',
      active: item.active ?? true,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'uid' });

    if (upsertError) {
      result.errors.push(`Upsert fallido para ${item.sku ?? '??'}: ${upsertError.message}`);
    } else if (existingUids.has(item.sku ?? '')) {
      result.countUpdated++;
    } else {
      result.countCreated++;
    }
  }

  // Desactivar productos ausentes
  for (const uid of existingUids) {
    if (!importedUids.has(uid)) {
      const { error: deactError } = await supabaseAdmin
        .from('products')
        .update({ active: false, updated_at: new Date().toISOString() })
        .eq('uid', uid);
      if (deactError) {
        result.errors.push(`Desactivación fallida para ${uid}: ${deactError.message}`);
      } else {
        result.countDeactivated++;
      }
    }
  }

  // Registrar auditoría
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
