import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_state.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/stocky_common.dart';

Order _order({
  required String id,
  required double total,
  OrderStatus status = OrderStatus.pendingApproval,
}) {
  return Order(
    id: id,
    storeId: 'store',
    supplierId: 'sup-1',
    items: [
      OrderItem(productUid: 'PRD-1', name: 'Café', qty: 1, unitPrice: total),
    ],
    subtotal: total,
    total: total,
    status: status,
    idempotencyKey: id,
  );
}

void main() {
  const rules = SpendingRules(
    maxPerOrder: 200,
    monthlyLimit: 800,
    requireApprovalAbove: 50,
  );

  test('Presupuesto restante y progreso', () {
    const state = StockyState(rules: rules, spentThisMonth: 200);
    expect(state.remaining, 600);
    expect(state.budgetProgress, closeTo(0.25, 0.001));
  });

  test('Stock bajo ordenado del más urgente al menos', () {
    const state = StockyState(
      products: [
        Product(
          id: '1',
          uid: 'A',
          supplierId: 's',
          name: 'Leche',
          price: 1,
          stock: 5,
          lowStockThreshold: 10,
        ),
        Product(
          id: '2',
          uid: 'B',
          supplierId: 's',
          name: 'Café',
          price: 1,
          stock: 0,
          lowStockThreshold: 4,
        ),
        Product(
          id: '3',
          uid: 'C',
          supplierId: 's',
          name: 'Azúcar',
          price: 1,
          stock: 40,
          lowStockThreshold: 10,
        ),
      ],
    );
    expect(state.lowStock.map((p) => p.name), ['Café', 'Leche']);
  });

  test('Un producto con pedido pagado aparece en camino', () {
    final state = StockyState(
      orders: [_order(id: 'o1', total: 30, status: OrderStatus.paid)],
    );
    expect(state.uidsInTransit, contains('PRD-1'));
  });

  test('Un pedido con el pago autorizado también está en camino', () {
    final state = StockyState(
      orders: [_order(id: 'o1', total: 30, status: OrderStatus.authorized)],
    );
    expect(state.uidsInTransit, contains('PRD-1'));
  });

  test('El pedido con entrega pendiente sale en ambos flujos', () {
    // El agente paga solo ('paid') y el pago retenido ('authorized'): en los
    // dos casos la mercancía se confirma con el albarán.
    final paid = StockyState(
      orders: [_order(id: 'o1', total: 30, status: OrderStatus.paid)],
    );
    expect(paid.latestDelivery?.id, 'o1');

    final authorized = StockyState(
      orders: [_order(id: 'o2', total: 30, status: OrderStatus.authorized)],
    );
    expect(authorized.latestDelivery?.id, 'o2');

    final pending = StockyState(
      orders: [_order(id: 'o3', total: 30, status: OrderStatus.pendingApproval)],
    );
    expect(pending.latestDelivery, isNull);
  });

  test('Motivo corto según las reglas', () {
    final l10n = lookupAppLocalizations(const Locale('es'));
    final state = StockyState(rules: rules, spentThisMonth: 100);
    expect(
      shortDecisionReason(l10n, state, _order(id: 'a', total: 30)),
      isNull,
    );
    expect(
      shortDecisionReason(l10n, state, _order(id: 'b', total: 120)),
      contains('sin aprobación'),
    );
    expect(
      shortDecisionReason(l10n, state, _order(id: 'c', total: 250)),
      contains('máximo'),
    );
  });
}
