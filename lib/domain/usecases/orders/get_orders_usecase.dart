import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class GetOrdersUsecase {
  final OrderRepository repository;
  GetOrdersUsecase({required this.repository});

  Future<Either<AppError, List<Order>>> call(String storeId) =>
      repository.getByStore(storeId);
}
