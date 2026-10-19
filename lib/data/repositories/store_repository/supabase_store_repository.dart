import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/store_repository/supabase_store_datasource.dart';
import 'package:store_automatization_app/data/models/store_model.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';

class SupabaseStoreRepository implements StoreRepository {
  final SupabaseStoreDatasource _datasource;
  SupabaseStoreRepository(this._datasource);

  @override
  Future<Either<String, Store?>> getOwn() async {
    try {
      final row = await _datasource.getOwn();
      return Right(row == null ? null : StoreModel.fromMap(row));
    } catch (error) {
      return Left('No se pudo cargar la tienda: $error');
    }
  }

  @override
  Future<Either<String, Unit>> update(
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
      return Left('No se pudo actualizar la tienda: $error');
    }
  }
}
