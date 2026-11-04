import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_state.dart';
import 'package:store_automatization_app/presentation/pages/catalog/catalog_page.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/stocky_common.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/stocky_ui.dart';
import 'package:store_automatization_app/core/audio/stocky_sounds.dart';

enum _Filter { active, outOfStock, eliminated, low, transit, all }

/// Pestaña Stock: todos los productos de los catálogos, con búsqueda por
/// nombre o UID y filtro.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  _Filter _filter = _Filter.all;
  String _query = '';
  String? _supplierFilter;
  final GlobalKey _todosKey = GlobalKey();
  final Map<_Filter, GlobalKey> _filterKeys = {};

  @override
  void initState() {
    super.initState();
    for (final f in _Filter.values) {
      _filterKeys[f] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _todosKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.5);
      }
    });
  }

  void _scrollToFilter(_Filter f) {
    final key = _filterKeys[f];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.5);
    });
  }

  List<Product> _visible(StockyState state) {
    final q = _query.trim().toLowerCase();
    return state.products.where((p) {
      final matchesQuery =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.uid.toLowerCase().contains(q);
      final matchesFilter = switch (_filter) {
        _Filter.active => p.active,
        _Filter.low => p.isLowStock && p.stock > 0,
        _Filter.transit => state.isInTransit(p),
        _Filter.outOfStock => p.active && p.stock <= 0,
        _Filter.eliminated => !p.active,
        _Filter.all => p.active,
      };
      final matchesSupplier =
          _supplierFilter == null ||
          _supplierFilter == '' ||
          p.supplierId == _supplierFilter;
      return p.active && matchesQuery && matchesFilter && matchesSupplier;
    }).toList();
  }

  Future<void> _editStock(BuildContext context, Product product) async {
    final cubit = context.read<StockyCubit>();
    final saved = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StockEditorSheet(
        product: product,
        cubit: cubit,
        onSave: (stock, threshold) async {
          final stockError = await cubit.updateStock(product.uid, stock);
          if (stockError != null) return stockError;
          return cubit.updateLowStockThreshold(product.uid, threshold);
        },
      ),
    );
    if (saved == true && context.mounted) {
      setState(() => _filter = _Filter.all);
      showStockySnack(
        context,
        context.l10n.stockRestoredMessage(context.l10n.productName(product.name)),
        title: context.l10n.stockRestored,
        tone: RSnackTone.success,
      );
    } else if (saved != null && saved is int && context.mounted) {
      showStockySnack(
        context,
        context.l10n.stockUpdatedMessage(
          context.l10n.productName(product.name),
          saved,
          context.l10n.unit(product.unit),
        ),
        title: context.l10n.stockUpdated,
        tone: RSnackTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RTabPage(
      builder: (context, state) {
        final p = context.rp;
        final t = context.rt;
        final l10n = context.l10n;
        final products = _visible(state);

        return [
          RLargeTitle(l10n.tabStock),
          const SizedBox(height: 12),
          RInsetGroup(
            children: [
              RListRow(
                title: l10n.catalogAddProducts,
                subtitle: Text(l10n.catalogAddProductsHint, style: t.footnote),
                trailing: RChevron(color: p.accent),
                onTap: () => pushStockyPage<void>(context, const CatalogPage()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CupertinoSearchTextField(
            placeholder: l10n.stockSearchPlaceholder,
            backgroundColor: p.fill,
            style: TextStyle(color: p.ink),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FilterTab(
                      key: _filterKeys[_Filter.low],
                      label: l10n.stockFilterLow,
                      selected: _filter == _Filter.low,
                      onTap: () {
                        setState(() => _filter = _Filter.low);
                        _scrollToFilter(_Filter.low);
                      },
                    ),
                    _FilterTab(
                      key: _filterKeys[_Filter.transit],
                      label: l10n.stockFilterTransit,
                      selected: _filter == _Filter.transit,
                      onTap: () {
                        setState(() => _filter = _Filter.transit);
                        _scrollToFilter(_Filter.transit);
                      },
                    ),
                    _FilterTab(
                      key: _filterKeys[_Filter.all],
                      label: l10n.stockFilterAll,
                      selected: _filter == _Filter.all,
                      onTap: () {
                        setState(() => _filter = _Filter.all);
                        _scrollToFilter(_Filter.all);
                      },
                    ),
                    _FilterTab(
                      key: _filterKeys[_Filter.outOfStock],
                      label: context.l10n.stockFilterOut,
                      selected: _filter == _Filter.outOfStock,
                      accent: Colors.amber,
                      onTap: () {
                        setState(() => _filter = _Filter.outOfStock);
                        _scrollToFilter(_Filter.outOfStock);
                      },
                    ),
                    _FilterTab(
                      key: _filterKeys[_Filter.eliminated],
                      label: context.l10n.stockFilterDeleted,
                      selected: _filter == _Filter.eliminated,
                      accent: Colors.red,
                      onTap: () {
                        setState(() => _filter = _Filter.eliminated);
                        _scrollToFilter(_Filter.eliminated);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _supplierFilter,
              hint: Text(context.l10n.catalogSupplierHint),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.l10n.catalogFilterAll),
                ),
                ...{
                  for (final p in state.products)
                    if (p.stock > 0) p.supplierId,
                }.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(state.supplierName(s)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _supplierFilter = v),
            ),
          ),
          const SizedBox(height: 16),
          if (products.isEmpty && !state.products.any((p) => !p.active))
            REmptyState(
              icon: CupertinoIcons.cube_box,
              title: state.products.isEmpty
                  ? l10n.stockEmptyTitle
                  : l10n.stockEmptyFilterTitle,
              message: state.products.isEmpty ? l10n.stockEmptyMessage : null,
            )
          else ...[
            RInsetGroup(
              children: [
                for (final product in products)
                  _ProductRow(
                    product: product,
                    state: state,
                    onTap: () => _editStock(context, product),
                  ),
              ],
            ),
            if (state.products.any((p) => !p.active))
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'Eliminados',
                    style: TextStyle(color: Colors.red),
                  ),
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    RInsetGroup(
                      children: [
                        for (final product in state.products.where(
                          (p) => !p.active,
                        ))
                          _ProductRow(
                            product: product,
                            state: state,
                            onTap: () => _editStock(context, product),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
          if (products.isNotEmpty || state.products.any((p) => !p.active)) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                l10n.stockProductCount(products.length),
                style: t.caption,
              ),
            ),
          ],
        ];
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final color = accent ?? p.accent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: t.footnote.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? color : p.inkSecondary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.state,
    required this.onTap,
  });

  final Product product;
  final StockyState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final inTransit = state.isInTransit(product);

    final (String label, Color text, Color bar, bool strong) = inTransit
        ? (l10n.stockStatusTransit, p.transit, p.transit, true)
        : product.stock <= 0
        ? (l10n.stockStatusOut, p.warning, p.warningBar, true)
        : product.isLowStock
        ? (l10n.stockStatusLow, p.warning, p.warningBar, true)
        : (l10n.stockStatusOk, p.inkSecondary, p.neutralBar, false);

    // La barra llega al 100 % con el doble del mínimo.
    final reference = product.lowStockThreshold <= 0
        ? 1
        : product.lowStockThreshold * 2;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.productName(product.name),
                      style: t.headline,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                      color: text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              RLevelBar(value: product.stock / reference, color: bar),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.stockUnitsMin(
                        product.stock,
                        l10n.unit(product.unit),
                        product.lowStockThreshold,
                      ),
                      style: t.footnote,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      state.supplierName(product.supplierId),
                      style: t.footnote,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  RChevron(color: p.chevron),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                product.uid,
                style: t.caption.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja para editar el stock de un producto: botones − / + y campo numérico.
class _StockEditorSheet extends StatefulWidget {
  const _StockEditorSheet({
    required this.product,
    required this.onSave,
    this.cubit,
  });

  final Product product;
  final StockyCubit? cubit;

  /// Devuelve null si se guardó bien, o el error.
  final Future<AppError?> Function(int stock, int threshold) onSave;

  @override
  State<_StockEditorSheet> createState() => _StockEditorSheetState();
}

class _StockEditorSheetState extends State<_StockEditorSheet> {
  late int _value = widget.product.stock;
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.product.stock}',
  );
  late int _threshold = widget.product.lowStockThreshold;
  late final TextEditingController _thresholdController = TextEditingController(
    text: '${widget.product.lowStockThreshold}',
  );
  bool _saving = false;
  AppError? _error;

  @override
  void dispose() {
    _controller.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = (_value + delta).clamp(0, 1000000);
    setState(() {
      _value = next;
      _error = null;
      _controller.text = '$next';
    });
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _onChanged(String text) {
    final parsed = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _value = parsed;
      _error = null;
    });
  }

  /// El mínimo también se puede escribir a mano; los botones son un atajo.
  void _stepThreshold(int delta) {
    final next = (_threshold + delta).clamp(0, 1000000);
    setState(() {
      _threshold = next;
      _error = null;
      _thresholdController.text = '$next';
    });
    _thresholdController.selection = TextSelection.collapsed(
      offset: _thresholdController.text.length,
    );
  }

  void _onThresholdChanged(String text) {
    final parsed = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _threshold = parsed;
      _error = null;
    });
  }

  Future<void> _confirmDelete() async {
    final cubit = widget.cubit!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.rp.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Acción irreversible',
          style: context.rt.title2.copyWith(color: context.rp.warning),
        ),
        content: Text(
          '¿Eliminar producto del control de su stock?',
          style: context.rt.body.copyWith(color: context.rp.inkSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.rp.ink,
              backgroundColor: context.rp.fill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.rp.onAccent,
              backgroundColor: context.rp.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _saving = true);
      try {
        final error = await cubit.deleteProduct(widget.product.uid);
        if (!mounted) return;
        if (error != null) {
          setState(() => _saving = false);
          // Si el servidor no lo sabe, el producto sigue vivo: se avisa.
          showStockySnack(
            context,
            context.l10n.describeDetail(error),
            tone: RSnackTone.warning,
          );
        } else {
          if (StockySounds.instance.enabled) {
            await StockySounds.instance.warmUp();
            if (mounted) StockySounds.instance.play(RSound.tap);
          }
          if (mounted) Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Future<void> _restore() async {
    final cubit = widget.cubit ?? (context.read<StockyCubit>());
    final error = await cubit.restoreProduct(widget.product.uid);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      showStockySnack(
        context,
        context.l10n.describeDetail(error),
        tone: RSnackTone.warning,
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_value, _threshold);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final low = _value <= _threshold;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.productName(widget.product.name),
                          style: t.title3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.stockEditorUid(
                            widget.product.uid,
                            l10n.unit(widget.product.unit),
                          ),
                          style: t.footnote,
                        ),
                      ],
                    ),
                  ),
                  if (widget.product.active)
                    IconButton(
                      icon: Icon(CupertinoIcons.delete_solid, color: p.warning),
                      onPressed: _saving ? null : _confirmDelete,
                      tooltip: l10n.actionDelete,
                    ),
                  if (!widget.product.active)
                    IconButton(
                      icon: const Icon(
                        Icons.restore,
                        size: 22,
                        color: Colors.green,
                      ),
                      onPressed: () => _restore(),
                      tooltip: l10n.actionRestore,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StepButton(
                    icon: CupertinoIcons.minus,
                    label: l10n.actionRemoveOneUnit,
                    onTap: _saving ? null : () => _step(-1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          onChanged: _onChanged,
                          style: t.largeTitle.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        Text(
                          l10n.unit(widget.product.unit),
                          style: t.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StepButton(
                    icon: CupertinoIcons.plus,
                    label: l10n.actionAddOneUnit,
                    onTap: _saving ? null : () => _step(1),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                decoration: BoxDecoration(
                  color: p.fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.stockThresholdLabel,
                            style: t.footnote.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.stockThresholdHelp(
                              _threshold,
                              l10n.unit(widget.product.unit),
                            ),
                            style: t.caption,
                          ),
                        ],
                      ),
                    ),
                    _SmallStepButton(
                      icon: CupertinoIcons.minus,
                      label: l10n.actionRemoveOneUnit,
                      onTap: _saving || _threshold <= 0
                          ? null
                          : () => _stepThreshold(-1),
                    ),
                    SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _thresholdController,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        onChanged: _onThresholdChanged,
                        style: t.headline.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    _SmallStepButton(
                      icon: CupertinoIcons.plus,
                      label: l10n.actionAddOneUnit,
                      onTap: _saving ? null : () => _stepThreshold(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: RPill(
                  low ? l10n.stockStatusLow : l10n.stockStatusOk,
                  tone: low ? RPillTone.warning : RPillTone.neutral,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.describeDetail(_error!),
                  style: t.footnote.copyWith(color: p.warning),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: RSecondaryButton(
                      l10n.actionCancel,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RPrimaryButton(
                      l10n.actionSave,
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: p.fill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              icon,
              size: 24,
              color: onTap == null ? p.chevron : p.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Versión compacta de [_StepButton] para el mínimo de bajo stock.
class _SmallStepButton extends StatelessWidget {
  const _SmallStepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: p.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 18,
              color: onTap == null ? p.chevron : p.accent,
            ),
          ),
        ),
      ),
    );
  }
}
