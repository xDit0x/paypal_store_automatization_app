import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_supplier_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_suppliers_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/update_low_stock_threshold_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/update_product_stock_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/approve_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/reject_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/assistant/assistant_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/sound/sound_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/presentation/pages/shell/stocky_shell.dart';
import 'package:store_automatization_app/preview/preview_assistant_repository.dart';
import 'package:store_automatization_app/preview/preview_repositories.dart';

class _MemoryStorage implements Storage {
  final _box = <String, dynamic>{};

  @override
  dynamic read(String key) => _box[key];

  @override
  Future<void> write(String key, dynamic value) async => _box[key] = value;

  @override
  Future<void> delete(String key) async => _box.remove(key);

  @override
  Future<void> clear() async => _box.clear();

  @override
  Future<void> close() async {}
}

StockyCubit _restockCubit() {
  final db = PreviewDb();
  final orders = PreviewOrderRepository(db);
  final products = PreviewProductRepository(db);
  final settings = PreviewSettingsRepository(db);
  final agent = PreviewAgentRepository(db);
  return StockyCubit(
    getCurrentStore: GetCurrentStoreUsecase(
      repository: PreviewStoreRepository(db),
    ),
    getSpendingRules: GetSpendingRulesUsecase(repository: settings),
    updateSpendingRules: UpdateSpendingRulesUsecase(repository: settings),
    getSpentThisMonth: GetSpentThisMonthUsecase(repository: orders),
    getOrders: GetOrdersUsecase(repository: orders),
    getSuppliers: GetSuppliersUsecase(
      repository: PreviewSupplierRepository(db),
    ),
    getSupplierCatalog: GetSupplierCatalogUsecase(repository: products),
    updateProductStock: UpdateProductStockUsecase(repository: products),
    updateLowStockThresholdUsecase: UpdateLowStockThresholdUsecase(
      repository: products,
    ),
    getAgentRuns: GetAgentRunsUsecase(repository: agent),
    runAgentUsecase: RunAgentUsecase(repository: agent),
    approveOrder: ApproveOrderUsecase(repository: orders),
    rejectOrder: RejectOrderUsecase(repository: orders),
  );
}

/// Campo de texto del chat del asistente.
Finder _assistantInput() => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.hintText == 'Pregunta lo que quieras',
);

void main() {
  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
    ShellTabStore.instance.index = 0;
  });

  testWidgets('el texto sin enviar sobrevive al cambio de pestaña', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(create: (_) => SoundCubit()),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StockyShell(
            createCubit: _restockCubit,
            createAssistantCubit: () =>
                AssistantCubit(repository: PreviewAssistantRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asistente').last);
    await tester.pumpAndSettle();

    await tester.enterText(_assistantInput(), 'Quiero comprar leche de avena');
    await tester.pump();

    // Se va a otra pestaña y se vuelve: el borrador no puede perderse.
    await tester.tap(find.text('Inicio').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asistente').last);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(_assistantInput());
    expect(field.controller?.text, 'Quiero comprar leche de avena');
  });

  testWidgets('al enviar el mensaje el campo se vacía', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(create: (_) => SoundCubit()),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StockyShell(
            createCubit: _restockCubit,
            createAssistantCubit: () =>
                AssistantCubit(repository: PreviewAssistantRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asistente').last);
    await tester.pumpAndSettle();

    await tester.enterText(_assistantInput(), 'Quiero comprar leche de avena');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(_assistantInput());
    expect(field.controller?.text, isEmpty);
  });
}
