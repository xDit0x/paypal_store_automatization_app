import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProductDatasource {
  final SupabaseClient _client;
  SupabaseProductDatasource(this._client);

  Future<List<Map<String, dynamic>>> getBySupplier(String supplierId) async {
    final rows = await _client
        .from('products')
        .select()
        .eq('supplier_id', supplierId)
        .order('name');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>?> getByUid(String uid) async {
    return _client.from('products').select().eq('uid', uid).maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getByUids(List<String> uids) async {
    if (uids.isEmpty) return const [];
    final rows = await _client.from('products').select().inFilter('uid', uids);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStock() async {
    final rows = await _client
        .from('products')
        .select()
        .eq('active', true)
        .order('stock');
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) {
          final stock = (row['stock'] as num?)?.toInt() ?? 0;
          final threshold = (row['low_stock_threshold'] as num?)?.toInt() ?? 0;
          return stock <= threshold;
        })
        .toList();
  }
}
