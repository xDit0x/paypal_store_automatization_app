import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class GetLowStockProductsUsecase {
  final ProductRepository repository;
  GetLowStockProductsUsecase({required this.repository});

  Future<Either<String, List<Product>>> call() => repository.getLowStock();
}
