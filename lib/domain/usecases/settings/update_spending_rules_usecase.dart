import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/repositories/settings_repository/settings_repository.dart';

class UpdateSpendingRulesUsecase {
  final SettingsRepository repository;
  UpdateSpendingRulesUsecase({required this.repository});

  Future<Either<String, Unit>> call(
    String storeId,
    SpendingRules rules,
  ) {
    if (rules.maxPerOrder <= 0) {
      return Future.value(const Left('El máximo por pedido debe ser mayor que 0.'));
    }
    if (rules.monthlyLimit < rules.maxPerOrder) {
      return Future.value(
        const Left('El límite mensual no puede ser menor que el máximo por pedido.'),
      );
    }
    if (rules.requireApprovalAbove > rules.maxPerOrder) {
      return Future.value(
        const Left('El umbral de aprobación no puede superar el máximo por pedido.'),
      );
    }
    return repository.updateSpendingRules(storeId, rules);
  }
}
