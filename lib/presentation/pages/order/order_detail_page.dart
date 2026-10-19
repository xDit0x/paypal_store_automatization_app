import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Detalle de un pedido. Si está pendiente, permite aprobarlo y pagarlo
/// con PayPal o rechazarlo.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  Future<void> _approve(BuildContext context, RestockState state, Order order) async {
    final cubit = context.read<RestockCubit>();
    final supplier = state.supplierName(order.supplierId);
    final error = await cubit.approve(order.id);
    if (!context.mounted) return;
    if (error != null) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('No se pudo pagar'),
          content: Text(error),
          actions: [
            CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('Vale')),
          ],
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    showRestockSnack(context, 'Pago de ${euros(order.total, state.currency)} enviado a $supplier con PayPal');
    Navigator.of(context).maybePop();
  }

  Future<void> _reject(BuildContext context, RestockState state, Order order) async {
    final supplier = state.supplierName(order.supplierId);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('¿Rechazar el pedido?'),
        content: Text('El agente no pagará a $supplier.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<RestockCubit>().reject(order.id);
    if (!context.mounted) return;
    showRestockSnack(context, error ?? 'Pedido rechazado');
    if (error == null) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final state = context.watch<RestockCubit>().state;
    final order = state.orderById(orderId);
    final media = MediaQuery.of(context);

    if (order == null) {
      return Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: RBackLink('Atrás')),
              Expanded(
                child: Center(
                  child: REmptyState(icon: CupertinoIcons.doc_text, title: 'Este pedido ya no está disponible'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final c = state.currency;
    final supplier = state.supplierName(order.supplierId);
    final pending = order.canBeApproved;
    final decision = state.evaluate(order);
    final reason = pending ? shortDecisionReason(state, order) : null;
    final (statusLabel, statusTone) = orderStatusLabel(order.status);
    final run = state.runForOrder(order);
    final busy = state.busyOrderId == order.id;
    final byAgent = order.createdByType == OrderCreatorType.agent;

    return Scaffold(
      backgroundColor: p.background,
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, media.padding.top + 4, 16, media.padding.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RBackLink('Atrás'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: reason != null
                        ? RPill(reason, tone: RPillTone.warning)
                        : RPill(statusLabel, tone: statusTone),
                  ),
                  const SizedBox(height: 8),
                  Text('Pedido a $supplier', style: t.title2),
                  const SizedBox(height: 4),
                  Text(
                    '${byAgent ? 'Lo preparó el agente' : 'Lo creaste tú'} · ${relativeDate(order.createdAt)}',
                    style: t.footnote,
                  ),
                  const SizedBox(height: 16),
                  RInsetGroup(children: [
                    for (final item in order.items)
                      RListRow(
                        title: '${item.name}  × ${item.qty}',
                        subtitle: Text('${euros(item.unitPrice, c)} / ud · ${item.productUid}', style: t.footnote),
                        trailing: Text(euros(item.lineTotal, c), style: t.amount.copyWith(fontWeight: FontWeight.w400)),
                      ),
                    RListRow(
                      title: 'Total',
                      bold: true,
                      trailing: Text(
                        euros(order.total, c),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: p.ink),
                      ),
                    ),
                  ]),
                  if (run != null) ...[
                    const SizedBox(height: 16),
                    RCard(
                      color: p.blueSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.sparkles, size: 16, color: p.navy),
                              const SizedBox(width: 6),
                              Text('Qué decidió el agente',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.navy)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(RestockCubit.describeDecision(run.decision ?? 'unknown'), style: t.callout),
                          const SizedBox(height: 6),
                          Text(
                            '${run.provider} · ${run.model}'
                            '${run.confidence != null ? ' · confianza ${(run.confidence! * 100).round()} %' : ''}',
                            style: t.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (order.paymentPayoutId != null) ...[
                    const SizedBox(height: 16),
                    RInsetGroup(children: [
                      RListRow(
                        title: 'Pago PayPal',
                        subtitle: Text(order.paymentPayoutId!, style: t.footnote),
                        trailing: RPill(order.paymentStatus ?? 'enviado', tone: RPillTone.info),
                      ),
                      if (order.paymentAt != null)
                        RListRow(title: 'Fecha de pago', trailing: Text(relativeDate(order.paymentAt), style: t.footnote)),
                    ]),
                  ],
                  if (pending) ...[
                    const SizedBox(height: 16),
                    _BudgetImpact(state: state, order: order),
                  ],
                ],
              ),
            ),
            if (pending) ...[
              const SizedBox(height: 12),
              RPrimaryButton(
                decision.isBlocked ? 'Bloqueado por tus reglas' : 'Aprobar y pagar con PayPal',
                loading: busy,
                onPressed: decision.isBlocked ? null : () => _approve(context, state, order),
              ),
              const SizedBox(height: 10),
              RSecondaryButton('Rechazar', color: p.warning, onPressed: busy ? null : () => _reject(context, state, order)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  decision.isBlocked
                      ? 'Cambia tus reglas en la pestaña Reglas si quieres permitirlo.'
                      : 'Al aprobar, el servidor paga a $supplier y genera la factura.',
                  style: t.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetImpact extends StatelessWidget {
  const _BudgetImpact({required this.state, required this.order});

  final RestockState state;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final c = state.currency;
    final cap = state.monthlyLimit <= 0 ? 1.0 : state.monthlyLimit;
    final after = state.spentThisMonth + order.total;
    final over = after > state.monthlyLimit;

    final spentFlex = (state.spentThisMonth / cap * 1000).round().clamp(0, 1000);
    final orderFlex = (order.total / cap * 1000).round().clamp(0, 1000 - spentFlex);
    final restFlex = (1000 - spentFlex - orderFlex).clamp(0, 1000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Gasto de ${currentMonthName()} tras el pago', style: t.footnote.copyWith(fontSize: 14))),
              Text(
                '${eurosShort(after.roundToDouble(), c)} de ${eurosShort(state.monthlyLimit, c)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: over ? p.warning : p.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (spentFlex > 0) Expanded(flex: spentFlex, child: ColoredBox(color: p.navy)),
                  if (orderFlex > 0) Expanded(flex: orderFlex, child: ColoredBox(color: p.blueLight)),
                  if (restFlex > 0) Expanded(flex: restFlex, child: ColoredBox(color: p.separator)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: p.navy, label: 'Ya gastado'),
              const SizedBox(width: 14),
              _Legend(color: p.blueLight, label: 'Este pedido'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: context.rt.caption),
      ],
    );
  }
}
