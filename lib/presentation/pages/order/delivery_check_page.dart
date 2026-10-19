import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
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
    final state = context.watch<RestockCubit>().state;
    final order = state.orderById(widget.orderId);
    final media = MediaQuery.of(context);

    if (order == null) {
      return Scaffold(
        backgroundColor: p.background,
        body: const SafeArea(
          child: Center(child: Text('Este pedido ya no está disponible')),
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
            const RBackLink('Pedidos'),
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
                          'Entrega de ${state.supplierName(order.supplierId)}',
                          style: t.title2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ajusta lo que ha llegado. Lo que falte se puede reclamar.',
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
                        'La lectura del albarán con IA llegará pronto.',
                        title: 'Próximamente',
                      ),
                      child: SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.camera, color: p.inkSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Foto del albarán',
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
                                  ? 'Pedido ${item.qty} · faltan ${item.qty - _got(item)}'
                                  : 'Pedido ${item.qty} · completo',
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
              'Confirmar entrega',
              onPressed: () {
                HapticFeedback.mediumImpact();
                showRestockSnack(
                  context,
                  'Se ha guardado lo que llegó del pedido.',
                  title: 'Entrega registrada',
                  tone: RSnackTone.success,
                );
                Navigator.of(context).maybePop();
              },
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 10),
              RSecondaryButton(
                'Reclamar $missingUnits uds · ${euros(missingValue, c)}',
                color: p.warning,
                onPressed: () => showRestockSnack(
                  context,
                  'Avísale de las unidades que faltan.',
                  title: 'Reclamación preparada',
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
            tooltip: 'Menos',
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
            tooltip: 'Más',
            icon: Icon(CupertinoIcons.plus, size: 18, color: p.navy),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
