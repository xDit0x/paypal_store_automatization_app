import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/spending_rules.dart';

void main() {
  const rules = SpendingRules(
    maxPerOrder: 200,
    monthlyLimit: 800,
    requireApprovalAbove: 50,
  );

  group('SpendingRules.evaluate', () {
    test('auto aprueba pedidos pequeños de proveedores válidos', () {
      final decision = rules.evaluate(
        orderTotal: 30,
        spentThisMonth: 0,
        supplierId: 'sup-1',
      );

      expect(decision.status, SpendingDecisionStatus.autoApproved);
      expect(decision.canProceed, isTrue);
      expect(decision.needsApproval, isFalse);
    });

    test('requiere aprobación por encima del umbral', () {
      final decision = rules.evaluate(
        orderTotal: 120,
        spentThisMonth: 0,
        supplierId: 'sup-1',
      );

      expect(decision.status, SpendingDecisionStatus.requiresApproval);
      expect(decision.canProceed, isTrue);
      expect(decision.needsApproval, isTrue);
    });

    test('bloquea pedidos sin importe', () {
      final decision = rules.evaluate(
        orderTotal: 0,
        spentThisMonth: 0,
        supplierId: 'sup-1',
      );

      expect(decision.isBlocked, isTrue);
    });

    test('bloquea pedidos por encima del máximo por pedido', () {
      final decision = rules.evaluate(
        orderTotal: 250,
        spentThisMonth: 0,
        supplierId: 'sup-1',
      );

      expect(decision.isBlocked, isTrue);
    });

    test('bloquea si supera el límite mensual acumulado', () {
      final decision = rules.evaluate(
        orderTotal: 100,
        spentThisMonth: 750,
        supplierId: 'sup-1',
      );

      expect(decision.isBlocked, isTrue);
    });

    test('bloquea proveedores fuera de la lista permitida', () {
      const restricted = SpendingRules(
        allowedSupplierIds: ['sup-1', 'sup-2'],
      );

      final decision = restricted.evaluate(
        orderTotal: 10,
        spentThisMonth: 0,
        supplierId: 'sup-9',
      );

      expect(decision.isBlocked, isTrue);
    });
  });
}
