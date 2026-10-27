import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/usecases/auth/check_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/resend_confirmation_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/send_reset_password_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_out_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_up_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/watch_auth_usecase.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUsecase signInUseCase;
  final SignUpUsecase signUpUseCase;
  final SignOutUsecase signOutUseCase;
  final CheckAuthUsecase checkAuthUseCase;
  final WatchAuthUsecase watchAuthUseCase;
  final SendResetPasswordEmailUsecase sendResetPasswordEmailUseCase;
  final ResendConfirmationEmailUsecase resendConfirmationEmailUseCase;

  StreamSubscription<AppUser?>? _authSubscription;

  AuthCubit({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.checkAuthUseCase,
    required this.watchAuthUseCase,
    required this.sendResetPasswordEmailUseCase,
    required this.resendConfirmationEmailUseCase,
  }) : super(const AuthState(status: AuthStatus.unknown)) {
    final user = checkAuthUseCase();
    emit(
      AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
      ),
    );

    _authSubscription = watchAuthUseCase().listen((user) {
      emit(
        AuthState(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
        ),
      );
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await signInUseCase(email, password);
    result.fold(
      (error) =>
          emit(AuthState(status: AuthStatus.unauthenticated, error: error)),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> signUp(
    String email,
    String password, {
    String? storeName,
    String? paypalMerchantEmail,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await signUpUseCase(
      email,
      password,
      storeName: storeName,
      paypalMerchantEmail: paypalMerchantEmail,
    );
    result.fold(
      (error) =>
          emit(AuthState(status: AuthStatus.unauthenticated, error: error)),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> signOut() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await signOutUseCase();
    result.fold(
      (error) => emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: state.user,
          error: error,
        ),
      ),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }

  Future<void> sendResetPasswordEmail(String email) async {
    final result = await sendResetPasswordEmailUseCase(email);
    result.fold(
      (error) => emit(state.copyWith(error: error)),
      (_) => emit(state.copyWith(error: null)),
    );
  }

  /// Reenvía el correo de confirmación de la cuenta. Devuelve `true` si
  /// Supabase lo aceptó.
  Future<bool> resendConfirmationEmail(String email) async {
    final result = await resendConfirmationEmailUseCase(email);
    return result.isRight();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
