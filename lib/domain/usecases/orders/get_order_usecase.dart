import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class GetOrderUsecase {
  final OrderRepository repository;
  GetOrderUsecase({required this.repository});

  Future<Either<String, Order>> call(String orderId) async {
    final result = await repository.getById(orderId);
    return result.fold(
      (error) => Left(error),
      (order) => order == null
          ? const Left('El pedido no existe.')
          : Right(order),
    );
  }
}
