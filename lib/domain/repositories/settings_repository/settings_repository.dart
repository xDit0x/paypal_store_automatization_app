import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';

abstract class SettingsRepository {
  Future<Either<AppError, SpendingRules>> getSpendingRules(String storeId);
  Future<Either<AppError, Unit>> updateSpendingRules(
    String storeId,
    SpendingRules rules,
  );
}
