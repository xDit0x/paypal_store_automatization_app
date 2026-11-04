import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/catalog_repository/supabase_product_datasource.dart';
import 'package:store_automatization_app/data/models/product_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class CatalogProductModel {
  const CatalogProductModel._();
  static CatalogProduct fromMap(Map<String, dynamic> map) {
    return CatalogProduct(
      id: map['id'] as String,
      uid: map['uid'] as String,
      supplierId: map['supplier_id'] as String,
      supplierName: map['supplier_name'] as String? ?? 'Proveedor',
      name: map['name'] as String? ?? 'Producto',
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'EUR',
      stock: (map['stock'] as num?)?.toInt(),
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toInt(),
      inInventory:
          map['in_inventory'] == true ||
          (map['stock'] != null && (map['stock'] as num?)!.toInt() > 0),
      unit: map['unit'] as String? ?? 'unidad',
      imageUrl: map['image_url'] as String?,
      active: map['active'] == true || map['active'] == null,
    );
  }
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseProductDatasource _datasource;
  SupabaseProductRepository(this._datasource);

  @override
  Future<Either<AppError, List<Product>>> getBySupplier(
    String storeId,
    String supplierId,
  ) async {
    try {
      final rows = await _datasource.getBySupplier(storeId, supplierId);
      return Right(rows.map(ProductModel.fromMap).toList());
    } catch (error) {
      return Left(logError(AppErrorCode.catalogLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Product?>> getByUid(
    String storeId,
    String uid,
  ) async {
    try {
      final row = await _datasource.getByUid(storeId, uid);
      return Right(row == null ? null : ProductModel.fromMap(row));
    } catch (error) {
      return Left(logError(AppErrorCode.productSearchFailed, error));
    }
  }

  @override
  Future<Either<AppError, List<Product>>> getByUids(
    String storeId,
    List<String> uids,
  ) async {
    try {
      final rows = await _datasource.getByUids(storeId, uids);
      return Right(rows.map(ProductModel.fromMap).toList());
    } catch (error) {
      return Left(logError(AppErrorCode.productsLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, List<Product>>> getLowStock(String storeId) async {
    try {
      final rows = await _datasource.getLowStock(storeId);
      return Right(rows.map(ProductModel.fromMap).toList());
    } catch (error) {
      return Left(logError(AppErrorCode.lowStockLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Unit>> deleteProduct(
    String storeId,
    String uid,
  ) async {
    try {
      await _datasource.setProductActive(storeId, uid, false);
      return const Right(unit);
    } catch (error) {
      return Left(
        AppError(AppErrorCode.productDeleteFailed, detail: _message(error)),
      );
    }
  }

  @override
  Future<Either<AppError, Unit>> restoreProduct(
    String storeId,
    String uid,
  ) async {
    try {
      await _datasource.setProductActive(storeId, uid, true);
      return const Right(unit);
    } catch (error) {
      return Left(
        AppError(AppErrorCode.productRestoreFailed, detail: _message(error)),
      );
    }
  }

  /// Texto que explica el fallo, si el datasource lo dio.
  static String? _message(Object error) {
    final text = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Exception', '')
        .trim();
    return text.isEmpty ? null : text;
  }

  @override
  Future<Either<AppError, List<CatalogProduct>>> searchCatalog({
    required String storeId,
    String? query,
    String? supplierId,
  }) async {
    try {
      final rows = await _datasource.searchCatalog(
        storeId: storeId,
        query: query,
        supplierId: supplierId,
      );
      return Right(rows.map(CatalogProductModel.fromMap).toList());
    } catch (error) {
      return Left(logError(AppErrorCode.catalogLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Unit>> updateStock(
    String storeId,
    String uid,
    int stock,
  ) async {
    try {
      await _datasource.updateStock(storeId, uid, stock);
      return const Right(unit);
    } catch (error) {
      return Left(
        AppError(AppErrorCode.stockUpdateFailed, detail: _message(error)),
      );
    }
  }

  @override
  Future<Either<AppError, Unit>> updateLowStockThreshold(
    String storeId,
    String uid,
    int threshold,
  ) async {
    try {
      await _datasource.updateLowStockThreshold(storeId, uid, threshold);
      return const Right(unit);
    } catch (error) {
      return Left(
        AppError(
          AppErrorCode.stockThresholdUpdateFailed,
          detail: _message(error),
        ),
      );
    }
  }
}
