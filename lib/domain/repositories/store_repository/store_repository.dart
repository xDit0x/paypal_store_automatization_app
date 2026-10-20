import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/store.dart';

abstract class StoreRepository {
  Future<Either<AppError, Store?>> getOwn();
  Future<Either<AppError, Unit>> update(
    String storeId, {
    String? name,
    String? paypalMerchantEmail,
    String? notificationEmail,
  });
}
