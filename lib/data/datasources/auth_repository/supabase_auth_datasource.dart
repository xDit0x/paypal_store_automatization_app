import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDatasource {
  final SupabaseClient _client;
  SupabaseAuthDatasource(this._client);

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendResetPasswordEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);

  Future<void> resendConfirmationEmail(String email) =>
      _client.auth.resend(email: email, type: OtpType.signup);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
