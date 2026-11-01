import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import { matchProductKey, type MarketOffer } from '../src/application/market/market_math.js';

// Lee las ofertas del seed de la migración para comprobar que las frases
// típicas del dueño encuentran el producto correcto.
const sql = ['20261101000000_sebas_market_directory.sql', '20261101000001_sebas_market_directory_more.sql']
  .map((file) => readFileSync(new URL(`../../supabase/migrations/${file}`, import.meta.url), 'utf8'))
  .join('\n');
const offers: MarketOffer[] = [
  ...sql.matchAll(/'([a-z-]+)', '([a-z-]+)', '([^']+)', array\[([^\]]+)\]::text\[\]/g),
].map((m, i) => ({
  id: String(i), distributorId: 'd', sku: m[1]!, productKey: m[2]!, name: m[3]!,
  keywords: [...m[4]!.matchAll(/'([^']+)'/g)].map((k) => k[1]!),
  unit: 'u', price: 1, minQty: 1, packSize: 1, notes: null,
}));

test('el seed tiene ofertas de los 19 productos', () => {
  assert.ok(offers.length >= 60);
  assert.equal(new Set(offers.map((o) => o.productKey)).size, 19);
});

const cases: [string, string | null][] = [
  ['Quiero empezar a vender leche de avena para los lattes', 'oat-barista'],
  ['necesito bebida vegetal de avena', 'oat-barista'],
  ['quiero meter kombucha en la nevera', 'kombucha'],
  ['busco un café de especialidad en grano', 'coffee-beans'],
  ['matcha para hacer matcha latte', 'matcha'],
  ['vasos compostables para llevar', 'compostable-cups'],
  ['I want to sell oat milk', 'oat-barista'],
  ['osos de gominola, tamaño pequeño en bolsa, marca haribo', 'gummy-bears'],
  ['quiero chuches a granel', 'gummies-bulk'],
  ['latas de coca cola', 'cola'],
  ['patatas fritas para la barra', 'chips'],
  ['cruasanes congelados', 'croissants'],
  ['sobres de azúcar', 'sugar-sticks'],
  ['zumo de naranja natural', 'orange-juice'],
  ['quiero vender bicicletas', null],
];

for (const [query, expected] of cases) {
  test(`"${query}" -> ${expected}`, () => {
    assert.equal(matchProductKey(query, offers), expected);
  });
}
