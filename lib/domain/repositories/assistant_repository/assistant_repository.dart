import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';

/// Conversación con el asistente de compras y alta de distribuidores.
abstract class AssistantRepository {
  Future<Either<AppError, AssistantReply>> send({
    required String storeId,
    required List<AssistantTurn> history,
    LastMarket? lastMarket,
  });

  /// Modo conversación: manda el audio (WAV) y recibe la respuesta con voz.
  Future<Either<AppError, VoiceReply>> voice({
    required String storeId,
    required List<AssistantTurn> history,
    required Uint8List wav,
    required String languageCode,
    LastMarket? lastMarket,
  });

  /// MP3 con la voz natural para un texto, o null si no hay (ElevenLabs).
  Future<Uint8List?> speak(String text);

  Future<Either<AppError, AdoptResult>> adopt({
    required String storeId,
    required String offerId,
    String? searchId,
    int? quantity,
    required bool placeOrder,
  });
}
