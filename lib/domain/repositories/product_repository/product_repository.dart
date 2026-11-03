import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';
import 'package:store_automatization_app/domain/entities/product.dart';

/// El catálogo (productos y precios) es común a todas las tiendas, pero el
/// stock es de cada tienda: por eso las consultas piden `storeId`.
abstract class ProductRepository {
  Future<Either<AppError, List<Product>>> getBySupplier(
    String storeId,
    String supplierId,
  );
  Future<Either<AppError, Product?>> getByUid(String storeId, String uid);
  Future<Either<AppError, List<Product>>> getByUids(
    String storeId,
    List<String> uids,
  );
  Future<Either<AppError, List<Product>>> getLowStock(String storeId);
  Future<Either<AppError, Unit>> updateStock(
    String storeId,
    String uid,
    int stock,
  );

  /// Marca el producto como eliminado (`active = false`). El agente de
  /// reposición deja de tenerlo en cuenta, así que no lo repone.
  Future<Either<AppError, Unit>> deleteProduct(String storeId, String uid);

  /// Devuelve el producto a la vida (`active = true`): vuelve a aparecer en
  /// el catálogo y el agente vuelve a considerarlo.
  Future<Either<AppError, Unit>> restoreProduct(String storeId, String uid);
  Future<Either<AppError, List<CatalogProduct>>> searchCatalog({
    required String storeId,
    String? query,
    String? supplierId,
  });
}
