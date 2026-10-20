import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/store_repository/supabase_store_datasource.dart';
import 'package:store_automatization_app/data/models/store_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';

class SupabaseStoreRepository implements StoreRepository {
  final SupabaseStoreDatasource _datasource;
  SupabaseStoreRepository(this._datasource);

  @override
  Future<Either<AppError, Store?>> getOwn() async {
    try {
      final row = await _datasource.getOwn();
      return Right(row == null ? null : StoreModel.fromMap(row));
    } catch (error) {
      return Left(logError(AppErrorCode.storeLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Unit>> update(
    String storeId, {
    String? name,
    String? paypalMerchantEmail,
    String? notificationEmail,
  }) async {
    try {
      await _datasource.update(storeId, {
        'name': ?name,
        'paypal_merchant_email': ?paypalMerchantEmail,
        'notification_email': ?notificationEmail,
      });
      return Right(unit);
    } catch (error) {
      return Left(logError(AppErrorCode.storeUpdateFailed, error));
    }
  }
}
