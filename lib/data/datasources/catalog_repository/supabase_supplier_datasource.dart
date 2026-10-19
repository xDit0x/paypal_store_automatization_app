import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSupplierDatasource {
  final SupabaseClient _client;
  SupabaseSupplierDatasource(this._client);

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _client
        .from('suppliers')
        .select()
        .eq('active', true)
        .order('name');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    return _client.from('suppliers').select().eq('id', id).maybeSingle();
  }
}
