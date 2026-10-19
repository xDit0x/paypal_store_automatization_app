import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';

class SearchProductByUidUsecase {
  final ProductRepository repository;
  SearchProductByUidUsecase({required this.repository});

  Future<Either<String, Product>> call(String uid) async {
    final normalized = uid.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const Left('Introduce un UID.');
    }

    final result = await repository.getByUid(normalized);
    return result.fold(
      (error) => Left(error),
      (product) => product == null
          ? Left('No existe ningún producto con UID $normalized.')
          : Right(product),
    );
  }
}
