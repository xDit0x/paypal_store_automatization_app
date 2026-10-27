import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/catalog_repository/supabase_product_datasource.dart';
import 'package:store_automatization_app/data/models/product_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

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
  Future<Either<AppError, Unit>> updateStock(
    String storeId,
    String uid,
    int stock,
  ) async {
    try {
      await _datasource.updateStock(storeId, uid, stock);
      return const Right(unit);
    } catch (error) {
      final message = error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Exception', '')
          .trim();
      return Left(
        AppError(
          AppErrorCode.stockUpdateFailed,
          detail: message.isEmpty ? null : message,
        ),
      );
    }
  }
}
