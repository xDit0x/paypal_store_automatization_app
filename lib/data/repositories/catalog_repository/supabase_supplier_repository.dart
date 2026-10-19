import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/data/datasources/catalog_repository/supabase_supplier_datasource.dart';
import 'package:store_automatization_app/data/models/supplier_model.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';
import 'package:store_automatization_app/domain/repositories/supplier_repository/supplier_repository.dart';

class SupabaseSupplierRepository implements SupplierRepository {
  final SupabaseSupplierDatasource _datasource;
  SupabaseSupplierRepository(this._datasource);

  @override
  Future<Either<String, List<Supplier>>> getAll() async {
    try {
      final rows = await _datasource.getAll();
      return Right(rows.map(SupplierModel.fromMap).toList());
    } catch (error) {
      return Left('No se pudieron cargar los proveedores: $error');
    }
  }

  @override
  Future<Either<String, Supplier?>> getById(String id) async {
    try {
      final row = await _datasource.getById(id);
      return Right(row == null ? null : SupplierModel.fromMap(row));
    } catch (error) {
      return Left('No se pudo cargar el proveedor: $error');
    }
  }
}
