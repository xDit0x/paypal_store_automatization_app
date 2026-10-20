import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';

class UpdateStoreUsecase {
  final StoreRepository repository;
  UpdateStoreUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(
    String storeId, {
    String? name,
    String? paypalMerchantEmail,
    String? notificationEmail,
  }) {
    if (name != null && name.trim().isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.storeNameEmpty)));
    }
    return repository.update(
      storeId,
      name: name?.trim(),
      paypalMerchantEmail: paypalMerchantEmail?.trim(),
      notificationEmail: notificationEmail?.trim(),
    );
  }
}
