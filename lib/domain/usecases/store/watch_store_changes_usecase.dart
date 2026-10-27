import 'package:store_automatization_app/domain/repositories/store_repository/store_changes_repository.dart';

class WatchStoreChangesUsecase {
  final StoreChangesRepository repository;
  WatchStoreChangesUsecase({required this.repository});

  Stream<void> call(String storeId) => repository.watch(storeId);
}
