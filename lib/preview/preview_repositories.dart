// Datos de ejemplo en memoria para ver el diseño sin Supabase ni servidor.
// Solo los usa lib/main_preview.dart; la app real no los toca.

import 'package:dartz/dartz.dart' hide Order;

import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';
import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';
import 'package:store_automatization_app/domain/repositories/product_repository/product_repository.dart';
import 'package:store_automatization_app/domain/repositories/settings_repository/settings_repository.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_repository.dart';
import 'package:store_automatization_app/domain/repositories/supplier_repository/supplier_repository.dart';

const _storeId = 'demo-store';

DateTime _today(int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

DateTime _daysAgo(int days, int hour) => _today(hour, 0).subtract(Duration(days: days));

/// Fuente única de datos de la vista previa, compartida por los repositorios.
class PreviewDb {
  Store store = const Store(
    id: _storeId,
    ownerId: 'demo-user',
    name: 'Café Lumbre',
    paypalMerchantEmail: 'cafelumbre@business.example.com',
  );

  SpendingRules rules = const SpendingRules(
    maxPerOrder: 200,
    monthlyLimit: 400,
    requireApprovalAbove: 100,
  );

  final suppliers = const [
    Supplier(id: 's1', name: 'Tostadores Norte', category: 'Café'),
    Supplier(id: 's2', name: 'Lácteos Sierra', category: 'Lácteos'),
    Supplier(id: 's3', name: 'Horno San Roque', category: 'Panadería'),
    Supplier(id: 's4', name: 'Envases Martín', category: 'Envases'),
  ];

  final products = <Product>[
    Product(id: 'p1', uid: 'CAF-001', supplierId: 's1', name: 'Café en grano 1 kg', price: 12.5, stock: 2, lowStockThreshold: 8, unit: 'kg'),
    Product(id: 'p2', uid: 'CAF-002', supplierId: 's1', name: 'Descafeinado 1 kg', price: 10, stock: 4, lowStockThreshold: 3, unit: 'kg'),
    Product(id: 'p3', uid: 'LAC-001', supplierId: 's2', name: 'Leche entera 1 L', price: 1.6, stock: 31, lowStockThreshold: 12, unit: 'L'),
    Product(id: 'p4', uid: 'LAC-002', supplierId: 's2', name: 'Leche de avena 1 L', price: 2.1, stock: 6, lowStockThreshold: 8, unit: 'L'),
    Product(id: 'p5', uid: 'PAN-001', supplierId: 's3', name: 'Croissant', price: 0.6, stock: 6, lowStockThreshold: 20, unit: 'ud'),
    Product(id: 'p6', uid: 'PAN-002', supplierId: 's3', name: 'Napolitana', price: 0.75, stock: 14, lowStockThreshold: 12, unit: 'ud'),
    Product(id: 'p7', uid: 'ENV-001', supplierId: 's4', name: 'Vasos 12 oz (caja 50)', price: 4.2, stock: 7, lowStockThreshold: 4, unit: 'cajas'),
    Product(id: 'p8', uid: 'ENV-002', supplierId: 's4', name: 'Azúcar en sobres (caja 500)', price: 6.5, stock: 3, lowStockThreshold: 2, unit: 'cajas'),
  ];

  late final List<Order> orders = [
    Order(
      id: 'o1',
      storeId: _storeId,
      supplierId: 's1',
      createdByType: OrderCreatorType.agent,
      items: const [
        OrderItem(productUid: 'CAF-001', name: 'Café en grano 1 kg', qty: 10, unitPrice: 12.5),
        OrderItem(productUid: 'CAF-002', name: 'Descafeinado 1 kg', qty: 2, unitPrice: 10),
      ],
      subtotal: 145,
      total: 145,
      status: OrderStatus.pendingApproval,
      agentRunId: 'r1',
      idempotencyKey: 'k1',
      createdAt: _today(7, 0),
    ),
    Order(
      id: 'o2',
      storeId: _storeId,
      supplierId: 's2',
      createdByType: OrderCreatorType.agent,
      items: const [OrderItem(productUid: 'LAC-001', name: 'Leche entera 1 L', qty: 24, unitPrice: 1.6)],
      subtotal: 38.4,
      total: 38.4,
      status: OrderStatus.paid,
      paymentProvider: 'paypal',
      paymentPayoutId: 'PAYOUT-7KD29XQ4',
      paymentStatus: 'SUCCESS',
      paymentAt: _today(7, 2),
      agentRunId: 'r2',
      idempotencyKey: 'k2',
      createdAt: _today(7, 1),
    ),
    Order(
      id: 'o3',
      storeId: _storeId,
      supplierId: 's3',
      createdByType: OrderCreatorType.agent,
      items: const [
        OrderItem(productUid: 'PAN-001', name: 'Croissant', qty: 60, unitPrice: 0.6),
        OrderItem(productUid: 'PAN-002', name: 'Napolitana', qty: 24, unitPrice: 0.75),
      ],
      subtotal: 54,
      total: 54,
      status: OrderStatus.invoiced,
      paymentProvider: 'paypal',
      paymentPayoutId: 'PAYOUT-3HF81LM0',
      paymentStatus: 'SUCCESS',
      paymentAt: _daysAgo(1, 18),
      idempotencyKey: 'k3',
      createdAt: _daysAgo(1, 18),
    ),
    Order(
      id: 'o4',
      storeId: _storeId,
      supplierId: 's4',
      items: const [
        OrderItem(productUid: 'ENV-001', name: 'Vasos 12 oz (caja 50)', qty: 10, unitPrice: 4.2),
        OrderItem(productUid: 'ENV-002', name: 'Azúcar en sobres (caja 500)', qty: 2, unitPrice: 6.5),
      ],
      subtotal: 55,
      total: 55,
      status: OrderStatus.completed,
      paymentProvider: 'paypal',
      paymentPayoutId: 'PAYOUT-9QA02RT5',
      paymentStatus: 'SUCCESS',
      paymentAt: _daysAgo(3, 10),
      idempotencyKey: 'k4',
      createdAt: _daysAgo(3, 10),
    ),
  ];

  late final List<AgentRun> runs = [
    AgentRun(
      id: 'r1',
      storeId: _storeId,
      orderId: 'o1',
      provider: 'groq',
      model: 'llama-3.3-70b-versatile',
      decision: 'order_created',
      confidence: 0.86,
      createdAt: _today(7, 0),
    ),
    AgentRun(
      id: 'r2',
      storeId: _storeId,
      orderId: 'o2',
      provider: 'groq',
      model: 'llama-3.3-70b-versatile',
      decision: 'auto_approved',
      confidence: 0.93,
      createdAt: _today(7, 1),
    ),
    AgentRun(
      id: 'r0',
      storeId: _storeId,
      provider: 'groq',
      model: 'llama-3.3-70b-versatile',
      decision: 'no_action',
      createdAt: _daysAgo(1, 7),
    ),
  ];

  int _counter = 10;
  String nextId(String prefix) => '$prefix${_counter++}';
}

class PreviewAuthRepository implements AuthRepository {
  static const _user = AppUser(id: 'demo-user', email: 'demo@restock.app', storeName: 'Café Lumbre');

  @override
  AppUser? currentUser() => _user;

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Either<AppError, AppUser>> signIn(String email, String password) async => const Right(_user);

  @override
  Future<Either<AppError, AppUser>> signUp(String email, String password, {String? storeName}) async =>
      const Right(_user);

  @override
  Future<Either<AppError, Unit>> signOut() async => const Left(AppError(AppErrorCode.previewNoSignOut));

  @override
  Future<Either<AppError, Unit>> sendResetPasswordEmail(String email) async => const Right(unit);
}

class PreviewStoreRepository implements StoreRepository {
  PreviewStoreRepository(this.db);
  final PreviewDb db;

  @override
  Future<Either<AppError, Store?>> getOwn() async => Right(db.store);

  @override
  Future<Either<AppError, Unit>> update(String storeId,
      {String? name, String? paypalMerchantEmail, String? notificationEmail}) async {
    final s = db.store;
    db.store = Store(
      id: s.id,
      ownerId: s.ownerId,
      name: name ?? s.name,
      currency: s.currency,
      paypalMerchantEmail: paypalMerchantEmail ?? s.paypalMerchantEmail,
      notificationEmail: notificationEmail ?? s.notificationEmail,
    );
    return const Right(unit);
  }
}

class PreviewSettingsRepository implements SettingsRepository {
  PreviewSettingsRepository(this.db);
  final PreviewDb db;

  @override
  Future<Either<AppError, SpendingRules>> getSpendingRules(String storeId) async => Right(db.rules);

  @override
  Future<Either<AppError, Unit>> updateSpendingRules(String storeId, SpendingRules rules) async {
    db.rules = rules;
    return const Right(unit);
  }
}

class PreviewSupplierRepository implements SupplierRepository {
  PreviewSupplierRepository(this.db);
  final PreviewDb db;

  @override
  Future<Either<AppError, List<Supplier>>> getAll() async => Right(db.suppliers);

  @override
  Future<Either<AppError, Supplier?>> getById(String id) async {
    for (final s in db.suppliers) {
      if (s.id == id) return Right(s);
    }
    return const Right(null);
  }
}

class PreviewProductRepository implements ProductRepository {
  PreviewProductRepository(this.db);
  final PreviewDb db;

  @override
  Future<Either<AppError, List<Product>>> getBySupplier(String supplierId) async =>
      Right(db.products.where((p) => p.supplierId == supplierId).toList());

  @override
  Future<Either<AppError, Product?>> getByUid(String uid) async {
    for (final p in db.products) {
      if (p.uid == uid) return Right(p);
    }
    return const Right(null);
  }

  @override
  Future<Either<AppError, List<Product>>> getByUids(List<String> uids) async =>
      Right(db.products.where((p) => uids.contains(p.uid)).toList());

  @override
  Future<Either<AppError, List<Product>>> getLowStock() async =>
      Right(db.products.where((p) => p.isLowStock).toList());

  @override
  Future<Either<AppError, Unit>> updateStock(String uid, int stock) async {
    final index = db.products.indexWhere((p) => p.uid == uid);
    if (index < 0) return const Left(AppError(AppErrorCode.productMissing));
    if (stock < 0) return const Left(AppError(AppErrorCode.stockNegative));
    db.products[index] = db.products[index].copyWith(stock: stock);
    return const Right(unit);
  }
}

class PreviewOrderRepository implements OrderRepository {
  PreviewOrderRepository(this.db);
  final PreviewDb db;

  static const _spentStatuses = {OrderStatus.paid, OrderStatus.invoiced, OrderStatus.completed};

  @override
  Future<Either<AppError, List<Order>>> getByStore(String storeId) async {
    final list = [...db.orders]
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return Right(list);
  }

  @override
  Future<Either<AppError, Order?>> getById(String id) async {
    for (final o in db.orders) {
      if (o.id == id) return Right(o);
    }
    return const Right(null);
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
    final total = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final order = Order(
      id: db.nextId('o'),
      storeId: storeId,
      supplierId: supplierId,
      createdByType: createdByType,
      createdById: createdById,
      items: items,
      subtotal: total,
      total: total,
      status: status,
      agentRunId: agentRunId,
      idempotencyKey: idempotencyKey,
      createdAt: DateTime.now(),
    );
    db.orders.add(order);
    return Right(order);
  }

  @override
  Future<Either<AppError, double>> getSpentThisMonth(String storeId) async => Right(
        db.orders.where((o) => _spentStatuses.contains(o.status)).fold<double>(0, (s, o) => s + o.total),
      );

  @override
  Future<Either<AppError, Unit>> approve(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final i = db.orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return const Left(AppError(AppErrorCode.orderNotFound));
    db.orders[i] = db.orders[i].copyWith(
      status: OrderStatus.paid,
      paymentProvider: 'paypal',
      paymentPayoutId: 'PAYOUT-DEMO${db.nextId('')}',
      paymentStatus: 'SUCCESS',
      paymentAt: DateTime.now(),
    );
    return const Right(unit);
  }

  @override
  Future<Either<AppError, Unit>> reject(String orderId) async {
    final i = db.orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return const Left(AppError(AppErrorCode.orderNotFound));
    db.orders[i] = db.orders[i].copyWith(status: OrderStatus.rejected);
    return const Right(unit);
  }
}

/// Agente simulado: si no hay nada pendiente, repone la leche de avena y la
/// "paga" porque está dentro de las reglas.
class PreviewAgentRepository implements AgentRepository {
  PreviewAgentRepository(this.db);
  final PreviewDb db;

  @override
  Future<Either<AppError, AgentRunResult>> run(String storeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    final pending = db.orders.where((o) => o.status == OrderStatus.pendingApproval).toList();
    if (pending.isNotEmpty) {
      _log('no_action');
      return const Right(AgentRunResult(
        decision: 'no_action',
        message: 'Ya tienes un pedido de café esperando tu aprobación. No preparo otro hasta que decidas.',
      ));
    }

    final alreadyOrdered = db.orders.any((o) => o.items.any((i) => i.productUid == 'LAC-002'));
    if (alreadyOrdered) {
      _log('no_action');
      return const Right(AgentRunResult(
        decision: 'no_action',
        message: 'He revisado el stock: lo que está bajo ya va en camino. No hace falta pedir nada más.',
      ));
    }

    final runId = db.nextId('r');
    final order = Order(
      id: db.nextId('o'),
      storeId: storeId,
      supplierId: 's2',
      createdByType: OrderCreatorType.agent,
      items: const [OrderItem(productUid: 'LAC-002', name: 'Leche de avena 1 L', qty: 20, unitPrice: 2.1)],
      subtotal: 42,
      total: 42,
      status: OrderStatus.paid,
      paymentProvider: 'paypal',
      paymentPayoutId: 'PAYOUT-DEMO${db.nextId('')}',
      paymentStatus: 'SUCCESS',
      paymentAt: DateTime.now(),
      agentRunId: runId,
      idempotencyKey: runId,
      createdAt: DateTime.now(),
    );
    db.orders.add(order);
    db.runs.insert(
      0,
      AgentRun(
        id: runId,
        storeId: storeId,
        orderId: order.id,
        provider: 'groq',
        model: 'llama-3.3-70b-versatile',
        decision: 'auto_approved',
        confidence: 0.91,
        createdAt: DateTime.now(),
      ),
    );
    return Right(AgentRunResult(
      orderId: order.id,
      decision: 'auto_approved',
      message: 'Pedí 20 L de leche de avena a Lácteos Sierra (42,00 €) y lo pagué con PayPal: '
          'estaba dentro de tus reglas.',
    ));
  }

  void _log(String decision) {
    db.runs.insert(
      0,
      AgentRun(
        id: db.nextId('r'),
        storeId: _storeId,
        provider: 'groq',
        model: 'llama-3.3-70b-versatile',
        decision: decision,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<AppError, List<AgentRun>>> getRuns(String storeId) async => Right([...db.runs]);
}
