import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Texto y tono de cada estado de pedido.
(String, RPillTone) orderStatusLabel(OrderStatus status) => switch (status) {
      OrderStatus.draft => ('Borrador', RPillTone.neutral),
      OrderStatus.pendingApproval => ('Por aprobar', RPillTone.warning),
      OrderStatus.approved => ('Aprobado', RPillTone.info),
      OrderStatus.paying => ('Pagando…', RPillTone.info),
      OrderStatus.paid => ('Pagado con PayPal', RPillTone.info),
      OrderStatus.invoiced => ('Facturado', RPillTone.info),
      OrderStatus.completed => ('Completado', RPillTone.neutral),
      OrderStatus.rejected => ('Rechazado', RPillTone.neutral),
      OrderStatus.paymentFailed => ('Pago fallido', RPillTone.warning),
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
String? shortDecisionReason(RestockState state, Order order) {
  final decision = state.evaluate(order);
  final c = state.currency;
  if (decision.isBlocked) {
    if (order.total > state.rules.maxPerOrder) {
      return 'Supera el máximo de ${eurosShort(state.rules.maxPerOrder, c)} por pedido';
    }
    if (state.spentThisMonth + order.total > state.rules.monthlyLimit) {
      return 'Supera tu tope de ${eurosShort(state.rules.monthlyLimit, c)} al mes';
    }
    return decision.reason;
  }
  if (decision.needsApproval) {
    return 'Supera ${eurosShort(state.rules.requireApprovalAbove, c)} sin aprobación';
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
          title: 'No se pudieron cargar tus datos',
          message: state.error,
          action: SizedBox(
            width: 200,
            child: RPrimaryButton('Reintentar', onPressed: () => context.read<RestockCubit>().load()),
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
            _ErrorBanner(message: state.error!),
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
