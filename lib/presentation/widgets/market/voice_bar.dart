import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:store_automatization_app/core/audio/stocky_sounds.dart';
import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';
import 'package:store_automatization_app/core/voice/voice_service.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/presentation/blocs/assistant/assistant_cubit.dart';
import 'package:store_automatization_app/presentation/widgets/market/voice_orb.dart';

enum VoicePhase { starting, listening, thinking, speaking, paused, noMic }

/// Conversación por voz con el asistente: escucha, piensa, habla y vuelve a
/// escuchar sola. Lo que se dice aparece en el chat como mensajes normales.
class VoiceConversation extends ChangeNotifier {
  VoiceConversation({
    required this.storeId,
    required this.assistant,
    required this.l10n,
    this.onAdopted,
  });

  final String storeId;
  final AssistantCubit assistant;
  final AppLocalizations l10n;

  /// Se eligió un distribuidor hablando ("me quedo con el primero").
  final void Function(AdoptResult adopted)? onAdopted;

  final VoiceService _voice = VoiceService.instance;
  final ValueNotifier<double> level = ValueNotifier(0);

  VoicePhase _phase = VoicePhase.starting;
  VoicePhase get phase => _phase;
  String? _error;
  String? get error => _error;

  bool _active = true;
  bool _looping = false;
  bool _disposed = false;

  String get _lang => l10n.localeName.startsWith('en') ? 'en' : 'es';

  void _set(VoicePhase phase, {String? error}) {
    if (_disposed) return;
    _phase = phase;
    _error = error;
    notifyListeners();
  }

  Future<void> start() async {
    _active = true;
    if (!await _voice.hasPermission()) {
      _set(VoicePhase.noMic, error: l10n.marketVoiceUnavailable);
      return;
    }
    unawaited(_loop());
  }

  Future<void> _loop() async {
    if (_looping) return;
    _looping = true;
    try {
      while (_active && !_disposed) {
        _set(VoicePhase.listening);
        final wav = await _voice.listen(
          onLevel: (l) {
            if (!_disposed) level.value = l;
          },
        );
        if (_disposed) break;
        level.value = 0;
        if (!_active) break;
        if (wav == null) {
          // No habló en un rato: pausa hasta que toque la barra.
          _set(VoicePhase.paused);
          break;
        }
        if (!await _ask(wav)) break;
      }
    } finally {
      _looping = false;
    }
  }

  /// Devuelve false si hay que pausar.
  Future<bool> _ask(Uint8List wav) async {
    _set(VoicePhase.thinking);
    StockySounds.instance.play(RSound.tap);
    final result = await assistant.sendVoice(storeId, wav, _lang);
    if (!_active || _disposed) return false;

    AppError? failure;
    VoiceReply? voice;
    result.fold((e) => failure = e, (v) => voice = v);
    final heard = voice;
    if (heard == null) {
      final error = failure;
      _set(VoicePhase.paused, error: error == null ? null : l10n.describeDetail(error));
      return false;
    }
    // Solo ruido: se vuelve a escuchar sin contestar.
    if (heard.transcript.isEmpty) return true;

    final adopted = heard.reply.adopted;
    if (adopted != null) {
      HapticFeedback.mediumImpact();
      onAdopted?.call(adopted);
    }
    await _say(heard.reply.text, heard.audio);
    return _active && !_disposed;
  }

  Future<void> _say(String text, Uint8List? audio) async {
    if (text.trim().isEmpty) return;
    _set(VoicePhase.speaking);
    final played = audio != null && await _voice.playMp3(audio);
    // Sin audio, o si no se pudo reproducir: voz del dispositivo.
    if (!played && _active && !_disposed) {
      await _voice.speakDevice(text, _lang);
    }
  }

  /// Respuesta rápida tocada mientras se habla (por ejemplo "Sí, hazlo").
  Future<void> reply(String text) async {
    if (_phase == VoicePhase.thinking) return;
    _active = false;
    await _voice.stopAll();
    _active = true;
    _set(VoicePhase.thinking);
    final entry = await assistant.send(storeId, text, viaVoice: true);
    if (!_active || _disposed) return;
    if (entry == null) {
      final last = assistant.state.entries.isEmpty ? null : assistant.state.entries.last;
      final error = last?.error;
      _set(VoicePhase.paused, error: error == null ? null : l10n.describeDetail(error));
      return;
    }
    final adopted = entry.adopted;
    if (adopted != null) onAdopted?.call(adopted);
    await _say(entry.text, await assistant.voiceFor(entry.text));
    if (_active && !_disposed) unawaited(_loop());
  }

  /// Toque en la barra: enviar ya, interrumpir o seguir.
  void tap() {
    HapticFeedback.selectionClick();
    switch (_phase) {
      case VoicePhase.listening:
        _voice.finishListening();
      case VoicePhase.speaking:
        _voice.stopSpeaking(); // el bucle vuelve a escuchar
      case VoicePhase.paused:
        _set(VoicePhase.listening);
        unawaited(_loop());
      case VoicePhase.noMic:
        unawaited(start());
      case VoicePhase.starting:
      case VoicePhase.thinking:
        break;
    }
  }

  /// Pausa sin cerrar (botón de pausa).
  Future<void> pause() async {
    _active = false;
    await _voice.stopAll();
    _set(VoicePhase.paused);
  }

  Future<void> stop() async {
    _active = false;
    await _voice.stopAll();
  }

  @override
  void dispose() {
    _active = false;
    _disposed = true;
    unawaited(_voice.stopAll());
    level.dispose();
    super.dispose();
  }
}

/// Barra azul compacta que sustituye a la caja de texto mientras se habla.
class VoiceBar extends StatelessWidget {
  const VoiceBar({super.key, required this.session, required this.onClose});

  final VoiceConversation session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final phase = session.phase;
        final status = switch (phase) {
          VoicePhase.starting => l10n.voiceStarting,
          VoicePhase.listening => l10n.voiceListening,
          VoicePhase.thinking => l10n.voiceThinking,
          VoicePhase.speaking => l10n.voiceSpeaking,
          VoicePhase.paused => l10n.voicePaused,
          VoicePhase.noMic => l10n.marketVoiceUnavailable,
        };
        final hint = session.error ??
            switch (phase) {
              VoicePhase.listening => l10n.voiceHintListening,
              VoicePhase.speaking => l10n.voiceHintSpeaking,
              VoicePhase.paused || VoicePhase.noMic => l10n.voiceHintPaused,
              _ => '',
            };
        final mode = switch (phase) {
          VoicePhase.listening => OrbMode.listening,
          VoicePhase.thinking => OrbMode.thinking,
          VoicePhase.speaking => OrbMode.speaking,
          _ => OrbMode.idle,
        };
        final paused = phase == VoicePhase.paused || phase == VoicePhase.noMic;

        return Material(
          color: p.blueSoft,
          shape: StadiumBorder(side: BorderSide(color: p.accent.withValues(alpha: 0.35))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: session.tap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: OverflowBox(
                      maxWidth: 60,
                      maxHeight: 60,
                      child: VoiceOrb(mode: mode, level: session.level, size: 30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.navy),
                        ),
                        if (hint.isNotEmpty)
                          Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: p.navy.withValues(alpha: 0.7)),
                          ),
                      ],
                    ),
                  ),
                  _BarButton(
                    icon: paused ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
                    label: paused ? l10n.voiceResume : l10n.voicePause,
                    onTap: paused ? session.tap : session.pause,
                  ),
                  const SizedBox(width: 4),
                  _BarButton(icon: CupertinoIcons.xmark, label: l10n.voiceClose, onTap: onClose, filled: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? p.accent : p.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 17, color: filled ? p.onAccent : p.accent),
          ),
        ),
      ),
    );
  }
}
