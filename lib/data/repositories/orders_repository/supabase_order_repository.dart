import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/data/datasources/orders_repository/supabase_order_datasource.dart';
import 'package:store_automatization_app/data/models/order_item_model.dart';
import 'package:store_automatization_app/data/models/order_model.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseOrderDatasource _datasource;
  SupabaseOrderRepository(this._datasource);

  @override
  Future<Either<String, List<Order>>> getByStore(String storeId) async {
    try {
      final rows = await _datasource.getByStore(storeId);
      return Right(rows.map(OrderModel.fromMap).toList());
    } catch (error) {
      return Left('No se pudieron cargar los pedidos: $error');
    }
  }

  @override
  Future<Either<String, Order?>> getById(String id) async {
    try {
      final row = await _datasource.getById(id);
      return Right(row == null ? null : OrderModel.fromMap(row));
    } catch (error) {
      return Left('No se pudo cargar el pedido: $error');
    }
  }

  @override
  Future<Either<String, Order>> create({
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
      final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);

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
      return Left('No se pudo crear el pedido: $error');
    }
  }

  @override
  Future<Either<String, double>> getSpentThisMonth(String storeId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);
      final spent = await _datasource.getSpentSince(storeId, startOfMonth);
      return Right(spent);
    } catch (error) {
      return Left('No se pudo calcular el gasto mensual: $error');
    }
  }

  @override
  Future<Either<String, Unit>> approve(String orderId) async {
    try {
      await _datasource.approve(orderId);
      return Right(unit);
    } catch (error) {
      return Left('No se pudo aprobar el pedido: $error');
    }
  }

  @override
  Future<Either<String, Unit>> reject(String orderId) async {
    try {
      await _datasource.reject(orderId);
      return Right(unit);
    } catch (error) {
      return Left('No se pudo rechazar el pedido: $error');
    }
  }
}
