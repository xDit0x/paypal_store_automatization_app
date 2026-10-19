import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStoreDatasource {
  final SupabaseClient _client;
  SupabaseStoreDatasource(this._client);

  Future<Map<String, dynamic>?> getOwn() async {
    return _client.from('stores').select().limit(1).maybeSingle();
  }

  Future<void> update(String storeId, Map<String, dynamic> values) async {
    await _client.from('stores').update(values).eq('id', storeId);
  }
}
