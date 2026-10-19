import 'package:store_automatization_app/domain/entities/app_user.dart';
import 'package:store_automatization_app/domain/repositories/auth_repository/auth_repository.dart';

class WatchAuthUsecase {
  final AuthRepository repository;
  WatchAuthUsecase({required this.repository});

  Stream<AppUser?> call() => repository.authStateChanges();
}
