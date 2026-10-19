import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class CheckAuthUsecase {
  final AuthRepository repository;
  CheckAuthUsecase({required this.repository});

  AppUser? call() => repository.currentUser();
}
