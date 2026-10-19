import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Pestaña Asistente: conversación con el agente de reposición.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _runAgent() async {
    _scrollToEnd();
    await context.read<RestockCubit>().runAgent(fromChat: true);
    _scrollToEnd();
  }

  void _askPending(RestockState state) {
    final pending = state.pendingOrders;
    final answer = pending.isEmpty
        ? 'No tienes pedidos esperando tu aprobación.'
        : 'Tienes ${pending.length} por aprobar: '
            '${pending.map((o) => '${state.supplierName(o.supplierId)} (${euros(o.total, state.currency)})').join(', ')}. '
            'Los encuentras en Inicio.';
    context.read<RestockCubit>().addExchange('¿Qué tengo por aprobar?', answer);
    _scrollToEnd();
  }

  void _askSpent(RestockState state) {
    final c = state.currency;
    final answer = 'Llevas ${euros(state.spentThisMonth, c)} gastados en ${currentMonthName()} '
        'de un tope de ${eurosShort(state.monthlyLimit, c)}. Te quedan ${euros(state.remaining, c)}.';
    context.read<RestockCubit>().addExchange('¿Cuánto llevo gastado?', answer);
    _scrollToEnd();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    context.read<RestockCubit>().ask(text);
    _input.clear();
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final state = context.watch<RestockCubit>().state;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final bottom = keyboard > 0 ? keyboard + 12 : CarouselNavBar.height + 22 + media.padding.bottom + 18;

    final chat = state.chat;
    final itemCount = 1 + chat.length + (state.agentRunning ? 1 : 0);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, media.padding.top + 16, 16, bottom),
      child: Column(
        children: [
          const RLargeTitle('Asistente', subtitle: 'Tu agente de reposición'),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const _Bubble(
                    fromUser: false,
                    text: 'Hola. Reviso tu stock, preparo pedidos a tus proveedores y los pago con '
                        'PayPal, siempre dentro de tus reglas de gasto.',
                  );
                }
                if (i <= chat.length) {
                  final entry = chat[i - 1];
                  return _Bubble(fromUser: entry.fromUser, text: entry.text, time: entry.at);
                }
                return const _TypingBubble();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: 'Revisa el stock ahora',
                  icon: CupertinoIcons.sparkles,
                  onTap: state.agentRunning || state.store == null ? null : _runAgent,
                ),
                const SizedBox(width: 8),
                _Chip(label: '¿Qué tengo por aprobar?', onTap: () => _askPending(state)),
                const SizedBox(width: 8),
                _Chip(label: '¿Cuánto llevo gastado?', onTap: () => _askSpent(state)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    style: t.body,
                    decoration: restockPlainInput(context, 'Pregunta lo que quieras'),
                  ),
                ),
                RRoundIconButton(
                  icon: CupertinoIcons.arrow_up,
                  label: 'Enviar',
                  size: 40,
                  filled: true,
                  onTap: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromUser, required this.text, this.time});

  final bool fromUser;
  final String text;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final maxWidth = MediaQuery.sizeOf(context).width * (fromUser ? 0.78 : 0.86);
    const big = Radius.circular(20);
    const small = Radius.circular(6);

    return Column(
      crossAxisAlignment: fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fromUser ? p.accent : p.fill,
            borderRadius: BorderRadius.only(
              topLeft: big,
              topRight: big,
              bottomLeft: fromUser ? big : small,
              bottomRight: fromUser ? small : big,
            ),
          ),
          child: Text(text, style: TextStyle(fontSize: 16, color: fromUser ? p.onAccent : p.ink, height: 1.35)),
        ),
        if (time != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Text(relativeDate(time), style: t.caption),
          ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: p.fill, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 8),
            const SizedBox(width: 8),
            Text('Revisando tu stock…', style: TextStyle(fontSize: 15, color: p.inkSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: p.surface,
        shape: StadiumBorder(side: BorderSide(color: p.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 15, color: p.accent), const SizedBox(width: 6)],
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.navy)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
