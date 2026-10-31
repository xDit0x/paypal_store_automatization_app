import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/pages/order/order_detail_page.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Buscador del catálogo de proveedores.
///
/// La tienda busca por nombre o UID, filtra por proveedor y va añadiendo
/// productos a un carrito de un solo proveedor. Al tramitarlo se crea un
/// pedido real que se aprueba y paga desde su detalle.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _query = '';
  String? _selectedSupplier;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Carga el catálogo al entrar, sin esperar a que se escriba una búsqueda.
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  Future<void> _search({String? supplierId}) async {
    final cubit = context.read<RestockCubit>();
    setState(() => _loading = true);
    await cubit.searchCatalog(
      query: _query.trim().isEmpty ? null : _query.trim(),
      supplierId: supplierId,
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _add(BuildContext context, CatalogProduct product, {int quantity = 1}) {
    context.read<RestockCubit>().addToCart(product, quantity: quantity);
    HapticFeedback.selectionClick();
  }

  /// Abre la hoja para elegir la cantidad exacta antes de añadir al carrito.
  void _openQuantitySheet(BuildContext context, CatalogProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuantitySheet(
        product: product,
        onAdd: (quantity) => _add(context, product, quantity: quantity),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext pageContext) async {
    final cubit = pageContext.read<RestockCubit>();
    final l10n = pageContext.l10n;
    final orders = await cubit.submitCart();
    if (!pageContext.mounted) return;

    if (orders.isEmpty) {
      final error = cubit.state.catalogError;
      if (error != null) {
        showRestockSnack(
          pageContext,
          l10n.describeDetail(error),
          tone: RSnackTone.warning,
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(pageContext).pop();

    if (orders.length == 1) {
      showRestockSnack(
        pageContext,
        l10n.catalogOrderCreated,
        title: l10n.catalogOrderButton,
        tone: RSnackTone.success,
      );
      await pushRestockPage<void>(
        pageContext,
        OrderDetailPage(orderId: orders.first.id),
      );
      if (pageContext.mounted) Navigator.of(pageContext).pop();
      return;
    }

    showRestockSnack(
      pageContext,
      l10n.catalogOrdersCreated(orders.length),
      title: l10n.catalogOrderButton,
      tone: RSnackTone.success,
    );
    if (pageContext.mounted) Navigator.of(pageContext).pop();
  }

  void _openCart(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<RestockCubit>(),
        child: _CartSheet(onOrder: () => _placeOrder(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.rp;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(l10n.catalogTitle),
      ),
      body: BlocBuilder<RestockCubit, RestockState>(
        builder: (context, state) {
          final results = state.catalogResults;
          final suppliers = state.suppliers.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoSearchTextField(
                      placeholder: l10n.catalogSearchPlaceholder,
                      backgroundColor: p.fill,
                      style: TextStyle(color: p.ink),
                      onChanged: (value) {
                        _query = value;
                        _search(supplierId: _selectedSupplier);
                      },
                      onSubmitted: (_) =>
                          _search(supplierId: _selectedSupplier),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _SupplierChip(
                            label: l10n.catalogFilterAll,
                            selected: _selectedSupplier == null,
                            onTap: () {
                              setState(() => _selectedSupplier = null);
                              _search();
                            },
                          ),
                          for (final supplier in suppliers)
                            _SupplierChip(
                              label: supplier.name,
                              selected: _selectedSupplier == supplier.id,
                              onTap: () {
                                setState(() => _selectedSupplier = supplier.id);
                                _search(supplierId: supplier.id);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading && results.isEmpty
                    ? const Center(child: CupertinoActivityIndicator())
                    : results.isEmpty
                    ? REmptyState(
                        icon: CupertinoIcons.search,
                        title: l10n.catalogEmptyTitle,
                        message: l10n.catalogEmptyHint,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: results.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: p.separator),
                        itemBuilder: (_, index) {
                          final product = results[index];
                          return _CatalogRow(
                            product: product,
                            quantity: state.cart
                                .where((c) => c.uid == product.uid)
                                .length,
                            onSelectQuantity: () =>
                                _openQuantitySheet(context, product),
                          );
                        },
                      ),
              ),
              if (state.cart.isNotEmpty)
                _CartBar(state: state, onTap: () => _openCart(context)),
            ],
          );
        },
      ),
    );
  }
}

class _SupplierChip extends StatelessWidget {
  const _SupplierChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? p.accent : p.fill,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : p.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.product,
    required this.quantity,
    required this.onSelectQuantity,
  });

  final CatalogProduct product;
  final int quantity;
  final VoidCallback onSelectQuantity;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    final l10n = context.l10n;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onSelectQuantity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: t.headline),
                    const SizedBox(height: 2),
                    Text(
                      '${product.supplierName} · ${product.uid}',
                      style: t.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.euros(product.price, product.currency),
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (quantity > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: RPill(
                    l10n.catalogCartQuantity(quantity),
                    tone: RPillTone.info,
                  ),
                ),
              RRoundIconButton(
                icon: CupertinoIcons.add,
                label: l10n.catalogAddToCart,
                onTap: onSelectQuantity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja para elegir cuántas unidades añadir al carrito.
class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.product, required this.onAdd});

  final CatalogProduct product;
  final ValueChanged<int> onAdd;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  static const _maxQuantity = 9999;

  int _quantity = 1;
  late final TextEditingController _controller = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuantity(int value) {
    final next = value.clamp(1, _maxQuantity);
    setState(() => _quantity = next);
    _controller.text = '$next';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _onChanged(String text) {
    final parsed = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
    setState(() => _quantity = (parsed ?? 1).clamp(1, _maxQuantity));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.fill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(widget.product.name, style: t.title3),
              const SizedBox(height: 4),
              Text(
                '${widget.product.supplierName} · '
                '${l10n.euros(widget.product.price, widget.product.currency)}',
                style: t.footnote,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _QuantityStepButton(
                    icon: CupertinoIcons.minus,
                    onTap: () => _setQuantity(_quantity - 1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          onChanged: _onChanged,
                          onEditingComplete: () => _setQuantity(_quantity),
                          style: t.largeTitle.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        Text(l10n.catalogQuantity, style: t.caption),
                      ],
                    ),
                  ),
                  _QuantityStepButton(
                    icon: CupertinoIcons.plus,
                    onTap: () => _setQuantity(_quantity + 1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.catalogCartTotal, style: t.headline),
                  Text(
                    l10n.euros(
                      widget.product.price * _quantity,
                      widget.product.currency,
                    ),
                    style: t.title3,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RPrimaryButton(
                l10n.catalogAddToCart,
                onPressed: () {
                  final quantity = _quantity;
                  Navigator.of(context).pop();
                  widget.onAdd(quantity);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepButton extends StatelessWidget {
  const _QuantityStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Material(
      color: p.fill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, size: 24, color: p.accent),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.state, required this.onTap});

  final RestockState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final total = state.cart.fold<double>(0, (sum, c) => sum + c.price);

    return Material(
      color: p.surface,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.catalogCartItems(state.cart.length),
                        style: t.footnote,
                      ),
                      Text(l10n.euros(total, state.currency), style: t.title3),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      l10n.catalogViewCart,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    RChevron(color: p.accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;

    return BlocBuilder<RestockCubit, RestockState>(
      builder: (context, state) {
        final cubit = context.read<RestockCubit>();
        // Proveedor → producto → unidades, para enseñar un bloque por pedido.
        final suppliers = <String, Map<String, List<CatalogProduct>>>{};
        for (final product in state.cart) {
          final byProduct = suppliers.putIfAbsent(
            product.supplierId,
            () => <String, List<CatalogProduct>>{},
          );
          byProduct.putIfAbsent(product.uid, () => []).add(product);
        }
        final total = state.cart.fold<double>(0, (sum, c) => sum + c.price);
        final maxLinesHeight = MediaQuery.sizeOf(context).height * 0.45;

        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: p.fill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(l10n.catalogCartTitle, style: t.title3),
                const SizedBox(height: 2),
                Text(l10n.catalogOrdersPerSupplier, style: t.footnote),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxLinesHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final supplier in suppliers.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(
                              state.supplierName(supplier.key),
                              style: t.headline,
                            ),
                          ),
                          for (final entry in supplier.value.entries)
                            _CartLine(
                              product: entry.value.first,
                              quantity: entry.value.length,
                              onRemove: () => cubit.removeFromCart(entry.key),
                              onAdd: () => cubit.addToCart(entry.value.first),
                            ),
                          Divider(height: 20, color: p.separator),
                        ],
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.catalogCartTotal, style: t.headline),
                    Text(l10n.euros(total, state.currency), style: t.title3),
                  ],
                ),
                const SizedBox(height: 16),
                RPrimaryButton(
                  l10n.catalogOrderButton,
                  loading: state.placingOrder,
                  onPressed: state.placingOrder ? null : onOrder,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final CatalogProduct product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: t.body),
                Text(
                  l10n.euros(product.price * quantity, product.currency),
                  style: t.footnote,
                ),
              ],
            ),
          ),
          _QtyButton(icon: CupertinoIcons.minus, onTap: onRemove),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: t.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _QtyButton(icon: CupertinoIcons.plus, onTap: onAdd),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Material(
      color: p.fill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 16, color: p.accent),
        ),
      ),
    );
  }
}
