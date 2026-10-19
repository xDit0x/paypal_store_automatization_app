import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/domain/entities/store.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';
import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_supplier_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_suppliers_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/approve_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/reject_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
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
  final GetAgentRunsUsecase getAgentRuns;
  final RunAgentUsecase runAgentUsecase;
  final ApproveOrderUsecase approveOrder;
  final RejectOrderUsecase rejectOrder;

  RestockCubit({
    required this.getCurrentStore,
    required this.getSpendingRules,
    required this.updateSpendingRules,
    required this.getSpentThisMonth,
    required this.getOrders,
    required this.getSuppliers,
    required this.getSupplierCatalog,
    required this.getAgentRuns,
    required this.runAgentUsecase,
    required this.approveOrder,
    required this.rejectOrder,
  }) : super(const RestockState());

  /// Carga todo. Si ya había datos, los mantiene visibles mientras refresca.
  Future<void> load() async {
    if (state.status != RestockStatus.ready) {
      emit(state.copyWith(status: RestockStatus.loading, clearError: true));
    }

    final storeResult = await getCurrentStore();
    final store = storeResult.fold<Store?>((_) => null, (s) => s);
    if (store == null) {
      final message = storeResult.fold<String>((e) => e, (_) => 'No se encontró la tienda.');
      emit(state.copyWith(status: RestockStatus.failure, error: message));
      return;
    }

    final errors = <String>[];

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
    final catalogs = await Future.wait(suppliers.map((s) => getSupplierCatalog(s.id)));
    final products = <Product>[];
    for (final result in catalogs) {
      result.fold<void>(errors.add, products.addAll);
    }
    products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final chat = state.chat.isEmpty ? _chatFromRuns(runs) : state.chat;

    emit(state.copyWith(
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
    ));
  }

  /// Ejecuta el agente. Devuelve el mensaje para mostrar al usuario.
  Future<String> runAgent({bool fromChat = false}) async {
    final store = state.store;
    if (store == null || state.agentRunning) return 'El agente ya está trabajando.';

    final chat = [...state.chat];
    if (fromChat) {
      chat.add(ChatEntry(fromUser: true, text: 'Revisa el stock ahora', at: DateTime.now()));
    }
    emit(state.copyWith(agentRunning: true, chat: chat));

    final result = await runAgentUsecase(store.id);
    final message = result.fold<String>(
      (error) => error,
      (r) => r.message.isNotEmpty ? r.message : describeDecision(r.decision),
    );

    emit(state.copyWith(
      agentRunning: false,
      chat: [...state.chat, ChatEntry(fromUser: false, text: message, at: DateTime.now())],
    ));
    await load();
    return message;
  }

  /// Pregunta libre en el Asistente. El chat libre está fuera del MVP,
  /// así que se responde con lo que el agente sí puede hacer.
  void ask(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now();
    emit(state.copyWith(chat: [
      ...state.chat,
      ChatEntry(fromUser: true, text: clean, at: now),
      ChatEntry(
        fromUser: false,
        text: 'De momento sé revisar tu stock, proponer pedidos y pagarlos con PayPal '
            'dentro de tus reglas. Pulsa «Revisa el stock ahora» y me pongo con ello.',
        at: now,
      ),
    ]));
  }

  /// Pregunta que se responde con los datos ya cargados (sin servidor).
  void addExchange(String question, String answer) {
    final now = DateTime.now();
    emit(state.copyWith(chat: [
      ...state.chat,
      ChatEntry(fromUser: true, text: question, at: now),
      ChatEntry(fromUser: false, text: answer, at: now),
    ]));
  }

  /// Devuelve null si todo fue bien, o el error.
  Future<String?> approve(String orderId) async {
    emit(state.copyWith(busyOrderId: orderId));
    final result = await approveOrder(orderId);
    emit(state.copyWith(clearBusyOrder: true));
    final error = result.fold<String?>((e) => e, (_) => null);
    await load();
    return error;
  }

  Future<String?> reject(String orderId) async {
    emit(state.copyWith(busyOrderId: orderId));
    final result = await rejectOrder(orderId);
    emit(state.copyWith(clearBusyOrder: true));
    final error = result.fold<String?>((e) => e, (_) => null);
    await load();
    return error;
  }

  Future<String?> saveRules(SpendingRules rules) async {
    final store = state.store;
    if (store == null) return 'No hay tienda cargada.';
    final result = await updateSpendingRules(store.id, rules);
    return result.fold<String?>((e) => e, (_) {
      emit(state.copyWith(rules: rules));
      return null;
    });
  }

  List<ChatEntry> _chatFromRuns(List<AgentRun> runs) {
    final recent = runs.where((r) => r.decision != null && r.decision != 'running').take(4).toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return [
      for (final r in recent)
        ChatEntry(
          fromUser: false,
          text: describeDecision(r.decision!),
          at: r.createdAt?.toLocal() ?? DateTime.now(),
        ),
    ];
  }

  /// Traduce los códigos de decisión del servidor a una frase.
  static String describeDecision(String decision) => switch (decision) {
        'order_created' => 'Preparé un pedido de reposición con tu stock bajo.',
        'no_action' => 'Revisé el stock: no hacía falta pedir nada.',
        'blocked' => 'Quise pedir, pero tus reglas de gasto lo bloquearon.',
        'failed' => 'La revisión falló. Inténtalo de nuevo en un momento.',
        'auto_approved' => 'Hice un pedido dentro de tus reglas y lo pagué con PayPal.',
        'requires_approval' => 'Preparé un pedido que necesita tu aprobación.',
        _ => 'Revisión del agente: $decision',
      };

  /// Pedido que el agente acaba de crear, si lo hay (para abrirlo).
  Order? newestPending() {
    final pending = state.pendingOrders;
    return pending.isEmpty ? null : pending.first;
  }
}
