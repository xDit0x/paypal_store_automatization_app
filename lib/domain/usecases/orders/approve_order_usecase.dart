import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

/// Aprueba un pedido. El backend lo paga con PayPal y genera la factura.
class ApproveOrderUsecase {
  final OrderRepository repository;
  ApproveOrderUsecase({required this.repository});

  Future<Either<String, Unit>> call(String orderId) {
    if (orderId.isEmpty) {
      return Future.value(const Left('Falta el pedido.'));
    }
    return repository.approve(orderId);
  }
}
