import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:store_automatization_app/data/datasources/auth_repository/supabase_auth_datasource.dart';
import 'package:store_automatization_app/data/repositories/auth_repository/supabase_auth_repository.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';

/// Datasource que falla siempre con el error de Supabase indicado.
class _FailingDatasource extends SupabaseAuthDatasource {
  _FailingDatasource(this.error)
    : super(SupabaseClient('https://example.supabase.co', 'anon-key'));

  final AuthException error;

  @override
  Future<AuthResponse> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    throw error;
  }
}

Future<AppErrorCode> _signUpError(AuthException error) async {
  final repository = SupabaseAuthRepository(_FailingDatasource(error));
  final result = await repository.signUp('ana@example.com', 'secreto123');
  return result.fold((failure) => failure.code, (_) => fail('No debía crear'));
}

void main() {
  test('un 429 al registrarse se trata como alta no creada', () async {
    expect(
      await _signUpError(
        const AuthException(
          'email rate limit exceeded',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      ),
      AppErrorCode.authSignUpRateLimited,
    );
  });

  test('un 429 de peticiones también deja el formulario abierto', () async {
    expect(
      await _signUpError(
        const AuthException(
          'request rate limit reached',
          statusCode: '429',
          code: 'over_request_rate_limit',
        ),
      ),
      AppErrorCode.authSignUpRateLimited,
    );
  });
}
