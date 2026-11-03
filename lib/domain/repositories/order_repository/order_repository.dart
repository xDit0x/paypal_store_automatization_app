import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_amount_review.dart';
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

  /// Aprueba el pedido y devuelve el enlace de PayPal donde el pagador
  /// autoriza el importe. `null` si no hace falta abrir nada.
  Future<Either<AppError, String?>> authorizationUrl(String orderId);

  /// Confirma la autorización cuando el pagador ya la ha aprobado en PayPal.
  Future<Either<AppError, Unit>> confirmAuthorization(String orderId);

  /// Importe que se pagaría ahora, con el precio vigente del catálogo.
  Future<Either<AppError, OrderAmountReview>> reviewAmount(String orderId);
}
