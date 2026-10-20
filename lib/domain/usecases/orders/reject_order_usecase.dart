import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class RejectOrderUsecase {
  final OrderRepository repository;
  RejectOrderUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(String orderId) {
    if (orderId.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.orderMissing)));
    }
    return repository.reject(orderId);
  }
}
