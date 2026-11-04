import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/presentation/pages/order/delivery_check_page.dart';
import 'package:store_automatization_app/preview/preview_repositories.dart';

StockyCubit _previewCubit() {
  final db = PreviewDb();
  final orders = PreviewOrderRepository(db);
  final products = PreviewProductRepository(db);
  final settings = PreviewSettingsRepository(db);
  final agent = PreviewAgentRepository(db);
  return StockyCubit(
    getCurrentStore: GetCurrentStoreUsecase(repository: PreviewStoreRepository(db)),
    getSpendingRules: GetSpendingRulesUsecase(repository: settings),
    updateSpendingRules: UpdateSpendingRulesUsecase(repository: settings),
    getSpentThisMonth: GetSpentThisMonthUsecase(repository: orders),
    getOrders: GetOrdersUsecase(repository: orders),
    getSuppliers: GetSuppliersUsecase(repository: PreviewSupplierRepository(db)),
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

void main() {
  testWidgets('un pedido ya pagado se puede confirmar con el albarán', (
    tester,
  ) async {
    final cubit = _previewCubit();
    await cubit.load();

    // El pedido "o2" del preview está pagado por el agente.
    final order = cubit.state.orderById('o2');
    expect(order, isNotNull);

    await tester.pumpWidget(
      BlocProvider<StockyCubit>.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeliveryCheckPage(orderId: 'o2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No hay nada que cobrar: el agente ya pagó.
    expect(find.text('Ya pagado (no se cobra nada más)'), findsOneWidget);
    expect(find.text('Leche entera 1 L'), findsOneWidget);
    expect(find.text('A cobrar'), findsNothing);
  });

  testWidgets('un pedido que no está pagado no se puede confirmar', (
    tester,
  ) async {
    final cubit = _previewCubit();
    await cubit.load();

    await tester.pumpWidget(
      BlocProvider<StockyCubit>.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeliveryCheckPage(orderId: 'o1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pedido no autorizado para entrega.'), findsOneWidget);
  });
}
