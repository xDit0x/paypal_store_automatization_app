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
import 'package:store_automatization_app/l10n/app_localizations_es.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/preview/preview_repositories.dart';

StockyCubit _cubit(PreviewDb db) {
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
    l10n: () => AppLocalizationsEs(),
  );
}

void main() {
  test('la app recoge el presupuesto que cambia el asistente', () async {
    final db = PreviewDb();
    final cubit = _cubit(db);
    await cubit.load();

    expect(cubit.state.rules.monthlyLimit, db.rules.monthlyLimit);

    // El asistente cambia el límite por su cuenta (por chat).
    db.rules = db.rules.copyWith(monthlyLimit: 200);

    final changed = await cubit.refreshRules();

    expect(changed, isTrue);
    expect(cubit.state.rules.monthlyLimit, 200);
    await cubit.close();
  });

  test('si el presupuesto no cambia, no se avisa', () async {
    final db = PreviewDb();
    final cubit = _cubit(db);
    await cubit.load();

    final changed = await cubit.refreshRules();

    expect(changed, isFalse);
    await cubit.close();
  });
}
