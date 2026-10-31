import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order_amount_review.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

/// Consulta el importe que se pagaría ahora mismo, con el precio vigente del
/// catálogo. No mueve dinero ni modifica el pedido.
class ReviewOrderAmountUsecase {
  final OrderRepository repository;

  ReviewOrderAmountUsecase({required this.repository});

  Future<Either<AppError, OrderAmountReview>> call(String orderId) =>
      repository.reviewAmount(orderId);
}
