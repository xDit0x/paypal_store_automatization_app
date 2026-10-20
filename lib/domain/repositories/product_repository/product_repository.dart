import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<AppError, List<Product>>> getBySupplier(String supplierId);
  Future<Either<AppError, Product?>> getByUid(String uid);
  Future<Either<AppError, List<Product>>> getByUids(List<String> uids);
  Future<Either<AppError, List<Product>>> getLowStock();
  Future<Either<AppError, Unit>> updateStock(String uid, int stock);
}
