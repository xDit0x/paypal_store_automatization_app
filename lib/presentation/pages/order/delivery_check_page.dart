import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Comprobar una entrega: lo pedido frente a lo que llegó.
///
/// TODO(backend): leer el albarán con un modelo con visión y guardar la
/// recepción en el servidor. De momento las cantidades se ajustan a mano.
class DeliveryCheckPage extends StatefulWidget {
  const DeliveryCheckPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryCheckPage> createState() => _DeliveryCheckPageState();
}

class _DeliveryCheckPageState extends State<DeliveryCheckPage> {
  final Map<String, int> _received = {};

  int _got(OrderItem item) => _received[item.productUid] ?? item.qty;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final state = context.watch<RestockCubit>().state;
    final order = state.orderById(widget.orderId);
    final media = MediaQuery.of(context);

    if (order == null) {
      return Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Center(child: Text(l10n.orderUnavailable)),
        ),
      );
    }

    final c = state.currency;
    final missing = order.items.where((i) => _got(i) < i.qty).toList();
    final missingUnits = missing.fold<int>(0, (s, i) => s + (i.qty - _got(i)));
    final missingValue = missing.fold<double>(
      0,
      (s, i) => s + (i.qty - _got(i)) * i.unitPrice,
    );

    return Scaffold(
      backgroundColor: p.background,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          media.padding.top + 4,
          16,
          media.padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RBackLink(l10n.ordersTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.deliveryTitle(state.supplierName(order.supplierId)),
                          style: t.title2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.deliverySubtitle,
                          style: t.subhead,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: p.fill,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => showRestockSnack(
                        context,
                        l10n.deliveryComingSoonMessage,
                        title: l10n.deliveryComingSoon,
                      ),
                      child: SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.camera, color: p.inkSecondary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deliveryPhoto,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: p.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RInsetGroup(
                    children: [
                      for (final item in order.items)
                        Container(
                          color: _got(item) < item.qty ? p.warningSoft : null,
                          child: RListRow(
                            title: item.name,
                            subtitle: Text(
                              _got(item) < item.qty
                                  ? l10n.deliveryOrderedMissing(
                                      item.qty,
                                      item.qty - _got(item),
                                    )
                                  : l10n.deliveryOrderedComplete(item.qty),
                              style: TextStyle(
                                fontSize: 13,
                                color: _got(item) < item.qty
                                    ? p.warning
                                    : p.inkSecondary,
                              ),
                            ),
                            trailing: _Stepper(
                              value: _got(item),
                              max: item.qty,
                              onChanged: (v) => setState(
                                () => _received[item.productUid] = v,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RPrimaryButton(
              l10n.actionConfirmDelivery,
              onPressed: () {
                HapticFeedback.mediumImpact();
                showRestockSnack(
                  context,
                  l10n.deliveryRegisteredMessage,
                  title: l10n.deliveryRegistered,
                  tone: RSnackTone.success,
                );
                Navigator.of(context).maybePop();
              },
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 10),
              RSecondaryButton(
                l10n.deliveryClaim(
                  missingUnits,
                  l10n.euros(missingValue, c),
                ),
                color: p.warning,
                onPressed: () => showRestockSnack(
                  context,
                  l10n.deliveryClaimMessage,
                  title: l10n.deliveryClaimReady,
                  tone: RSnackTone.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Container(
      decoration: BoxDecoration(
        color: p.fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.semanticsLess,
            icon: Icon(CupertinoIcons.minus, size: 18, color: p.navy),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: context.rt.headline,
            ),
          ),
          IconButton(
            tooltip: context.l10n.semanticsMore,
            icon: Icon(CupertinoIcons.plus, size: 18, color: p.navy),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
