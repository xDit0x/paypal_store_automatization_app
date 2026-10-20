import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

enum _Filter { all, low, transit }

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

  List<Product> _visible(RestockState state) {
    final q = _query.trim().toLowerCase();
    return state.products.where((p) {
      final matchesQuery =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.uid.toLowerCase().contains(q);
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.low => p.isLowStock,
        _Filter.transit => state.isInTransit(p),
      };
      return p.active && matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _editStock(BuildContext context, Product product) async {
    final cubit = context.read<RestockCubit>();
    final saved = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StockEditorSheet(
        product: product,
        onSave: (stock) => cubit.updateStock(product.uid, stock),
      ),
    );
    if (saved != null && context.mounted) {
      showRestockSnack(
        context,
        context.l10n.stockUpdatedMessage(product.name, saved, product.unit),
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
        final segmentStyle = TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.ink,
        );

        return [
          RLargeTitle(l10n.tabStock),
          const SizedBox(height: 16),
          CupertinoSearchTextField(
            placeholder: l10n.stockSearchPlaceholder,
            backgroundColor: p.fill,
            style: TextStyle(color: p.ink),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<_Filter>(
              groupValue: _filter,
              backgroundColor: p.fill,
              thumbColor: p.surface,
              children: {
                _Filter.all: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l10n.stockFilterAll, style: segmentStyle),
                ),
                _Filter.low: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l10n.stockFilterLow, style: segmentStyle),
                ),
                _Filter.transit: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l10n.stockFilterTransit, style: segmentStyle),
                ),
              },
              onValueChanged: (value) =>
                  setState(() => _filter = value ?? _Filter.all),
            ),
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            REmptyState(
              icon: CupertinoIcons.cube_box,
              title: state.products.isEmpty
                  ? l10n.stockEmptyTitle
                  : l10n.stockEmptyFilterTitle,
              message: state.products.isEmpty ? l10n.stockEmptyMessage : null,
            )
          else
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
          if (products.isNotEmpty) ...[
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

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.state,
    required this.onTap,
  });

  final Product product;
  final RestockState state;
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
                  Expanded(child: Text(product.name, style: t.headline)),
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
                        product.unit,
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
  const _StockEditorSheet({required this.product, required this.onSave});

  final Product product;

  /// Devuelve null si se guardó bien, o el error.
  final Future<AppError?> Function(int stock) onSave;

  @override
  State<_StockEditorSheet> createState() => _StockEditorSheetState();
}

class _StockEditorSheetState extends State<_StockEditorSheet> {
  late int _value = widget.product.stock;
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.product.stock}',
  );
  bool _saving = false;
  AppError? _error;

  @override
  void dispose() {
    _controller.dispose();
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_value);
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
    final low = _value <= widget.product.lowStockThreshold;

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
                l10n.stockEditorUid(
                  widget.product.uid,
                  widget.product.lowStockThreshold,
                  widget.product.unit,
                ),
                style: t.footnote,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StepButton(
                    icon: CupertinoIcons.minus,
                    label: l10n.actionRemoveOneUnit,
                    onTap: _saving ? null : () => _step(-1),
                  ),
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
                        Text(widget.product.unit, style: t.caption),
                      ],
                    ),
                  ),
                  _StepButton(
                    icon: CupertinoIcons.plus,
                    label: l10n.actionAddOneUnit,
                    onTap: _saving ? null : () => _step(1),
                  ),
                ],
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
