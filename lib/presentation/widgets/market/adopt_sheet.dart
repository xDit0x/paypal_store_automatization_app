import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:store_automatization_app/common/helpers/stocky_format.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/stocky_ui.dart';

/// Lo que elige el dueño antes de añadir el distribuidor.
class AdoptChoice {
  const AdoptChoice({required this.quantity, required this.placeOrder});

  final int quantity;
  final bool placeOrder;
}

Future<AdoptChoice?> showAdoptSheet(
  BuildContext context, {
  required MarketOption option,
  required int? monthlyQuantity,
}) {
  return showModalBottomSheet<AdoptChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AdoptSheet(option: option, initial: monthlyQuantity ?? option.orderQty),
  );
}

class _AdoptSheet extends StatefulWidget {
  const _AdoptSheet({required this.option, required this.initial});

  final MarketOption option;
  final int initial;

  @override
  State<_AdoptSheet> createState() => _AdoptSheetState();
}

class _AdoptSheetState extends State<_AdoptSheet> {
  late int _qty = widget.initial < 1 ? 1 : widget.initial;
  bool _order = true;

  /// La cantidad se puede escribir a mano además de usar los botones.
  late final TextEditingController _qtyController = TextEditingController(
    text: '$_qty',
  );
  final FocusNode _qtyFocus = FocusNode();

  int get _step => widget.option.packSize < 1 ? 1 : widget.option.packSize;

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  /// Cambia la cantidad desde los botones: el texto se actualiza.
  void _setQty(int value) {
    final next = value < 1 ? 1 : value;
    setState(() {
      _qty = next;
      _qtyController.text = '$next';
      _qtyController.selection = TextSelection.collapsed(
        offset: _qtyController.text.length,
      );
    });
  }

  /// Cambia la cantidad escribiendo: se acepta cualquier número entero
  /// positivo (el servidor lo ajusta a cajas completas).
  void _onQtyTyped(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) return;
    setState(() => _qty = parsed);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final option = widget.option;
    final orderQty = option.qtyFor(_qty);
    // Aproximado: el servidor recalcula el importe exacto (envío incluido).
    final estimate = option.unitLandedEur * orderQty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.paddingOf(context).bottom),
        // Con el teclado abierto la hoja puede no caber: se deja deslizar.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.marketAdoptTitle(option.productName), style: t.title3),
              const SizedBox(height: 4),
              Text(l10n.marketAdoptFrom(option.distributorName), style: t.subhead),
              const SizedBox(height: 18),
              RCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.marketAdoptQuantity,
                            style: t.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        RRoundIconButton(
                          icon: CupertinoIcons.minus,
                          label: '-',
                          size: 34,
                          onTap: _qty > 1 ? () => _setQty(_qty - _step) : null,
                        ),
                        SizedBox(
                          width: 54,
                          child: TextField(
                            controller: _qtyController,
                            focusNode: _qtyFocus,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: t.headline,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: t.headline,
                            ),
                            onChanged: _onQtyTyped,
                            onSubmitted: (_) => _qtyFocus.unfocus(),
                            onTapOutside: (_) => _qtyFocus.unfocus(),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(option.unit, style: t.headline),
                        const SizedBox(width: 4),
                        RRoundIconButton(
                          icon: CupertinoIcons.plus,
                          label: '+',
                          size: 34,
                          onTap: () => _setQty(_qty + _step),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.marketMinPack(option.minQty, option.packSize), style: t.caption),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: p.separator),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.marketAdoptOrderNow, style: t.body),
                              const SizedBox(height: 2),
                              Text(
                                l10n.marketAdoptOrderHint(l10n.euros(estimate)),
                                style: t.footnote,
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _order,
                          activeTrackColor: p.accent,
                          onChanged: (value) => setState(() => _order = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              RPrimaryButton(
                l10n.marketAdoptConfirm,
                onPressed: () => Navigator.of(context).pop(
                  AdoptChoice(quantity: _qty < 1 ? 1 : _qty, placeOrder: _order),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
