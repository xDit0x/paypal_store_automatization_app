import 'package:store_automatization_app/data/datasources/store_repository/supabase_store_changes_datasource.dart';
import 'package:store_automatization_app/domain/repositories/store_repository/store_changes_repository.dart';

class SupabaseStoreChangesRepository implements StoreChangesRepository {
  final SupabaseStoreChangesDatasource _datasource;
  SupabaseStoreChangesRepository(this._datasource);

  @override
  Stream<void> watch(String storeId) => _datasource.watch(storeId);
}
