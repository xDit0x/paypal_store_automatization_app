import 'package:flutter/cupertino.dart';
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
import 'package:store_automatization_app/presentation/blocs/assistant/assistant_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/locale/locale_cubit.dart';

import 'package:store_automatization_app/presentation/blocs/sound/sound_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:store_automatization_app/presentation/pages/shell/stocky_shell.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/carousel_nav_bar.dart';

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
    getAgentRuns: GetAgentRunsUsecase(repository: agent),
    runAgentUsecase: RunAgentUsecase(repository: agent),
    approveOrder: ApproveOrderUsecase(repository: orders),
    rejectOrder: RejectOrderUsecase(repository: orders),
  );
}

/// Tamaño del icono de la pestaña con ese icono, dentro del dock.
double _iconSize(WidgetTester tester, IconData icon) {
  final finder = find.descendant(
    of: find.byType(CarouselNavBar),
    matching: find.byIcon(icon),
  );
  return tester.getSize(finder.first).width;
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
              home: StockyShell(createCubit: _restockCubit),
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
          home: StockyShell(createCubit: _restockCubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stock').last);
    await tester.pumpAndSettle();
    expect(_page(tester), 1);

    // Desde Stock se puede abrir el catálogo de proveedores para comprar.
    expect(find.text('Añadir productos al stock'), findsOneWidget);
    await tester.tap(find.text('Añadir productos al stock'));
    await tester.pumpAndSettle();
    expect(find.text('Catálogo de proveedores'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

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
            child: StockyShell(createCubit: _restockCubit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_page(tester), 1);
  });

  testWidgets('la píldora se encoge al viajar y recupera su tamaño al llegar', (
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

    final resting = _pillRect(tester);
    expect(resting.width, closeTo(84, 1));

    // De Inicio (0) a Asistente (4): la cascada dura 4 x 165 ms.
    await tester.tap(find.text('Asistente').last);
    await tester.pump();

    // A lo largo del recorrido la píldora se deshincha hasta ser una burbuja
    // pequeña (34 px, ~50 % del alto) en mitad de cada salto.
    var smallest = resting;
    for (var i = 0; i < 28; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      final r = _pillRect(tester);
      if (r.width < smallest.width) smallest = r;
    }
    expect(smallest.width, lessThan(resting.width * 0.55));
    expect(smallest.height, lessThan(resting.height * 0.75));

    await tester.pumpAndSettle();

    // Al llegar se expande hasta su tamaño real, en la pestaña correcta.
    final arrived = _pillRect(tester);
    expect(arrived.width, closeTo(resting.width, 1));
    expect(arrived.height, closeTo(resting.height, 1));
    expect(_page(tester), 4);
  });

  testWidgets('la píldora también viaja en el segundo cambio de pestaña', (
    tester,
  ) async {
    // Regresión: `forward(from: 0)` pasa por el estado `dismissed`, y si se
    // toma por "cascada terminada" la píldora aparece ya en el destino en
    // todos los cambios menos el primero.
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
    final atAssistant = _pillRect(tester);

    // Segundo cambio: de Asistente (4) a Stock (1).
    await tester.tap(find.text('Stock').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final moving = _pillRect(tester);

    // En pleno vuelo no puede estar donde estaba ni donde va.
    expect(moving.width, lessThan(atAssistant.width - 8));
    expect(moving.center.dx, lessThan(atAssistant.center.dx - 20));

    await tester.pumpAndSettle();
    final atStock = _pillRect(tester);
    expect(
      (moving.center.dx - atStock.center.dx).abs(),
      greaterThan(20),
      reason: 'la píldora se teletransportó al destino sin recorrerlo',
    );
    expect(atStock.width, closeTo(atAssistant.width, 1));
    expect(_page(tester), 1);
  });

  testWidgets('las pestañas se agrandan una a una al pasar la píldora', (
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

    final home = CupertinoIcons.house;
    final stock = CupertinoIcons.cube_box;
    final assistant = CupertinoIcons.chat_bubble;

    final homeRest = _iconSize(tester, home);
    final stockRest = _iconSize(tester, stock);
    expect(stockRest, lessThan(homeRest));

    // De Inicio (0) a Asistente (4): la cascada pasa por todas.
    await tester.tap(find.text('Asistente').last);
    await tester.pump();

    // A mitad del primer salto el foco está en Stock: su icono ha crecido.
    await tester.pump(const Duration(milliseconds: 180));
    expect(_iconSize(tester, stock), greaterThan(stockRest + 3));
    expect(_iconSize(tester, home), lessThan(homeRest - 3));

    await tester.pumpAndSettle();

    // Al llegar, Asistente se queda grande y el resto vuelve a su tamaño.
    expect(_iconSize(tester, assistant), greaterThan(stockRest + 3));
    expect(_iconSize(tester, home), lessThan(homeRest - 3));
    expect(_page(tester), 4);
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
            home: StockyShell(createCubit: _restockCubit),
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
