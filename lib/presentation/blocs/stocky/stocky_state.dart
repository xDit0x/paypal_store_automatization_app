import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';

enum StockyStatus { initial, loading, ready, failure }

/// Mensaje de la pantalla Asistente.
class ChatEntry {
  final bool fromUser;
  final String text;
  final DateTime at;

  const ChatEntry({
    required this.fromUser,
    required this.text,
    required this.at,
  });
}

/// Estado de las pantallas principales de Stocky (Inicio, Stock, Pedidos,
/// Reglas y Asistente). Se carga una vez y se refresca tras cada acción.
class StockyState {
  final StockyStatus status;
  final AppError? error;
  final Store? store;
  final SpendingRules rules;
  final double spentThisMonth;
  final List<Order> orders;
  final Map<String, Supplier> suppliers;
  final List<Product> products;
  final List<AgentRun> agentRuns;
  final List<ChatEntry> chat;
  final bool agentRunning;
  final String? busyOrderId;
  final List<CatalogProduct> cart;
  final List<CatalogProduct> catalogResults;
  final bool placingOrder;
  final AppError? catalogError;

  /// Texto que se usa cuando un proveedor no tiene nombre (está en el
  /// idioma activo).
  final String supplierFallback;

  const StockyState({
    this.status = StockyStatus.initial,
    this.error,
    this.store,
    this.rules = const SpendingRules(),
    this.spentThisMonth = 0,
    this.orders = const [],
    this.suppliers = const {},
    this.products = const [],
    this.agentRuns = const [],
    this.chat = const [],
    this.agentRunning = false,
    this.busyOrderId,
    this.cart = const [],
    this.catalogResults = const [],
    this.placingOrder = false,
    this.catalogError,
    this.supplierFallback = 'Proveedor',
  });

  bool get isLoading =>
      status == StockyStatus.initial || status == StockyStatus.loading;
  String get currency => store?.currency ?? 'EUR';

  double get monthlyLimit => rules.monthlyLimit;
  double get remaining =>
      (monthlyLimit - spentThisMonth).clamp(0, double.infinity).toDouble();
  double get budgetProgress => monthlyLimit <= 0
      ? 0
      : (spentThisMonth / monthlyLimit).clamp(0, 1).toDouble();

  String supplierName(String supplierId) {
    final name = suppliers[supplierId]?.name ?? '';
    return name.trim().isEmpty ? supplierFallback : name;
  }

  List<Order> get pendingOrders =>
      orders.where((o) => o.status == OrderStatus.pendingApproval).toList();

  int get agentCreatedCount =>
      orders.where((o) => o.createdByType == OrderCreatorType.agent).length;

  /// Pedidos pagados pero aún no recibidos/cerrados.
  static const _inTransitStatuses = {
    OrderStatus.approved,
    OrderStatus.paying,
    OrderStatus.authorized,
    OrderStatus.paid,
    OrderStatus.invoiced,
  };

  Set<String> get uidsInTransit => {
    for (final o in orders)
      if (_inTransitStatuses.contains(o.status))
        for (final item in o.items) item.productUid,
  };

  bool isInTransit(Product p) => uidsInTransit.contains(p.uid);

  List<Product> get lowStock {
    final list = products.where((p) => p.active && p.isLowStock).toList()
      ..sort((a, b) => _ratio(a).compareTo(_ratio(b)));
    return list;
  }

  static double _ratio(Product p) => p.lowStockThreshold <= 0
      ? p.stock.toDouble()
      : p.stock / p.lowStockThreshold;

  /// Pedido más reciente con el dinero comprometido y aún sin entrega: el
  /// que se comprueba con el albarán.
  ///
  /// - 'authorized': el dinero está retenido en PayPal y se cobra al entregar.
  /// - 'paid'/'invoiced': el agente ya pagó al proveedor; solo falta confirmar
  ///   lo que ha llegado.
  Order? get latestDelivery {
    for (final o in orders) {
      if (o.status == OrderStatus.authorized ||
          o.status == OrderStatus.paid ||
          o.status == OrderStatus.invoiced) {
        return o;
      }
    }
    return null;
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  AgentRun? runForOrder(Order order) {
    for (final r in agentRuns) {
      if (r.id == order.agentRunId || r.orderId == order.id) return r;
    }
    return null;
  }

  /// Evalúa un pedido con las mismas reglas que usa el dominio.
  SpendingDecision evaluate(Order order) => rules.evaluate(
    orderTotal: order.total,
    spentThisMonth: spentThisMonth,
    supplierId: order.supplierId,
  );

  StockyState copyWith({
    StockyStatus? status,
    AppError? error,
    bool clearError = false,
    Store? store,
    SpendingRules? rules,
    double? spentThisMonth,
    List<Order>? orders,
    Map<String, Supplier>? suppliers,
    List<Product>? products,
    List<AgentRun>? agentRuns,
    List<ChatEntry>? chat,
    bool? agentRunning,
    String? busyOrderId,
    bool clearBusyOrder = false,
    List<CatalogProduct>? cart,
    List<CatalogProduct>? catalogResults,
    bool? placingOrder,
    AppError? catalogError,
    bool clearCatalogError = false,
    String? supplierFallback,
  }) {
    return StockyState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      store: store ?? this.store,
      rules: rules ?? this.rules,
      spentThisMonth: spentThisMonth ?? this.spentThisMonth,
      orders: orders ?? this.orders,
      suppliers: suppliers ?? this.suppliers,
      products: products ?? this.products,
      agentRuns: agentRuns ?? this.agentRuns,
      chat: chat ?? this.chat,
      agentRunning: agentRunning ?? this.agentRunning,
      busyOrderId: clearBusyOrder ? null : (busyOrderId ?? this.busyOrderId),
      cart: cart ?? this.cart,
      catalogResults: catalogResults ?? this.catalogResults,
      placingOrder: placingOrder ?? this.placingOrder,
      catalogError: clearCatalogError
          ? null
          : (catalogError ?? this.catalogError),
      supplierFallback: supplierFallback ?? this.supplierFallback,
    );
  }
}
