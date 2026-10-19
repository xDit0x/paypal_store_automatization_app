import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';

Order _order({required String id, required double total, OrderStatus status = OrderStatus.pendingApproval}) {
  return Order(
    id: id,
    storeId: 'store',
    supplierId: 'sup-1',
    items: [OrderItem(productUid: 'PRD-1', name: 'Café', qty: 1, unitPrice: total)],
    subtotal: total,
    total: total,
    status: status,
    idempotencyKey: id,
  );
}

void main() {
  const rules = SpendingRules(maxPerOrder: 200, monthlyLimit: 800, requireApprovalAbove: 50);

  test('Presupuesto restante y progreso', () {
    const state = RestockState(rules: rules, spentThisMonth: 200);
    expect(state.remaining, 600);
    expect(state.budgetProgress, closeTo(0.25, 0.001));
  });

  test('Stock bajo ordenado del más urgente al menos', () {
    const state = RestockState(products: [
      Product(id: '1', uid: 'A', supplierId: 's', name: 'Leche', price: 1, stock: 5, lowStockThreshold: 10),
      Product(id: '2', uid: 'B', supplierId: 's', name: 'Café', price: 1, stock: 0, lowStockThreshold: 4),
      Product(id: '3', uid: 'C', supplierId: 's', name: 'Azúcar', price: 1, stock: 40, lowStockThreshold: 10),
    ]);
    expect(state.lowStock.map((p) => p.name), ['Café', 'Leche']);
  });

  test('Un producto con pedido pagado aparece en camino', () {
    final state = RestockState(orders: [_order(id: 'o1', total: 30, status: OrderStatus.paid)]);
    expect(state.uidsInTransit, contains('PRD-1'));
  });

  test('Motivo corto según las reglas', () {
    final state = RestockState(rules: rules, spentThisMonth: 100);
    expect(shortDecisionReason(state, _order(id: 'a', total: 30)), isNull);
    expect(shortDecisionReason(state, _order(id: 'b', total: 120)), contains('sin aprobación'));
    expect(shortDecisionReason(state, _order(id: 'c', total: 250)), contains('máximo'));
  });
}
