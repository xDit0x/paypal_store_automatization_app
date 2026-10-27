import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<AppError, AppUser>> signIn(String email, String password);
  Future<Either<AppError, AppUser>> signUp(
    String email,
    String password, {
    String? storeName,
    String? paypalMerchantEmail,
  });
  Future<Either<AppError, Unit>> signOut();
  Future<Either<AppError, Unit>> sendResetPasswordEmail(String email);
  Future<Either<AppError, Unit>> resendConfirmationEmail(String email);
  AppUser? currentUser();
  Stream<AppUser?> authStateChanges();
}
