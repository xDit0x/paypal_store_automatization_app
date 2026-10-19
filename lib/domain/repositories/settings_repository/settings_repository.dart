import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/spending_rules.dart';

abstract class SettingsRepository {
  Future<Either<String, SpendingRules>> getSpendingRules(String storeId);
  Future<Either<String, Unit>> updateSpendingRules(
    String storeId,
    SpendingRules rules,
  );
}
