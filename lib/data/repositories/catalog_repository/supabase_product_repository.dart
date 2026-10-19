import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/catalog_repository/supabase_product_datasource.dart';
import 'package:store_automatization_app/data/models/product_model.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class SupabaseProductRepository implements ProductRepository {
  final SupabaseProductDatasource _datasource;
  SupabaseProductRepository(this._datasource);

  @override
  Future<Either<String, List<Product>>> getBySupplier(String supplierId) async {
    try {
      final rows = await _datasource.getBySupplier(supplierId);
      return Right(rows.map(ProductModel.fromMap).toList());
    } catch (error) {
      return Left('No se pudo cargar el catálogo: $error');
    }
  }

  @override
  Future<Either<String, Product?>> getByUid(String uid) async {
    try {
      final row = await _datasource.getByUid(uid);
      return Right(row == null ? null : ProductModel.fromMap(row));
    } catch (error) {
      return Left('No se pudo buscar el producto: $error');
    }
  }

  @override
  Future<Either<String, List<Product>>> getByUids(List<String> uids) async {
    try {
      final rows = await _datasource.getByUids(uids);
      return Right(rows.map(ProductModel.fromMap).toList());
    } catch (error) {
      return Left('No se pudieron cargar los productos: $error');
    }
  }

  @override
  Future<Either<String, List<Product>>> getLowStock() async {
    try {
      final rows = await _datasource.getLowStock();
      return Right(rows.map(ProductModel.fromMap).toList());
    } catch (error) {
      return Left('No se pudo cargar el stock bajo: $error');
    }
  }

  @override
  Future<Either<String, Unit>> updateStock(String uid, int stock) async {
    try {
      await _datasource.updateStock(uid, stock);
      return const Right(unit);
    } catch (error) {
      final message = error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Exception', '');
      return Left('No se pudo actualizar el stock: $message');
    }
  }
}
