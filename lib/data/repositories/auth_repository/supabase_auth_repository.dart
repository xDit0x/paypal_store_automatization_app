import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:store_automatization_app/data/datasources/auth_repository/supabase_auth_datasource.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseAuthDatasource _datasource;
  SupabaseAuthRepository(this._datasource);

  @override
  Future<Either<AppError, AppUser>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await _datasource.signIn(email, password);
      final user = response.user;
      if (user == null) {
        return const Left(AppError(AppErrorCode.authUserMissing));
      }
      return Right(_toAppUser(user));
    } on AuthException catch (error) {
      return Left(_mapError(error, AppErrorCode.authSignInFailed));
    } catch (error) {
      return Left(logError(AppErrorCode.authSignInFailed, error));
    }
  }

  @override
  Future<Either<AppError, AppUser>> signUp(
    String email,
    String password, {
    String? storeName,
    String? paypalMerchantEmail,
  }) async {
    try {
      final response = await _datasource.signUp(
        email,
        password,
        data: {
          if (storeName != null && storeName.trim().isNotEmpty)
            'store_name': storeName.trim(),
          if (paypalMerchantEmail != null &&
              paypalMerchantEmail.trim().isNotEmpty)
            'paypal_merchant_email': paypalMerchantEmail.trim(),
        },
      );
      final user = response.user;
      if (user == null) {
        return const Left(AppError(AppErrorCode.authSignUpFailed));
      }
      // Con la confirmación por correo activada, Supabase devuelve un usuario
      // sin `identities` cuando el correo ya está registrado, para no revelar
      // qué cuentas existen. Ese es el aviso de "correo ya registrado".
      if (user.identities != null && user.identities!.isEmpty) {
        return const Left(AppError(AppErrorCode.authEmailTaken));
      }
      // Sin sesión el correo aún no está confirmado: no se entra a la app.
      if (response.session == null) {
        return const Left(AppError(AppErrorCode.authConfirmEmail));
      }
      return Right(_toAppUser(user));
    } on AuthException catch (error) {
      // Supabase crea la cuenta antes de mandar el correo de confirmación. Si
      // el envío choca con su límite de correos, la cuenta ya existe: hay que
      // avisar de eso, no de un alta fallida.
      if (error.code == 'over_email_send_rate_limit') {
        return const Left(AppError(AppErrorCode.authSignUpEmailRateLimited));
      }
      return Left(_mapError(error, AppErrorCode.authSignUpFailed));
    } catch (error) {
      return Left(logError(AppErrorCode.authSignUpFailed, error));
    }
  }

  @override
  Future<Either<AppError, Unit>> signOut() async {
    try {
      await _datasource.signOut();
      return Right(unit);
    } catch (_) {
      return const Left(AppError(AppErrorCode.authSignOutFailed));
    }
  }

  @override
  Future<Either<AppError, Unit>> sendResetPasswordEmail(String email) async {
    try {
      await _datasource.sendResetPasswordEmail(email);
      return Right(unit);
    } on AuthException catch (error) {
      return Left(_mapError(error, AppErrorCode.authResetEmailFailed));
    } catch (_) {
      return const Left(AppError(AppErrorCode.authResetEmailFailed));
    }
  }

  @override
  Future<Either<AppError, Unit>> resendConfirmationEmail(String email) async {
    try {
      await _datasource.resendConfirmationEmail(email);
      return Right(unit);
    } on AuthException catch (error) {
      return Left(_mapError(error, AppErrorCode.authResendConfirmFailed));
    } catch (error) {
      return Left(logError(AppErrorCode.authResendConfirmFailed, error));
    }
  }

  @override
  AppUser? currentUser() {
    final user = _datasource.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _datasource.authStateChanges.map((state) {
      final user = state.session?.user;
      return user == null ? null : _toAppUser(user);
    });
  }

  AppUser _toAppUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email,
      storeName: user.userMetadata?['store_name'] as String?,
    );
  }

  AppError _mapError(AuthException error, AppErrorCode fallback) {
    switch (error.code) {
      case 'invalid_credentials':
        return const AppError(AppErrorCode.authInvalidCredentials);
      case 'email_exists':
      case 'user_already_exists':
        return const AppError(AppErrorCode.authEmailTaken);
      case 'weak_password':
        return const AppError(AppErrorCode.authWeakPassword);
      case 'email_not_confirmed':
        return const AppError(AppErrorCode.authEmailNotConfirmed);
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return const AppError(AppErrorCode.authTooManyAttempts);
      case 'validation_failed':
        return const AppError(AppErrorCode.authValidationFailed);
      default:
        return logError(fallback, error);
    }
  }
}
