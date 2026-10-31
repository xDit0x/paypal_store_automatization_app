import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _orderSelect = '*, order_items(*)';

class SupabaseOrderDatasource {
  final SupabaseClient _client;
  final Dio _dio;
  SupabaseOrderDatasource(this._client, this._dio);

  Future<List<Map<String, dynamic>>> getByStore(String storeId) async {
    final rows = await _client
        .from('orders')
        .select(_orderSelect)
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    return _client
        .from('orders')
        .select(_orderSelect)
        .eq('id', id)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> insertOrder(Map<String, dynamic> row) async {
    final result = await _client
        .from('orders')
        .insert(row)
        .select(_orderSelect)
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> insertItems(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('order_items').insert(rows);
  }

  Future<double> getSpentSince(String storeId, DateTime since) async {
    final rows = await _client
        .from('orders')
        .select('total')
        .eq('store_id', storeId)
        .inFilter('status', ['paid', 'invoiced', 'completed'])
        .gte('created_at', since.toUtc().toIso8601String());
    return rows.fold<double>(
      0,
      (sum, row) => sum + ((row['total'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<void> approve(String orderId) async {
    await _dio.post<Map<String, dynamic>>('/orders/$orderId/approve', data: {});
  }

  Future<Map<String, dynamic>> reviewAmount(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId/amount',
    );
    return response.data ?? const {};
  }

  Future<void> reject(String orderId) async {
    await _dio.post<Map<String, dynamic>>('/orders/$orderId/reject', data: {});
  }
}
