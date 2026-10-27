import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';
import 'package:store_automatization_app/domain/services/order_builder.dart';
import 'package:store_automatization_app/domain/usecases/orders/create_draft_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/evaluate_spending_rules_usecase.dart';

class _FakeProductRepository implements ProductRepository {
  final List<Product> products;
  _FakeProductRepository(this.products);

  @override
  Future<Either<AppError, List<Product>>> getBySupplier(
    String storeId,
    String supplierId,
  ) async {
    return Right(products);
  }

  @override
  Future<Either<AppError, Product?>> getByUid(
    String storeId,
    String uid,
  ) async {
    final matches = products.where((product) => product.uid == uid);
    return Right(matches.isEmpty ? null : matches.first);
  }

  @override
  Future<Either<AppError, List<Product>>> getByUids(
    String storeId,
    List<String> uids,
  ) async {
    return Right(
      products.where((product) => uids.contains(product.uid)).toList(),
    );
  }

  @override
  Future<Either<AppError, List<Product>>> getLowStock(String storeId) async {
    return Right(products.where((product) => product.isLowStock).toList());
  }

  @override
  Future<Either<AppError, Unit>> updateStock(
    String storeId,
    String uid,
    int stock,
  ) async {
    final exists = products.any((product) => product.uid == uid);
    return exists
        ? const Right(unit)
        : const Left(AppError(AppErrorCode.productMissing));
  }
}

class _FakeOrderRepository implements OrderRepository {
  OrderStatus? lastStatus;
  List<OrderItem>? lastItems;

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
    lastStatus = status;
    lastItems = items;
    final total = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    return Right(
      Order(
        id: 'order-1',
        storeId: storeId,
        supplierId: supplierId,
        items: items,
        subtotal: total,
        total: total,
        status: status,
        idempotencyKey: idempotencyKey,
        createdByType: createdByType,
      ),
    );
  }

  @override
  Future<Either<AppError, List<Order>>> getByStore(String storeId) async {
    return const Left(AppError(AppErrorCode.orderCreateFailed));
  }

  @override
  Future<Either<AppError, Order?>> getById(String id) async {
    return const Left(AppError(AppErrorCode.orderCreateFailed));
  }

  @override
  Future<Either<AppError, double>> getSpentThisMonth(String storeId) async {
    return const Right(0);
  }

  @override
  Future<Either<AppError, Unit>> approve(String orderId) async {
    return const Left(AppError(AppErrorCode.orderCreateFailed));
  }

  @override
  Future<Either<AppError, Unit>> reject(String orderId) async {
    return const Left(AppError(AppErrorCode.orderCreateFailed));
  }
}

void main() {
  const product = Product(
    id: 'product-1',
    uid: 'LECHE-001',
    supplierId: 'sup-1',
    name: 'Leche',
    price: 10,
    stock: 10,
    lowStockThreshold: 2,
  );

  late _FakeOrderRepository orderRepository;
  late CreateDraftOrderUsecase usecase;

  setUp(() {
    orderRepository = _FakeOrderRepository();
    usecase = CreateDraftOrderUsecase(
      productRepository: _FakeProductRepository(const [product]),
      orderRepository: orderRepository,
      evaluateSpendingRules: const EvaluateSpendingRulesUsecase(),
    );
  });

  test('crea un draft cuando el pedido es autoaprobado', () async {
    final result = await usecase(
      storeId: 'store-1',
      supplierId: 'sup-1',
      lines: const [DraftOrderLine(productUid: 'LECHE-001', qty: 2)],
    );

    final value = result.getOrElse(
      () => throw StateError('esperaba un pedido'),
    );
    expect(value.order.total, 20);
    expect(orderRepository.lastStatus, OrderStatus.draft);
    expect(orderRepository.lastItems?.single.qty, 2);
  });

  test(
    'crea un pedido pendiente de aprobación por encima del umbral',
    () async {
      final result = await usecase(
        storeId: 'store-1',
        supplierId: 'sup-1',
        lines: const [DraftOrderLine(productUid: 'LECHE-001', qty: 6)],
      );

      final value = result.getOrElse(
        () => throw StateError('esperaba un pedido'),
      );
      expect(value.decision.needsApproval, isTrue);
      expect(orderRepository.lastStatus, OrderStatus.pendingApproval);
    },
  );

  test('no crea el pedido si las reglas lo bloquean', () async {
    final result = await usecase(
      storeId: 'store-1',
      supplierId: 'sup-1',
      lines: const [DraftOrderLine(productUid: 'LECHE-001', qty: 30)],
    );

    expect(result.isLeft(), isTrue);
    expect(orderRepository.lastStatus, isNull);
  });

  test('falla con un UID desconocido', () async {
    final result = await usecase(
      storeId: 'store-1',
      supplierId: 'sup-1',
      lines: const [DraftOrderLine(productUid: 'NOPE', qty: 1)],
    );

    expect(result.isLeft(), isTrue);
  });
}
