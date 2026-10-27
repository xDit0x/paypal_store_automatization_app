import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class GetLowStockProductsUsecase {
  final ProductRepository repository;
  GetLowStockProductsUsecase({required this.repository});

  Future<Either<AppError, List<Product>>> call(String storeId) =>
      repository.getLowStock(storeId);
}
