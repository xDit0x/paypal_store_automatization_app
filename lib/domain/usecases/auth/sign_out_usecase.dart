import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class SignOutUsecase {
  final AuthRepository repository;
  SignOutUsecase({required this.repository});

  Future<Either<AppError, Unit>> call() => repository.signOut();
}
