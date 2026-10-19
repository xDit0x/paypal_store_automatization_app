import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class RejectOrderUsecase {
  final OrderRepository repository;
  RejectOrderUsecase({required this.repository});

  Future<Either<String, Unit>> call(String orderId) {
    if (orderId.isEmpty) {
      return Future.value(const Left('Falta el pedido.'));
    }
    return repository.reject(orderId);
  }
}
