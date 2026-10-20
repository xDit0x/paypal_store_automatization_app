import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class SendResetPasswordEmailUsecase {
  final AuthRepository repository;
  SendResetPasswordEmailUsecase({required this.repository});

  Future<Either<AppError, Unit>> call(String email) =>
      repository.sendResetPasswordEmail(email);
}
