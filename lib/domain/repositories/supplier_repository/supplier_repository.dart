import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<Either<AppError, List<Supplier>>> getAll();
  Future<Either<AppError, Supplier?>> getById(String id);
}
