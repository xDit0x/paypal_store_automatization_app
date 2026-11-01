import assert from 'node:assert/strict';
import test from 'node:test';

import {
  isInRegion,
  landedCost,
  matchProductKey,
  parseRegion,
  rankOffers,
  type MarketDistributor,
  type MarketOffer,
} from '../src/application/market/market_math.js';

const rates = { USD: 1.1, GBP: 0.85 };

function dist(over: Partial<MarketDistributor> = {}): MarketDistributor {
  return {
    id: 'd1', code: 'd1', name: 'Dist', country: 'ES', city: null, currency: 'EUR',
    paypalEmail: null, website: null, rating: 4.5, leadDays: 3, shippingBase: 10,
    shippingPerUnit: 0.5, freeShippingOver: null, dutyRate: 0, description: null, ...over,
  };
}

function offer(over: Partial<MarketOffer> = {}): MarketOffer {
  return {
    id: 'o1', distributorId: 'd1', sku: 'oat-barista', productKey: 'oat-barista',
    name: 'Bebida de avena barista 1 L', keywords: ['avena', 'leche de avena', 'oat milk'],
    unit: 'L', price: 2, minQty: 12, packSize: 6, notes: null, ...over,
  };
}

test('regiones', () => {
  assert.equal(isInRegion('ES', 'spain'), true);
  assert.equal(isInRegion('PT', 'spain'), false);
  assert.equal(isInRegion('GB', 'europe'), true);
  assert.equal(isInRegion('CO', 'europe'), false);
  assert.equal(isInRegion('JP', 'world'), true);
  assert.equal(parseRegion('Solo España'), 'spain');
  assert.equal(parseRegion('europa'), 'europe');
  assert.equal(parseRegion('todo el mundo'), 'world');
});

test('reconoce el producto pedido en lenguaje natural', () => {
  const offers = [
    offer(),
    offer({ id: 'o2', productKey: 'matcha', name: 'Matcha ceremonial 100 g', keywords: ['matcha', 'te verde'] }),
  ];
  assert.equal(matchProductKey('Quiero vender leche de avena para los cafés', offers), 'oat-barista');
  assert.equal(matchProductKey('un MATCHA bueno', offers), 'matcha');
  assert.equal(matchProductKey('tornillos', offers), null);
});

test('coste real: mínimo, cajas completas y envío', () => {
  const cost = landedCost({ offer: offer(), distributor: dist(), quantity: 20, rates });
  assert.equal(cost.orderQty, 24); // 20 -> cajas de 6
  assert.equal(cost.extraUnits, 4);
  assert.equal(cost.goodsEur, 48);
  assert.equal(cost.shippingEur, 22); // 10 + 0.5 * 24
  assert.equal(cost.totalEur, 70);
  assert.equal(cost.unitLandedEur, 2.92);
});

test('sin cantidad se usa el pedido mínimo', () => {
  const cost = landedCost({ offer: offer(), distributor: dist(), rates });
  assert.equal(cost.orderQty, 12);
  assert.equal(cost.extraUnits, 0);
});

test('envío gratis y aranceles con cambio de moneda', () => {
  const cost = landedCost({
    offer: offer({ price: 11 }),
    distributor: dist({ country: 'CO', currency: 'USD', freeShippingOver: 100, dutyRate: 0.1 }),
    quantity: 12,
    rates,
  });
  assert.equal(cost.goodsEur, 120); // 132 USD / 1.1
  assert.equal(cost.shippingEur, 0);
  assert.equal(cost.dutiesEur, 12);
  assert.equal(cost.outsideEu, true);
});

test('moneda sin tipo de cambio lanza error', () => {
  assert.throws(() => landedCost({ offer: offer(), distributor: dist({ currency: 'XYZ' }), rates }));
});

test('ranking: top 3, etiquetas y presupuesto', () => {
  const costs = [
    landedCost({ offer: offer({ id: 'a', price: 3 }), distributor: dist({ id: 'a', leadDays: 1, rating: 4.9 }), rates }),
    landedCost({ offer: offer({ id: 'b', price: 1 }), distributor: dist({ id: 'b', leadDays: 5 }), rates }),
    landedCost({ offer: offer({ id: 'c', price: 2 }), distributor: dist({ id: 'c', leadDays: 4 }), rates }),
    landedCost({ offer: offer({ id: 'd', price: 5 }), distributor: dist({ id: 'd' }), rates }),
  ];
  const top = rankOffers(costs);
  assert.deepEqual(top.map((c) => c.offerId), ['b', 'c', 'a']);
  assert.ok(top[0]!.tags.includes('cheapest'));
  assert.ok(top[2]!.tags.includes('fastest'));
  assert.ok(top[2]!.tags.includes('best_rated'));

  const cheap = rankOffers(costs, { maxUnitPriceEur: 2.5 });
  assert.deepEqual(cheap.map((c) => c.offerId), ['b']);

  const none = rankOffers(costs, { maxUnitPriceEur: 0.5 });
  assert.equal(none.length, 3);
  assert.ok(none.every((c) => c.overBudget));
});
