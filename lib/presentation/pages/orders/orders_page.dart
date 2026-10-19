import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/pages/order/delivery_check_page.dart';
import 'package:store_automatization_app/presentation/pages/order/order_detail_page.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Pestaña Pedidos: gasto del mes, comprobar entrega e historial.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RTabPage(
      builder: (context, state) {
        final delivery = state.latestDelivery;
        return [
          const RLargeTitle('Pedidos'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Gastado en ${currentMonthName()}',
                  value: eurosShort(state.spentThisMonth.roundToDouble(), state.currency),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Creados por el agente',
                  value: '${state.agentCreatedCount} de ${state.orders.length}',
                ),
              ),
            ],
          ),
          if (delivery != null) ...[
            const SizedBox(height: 16),
            _DeliveryBanner(
              supplier: state.supplierName(delivery.supplierId),
              onTap: () => pushRestockPage<void>(context, DeliveryCheckPage(orderId: delivery.id)),
            ),
          ],
          const SizedBox(height: 22),
          const RSectionTitle('Historial'),
          if (state.orders.isEmpty)
            const REmptyState(
              icon: CupertinoIcons.doc_text,
              title: 'Todavía no hay pedidos',
              message: 'Pulsa «Revisar stock ahora» en Inicio para que el agente prepare el primero.',
            )
          else
            RInsetGroup(children: [for (final o in state.orders) _OrderRow(order: o, state: state)]),
        ];
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return RCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.rt.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: p.ink)),
        ],
      ),
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner({required this.supplier, required this.onTap});

  final String supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Material(
      color: p.banner,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.onBanner.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(CupertinoIcons.camera, color: p.onBanner, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Ha llegado el pedido?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.onBanner)),
                    const SizedBox(height: 2),
                    Text('Comprueba la entrega de $supplier',
                        style: TextStyle(fontSize: 13, color: p.onBannerSecondary)),
                  ],
                ),
              ),
              RChevron(color: p.onBannerSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.state});

  final Order order;
  final RestockState state;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    final (label, tone) = orderStatusLabel(order.status);
    final who = order.createdByType == OrderCreatorType.agent ? 'agente' : 'tú';

    return RListRow(
      title: state.supplierName(order.supplierId),
      bold: true,
      subtitle: Text.rich(
        TextSpan(
          style: t.footnote,
          children: [
            TextSpan(
              text: label,
              style: TextStyle(fontWeight: FontWeight.w600, color: pillToneColor(context, tone)),
            ),
            TextSpan(text: ' · ${relativeDate(order.createdAt)} · $who'),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(euros(order.total, state.currency), style: t.amount),
          const SizedBox(width: 8),
          const RChevron(),
        ],
      ),
      onTap: () => pushRestockPage<void>(context, OrderDetailPage(orderId: order.id)),
    );
  }
}
