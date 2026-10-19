import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/supplier.dart';
import 'package:store_automatization_app/domain/repositories/supplier_repository/supplier_repository.dart';

class GetSuppliersUsecase {
  final SupplierRepository repository;
  GetSuppliersUsecase({required this.repository});

  Future<Either<String, List<Supplier>>> call() => repository.getAll();
}
