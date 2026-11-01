import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/domain/repositories/assistant_repository/assistant_repository.dart';

/// Mensaje de la conversación con el asistente de compras.
class AssistantEntry {
  const AssistantEntry({
    required this.fromUser,
    required this.text,
    required this.at,
    this.quickReplies = const [],
    this.market,
    this.error,
    this.viaVoice = false,
  });

  final bool fromUser;
  final String text;
  final DateTime at;
  final List<String> quickReplies;
  final MarketResearch? market;

  /// Si no es null, el texto se resuelve en la pantalla con l10n.
  final AppError? error;

  /// El dueño lo dijo por voz: la respuesta se lee en voz alta.
  final bool viaVoice;
}

class AssistantState {
  const AssistantState({
    this.entries = const [],
    this.sending = false,
    this.adoptingOfferId,
    this.speakReplies = false,
  });

  final List<AssistantEntry> entries;
  final bool sending;
  final String? adoptingOfferId;

  /// Leer siempre las respuestas en voz alta (aunque se escriba).
  final bool speakReplies;

  AssistantState copyWith({
    List<AssistantEntry>? entries,
    bool? sending,
    String? adoptingOfferId,
    bool clearAdopting = false,
    bool? speakReplies,
  }) =>
      AssistantState(
        entries: entries ?? this.entries,
        sending: sending ?? this.sending,
        adoptingOfferId: clearAdopting ? null : adoptingOfferId ?? this.adoptingOfferId,
        speakReplies: speakReplies ?? this.speakReplies,
      );
}

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({required AssistantRepository repository})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(const AssistantState());

  final AssistantRepository _repository;

  /// Turnos que se mandan al servidor (sin errores, los últimos 20).
  List<AssistantTurn> get _history => state.entries
      .where((e) => e.error == null && e.text.trim().isNotEmpty)
      .map((e) => AssistantTurn(fromUser: e.fromUser, text: e.text))
      .toList()
      .reversed
      .take(20)
      .toList()
      .reversed
      .toList();

  /// Envía un mensaje. Devuelve la respuesta (o null si falló) para que la
  /// pantalla decida si la lee en voz alta.
  Future<AssistantEntry?> send(String storeId, String text, {bool viaVoice = false}) async {
    final clean = text.trim();
    if (clean.isEmpty || state.sending) return null;

    emit(state.copyWith(
      sending: true,
      entries: [
        ...state.entries,
        AssistantEntry(fromUser: true, text: clean, at: DateTime.now(), viaVoice: viaVoice),
      ],
    ));

    final result = await _repository.send(storeId: storeId, history: _history);
    final entry = result.fold(
      (error) => AssistantEntry(fromUser: false, text: '', at: DateTime.now(), error: error),
      (reply) => AssistantEntry(
        fromUser: false,
        text: reply.text,
        at: DateTime.now(),
        quickReplies: reply.quickReplies,
        market: reply.market,
        viaVoice: viaVoice,
      ),
    );
    if (isClosed) return null;
    emit(state.copyWith(sending: false, entries: [...state.entries, entry]));
    return entry.error == null ? entry : null;
  }

  /// Añade una respuesta local (resumen tras añadir un distribuidor).
  void addNote(String text) {
    emit(state.copyWith(entries: [
      ...state.entries,
      AssistantEntry(fromUser: false, text: text, at: DateTime.now()),
    ]));
  }

  void toggleSpeak() => emit(state.copyWith(speakReplies: !state.speakReplies));

  Future<Either<AppError, AdoptResult>> adopt({
    required String storeId,
    required MarketResearch research,
    required MarketOption option,
    required int? quantity,
    required bool placeOrder,
  }) async {
    emit(state.copyWith(adoptingOfferId: option.offerId));
    final result = await _repository.adopt(
      storeId: storeId,
      offerId: option.offerId,
      searchId: research.searchId,
      quantity: quantity,
      placeOrder: placeOrder,
    );
    if (!isClosed) emit(state.copyWith(clearAdopting: true));
    return result;
  }
}
