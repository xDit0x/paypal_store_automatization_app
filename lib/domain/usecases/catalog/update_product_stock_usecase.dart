import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class UpdateProductStockUsecase {
  final ProductRepository repository;
  UpdateProductStockUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(String uid, int stock) {
    if (uid.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.productMissing)));
    }
    if (stock < 0) {
      return Future.value(const Left(AppError(AppErrorCode.stockNegative)));
    }
    return repository.updateStock(uid, stock);
  }
}
