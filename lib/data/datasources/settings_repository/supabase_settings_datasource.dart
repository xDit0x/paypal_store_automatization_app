import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSettingsDatasource {
  final SupabaseClient _client;
  SupabaseSettingsDatasource(this._client);

  Future<Map<String, dynamic>?> getSpendingRules(String storeId) async {
    return _client
        .from('spending_rules')
        .select()
        .eq('store_id', storeId)
        .maybeSingle();
  }

  Future<void> updateSpendingRules(
    String storeId,
    Map<String, dynamic> values,
  ) async {
    await _client
        .from('spending_rules')
        .update(values)
        .eq('store_id', storeId);
  }
}
