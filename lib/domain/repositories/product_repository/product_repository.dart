import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<String, List<Product>>> getBySupplier(String supplierId);
  Future<Either<String, Product?>> getByUid(String uid);
  Future<Either<String, List<Product>>> getByUids(List<String> uids);
  Future<Either<String, List<Product>>> getLowStock();
  Future<Either<String, Unit>> updateStock(String uid, int stock);
}
