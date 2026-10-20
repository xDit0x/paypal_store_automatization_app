import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';

abstract class OrderRepository {
  Future<Either<AppError, List<Order>>> getByStore(String storeId);
  Future<Either<AppError, Order?>> getById(String id);
  Future<Either<AppError, Order>> create({
    required String storeId,
    required String supplierId,
    required List<OrderItem> items,
    required String idempotencyKey,
    required OrderStatus status,
    OrderCreatorType createdByType = OrderCreatorType.user,
    String? createdById,
    String? agentRunId,
  });
  Future<Either<AppError, double>> getSpentThisMonth(String storeId);
  Future<Either<AppError, Unit>> approve(String orderId);
  Future<Either<AppError, Unit>> reject(String orderId);
}
