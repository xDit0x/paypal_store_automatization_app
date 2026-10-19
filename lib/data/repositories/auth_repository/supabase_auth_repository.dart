import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:store_automatization_app/data/datasources/auth_repository/supabase_auth_datasource.dart';
import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseAuthDatasource _datasource;
  SupabaseAuthRepository(this._datasource);

  @override
  Future<Either<String, AppUser>> signIn(String email, String password) async {
    try {
      final response = await _datasource.signIn(email, password);
      final user = response.user;
      if (user == null) return const Left('No se pudo obtener el usuario');
      return Right(_toAppUser(user));
    } on AuthException catch (error) {
      return Left(_mapError(error));
    } catch (error) {
      return Left('No se pudo iniciar sesión: $error');
    }
  }

  @override
  Future<Either<String, AppUser>> signUp(
    String email,
    String password, {
    String? storeName,
  }) async {
    try {
      final response = await _datasource.signUp(
        email,
        password,
        data: {
          if (storeName != null && storeName.trim().isNotEmpty)
            'store_name': storeName.trim(),
        },
      );
      final user = response.user;
      if (user == null) {
        return const Left(
          'Cuenta creada. Revisa tu correo para confirmarla e inicia sesión.',
        );
      }
      return Right(_toAppUser(user));
    } on AuthException catch (error) {
      return Left(_mapError(error));
    } catch (error) {
      return Left('No se pudo registrar: $error');
    }
  }

  @override
  Future<Either<String, Unit>> signOut() async {
    try {
      await _datasource.signOut();
      return Right(unit);
    } catch (_) {
      return const Left('No se pudo cerrar sesión. Inténtalo de nuevo.');
    }
  }

  @override
  Future<Either<String, Unit>> sendResetPasswordEmail(String email) async {
    try {
      await _datasource.sendResetPasswordEmail(email);
      return Right(unit);
    } on AuthException catch (error) {
      return Left(_mapError(error));
    } catch (_) {
      return const Left('No se pudo enviar el correo de recuperación.');
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

  String _mapError(AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos';
      case 'email_exists':
      case 'user_already_exists':
        return 'Ese correo ya está registrado';
      case 'weak_password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'email_not_confirmed':
        return 'Confirma tu correo antes de entrar';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Demasiados intentos. Espera un momento.';
      case 'validation_failed':
        return 'Revisa el correo y la contraseña';
      default:
        return error.message;
    }
  }
}
