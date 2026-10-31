import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class SearchCatalogUsecase {
  final ProductRepository repository;
  SearchCatalogUsecase({required this.repository});

  Future<Either<AppError, List<CatalogProduct>>> call({
    required String storeId,
    String? query,
    String? supplierId,
  }) => repository.searchCatalog(
    storeId: storeId,
    query: query,
    supplierId: supplierId,
  );
}
