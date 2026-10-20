import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';

/// Deja el detalle técnico en la consola y devuelve el error que verá el
/// usuario. Así la interfaz nunca enseña un volcado de excepción.
AppError logError(
  AppErrorCode code,
  Object error, {
  String? detail,
  String? subject,
}) {
  debugPrint('[${code.name}] $error');
  return AppError(code, detail: detail, subject: subject);
}

/// Mensaje que el servidor manda en un error HTTP (`{ "error": "..." }`).
///
/// Ya viene redactado para el usuario (por ejemplo, por qué un pedido no
/// supera las reglas), así que se conserva como detalle del error.
String? serverMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is Map) {
    final message = data['error'] ?? data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
  }
  return null;
}
