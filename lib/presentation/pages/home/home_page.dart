import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/pages/order/order_detail_page.dart';
import 'package:store_automatization_app/presentation/widgets/restock/budget_ring.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Pestaña Inicio: presupuesto, agente, pedidos por aprobar y stock bajo.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RTabPage(
      builder: (context, state) {
        final t = context.rt;
        final pending = state.pendingOrders;
        final low = state.lowStock.take(4).toList();

        return [
          RLargeTitle(
            'Hoy',
            overline:
                '${shortDate(DateTime.now())} · ${state.store?.name ?? ''}',
            trailing: _AgentBadge(running: state.agentRunning),
          ),
          const SizedBox(height: 22),
          _BudgetCard(state: state),
          const SizedBox(height: 14),
          _AgentCard(running: state.agentRunning),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 22),
            const RSectionTitle('Para aprobar'),
            for (final order in pending) ...[
              _ApprovalTile(order: order, state: state),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 14),
          const RSectionTitle('Se agota pronto'),
          if (low.isEmpty)
            RInsetGroup(
              children: [
                RListRow(
                  title: 'Todo en orden',
                  subtitle: Text(
                    'Ningún producto está por debajo del mínimo',
                    style: t.footnote,
                  ),
                  trailing: Icon(
                    CupertinoIcons.checkmark_seal,
                    color: context.rp.accent,
                  ),
                ),
              ],
            )
          else
            RInsetGroup(
              children: [
                for (final p in low) _LowStockRow(product: p, state: state),
              ],
            ),
        ];
      },
    );
  }
}

class _AgentBadge extends StatelessWidget {
  const _AgentBadge({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.blueSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (running)
              const CupertinoActivityIndicator(radius: 6)
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              running ? 'Trabajando…' : 'Agente activo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.state});

  final RestockState state;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final c = state.currency;
    return RCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          BudgetRing(progress: state.budgetProgress),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presupuesto de ${currentMonthName()}', style: t.footnote),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text:
                          '${eurosShort(state.spentThisMonth.roundToDouble(), c)} ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: p.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      children: [
                        TextSpan(
                          text:
                              '/ ${eurosShort(state.monthlyLimit.roundToDouble(), c)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: p.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quedan ${eurosShort(state.remaining, c)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.running});

  final bool running;

  Future<void> _run(BuildContext context) async {
    final cubit = context.read<RestockCubit>();
    final message = await cubit.runAgent();
    if (!context.mounted) return;
    final lower = message.toLowerCase();
    final failed =
        lower.contains('fall') ||
        lower.contains('no se pudo') ||
        lower.contains('error');
    showRestockSnack(
      context,
      message,
      title: failed ? 'Algo salió mal' : 'Revisión del stock',
      tone: failed ? RSnackTone.warning : RSnackTone.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    return RCard(
      color: p.blueSoft,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.sparkles, size: 18, color: p.navy),
              const SizedBox(width: 6),
              Text(
                'Agente de reposición',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Revisa tu stock, prepara pedidos y págalos con PayPal dentro de tus reglas.',
            style: t.callout,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: running ? null : () => _run(context),
              icon: running
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.onAccent,
                      ),
                    )
                  : const Icon(CupertinoIcons.arrow_clockwise, size: 18),
              label: Text(running ? 'Revisando…' : 'Revisar stock ahora'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: p.accent,
                foregroundColor: p.onAccent,
                disabledBackgroundColor: p.accent.withValues(alpha: 0.5),
                disabledForegroundColor: p.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({required this.order, required this.state});

  final Order order;
  final RestockState state;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            pushRestockPage<void>(context, OrderDetailPage(orderId: order.id)),
        child: RCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 20,
                  color: p.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.supplierName(order.supplierId),
                      style: t.headline,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortDecisionReason(state, order) ??
                          'Necesita tu aprobación',
                      style: TextStyle(fontSize: 13, color: p.warning),
                    ),
                  ],
                ),
              ),
              Text(
                eurosShort(order.total, state.currency),
                style: t.amount.copyWith(fontSize: 17),
              ),
              const SizedBox(width: 8),
              const RChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product, required this.state});

  final Product product;
  final RestockState state;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    final Widget pill;
    if (state.isInTransit(product)) {
      pill = const RPill('En camino', tone: RPillTone.transit);
    } else if (product.stock <= 0) {
      pill = const RPill('Agotado', tone: RPillTone.warning);
    } else {
      pill = const RPill('Bajo mínimo', tone: RPillTone.warning);
    }
    return RListRow(
      title: product.name,
      subtitle: Text(
        '${product.stock} ${product.unit} · mínimo ${product.lowStockThreshold}',
        style: t.footnote,
      ),
      trailing: pill,
    );
  }
}
