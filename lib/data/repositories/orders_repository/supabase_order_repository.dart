import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/data/datasources/orders_repository/supabase_order_datasource.dart';
import 'package:store_automatization_app/data/models/order_item_model.dart';
import 'package:store_automatization_app/data/models/order_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_amount_review.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseOrderDatasource _datasource;
  SupabaseOrderRepository(this._datasource);

  @override
  Future<Either<AppError, List<Order>>> getByStore(String storeId) async {
    try {
      final rows = await _datasource.getByStore(storeId);
      return Right(rows.map(OrderModel.fromMap).toList());
    } catch (error) {
      return Left(logError(AppErrorCode.ordersLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Order?>> getById(String id) async {
    try {
      final row = await _datasource.getById(id);
      return Right(row == null ? null : OrderModel.fromMap(row));
    } catch (error) {
      return Left(logError(AppErrorCode.orderLoadFailed, error));
    }
  }

  @override
  Future<Either<AppError, Order>> create({
    required String storeId,
    required String supplierId,
    required List<OrderItem> items,
    required String idempotencyKey,
    required OrderStatus status,
    OrderCreatorType createdByType = OrderCreatorType.user,
    String? createdById,
    String? agentRunId,
  }) async {
    try {
      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + item.lineTotal,
      );

      final row = await _datasource.insertOrder({
        'store_id': storeId,
        'supplier_id': supplierId,
        'created_by_type': createdByType.value,
        'created_by_id': createdById,
        'subtotal': subtotal,
        'total': subtotal,
        'status': status.value,
        'agent_run_id': agentRunId,
        'idempotency_key': idempotencyKey,
      });

      final orderId = row['id'] as String;
      await _datasource.insertItems(
        items
            .map((item) => OrderItemModel.toMap(orderId: orderId, item: item))
            .toList(),
      );

      final saved = await _datasource.getById(orderId);
      return Right(OrderModel.fromMap(saved ?? row));
    } catch (error) {
      return Left(logError(AppErrorCode.orderCreateFailed, error));
    }
  }

  @override
  Future<Either<AppError, double>> getSpentThisMonth(String storeId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);
      final spent = await _datasource.getSpentSince(storeId, startOfMonth);
      return Right(spent);
    } catch (error) {
      return Left(logError(AppErrorCode.orderSpentFailed, error));
    }
  }

  @override
  Future<Either<AppError, Unit>> approve(String orderId) async {
    try {
      await _datasource.approve(orderId);
      return Right(unit);
    } catch (error) {
      return Left(
        logError(
          AppErrorCode.orderApproveFailed,
          error,
          detail: serverMessage(error),
        ),
      );
    }
  }

  @override
  Future<Either<AppError, Unit>> reject(String orderId) async {
    try {
      await _datasource.reject(orderId);
      return Right(unit);
    } catch (error) {
      return Left(
        logError(
          AppErrorCode.orderRejectFailed,
          error,
          detail: serverMessage(error),
        ),
      );
    }
  }

  @override
  Future<Either<AppError, OrderAmountReview>> reviewAmount(
    String orderId,
  ) async {
    try {
      final row = await _datasource.reviewAmount(orderId);
      return Right(
        OrderAmountReview(
          total: (row['total'] as num?)?.toDouble() ?? 0,
          previousTotal: (row['previous_total'] as num?)?.toDouble() ?? 0,
          changed: row['changed'] == true,
        ),
      );
    } catch (error) {
      return Left(
        logError(
          AppErrorCode.orderAmountFailed,
          error,
          detail: serverMessage(error),
        ),
      );
    }
  }
}
