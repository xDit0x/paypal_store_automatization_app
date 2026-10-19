import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';

class GetCurrentStoreUsecase {
  final StoreRepository repository;
  GetCurrentStoreUsecase({required this.repository});

  Future<Either<String, Store>> call() async {
    final result = await repository.getOwn();
    return result.fold(
      (error) => Left(error),
      (store) => store == null
          ? const Left('No se encontró la tienda del usuario.')
          : Right(store),
    );
  }
}
