import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/store.dart';

abstract class StoreRepository {
  Future<Either<String, Store?>> getOwn();
  Future<Either<String, Unit>> update(
    String storeId, {
    String? name,
    String? paypalMerchantEmail,
    String? notificationEmail,
  });
}
