import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';
import 'package:store_automatization_app/core/service_locator.dart';
import 'package:store_automatization_app/data/datasources/store_repository/supabase_store_changes_datasource.dart';
import 'package:store_automatization_app/data/repositories/assistant_repository/api_assistant_repository.dart';
import 'package:store_automatization_app/data/repositories/store_repository/supabase_store_changes_repository.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';
import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_supplier_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/get_suppliers_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/update_product_stock_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/approve_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/create_draft_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/get_spent_this_month_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/reject_order_usecase.dart';
import 'package:store_automatization_app/domain/usecases/orders/review_order_amount_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/get_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/settings/update_spending_rules_usecase.dart';
import 'package:store_automatization_app/domain/usecases/catalog/search_catalog_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/get_current_store_usecase.dart';
import 'package:store_automatization_app/domain/usecases/store/watch_store_changes_usecase.dart';
import 'package:store_automatization_app/presentation/blocs/assistant/assistant_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/presentation/pages/agent/assistant_page.dart';
import 'package:store_automatization_app/presentation/pages/catalog/stock_page.dart';
import 'package:store_automatization_app/presentation/pages/home/home_page.dart';
import 'package:store_automatization_app/presentation/pages/orders/orders_page.dart';
import 'package:store_automatization_app/presentation/pages/settings/rules_page.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/carousel_nav_bar.dart';

/// App principal tras iniciar sesión: 5 pestañas en un PageView con la
/// barra en carrusel flotando encima.

/// Recuerda la pestaña activa fuera del widget para que el dock no vuelva a
/// "Inicio" si el shell se reconstruye (por ejemplo, al cambiar el tema o
/// cuando la autenticación vuelve a emitir).
class ShellTabStore {
  ShellTabStore._();

  static final ShellTabStore instance = ShellTabStore._();

  final ValueNotifier<int> indexNotifier = ValueNotifier(0);

  int get index => indexNotifier.value;
  set index(int value) => indexNotifier.value = value;
}

class StockyShell extends StatelessWidget {
  const StockyShell({super.key, this.createCubit, this.createAssistantCubit});

  /// Para la vista previa del diseño (lib/main_preview.dart): permite usar
  /// datos de ejemplo en vez de Supabase. En la app real es null.
  final StockyCubit Function()? createCubit;

  /// Igual para el asistente de compras (estudio de mercado y voz).
  final AssistantCubit Function()? createAssistantCubit;

  StockyCubit _defaultCubit(BuildContext context) => StockyCubit(
    getCurrentStore: sl<GetCurrentStoreUsecase>(),
    getSpendingRules: sl<GetSpendingRulesUsecase>(),
    updateSpendingRules: sl<UpdateSpendingRulesUsecase>(),
    getSpentThisMonth: sl<GetSpentThisMonthUsecase>(),
    getOrders: sl<GetOrdersUsecase>(),
    getSuppliers: sl<GetSuppliersUsecase>(),
    getSupplierCatalog: sl<GetSupplierCatalogUsecase>(),
    updateProductStock: sl<UpdateProductStockUsecase>(),
    searchCatalogUsecase: sl<SearchCatalogUsecase>(),
    createDraftOrder: sl<CreateDraftOrderUsecase>(),
    getAgentRuns: sl<GetAgentRunsUsecase>(),
    runAgentUsecase: sl<RunAgentUsecase>(),
    // Estos dos casos de uso son nuevos; se crean aquí para no tocar
    // service_locator.dart. Se pueden registrar allí más adelante.
    approveOrder: ApproveOrderUsecase(repository: sl<OrderRepository>()),
    rejectOrder: RejectOrderUsecase(repository: sl<OrderRepository>()),
    reviewOrderAmountUsecase: ReviewOrderAmountUsecase(
      repository: sl<OrderRepository>(),
    ),
    // Tiempo real: la app se actualiza sola cuando cambian pedidos o stock.
    watchStoreChanges: WatchStoreChangesUsecase(
      repository: SupabaseStoreChangesRepository(
        SupabaseStoreChangesDatasource(sl<SupabaseClient>()),
      ),
    ),
    // Se resuelve en cada llamada, así que al cambiar de idioma los
    // mensajes del agente salen en el idioma nuevo sin recrear el cubit.
    l10n: () => AppLocalizations.of(context),
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StockyCubit>(
          create: (context) =>
              (createCubit?.call() ?? _defaultCubit(context))..load(),
        ),
        // Vive en el shell para que la conversación no se pierda al cambiar
        // de pestaña.
        BlocProvider<AssistantCubit>(
          create: (_) =>
              createAssistantCubit?.call() ??
              AssistantCubit(repository: ApiAssistantRepository(sl<Dio>())),
        ),
      ],
      child: ShellView(key: _shellKey),
    );
  }
}

final _shellKey = GlobalKey<ShellViewState>();

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  static void jumpToTab(int index) =>
      _shellKey.currentState?._goTo(index, animate: false);

  @override
  State<ShellView> createState() => ShellViewState();
}

class ShellViewState extends State<ShellView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PageController _pages = PageController(
    initialPage: ShellTabStore.instance.index,
  );
  late int _index = ShellTabStore.instance.index;

  /// Fundido para saltar a una pestaña lejana sin pasar por las de en medio.
  late final AnimationController _fade = AnimationController(vsync: this, value: 1);
  int? _jumpFrom;
  int? _jumpTo;
  int _jumpToken = 0;

  /// Las pestañas del dock, con los textos del idioma activo.
  List<NavItem> _items(AppLocalizations l10n) => [
    NavItem(l10n.tabHome, CupertinoIcons.house),
    NavItem(l10n.tabStock, CupertinoIcons.cube_box),
    NavItem(l10n.tabOrders, CupertinoIcons.doc_text),
    NavItem(l10n.tabRules, CupertinoIcons.slider_horizontal_3),
    NavItem(l10n.tabAssistant, CupertinoIcons.chat_bubble),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShellTabStore.instance.indexNotifier.addListener(_onTabChanged);
  }

  /// Al volver a la app (desde otra app o con la pantalla apagada) se
  /// recargan los datos, por si algo cambió mientras tanto.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<StockyCubit>().load();
    }
  }

  void _onTabChanged() {
    final newIndex = ShellTabStore.instance.index;
    if (newIndex == _index) return;
    _index = newIndex;
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pages.jumpToPage(newIndex);
      });
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShellTabStore.instance.indexNotifier.removeListener(_onTabChanged);
    _pages.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _goTo(int index, {bool animate = true}) {
    if (index == _index) return;
    final from = _index;
    _index = index;
    ShellTabStore.instance.index = index;
    if (!animate) {
      _pages.jumpToPage(index);
    } else if ((index - from).abs() > 1) {
      _crossFadeTo(from, index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// La pantalla actual se desvanece, la píldora del dock viaja hasta la
  /// pestaña elegida y la nueva aparece: no se ven las pantallas de en medio.
  Future<void> _crossFadeTo(int from, int index) async {
    final token = ++_jumpToken;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _jumpFrom = from;
      _jumpTo = index;
    });
    _fade.animateTo(0, duration: const Duration(milliseconds: 130), curve: Curves.easeOut);
    await _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted || token != _jumpToken) return;
    setState(() {
      _jumpFrom = null;
      _jumpTo = null;
    });
    await _fade.animateTo(1, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }

  void _dragTo(int index) {
    if (index == _index) return;
    _index = index;
    ShellTabStore.instance.index = index;
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.background,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            FadeTransition(
              opacity: _fade,
              child: PageView(
              controller: _pages,
              onPageChanged: (i) {
                // Durante un salto lejano no se cuentan las pestañas de en medio.
                if (_jumpTo != null) return;
                HapticFeedback.selectionClick();
                FocusScope.of(context).unfocus();
                ShellTabStore.instance.index = i;
                setState(() => _index = i);
              },
              children: [
                for (final (i, page) in const [
                  HomePage(),
                  StockPage(),
                  OrdersPage(),
                  RulesPage(),
                  AssistantPage(),
                ].indexed)
                  // En un salto lejano, las pantallas de en medio no se pintan.
                  Opacity(
                    opacity: _jumpTo == null || i == _jumpTo || i == _jumpFrom ? 1 : 0,
                    child: page,
                  ),
              ],
            ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 22 + bottom,
              child: Center(
                child: ConstrainedBox(
                  // En tablet y web la barra no se estira de lado a lado.
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: CarouselNavBar(
                    controller: _pages,
                    items: _items(context.l10n),
                    onSelect: (i) => _goTo(i),
                    onDragSelect: _dragTo,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
