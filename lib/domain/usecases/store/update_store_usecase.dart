import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';

class UpdateStoreUsecase {
  final StoreRepository repository;
  UpdateStoreUsecase({required this.repository});

  Future<Either<String, Unit>> call(
    String storeId, {
    String? name,
    String? paypalMerchantEmail,
    String? notificationEmail,
  }) {
    if (name != null && name.trim().isEmpty) {
      return Future.value(const Left('El nombre de la tienda no puede estar vacío.'));
    }
    return repository.update(
      storeId,
      name: name?.trim(),
      paypalMerchantEmail: paypalMerchantEmail?.trim(),
      notificationEmail: notificationEmail?.trim(),
    );
  }
}
