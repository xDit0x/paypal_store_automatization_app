import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Texto y tono de cada estado de pedido.
(String, RPillTone) orderStatusLabel(AppLocalizations l10n, OrderStatus status) =>
    switch (status) {
      OrderStatus.draft => (l10n.statusDraft, RPillTone.neutral),
      OrderStatus.pendingApproval => (l10n.statusPendingApproval, RPillTone.warning),
      OrderStatus.approved => (l10n.statusApproved, RPillTone.info),
      OrderStatus.paying => (l10n.statusPaying, RPillTone.info),
      OrderStatus.paid => (l10n.statusPaid, RPillTone.info),
      OrderStatus.invoiced => (l10n.statusInvoiced, RPillTone.info),
      OrderStatus.completed => (l10n.statusCompleted, RPillTone.neutral),
      OrderStatus.rejected => (l10n.statusRejected, RPillTone.neutral),
      OrderStatus.paymentFailed => (l10n.statusPaymentFailed, RPillTone.warning),
    };

Color pillToneColor(BuildContext context, RPillTone tone) {
  final p = context.rp;
  return switch (tone) {
    RPillTone.warning => p.warning,
    RPillTone.transit => p.transit,
    RPillTone.info => p.accent,
    RPillTone.neutral => p.inkSecondary,
  };
}

/// Motivo corto por el que un pedido no se paga solo.
String? shortDecisionReason(
  AppLocalizations l10n,
  RestockState state,
  Order order,
) {
  final decision = state.evaluate(order);
  final c = state.currency;
  if (decision.isBlocked) {
    if (order.total > state.rules.maxPerOrder) {
      return l10n.reasonOverMaxPerOrder(l10n.eurosShort(state.rules.maxPerOrder, c));
    }
    if (state.spentThisMonth + order.total > state.rules.monthlyLimit) {
      return l10n.reasonOverMonthlyLimit(l10n.eurosShort(state.rules.monthlyLimit, c));
    }
    return switch (decision.reason) {
      SpendingReason.noAmount => l10n.reasonNoAmount,
      SpendingReason.supplierNotAllowed => l10n.reasonSupplierNotAllowed,
      _ => null,
    };
  }
  if (decision.needsApproval) {
    if (state.rules.requireApprovalAbove <= 0) {
      return l10n.reasonAnyOrderApproval;
    }
    return l10n.reasonOverApprovalThreshold(
      l10n.eurosShort(state.rules.requireApprovalAbove, c),
    );
  }
  return null;
}

/// Abre una pantalla nueva conservando el RestockCubit.
Future<T?> pushRestockPage<T>(BuildContext context, Widget page) {
  final cubit = context.read<RestockCubit>();
  return Navigator.of(context).push<T>(
    CupertinoPageRoute<T>(
      builder: (_) => BlocProvider<RestockCubit>.value(value: cubit, child: page),
    ),
  );
}

/// Espacio inferior para que el contenido no quede bajo la barra flotante.
double navBarClearance(BuildContext context) =>
    CarouselNavBar.height + 22 + MediaQuery.paddingOf(context).bottom + 36;

/// Esqueleto común de cada pestaña: carga, error y "deslizar para refrescar".
class RTabPage extends StatelessWidget {
  const RTabPage({super.key, required this.builder});

  final List<Widget> Function(BuildContext context, RestockState state) builder;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RestockCubit>().state;
    final top = MediaQuery.paddingOf(context).top;

    if (state.isLoading && state.store == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (state.status == RestockStatus.failure && state.store == null) {
      return Center(
        child: REmptyState(
          icon: CupertinoIcons.wifi_exclamationmark,
          title: context.l10n.errorLoadData,
          message: state.error == null
              ? null
              : context.l10n.describe(state.error!),
          action: SizedBox(
            width: 200,
            child: RPrimaryButton(
              context.l10n.actionRetry,
              onPressed: () => context.read<RestockCubit>().load(),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator.adaptive(
      color: context.rp.accent,
      edgeOffset: top,
      onRefresh: () => context.read<RestockCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, top + 16, 16, navBarClearance(context)),
        children: [
          if (state.error != null) ...[
            _ErrorBanner(message: context.l10n.describe(state.error!)),
            const SizedBox(height: 16),
          ],
          ...builder(context, state),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return RCard(
      color: p.warningSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 18, color: p.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: p.warning))),
        ],
      ),
    );
  }
}
