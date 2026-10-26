import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/core/service_locator.dart';
import 'package:store_automatization_app/domain/repositories/order_repository/order_repository.dart';
import 'package:store_automatization_app/domain/usecases/agent/get_agent_runs_usecase.dart';
import 'package:store_automatization_app/domain/usecases/agent/run_agent_usecase.dart';
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
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/pages/agent/assistant_page.dart';
import 'package:store_automatization_app/presentation/pages/catalog/stock_page.dart';
import 'package:store_automatization_app/presentation/pages/home/home_page.dart';
import 'package:store_automatization_app/presentation/pages/orders/orders_page.dart';
import 'package:store_automatization_app/presentation/pages/settings/rules_page.dart';
import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';

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

class RestockShell extends StatelessWidget {
  const RestockShell({super.key, this.createCubit});

  /// Para la vista previa del diseño (lib/main_preview.dart): permite usar
  /// datos de ejemplo en vez de Supabase. En la app real es null.
  final RestockCubit Function()? createCubit;

  RestockCubit _defaultCubit(BuildContext context) => RestockCubit(
    getCurrentStore: sl<GetCurrentStoreUsecase>(),
    getSpendingRules: sl<GetSpendingRulesUsecase>(),
    updateSpendingRules: sl<UpdateSpendingRulesUsecase>(),
    getSpentThisMonth: sl<GetSpentThisMonthUsecase>(),
    getOrders: sl<GetOrdersUsecase>(),
    getSuppliers: sl<GetSuppliersUsecase>(),
    getSupplierCatalog: sl<GetSupplierCatalogUsecase>(),
    updateProductStock: sl<UpdateProductStockUsecase>(),
    getAgentRuns: sl<GetAgentRunsUsecase>(),
    runAgentUsecase: sl<RunAgentUsecase>(),
    // Estos dos casos de uso son nuevos; se crean aquí para no tocar
    // service_locator.dart. Se pueden registrar allí más adelante.
    approveOrder: ApproveOrderUsecase(repository: sl<OrderRepository>()),
    rejectOrder: RejectOrderUsecase(repository: sl<OrderRepository>()),
    // Se resuelve en cada llamada, así que al cambiar de idioma los
    // mensajes del agente salen en el idioma nuevo sin recrear el cubit.
    l10n: () => AppLocalizations.of(context),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RestockCubit>(
      create: (context) =>
          (createCubit?.call() ?? _defaultCubit(context))..load(),
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

class ShellViewState extends State<ShellView> {
  late final PageController _pages = PageController(
    initialPage: ShellTabStore.instance.index,
  );
  late int _index = ShellTabStore.instance.index;

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
    ShellTabStore.instance.indexNotifier.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final newIndex = ShellTabStore.instance.index;
    if (newIndex == _index) return;
    _index = newIndex;
  }

  @override
  void dispose() {
    ShellTabStore.instance.indexNotifier.removeListener(_onTabChanged);
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index, {bool animate = true}) {
    if (index == _index) return;
    _index = index;
    ShellTabStore.instance.index = index;
    if (animate) {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _pages.jumpToPage(index);
    }
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
            PageView(
              controller: _pages,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                FocusScope.of(context).unfocus();
                ShellTabStore.instance.index = i;
                setState(() => _index = i);
              },
              children: const [
                HomePage(),
                StockPage(),
                OrdersPage(),
                RulesPage(),
                AssistantPage(),
              ],
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
