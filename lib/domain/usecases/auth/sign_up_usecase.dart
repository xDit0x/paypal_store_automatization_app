import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class SignUpUsecase {
  final AuthRepository repository;
  SignUpUsecase({required this.repository});

  Future<Either<AppError, AppUser>> call(
    String email,
    String password, {
    String? storeName,
  }) => repository.signUp(email, password, storeName: storeName);
}
