import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

/// Confirma que el pagador ya autorizó el importe en PayPal. El dinero
/// queda retenido hasta que se confirme la entrega.
class ConfirmAuthorizationUsecase {
  final OrderRepository repository;
  ConfirmAuthorizationUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(String orderId) {
    if (orderId.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.orderMissing)));
    }
    return repository.confirmAuthorization(orderId);
  }
}
