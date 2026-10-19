import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/repositories/settings_repository/settings_repository.dart';

class GetSpendingRulesUsecase {
  final SettingsRepository repository;
  GetSpendingRulesUsecase({required this.repository});

  Future<Either<String, SpendingRules>> call(String storeId) =>
      repository.getSpendingRules(storeId);
}
