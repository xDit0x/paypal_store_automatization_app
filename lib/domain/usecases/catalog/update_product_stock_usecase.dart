import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class UpdateProductStockUsecase {
  final ProductRepository repository;
  UpdateProductStockUsecase({required this.repository});

  Future<Either<String, Unit>> call(String uid, int stock) {
    if (uid.isEmpty) {
      return Future.value(const Left('Falta el producto.'));
    }
    if (stock < 0) {
      return Future.value(const Left('El stock no puede ser negativo.'));
    }
    return repository.updateStock(uid, stock);
  }
}
