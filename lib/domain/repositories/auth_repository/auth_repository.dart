import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<String, AppUser>> signIn(String email, String password);
  Future<Either<String, AppUser>> signUp(
    String email,
    String password, {
    String? storeName,
  });
  Future<Either<String, Unit>> signOut();
  Future<Either<String, Unit>> sendResetPasswordEmail(String email);
  AppUser? currentUser();
  Stream<AppUser?> authStateChanges();
}
