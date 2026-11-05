import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:store_automatization_app/data/models/market_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/domain/repositories/assistant_repository/assistant_repository.dart';

/// Habla con el servidor (POST /assistant/message y /assistant/adopt).
class ApiAssistantRepository implements AssistantRepository {
  ApiAssistantRepository(this._dio);

  final Dio _dio;

  // La IA, la búsqueda web y el pago con PayPal pueden tardar.
  static final _slow = Options(receiveTimeout: const Duration(seconds: 75));

  AppError _error(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) return const AppError(AppErrorCode.sessionExpired);
      return logError(AppErrorCode.agentUnreachable, error, detail: serverMessage(error));
    }
    return logError(AppErrorCode.agentFailed, error);
  }

  @override
  Future<Either<AppError, AssistantReply>> send({
    required String storeId,
    required List<AssistantTurn> history,
    LastMarket? lastMarket,
    String? locale,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/assistant/message',
        data: {
          'store_id': storeId,
          'locale': locale,
          'messages': _turns(history),
          if (lastMarket != null) 'last_market': lastMarket.toJson(),
        },
        options: _slow,
      );
      return Right(MarketModel.reply(response.data ?? const {}));
    } catch (error) {
      return Left(_error(error));
    }
  }

  static List<Map<String, String>> _turns(List<AssistantTurn> history) => [
        for (final turn in history)
          {'role': turn.fromUser ? 'user' : 'assistant', 'content': turn.text},
      ];

  @override
  Future<Either<AppError, VoiceReply>> voice({
    required String storeId,
    required List<AssistantTurn> history,
    required Uint8List wav,
    required String languageCode,
    LastMarket? lastMarket,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/assistant/voice',
        data: {
          'store_id': storeId,
          'messages': _turns(history),
          'audio_base64': base64Encode(wav),
          'mime_type': 'audio/wav',
          'language': languageCode,
          if (lastMarket != null) 'last_market': lastMarket.toJson(),
        },
        options: _slow,
      );
      return Right(MarketModel.voice(response.data ?? const {}));
    } catch (error) {
      return Left(_error(error));
    }
  }

  @override
  Future<Uint8List?> speak(String text) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/assistant/speak', data: {'text': text});
      final audio = response.data?['audio_base64'];
      return audio is String && audio.isNotEmpty ? base64Decode(audio) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<AppError, AdoptResult>> adopt({
    required String storeId,
    required String offerId,
    String? searchId,
    int? quantity,
    required bool placeOrder,
    String? locale,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/assistant/adopt',
        data: {
          'store_id': storeId,
          'offer_id': offerId,
          'search_id': searchId,
          'quantity': quantity,
          'place_order': placeOrder,
          'locale': locale,
        },
        options: _slow,
      );
      return Right(MarketModel.adopt(response.data ?? const {}));
    } catch (error) {
      return Left(_error(error));
    }
  }
}
