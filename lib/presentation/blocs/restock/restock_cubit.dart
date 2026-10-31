import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/order_amount_review.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';
import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_supplier_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_suppliers_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/search_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/update_product_stock_usecase.dart';
import 'package:store_automatization_app/domain/services/order_builder.dart';
import 'package:store_automatization_app/domain/usecases/orders/create_draft_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/approve_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/reject_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/review_order_amount_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/watch_store_changes_usecase.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';

/// Cubit de las pantallas principales. Solo usa casos de uso del dominio.
class RestockCubit extends Cubit<RestockState> {
  final GetCurrentStoreUsecase getCurrentStore;
  final GetSpendingRulesUsecase getSpendingRules;
  final UpdateSpendingRulesUsecase updateSpendingRules;
  final GetSpentThisMonthUsecase getSpentThisMonth;
  final GetOrdersUsecase getOrders;
  final GetSuppliersUsecase getSuppliers;
  final GetSupplierCatalogUsecase getSupplierCatalog;
  final UpdateProductStockUsecase updateProductStock;
  final GetAgentRunsUsecase getAgentRuns;
  final RunAgentUsecase runAgentUsecase;
  final SearchCatalogUsecase? searchCatalogUsecase;
  final ApproveOrderUsecase approveOrder;
  final RejectOrderUsecase rejectOrder;

  /// Consulta el importe vigente antes de cobrar. Opcional para no romper la
  /// vista previa ni los tests que no lo ejercitan.
  final ReviewOrderAmountUsecase? reviewOrderAmountUsecase;

  /// Crea el pedido del carrito del catálogo. Opcional para no romper la vista
  /// previa ni los tests que no ejercitan la compra.
  final CreateDraftOrderUsecase? createDraftOrder;

  /// Cambios en tiempo real de la tienda. Opcional: sin él (vista previa,
  /// tests) la app solo se actualiza al cargar o tras una acción.
  final WatchStoreChangesUsecase? watchStoreChanges;

  StreamSubscription<void>? _changesSubscription;
  String? _watchedStoreId;
  Timer? _reloadTimer;

  /// Textos del idioma activo. La pantalla inyecta una función que los
  /// resuelve en cada llamada, así que un cambio de idioma se nota al
  /// instante. Sin ella se usa el Locale del dispositivo.
  final AppLocalizations Function() _l10n;

  /// El último `runAgent` terminó con error.
  bool lastRunFailed = false;

  AppLocalizations get l10n => _l10n();

  RestockCubit({
    required this.getCurrentStore,
    required this.getSpendingRules,
    required this.updateSpendingRules,
    required this.getSpentThisMonth,
    required this.getOrders,
    required this.getSuppliers,
    required this.getSupplierCatalog,
    required this.updateProductStock,
    required this.getAgentRuns,
    required this.runAgentUsecase,
    this.searchCatalogUsecase,
    required this.approveOrder,
    required this.rejectOrder,
    this.reviewOrderAmountUsecase,
    this.createDraftOrder,
    this.watchStoreChanges,
    AppLocalizations Function()? l10n,
  }) : _l10n = l10n ?? (() => l10nFor(deviceLocale())),
       super(const RestockState());

  /// Carga todo. Si ya había datos, los mantiene visibles mientras refresca.
  Future<void> load() async {
    if (state.status != RestockStatus.ready) {
      emit(state.copyWith(status: RestockStatus.loading, clearError: true));
    }

    final storeResult = await getCurrentStore();
    final store = storeResult.fold<Store?>((_) => null, (s) => s);
    if (store == null) {
      final message = storeResult.fold<AppError>(
        (error) => error,
        (_) => const AppError(AppErrorCode.storeNotFound),
      );
      emit(state.copyWith(status: RestockStatus.failure, error: message));
      return;
    }

    final errors = <AppError>[];

    final rulesF = getSpendingRules(store.id);
    final spentF = getSpentThisMonth(store.id);
    final ordersF = getOrders(store.id);
    final suppliersF = getSuppliers();
    final runsF = getAgentRuns(store.id);

    final rules = (await rulesF).fold<SpendingRules>((e) {
      errors.add(e);
      return state.rules;
    }, (r) => r);
    final spent = (await spentF).fold<double>((e) {
      errors.add(e);
      return state.spentThisMonth;
    }, (v) => v);
    final orders = (await ordersF).fold<List<Order>>((e) {
      errors.add(e);
      return state.orders;
    }, (v) => v);
    final suppliers = (await suppliersF).fold<List<Supplier>>((e) {
      errors.add(e);
      return const <Supplier>[];
    }, (v) => v);
    final runs = (await runsF).fold<List<AgentRun>>((e) {
      errors.add(e);
      return state.agentRuns;
    }, (v) => v);

    // No hay un "listar todos los productos": se juntan los catálogos.
    final catalogs = await Future.wait(
      suppliers.map((s) => getSupplierCatalog(store.id, s.id)),
    );
    final products = <Product>[];
    for (final result in catalogs) {
      result.fold<void>(errors.add, products.addAll);
    }
    products.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final chat = state.chat.isEmpty ? _chatFromRuns(runs) : state.chat;

    emit(
      state.copyWith(
        status: RestockStatus.ready,
        store: store,
        rules: rules,
        spentThisMonth: spent,
        orders: orders,
        suppliers: {for (final s in suppliers) s.id: s},
        products: products.isEmpty ? state.products : products,
        agentRuns: runs,
        chat: chat,
        error: errors.isEmpty ? null : errors.first,
        clearError: errors.isEmpty,
      ),
    );

    _watch(store.id);
  }

  /// Se suscribe a los cambios en tiempo real de la tienda (una sola vez).
  void _watch(String storeId) {
    final watch = watchStoreChanges;
    if (watch == null || isClosed || _watchedStoreId == storeId) return;

    _changesSubscription?.cancel();
    _watchedStoreId = storeId;
    _changesSubscription = watch(storeId).listen(
      (_) => _scheduleReload(),
      // Si el tiempo real falla, la app sigue funcionando: se actualiza al
      // volver a abrirla o al deslizar para refrescar.
      onError: (Object _) {},
    );
  }

  /// Agrupa los cambios que llegan seguidos (un pedido nuevo suele traer
  /// también cambios de stock) en una sola recarga.
  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 700), () {
      if (!isClosed) load();
    });
  }

  @override
  Future<void> close() async {
    _reloadTimer?.cancel();
    await _changesSubscription?.cancel();
    return super.close();
  }

  /// Ejecuta el agente. Devuelve el mensaje para mostrar al usuario.
  Future<String> runAgent({bool fromChat = false}) async {
    final store = state.store;
    if (store == null || state.agentRunning) return l10n.errorAgentBusy;

    final chat = [...state.chat];
    if (fromChat) {
      chat.add(
        ChatEntry(
          fromUser: true,
          text: l10n.agentChatTrigger,
          at: DateTime.now(),
        ),
      );
    }
    emit(state.copyWith(agentRunning: true, chat: chat));

    final result = await runAgentUsecase(store.id);
    var failed = false;
    final message = result.fold<String>(
      (error) {
        failed = true;
        return l10n.describeDetail(error);
      },
      (r) => r.message.isNotEmpty
          ? r.message
          : describeAgentDecision(l10n, r.decision),
    );
    lastRunFailed = failed;

    emit(
      state.copyWith(
        agentRunning: false,
        chat: [
          ...state.chat,
          ChatEntry(fromUser: false, text: message, at: DateTime.now()),
        ],
      ),
    );
    await load();
    return message;
  }

  /// Pregunta libre en el Asistente. El chat libre está fuera del MVP,
  /// así que se responde con lo que el agente sí puede hacer.
  void ask(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now();
    emit(
      state.copyWith(
        chat: [
          ...state.chat,
          ChatEntry(fromUser: true, text: clean, at: now),
          ChatEntry(fromUser: false, text: l10n.agentChatFallback, at: now),
        ],
      ),
    );
  }

  /// Pregunta que se responde con los datos ya cargados (sin servidor).
  void addExchange(String question, String answer) {
    final now = DateTime.now();
    emit(
      state.copyWith(
        chat: [
          ...state.chat,
          ChatEntry(fromUser: true, text: question, at: now),
          ChatEntry(fromUser: false, text: answer, at: now),
        ],
      ),
    );
  }

  /// Devuelve null si todo fue bien, o el error.
  Future<AppError?> approve(String orderId) async {
    emit(state.copyWith(busyOrderId: orderId));
    final result = await approveOrder(orderId);
    emit(state.copyWith(clearBusyOrder: true));
    final error = result.fold<AppError?>((e) => e, (_) => null);
    await load();
    return error;
  }

  Future<AppError?> reject(String orderId) async {
    emit(state.copyWith(busyOrderId: orderId));
    final result = await rejectOrder(orderId);
    emit(state.copyWith(clearBusyOrder: true));
    final error = result.fold<AppError?>((e) => e, (_) => null);
    await load();
    return error;
  }

  /// Importe que se pagaría ahora. `null` si no se pudo consultar.
  Future<OrderAmountReview?> reviewOrderAmount(String orderId) async {
    final usecase = reviewOrderAmountUsecase;
    if (usecase == null) return null;
    final result = await usecase(orderId);
    return result.fold<OrderAmountReview?>((_) => null, (review) => review);
  }

  /// Cambia el stock de un producto en la tienda actual. Devuelve null si
  /// todo fue bien.
  Future<AppError?> updateStock(String uid, int stock) async {
    final store = state.store;
    if (store == null) return const AppError(AppErrorCode.storeNotFound);

    final result = await updateProductStock(store.id, uid, stock);
    return result.fold<AppError?>((error) => error, (_) {
      emit(
        state.copyWith(
          products: [
            for (final product in state.products)
              product.uid == uid ? product.copyWith(stock: stock) : product,
          ],
        ),
      );
      return null;
    });
  }

  Future<AppError?> saveRules(SpendingRules rules) async {
    final store = state.store;
    if (store == null) return const AppError(AppErrorCode.storeNotFound);
    final result = await updateSpendingRules(store.id, rules);
    return result.fold<AppError?>((e) => e, (_) {
      emit(state.copyWith(rules: rules));
      return null;
    });
  }

  List<ChatEntry> _chatFromRuns(List<AgentRun> runs) {
    final recent =
        runs
            .where((r) => r.decision != null && r.decision != 'running')
            .take(4)
            .toList()
          ..sort(
            (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
              b.createdAt ?? DateTime(0),
            ),
          );
    return [
      for (final r in recent)
        ChatEntry(
          fromUser: false,
          text: describeAgentDecision(l10n, r.decision!),
          at: r.createdAt?.toLocal() ?? DateTime.now(),
        ),
    ];
  }

  /// Pedido que el agente acaba de crear, si lo hay (para abrirlo).
  Order? newestPending() {
    final pending = state.pendingOrders;
    return pending.isEmpty ? null : pending.first;
  }

  /// Busca en el catálogo global y guarda resultados en el estado.
  Future<void> searchCatalog({String? query, String? supplierId}) async {
    final store = state.store;
    if (store == null || searchCatalogUsecase == null) return;
    final result = await searchCatalogUsecase!.call(
      storeId: store.id,
      query: query,
      supplierId: supplierId,
    );
    emit(
      state.copyWith(
        catalogResults: result.fold<List<CatalogProduct>>(
          (_) => state.catalogResults,
          (r) => r,
        ),
      ),
    );
  }

  /// Añade [quantity] unidades de [product] al carrito.
  ///
  /// El carrito puede mezclar proveedores: al tramitarlo se crea un pedido
  /// por cada uno.
  void addToCart(CatalogProduct product, {int quantity = 1}) {
    final qty = quantity < 1 ? 1 : quantity;
    emit(
      state.copyWith(
        cart: [...state.cart, for (var i = 0; i < qty; i++) product],
        clearCatalogError: true,
      ),
    );
  }

  /// Quita una unidad del producto [uid].
  void removeFromCart(String uid) {
    final index = state.cart.lastIndexWhere((c) => c.uid == uid);
    if (index < 0) return;
    final updated = List<CatalogProduct>.from(state.cart)..removeAt(index);
    emit(state.copyWith(cart: updated));
  }

  int quantityInCart(String uid) =>
      state.cart.where((c) => c.uid == uid).length;

  void clearCart() => emit(state.copyWith(cart: const []));

  /// Crea un pedido por cada proveedor del carrito. Devuelve los pedidos
  /// creados; si uno falla, deja en el carrito solo las líneas pendientes.
  Future<List<Order>> submitCart() async {
    final store = state.store;
    final cart = List<CatalogProduct>.from(state.cart);
    final usecase = createDraftOrder;
    if (store == null || cart.isEmpty || usecase == null) return const [];

    // Agrupa por proveedor y, dentro de cada uno, por producto y cantidad.
    final bySupplier = <String, Map<String, int>>{};
    for (final product in cart) {
      final lines = bySupplier.putIfAbsent(
        product.supplierId,
        () => <String, int>{},
      );
      lines.update(product.uid, (qty) => qty + 1, ifAbsent: () => 1);
    }

    emit(state.copyWith(placingOrder: true, clearCatalogError: true));
    final created = <Order>[];
    final succeededSuppliers = <String>{};
    AppError? failure;
    var spent = state.spentThisMonth;

    for (final entry in bySupplier.entries) {
      final lines = [
        for (final line in entry.value.entries)
          DraftOrderLine(productUid: line.key, qty: line.value),
      ];
      final result = await usecase(
        storeId: store.id,
        supplierId: entry.key,
        lines: lines,
        rules: state.rules,
        spentThisMonth: spent,
        // Una compra manual de stock queda por aprobar aunque las reglas la
        // autoaprueben: el dueño confirma el pedido antes de pagar.
        forceApproval: true,
      );
      final (order, error) = result.fold<(Order?, AppError?)>(
        (error) => (null, error),
        (value) => (value.order, null),
      );
      if (error != null) {
        failure = error;
        break;
      }
      created.add(order!);
      succeededSuppliers.add(entry.key);
      spent += order.total;
    }

    final remaining = [
      for (final product in cart)
        if (!succeededSuppliers.contains(product.supplierId)) product,
    ];

    emit(
      state.copyWith(
        cart: remaining,
        placingOrder: false,
        catalogError: failure,
      ),
    );
    if (created.isNotEmpty) unawaited(load());
    return created;
  }
}

/// Traduce los códigos de decisión del servidor a una frase.
String describeAgentDecision(AppLocalizations l10n, String decision) =>
    switch (decision) {
      'order_created' => l10n.decisionOrderCreated,
      'no_action' => l10n.decisionNoAction,
      'blocked' => l10n.decisionBlocked,
      'failed' => l10n.decisionFailed,
      'auto_approved' => l10n.decisionAutoApproved,
      'requires_approval' => l10n.decisionRequiresApproval,
      _ => l10n.decisionGeneric(decision),
    };
