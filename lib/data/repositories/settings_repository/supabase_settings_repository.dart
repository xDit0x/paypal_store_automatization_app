import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/settings_repository/supabase_settings_datasource.dart';
import 'package:store_automatization_app/data/models/spending_rules_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/repositories/settings_repository/settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseSettingsDatasource _datasource;
  SupabaseSettingsRepository(this._datasource);

  @override
  Future<Either<AppError, SpendingRules>> getSpendingRules(String storeId) async {
    try {
      final row = await _datasource.getSpendingRules(storeId);
      if (row == null) {
        return const Left(AppError(AppErrorCode.rulesNotFound));
      }
      return Right(SpendingRulesModel.fromMap(row));
    } catch (error) {
      return Left(logError(AppErrorCode.rulesLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Unit>> updateSpendingRules(
    String storeId,
    SpendingRules rules,
  ) async {
    try {
      await _datasource.updateSpendingRules(
        storeId,
        SpendingRulesModel.toMap(rules),
      );
      return Right(unit);
    } catch (error) {
      return Left(
        logError(
          AppErrorCode.rulesSaveFailed,
          error,
          detail: serverMessage(error),
        ),
      );
    }
  }
}
