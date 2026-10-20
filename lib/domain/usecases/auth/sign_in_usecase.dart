import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class SignInUsecase {
  final AuthRepository repository;
  SignInUsecase({required this.repository});

  Future<Either<AppError, AppUser>> call(String email, String password) =>
      repository.signIn(email, password);
}
