import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';

class GetCurrentStoreUsecase {
  final StoreRepository repository;
  GetCurrentStoreUsecase({required this.repository});

  Future<Either<AppError, Store>> call() async {
    final result = await repository.getOwn();
    return result.fold(
      (error) => Left(error),
      (store) => store == null
          ? const Left(AppError(AppErrorCode.storeNotFound))
          : Right(store),
    );
  }
}
