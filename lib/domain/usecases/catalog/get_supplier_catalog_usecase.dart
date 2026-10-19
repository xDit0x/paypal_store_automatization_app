import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class GetSupplierCatalogUsecase {
  final ProductRepository repository;
  GetSupplierCatalogUsecase({required this.repository});

  Future<Either<String, List<Product>>> call(String supplierId) =>
      repository.getBySupplier(supplierId);
}
