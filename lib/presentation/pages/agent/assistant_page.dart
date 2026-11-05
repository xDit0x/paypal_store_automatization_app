import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/helpers/stocky_format.dart';
import 'package:store_automatization_app/common/helpers/stocky_markdown.dart';
import 'package:store_automatization_app/core/audio/stocky_sounds.dart';
import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';
import 'package:store_automatization_app/core/voice/voice_service.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/presentation/blocs/assistant/assistant_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_state.dart';
import 'package:store_automatization_app/presentation/pages/shell/stocky_shell.dart';
import 'package:store_automatization_app/presentation/widgets/market/adopt_sheet.dart';
import 'package:store_automatization_app/presentation/widgets/market/market_results.dart';
import 'package:store_automatization_app/presentation/widgets/market/voice_bar.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/carousel_nav_bar.dart';
import 'package:store_automatization_app/presentation/widgets/stocky/stocky_ui.dart';

/// Pestaña Asistente: el agente de reposición y el asistente de compras
/// (estudio de mercado), por texto o por voz.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

/// Un elemento de la conversación: viene del agente (StockyCubit) o del
/// asistente de compras (AssistantCubit). Se ordenan por hora.
class _Item {
  const _Item({required this.fromUser, required this.text, required this.at, this.entry});

  final bool fromUser;
  final String text;
  final DateTime at;
  final AssistantEntry? entry;
}

class _AssistantPageState extends State<AssistantPage> {
  late final TextEditingController _input;
  final _scroll = ScrollController();

  /// Conversación por voz en curso (la barra azul sustituye a la caja de texto).
  VoiceConversation? _voiceSession;

  @override
  void initState() {
    super.initState();
    // Si el dueño dejó algo escrito y cambió de pestaña, el borrador sigue
    // en el cubit: se recupera al volver.
    _input = TextEditingController(
      text: context.read<AssistantCubit>().state.draft,
    );
  }

  @override
  void dispose() {
    _voiceSession?.removeListener(_scrollToEnd);
    _voiceSession?.dispose();
    VoiceService.instance.stopSpeaking();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

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
    if (context.read<StockyCubit>().state.agentRunning) return;
    _scrollToEnd();
    final message = await context.read<StockyCubit>().runAgent(fromChat: true);
    StockySounds.instance.play(RSound.message);
    if (mounted && context.read<AssistantCubit>().state.speakReplies) {
      _say(message);
    }
    _scrollToEnd();
  }

  void _askPending(StockyState state) {
    final l10n = context.l10n;
    final pending = state.pendingOrders;
    final answer = pending.isEmpty
        ? l10n.assistantPendingEmpty
        : l10n.assistantPendingList(
            pending.length,
            pending
                .map((o) =>
                    '**${state.supplierName(o.supplierId)}** (**${l10n.euros(o.total, state.currency)}**)')
                .join(', '),
          );
    context.read<StockyCubit>().addExchange(l10n.assistantPendingQuestion, answer);
    _scrollToEnd();
  }

  void _askSpent(StockyState state) {
    final l10n = context.l10n;
    final c = state.currency;
    final answer = l10n.assistantSpentAnswer(
      l10n.euros(state.spentThisMonth, c),
      l10n.currentMonthName(),
      l10n.eurosShort(state.monthlyLimit, c),
      l10n.euros(state.remaining, c),
    );
    context.read<StockyCubit>().addExchange(l10n.assistantSpentQuestion, answer);
    _scrollToEnd();
  }

  Future<void> _sendText(String text, {bool viaVoice = false}) async {
    final store = context.read<StockyCubit>().state.store;
    final assistant = context.read<AssistantCubit>();
    if (store == null || assistant.state.sending || text.trim().isEmpty) return;

    StockySounds.instance.play(RSound.tap);
    _scrollToEnd();
    final reply = await assistant.send(
      store.id,
      text,
      viaVoice: viaVoice,
      locale: context.l10n.localeName,
    );
    if (!mounted) return;
    // Eligió un distribuidor escribiendo ("me quedo con el primero").
    if (reply?.adopted != null) context.read<StockyCubit>().load();
    // El mensaje ya está en la conversación: el campo y el borrador se
    // vacían (el cubit ya lo ha hecho al enviar).
    if (_input.text.trim() == text.trim()) _input.clear();
    StockySounds.instance.play(RSound.message);
    if (reply != null && (viaVoice || assistant.state.speakReplies)) {
      _say(reply.text);
    }
    await _syncRules();
    _scrollToEnd();
  }

  /// El asistente puede cambiar el presupuesto desde el chat: la app
  /// recarga las reglas y avisa con un atajo a la pestaña Reglas.
  Future<void> _syncRules() async {
    final changed = await context.read<StockyCubit>().refreshRules();
    if (!changed || !mounted) return;

    final l10n = context.l10n;
    showStockySnack(
      context,
      l10n.assistantBudgetUpdated,
      title: l10n.rulesSaved,
      tone: RSnackTone.success,
      actionLabel: l10n.tabRules,
      onAction: () => ShellView.jumpToTab(3),
    );
  }

  void _send() => _sendText(_input.text);

  /// Lee un texto con la voz natural (ElevenLabs) o, si no hay, con la del
  /// dispositivo.
  Future<void> _say(String text) async {
    final audio = await context.read<AssistantCubit>().voiceFor(text);
    if (!mounted) return;
    if (audio != null) {
      await VoiceService.instance.playMp3(audio);
    } else {
      await VoiceService.instance.speakDevice(text, _lang);
    }
  }

  Future<void> _openConversation() async {
    final store = context.read<StockyCubit>().state.store;
    if (store == null || _voiceSession != null) return;
    FocusScope.of(context).unfocus();
    StockySounds.instance.play(RSound.tap);
    final stocky = context.read<StockyCubit>();
    final session = VoiceConversation(
      storeId: store.id,
      assistant: context.read<AssistantCubit>(),
      l10n: context.l10n,
      onAdopted: (_) {
        StockySounds.instance.play(RSound.success);
        stocky.load();
      },
    )..addListener(_scrollToEnd);
    setState(() => _voiceSession = session);
    await VoiceService.instance.stopSpeaking();
    await session.start();
  }

  void _closeConversation() {
    final session = _voiceSession;
    if (session == null) return;
    session.removeListener(_scrollToEnd);
    session.dispose();
    setState(() => _voiceSession = null);
  }

  Future<void> _choose(MarketResearch research, MarketOption option) async {
    final store = context.read<StockyCubit>().state.store;
    if (store == null) return;
    final choice = await showAdoptSheet(context, option: option, monthlyQuantity: research.monthlyQuantity);
    if (choice == null || !mounted) return;

    final assistant = context.read<AssistantCubit>();
    final stocky = context.read<StockyCubit>();
    final l10n = context.l10n;
    final result = await assistant.adopt(
      storeId: store.id,
      research: research,
      option: option,
      quantity: choice.quantity,
      placeOrder: choice.placeOrder,
      locale: l10n.localeName,
    );
    if (!mounted) return;

    result.fold(
      (error) => showStockySnack(context, l10n.describeDetail(error), tone: RSnackTone.warning),
      (adopted) {
        final order = adopted.order;
        final lines = [
          l10n.marketAdoptDone(adopted.productName, adopted.supplierName),
          if (order != null && order.blocked) l10n.marketAdoptBlocked(order.reason ?? ''),
          if (order != null && !order.blocked && order.id != null)
            l10n.marketAdoptOrderCreated(l10n.euros(order.total, adopted.currency)),
        ];
        final note = lines.join(' ');
        assistant.addNote(note);
        showStockySnack(
          context,
          note.replaceAll('**', ''),
          title: l10n.marketAdoptSuccessTitle,
          tone: order != null && order.blocked ? RSnackTone.warning : RSnackTone.success,
        );
        if (assistant.state.speakReplies) _say(note);
        stocky.load();
        _scrollToEnd();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final state = context.watch<StockyCubit>().state;
    final assistant = context.watch<AssistantCubit>().state;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final bottom = keyboard > 0 ? keyboard + 12 : CarouselNavBar.height + 22 + media.padding.bottom + 18;
    final busy = state.agentRunning || assistant.sending;

    final items = <_Item>[
      for (final c in state.chat) _Item(fromUser: c.fromUser, text: c.text, at: c.at),
      for (final e in assistant.entries)
        _Item(
          fromUser: e.fromUser,
          text: e.error != null ? l10n.describeDetail(e.error!) : e.text,
          at: e.at,
          entry: e,
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    // Respuestas rápidas: solo las de la última respuesta del asistente.
    final last = assistant.entries.isEmpty ? null : assistant.entries.last;
    final quickReplies = !busy && last != null && !last.fromUser ? last.quickReplies : const <String>[];
    final lastUserVoice = assistant.entries.lastWhere(
      (e) => e.fromUser,
      orElse: () => AssistantEntry(fromUser: true, text: '', at: DateTime(0)),
    ).viaVoice;

    final itemCount = 2 + items.length + (busy ? 1 : 0);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, media.padding.top + 16, 16, bottom),
      child: Column(
        children: [
          RLargeTitle(
            l10n.assistantTitle,
            subtitle: l10n.assistantSubtitle,
            trailing: RRoundIconButton(
              icon: assistant.speakReplies ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash,
              label: assistant.speakReplies ? l10n.marketSpeakOff : l10n.marketSpeakOn,
              size: 40,
              filled: assistant.speakReplies,
              onTap: () {
                StockySounds.instance.play(RSound.tap);
                if (assistant.speakReplies) VoiceService.instance.stopSpeaking();
                context.read<AssistantCubit>().toggleSpeak();
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) return _Bubble(fromUser: false, text: l10n.assistantGreeting);
                if (i == 1) return _Bubble(fromUser: false, text: l10n.marketGreeting);
                final index = i - 2;
                if (index < items.length) {
                  final item = items[index];
                  final market = item.entry?.market;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Bubble(fromUser: item.fromUser, text: item.text, time: item.at),
                      if (market != null &&
                          (market.options.isNotEmpty || market.webLeads.isNotEmpty)) ...[
                        const SizedBox(height: 10),
                        MarketResults(
                          research: market,
                          busyOfferId: assistant.adoptingOfferId,
                          onChoose: (option) => _choose(market, option),
                        ),
                      ],
                    ],
                  );
                }
                return _TypingBubble(
                  text: assistant.sending ? l10n.marketThinking : l10n.assistantTyping,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: quickReplies.isNotEmpty
                  ? [
                      for (final reply in quickReplies) ...[
                        _Chip(
                          label: reply,
                          highlighted: true,
                          onTap: () => _voiceSession != null
                              ? _voiceSession!.reply(reply)
                              : _sendText(reply, viaVoice: lastUserVoice),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ]
                  : [
                      _Chip(
                        label: l10n.marketChipNewProduct,
                        icon: CupertinoIcons.globe,
                        onTap: busy || state.store == null
                            ? null
                            : () => _sendText(l10n.marketNewProductPrompt),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: l10n.assistantChipReview,
                        icon: CupertinoIcons.sparkles,
                        onTap: busy || state.store == null ? null : _runAgent,
                      ),
                      const SizedBox(width: 8),
                      _Chip(label: l10n.assistantChipPending, onTap: () => _askPending(state)),
                      const SizedBox(width: 8),
                      _Chip(label: l10n.assistantChipSpent, onTap: () => _askSpent(state)),
                    ],
            ),
          ),
          const SizedBox(height: 12),
          if (_voiceSession != null)
            VoiceBar(session: _voiceSession!, onClose: _closeConversation)
          else
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
                    onChanged: (value) =>
                        context.read<AssistantCubit>().setDraft(value),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    style: t.body,
                    decoration: stockyPlainInput(
                      context,
                      l10n.assistantInputHint,
                    ),
                  ),
                ),
                RRoundIconButton(
                  icon: CupertinoIcons.waveform,
                  label: l10n.voiceTitle,
                  size: 40,
                  onTap: busy ? null : _openConversation,
                ),
                const SizedBox(width: 6),
                RRoundIconButton(
                  icon: CupertinoIcons.arrow_up,
                  label: l10n.assistantSend,
                  size: 40,
                  filled: true,
                  onTap: busy ? null : _send,
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
          child: Text.rich(
            TextSpan(
              children: buildInlineMarkdown(
                text,
                TextStyle(
                  fontSize: 16,
                  color: fromUser ? p.onAccent : p.ink,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
        if (time != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Text(
              context.l10n.relativeDate(time),
              style: t.caption,
            ),
          ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.text});

  final String text;

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
            Text(text, style: TextStyle(fontSize: 15, color: p.inkSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.icon, this.highlighted = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Respuesta rápida que propone el asistente.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: highlighted ? p.blueSoft : p.surface,
        shape: StadiumBorder(side: BorderSide(color: highlighted ? p.accent : p.border)),
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
