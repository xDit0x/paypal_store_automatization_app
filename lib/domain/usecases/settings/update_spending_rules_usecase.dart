import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/repositories/settings_repository/settings_repository.dart';

class UpdateSpendingRulesUsecase {
  final SettingsRepository repository;
  UpdateSpendingRulesUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(
    String storeId,
    SpendingRules rules,
  ) {
    if (rules.maxPerOrder <= 0) {
      return Future.value(const Left(AppError(AppErrorCode.ruleMaxPerOrderInvalid)));
    }
    if (rules.monthlyLimit < rules.maxPerOrder) {
      return Future.value(
        const Left(AppError(AppErrorCode.ruleMonthlyBelowMax)),
      );
    }
    if (rules.requireApprovalAbove > rules.maxPerOrder) {
      return Future.value(
        const Left(AppError(AppErrorCode.ruleApprovalAboveMax)),
      );
    }
    return repository.updateSpendingRules(storeId, rules);
  }
}
