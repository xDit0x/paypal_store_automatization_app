import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class ResendConfirmationEmailUsecase {
  final AuthRepository repository;
  ResendConfirmationEmailUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(String email) =>
      repository.resendConfirmationEmail(email);
}
