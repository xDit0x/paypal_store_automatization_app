import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

/// Cambia el mínimo de bajo stock de un producto en una tienda: a partir de
/// cuántas unidades se avisa y se repone.
class UpdateLowStockThresholdUsecase {
  final ProductRepository repository;
  UpdateLowStockThresholdUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(
    String storeId,
    String uid,
    int threshold,
  ) {
    if (storeId.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.storeNotFound)));
    }
    if (uid.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.productMissing)));
    }
    if (threshold < 0) {
      return Future.value(const Left(AppError(AppErrorCode.stockNegative)));
    }
    return repository.updateLowStockThreshold(storeId, uid, threshold);
  }
}
