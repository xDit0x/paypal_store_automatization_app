import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

/// Enlace de PayPal para que el pagador autorice el importe del pedido.
class AuthorizationUrlUsecase {
  final OrderRepository repository;
  AuthorizationUrlUsecase({required this.repository});

  Future<Either<AppError, String?>> call(String orderId) {
    if (orderId.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.orderMissing)));
    }
    return repository.authorizationUrl(orderId);
  }
}
