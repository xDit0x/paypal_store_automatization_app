import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:store_automatization_app/core/configs/env.dart';
import 'package:store_automatization_app/core/configs/l10n/app_language.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }
}

/// Manda el idioma de la app en cada petición.
///
/// El servidor lo usa para contestar en el mismo idioma (agente, asistente y
/// mensajes de error).
class LocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-App-Locale'] = AppLanguage.code;
    handler.next(options);
  }
}

class DioClient {
  const DioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.agentApiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(LocaleInterceptor());
    return dio;
  }
}
