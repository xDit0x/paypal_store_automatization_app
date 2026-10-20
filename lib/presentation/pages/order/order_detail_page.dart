import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
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

  Future<void> _approve(
    BuildContext context,
    RestockState state,
    Order order,
  ) async {
    final cubit = context.read<RestockCubit>();
    final l10n = context.l10n;
    final supplier = state.supplierName(order.supplierId);
    final error = await cubit.approve(order.id);
    if (!context.mounted) return;
    if (error != null) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.orderPaymentFailed),
          content: Text(error),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionOk),
            ),
          ],
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    showRestockSnack(
      context,
      l10n.orderPaymentSentMessage(l10n.euros(order.total, state.currency), supplier),
      title: l10n.orderPaymentSent,
      tone: RSnackTone.success,
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _reject(
    BuildContext context,
    RestockState state,
    Order order,
  ) async {
    final l10n = context.l10n;
    final supplier = state.supplierName(order.supplierId);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.orderRejectQuestion),
        content: Text(l10n.orderRejectMessage(supplier)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionReject),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<RestockCubit>().reject(order.id);
    if (!context.mounted) return;
    if (error != null) {
      showRestockSnack(
        context,
        error,
        title: l10n.orderRejectFailed,
        tone: RSnackTone.warning,
      );
    } else {
      showRestockSnack(
        context,
        l10n.orderRejectMessage(supplier),
        title: l10n.orderRejected,
        tone: RSnackTone.success,
      );
    }
    if (error == null) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final state = context.watch<RestockCubit>().state;
    final l10n = context.l10n;
    final order = state.orderById(orderId);
    final media = MediaQuery.of(context);

    if (order == null) {
      return Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RBackLink(l10n.actionBack),
              ),
              Expanded(
                child: Center(
                  child: REmptyState(
                    icon: CupertinoIcons.doc_text,
                    title: l10n.orderUnavailable,
                  ),
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
    final reason = pending ? shortDecisionReason(l10n, state, order) : null;
    final (statusLabel, statusTone) = orderStatusLabel(l10n, order.status);
    final run = state.runForOrder(order);
    final busy = state.busyOrderId == order.id;
    final byAgent = order.createdByType == OrderCreatorType.agent;

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
            RBackLink(l10n.actionBack),
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
                  Text(l10n.orderTitle(supplier), style: t.title2),
                  const SizedBox(height: 4),
                  Text(
                    '${byAgent ? l10n.orderCreatedByAgent : l10n.orderCreatedByYou} · ${l10n.relativeDate(order.createdAt)}',
                    style: t.footnote,
                  ),
                  const SizedBox(height: 16),
                  RInsetGroup(
                    children: [
                      for (final item in order.items)
                        RListRow(
                          title: '${item.name}  × ${item.qty}',
                          subtitle: Text(
                            l10n.orderUnitPrice(
                              l10n.euros(item.unitPrice, c),
                              item.productUid,
                            ),
                            style: t.footnote,
                          ),
                          trailing: Text(
                            l10n.euros(item.lineTotal, c),
                            style: t.amount.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      RListRow(
                        title: l10n.orderTotal,
                        bold: true,
                        trailing: Text(
                          l10n.euros(order.total, c),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (run != null) ...[
                    const SizedBox(height: 16),
                    RCard(
                      color: p.blueSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.sparkles,
                                size: 16,
                                color: p.navy,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.orderWhatAgentDecided,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            describeAgentDecision(
                              l10n,
                              run.decision ?? 'unknown',
                            ),
                            style: t.callout,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${run.provider} · ${run.model}'
                            '${run.confidence != null ? ' · ${l10n.orderConfidence((run.confidence! * 100).round())}' : ''}',
                            style: t.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (order.paymentPayoutId != null) ...[
                    const SizedBox(height: 16),
                    RInsetGroup(
                      children: [
                        RListRow(
                          title: l10n.orderPaypalPayment,
                          subtitle: Text(
                            order.paymentPayoutId!,
                            style: t.footnote,
                          ),
                          trailing: RPill(
                            order.paymentStatus ?? l10n.orderPaymentStatusSent,
                            tone: RPillTone.info,
                          ),
                        ),
                        if (order.paymentAt != null)
                          RListRow(
                            title: l10n.orderPaymentDate,
                            trailing: Text(
                              l10n.relativeDate(order.paymentAt),
                              style: t.footnote,
                            ),
                          ),
                      ],
                    ),
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
                decision.isBlocked
                    ? l10n.orderBlockedByRules
                    : l10n.actionApproveAndPay,
                loading: busy,
                onPressed: decision.isBlocked
                    ? null
                    : () => _approve(context, state, order),
              ),
              const SizedBox(height: 10),
              RSecondaryButton(
                l10n.actionReject,
                color: p.warning,
                onPressed: busy ? null : () => _reject(context, state, order),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  decision.isBlocked
                      ? l10n.orderBlockedHint
                      : l10n.orderApproveHint(supplier),
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
    final l10n = context.l10n;
    final c = state.currency;
    final cap = state.monthlyLimit <= 0 ? 1.0 : state.monthlyLimit;
    final after = state.spentThisMonth + order.total;
    final over = after > state.monthlyLimit;

    final spentFlex = (state.spentThisMonth / cap * 1000).round().clamp(
      0,
      1000,
    );
    final orderFlex = (order.total / cap * 1000).round().clamp(
      0,
      1000 - spentFlex,
    );
    final restFlex = (1000 - spentFlex - orderFlex).clamp(0, 1000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.orderSpendAfterPayment(l10n.currentMonthName()),
                  style: t.footnote.copyWith(fontSize: 14),
                ),
              ),
              Text(
                l10n.orderSpendOf(
                  l10n.eurosShort(after.roundToDouble(), c),
                  l10n.eurosShort(state.monthlyLimit, c),
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: over ? p.warning : p.ink,
                ),
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
                  if (spentFlex > 0)
                    Expanded(
                      flex: spentFlex,
                      child: ColoredBox(color: p.navy),
                    ),
                  if (orderFlex > 0)
                    Expanded(
                      flex: orderFlex,
                      child: ColoredBox(color: p.blueLight),
                    ),
                  if (restFlex > 0)
                    Expanded(
                      flex: restFlex,
                      child: ColoredBox(color: p.separator),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: p.navy, label: l10n.orderLegendSpent),
              const SizedBox(width: 14),
              _Legend(color: p.blueLight, label: l10n.orderLegendThisOrder),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.rt.caption),
      ],
    );
  }
}
