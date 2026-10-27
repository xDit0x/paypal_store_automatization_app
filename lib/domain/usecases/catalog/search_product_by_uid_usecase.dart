import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class SearchProductByUidUsecase {
  final ProductRepository repository;
  SearchProductByUidUsecase({required this.repository});

  Future<Either<AppError, Product>> call(String storeId, String uid) async {
    if (storeId.isEmpty) {
      return const Left(AppError(AppErrorCode.storeNotFound));
    }
    final normalized = uid.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const Left(AppError(AppErrorCode.productUidMissing));
    }

    final result = await repository.getByUid(storeId, normalized);
    return result.fold(
      (error) => Left(error),
      (product) => product == null
          ? Left(AppError(AppErrorCode.productNotFound, subject: normalized))
          : Right(product),
    );
  }
}
