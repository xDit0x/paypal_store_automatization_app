import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

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
import 'package:store_automatization_app/domain/usecases/catalog/update_product_stock_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/approve_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/reject_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/sound/sound_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:store_automatization_app/presentation/pages/shell/restock_shell.dart';
import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';
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

RestockCubit _restockCubit() {
  final db = PreviewDb();
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
    updateProductStock: UpdateProductStockUsecase(repository: products),
    getAgentRuns: GetAgentRunsUsecase(repository: agent),
    runAgentUsecase: RunAgentUsecase(repository: agent),
    approveOrder: ApproveOrderUsecase(repository: orders),
    rejectOrder: RejectOrderUsecase(repository: orders),
  );
}

/// Rectángulo de la píldora azul del dock.
Rect _pillRect(WidgetTester tester) {
  final pill = find
      .descendant(
        of: find.byType(CarouselNavBar),
        matching: find.byType(Positioned),
      )
      .first;
  return tester.getRect(pill);
}

double _page(WidgetTester tester) {
  return tester.widget<PageView>(find.byType(PageView)).controller!.page!;
}

void main() {
  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
    ShellTabStore.instance.index = 0;
  });

  testWidgets('cambiar el tema no devuelve el dock a Inicio', (tester) async {
    final theme = ThemeCubit();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: theme),
            BlocProvider.value(value: _authCubit()),
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => SoundCubit()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: mode,
              locale: const Locale('es'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RestockShell(createCubit: _restockCubit),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reglas').last);
    await tester.pumpAndSettle();
    expect(_page(tester), 3);

    final pillBefore = _pillRect(tester);

    theme.updateTheme(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(_page(tester), 3);
    expect(
      (_pillRect(tester).center.dx - pillBefore.center.dx).abs(),
      lessThan(2),
    );
  });

  testWidgets('reconstruir el shell conserva la pestaña activa', (
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
          home: RestockShell(createCubit: _restockCubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stock').last);
    await tester.pumpAndSettle();
    expect(_page(tester), 1);

    // Simula que el shell se vuelve a crear (cambio de tema, re-emisión de
    // autenticación, etc.): la pestaña activa debe conservarse.
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
          home: KeyedSubtree(
            key: const ValueKey('otro-shell'),
            child: RestockShell(createCubit: _restockCubit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_page(tester), 1);
  });

  testWidgets('el selector de idioma traduce la app al inglés', (tester) async {
    final locale = LocaleCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: locale),
          BlocProvider.value(value: _authCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => SoundCubit()),
        ],
        child: BlocBuilder<LocaleCubit, Locale?>(
          builder: (context, selected) => MaterialApp(
            locale: selected ?? const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RestockShell(createCubit: _restockCubit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reglas').last);
    await tester.pumpAndSettle();

    final english = find.text('English');
    // La tarjeta de cuenta está al final de la pestaña: baja del todo para
    // que el selector quede por encima del dock.
    await tester.fling(
      find.byType(Scrollable).last,
      const Offset(0, -700),
      1500,
    );
    await tester.pumpAndSettle();
    await tester.tap(english);
    await tester.pumpAndSettle();

    expect(locale.state, const Locale('en'));
    expect(find.text('Rules'), findsWidgets);
    expect(find.text('Reglas'), findsNothing);
  });
}
