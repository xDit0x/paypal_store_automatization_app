import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<Either<String, List<Supplier>>> getAll();
  Future<Either<String, Supplier?>> getById(String id);
}
