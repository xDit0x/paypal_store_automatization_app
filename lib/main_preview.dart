// VISTA PREVIA DEL DISEÑO, sin Supabase ni servidor.
//
// Arranca con:   flutter run -t lib/main_preview.dart
//
// Usa datos de ejemplo en memoria (lib/preview/). La app real sigue
// arrancando con lib/main.dart, que no se ha tocado.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:store_automatization_app/core/configs/theme/app_theme.dart';
import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/check_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/send_reset_password_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/resend_confirmation_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_out_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_up_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/watch_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_supplier_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_suppliers_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/search_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/update_product_stock_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/approve_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/create_draft_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/evaluate_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/reject_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/review_order_amount_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:store_automatization_app/presentation/pages/shell/restock_shell.dart';
import 'package:store_automatization_app/preview/preview_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El ThemeCubit guarda el modo claro/oscuro, igual que en main.dart.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  runApp(PreviewApp(db: PreviewDb()));
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key, required this.db});

  final PreviewDb db;

  RestockCubit _restockCubit() {
    final orders = PreviewOrderRepository(db);
    final products = PreviewProductRepository(db);
    final settings = PreviewSettingsRepository(db);
    final agent = PreviewAgentRepository(db);
    return RestockCubit(
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
      searchCatalogUsecase: SearchCatalogUsecase(repository: products),
      createDraftOrder: CreateDraftOrderUsecase(
        productRepository: products,
        orderRepository: orders,
        evaluateSpendingRules: EvaluateSpendingRulesUsecase(),
      ),
      updateProductStock: UpdateProductStockUsecase(repository: products),
      getAgentRuns: GetAgentRunsUsecase(repository: agent),
      runAgentUsecase: RunAgentUsecase(repository: agent),
      approveOrder: ApproveOrderUsecase(repository: orders),
      rejectOrder: RejectOrderUsecase(repository: orders),
      reviewOrderAmountUsecase: ReviewOrderAmountUsecase(repository: orders),
    );
  }

  AuthCubit _authCubit() {
    final auth = PreviewAuthRepository();
    return AuthCubit(
      signInUseCase: SignInUsecase(repository: auth),
      signUpUseCase: SignUpUsecase(repository: auth),
      signOutUseCase: SignOutUsecase(repository: auth),
      checkAuthUseCase: CheckAuthUsecase(repository: auth),
      watchAuthUseCase: WatchAuthUsecase(repository: auth),
      sendResetPasswordEmailUseCase: SendResetPasswordEmailUsecase(
        repository: auth,
      ),
      resendConfirmationEmailUseCase: ResendConfirmationEmailUsecase(
        repository: auth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => _authCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => BlocBuilder<LocaleCubit, Locale?>(
          builder: (context, locale) => MaterialApp(
            title: 'Restock (vista previa)',
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: RestockShell(createCubit: _restockCubit),
          ),
        ),
      ),
    );
  }
}
