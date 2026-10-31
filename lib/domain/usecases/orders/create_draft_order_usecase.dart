import 'dart:math';

import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';
import 'package:store_automatization_app/domain/services/order_builder.dart';
import 'package:store_automatization_app/domain/usecases/orders/evaluate_spending_rules_usecase.dart';

class CreateOrderResult {
  final Order order;
  final SpendingDecision decision;

  const CreateOrderResult({required this.order, required this.decision});
}

class CreateDraftOrderUsecase {
  final ProductRepository productRepository;
  final OrderRepository orderRepository;
  final EvaluateSpendingRulesUsecase evaluateSpendingRules;

  CreateDraftOrderUsecase({
    required this.productRepository,
    required this.orderRepository,
    required this.evaluateSpendingRules,
  });

  Future<Either<AppError, CreateOrderResult>> call({
    required String storeId,
    required String supplierId,
    required List<DraftOrderLine> lines,
    SpendingRules rules = const SpendingRules(),
    double? spentThisMonth,
    OrderCreatorType createdByType = OrderCreatorType.user,
    String? createdById,
    String? agentRunId,

    /// Fuerza que el pedido quede pendiente de aprobación aunque las reglas
    /// lo autoaprueben. Se usa al comprar stock desde el catálogo.
    bool forceApproval = false,
  }) async {
    if (lines.isEmpty) {
      return const Left(AppError(AppErrorCode.orderEmpty));
    }

    final uids = {for (final line in lines) line.productUid}.toList();
    final productsResult = await productRepository.getByUids(storeId, uids);
    if (productsResult.isLeft()) {
      return Left(
        productsResult.fold(
          (error) => error,
          (_) => const AppError(AppErrorCode.orderCreateFailed),
        ),
      );
    }
    final products = productsResult.getOrElse(() => const <Product>[]);

    final itemsResult = OrderBuilder.buildItems(
      lines: lines,
      products: products,
    );
    if (itemsResult.isLeft()) {
      return Left(
        itemsResult.fold(
          (error) => error,
          (_) => const AppError(AppErrorCode.orderCreateFailed),
        ),
      );
    }
    final items = itemsResult.getOrElse(() => const <OrderItem>[]);

    var spent = spentThisMonth;
    if (spent == null) {
      final spentResult = await orderRepository.getSpentThisMonth(storeId);
      if (spentResult.isLeft()) {
        return Left(
          spentResult.fold(
            (error) => error,
            (_) => const AppError(AppErrorCode.orderSpentFailed),
          ),
        );
      }
      spent = spentResult.getOrElse(() => 0);
    }

    final total = OrderBuilder.total(items);
    final decision = evaluateSpendingRules(
      rules: rules,
      orderTotal: total,
      spentThisMonth: spent,
      supplierId: supplierId,
    );

    if (decision.isBlocked) {
      return const Left(AppError(AppErrorCode.orderBlocked));
    }

    final status = (decision.needsApproval || forceApproval)
        ? OrderStatus.pendingApproval
        : OrderStatus.draft;

    final createdResult = await orderRepository.create(
      storeId: storeId,
      supplierId: supplierId,
      items: items,
      status: status,
      idempotencyKey: _generateIdempotencyKey(),
      createdByType: createdByType,
      createdById: createdById,
      agentRunId: agentRunId,
    );

    return createdResult.fold(
      (error) => Left(error),
      (order) => Right(CreateOrderResult(order: order, decision: decision)),
    );
  }

  String _generateIdempotencyKey() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
