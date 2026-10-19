import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAgentDatasource {
  final SupabaseClient _client;
  final Dio _dio;

  SupabaseAgentDatasource(this._client, this._dio);

  Future<Map<String, dynamic>> run(String storeId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/agent/run',
      data: {'store_id': storeId},
    );
    return response.data ?? const {};
  }

  Future<List<Map<String, dynamic>>> getRuns(String storeId) async {
    final rows = await _client
        .from('agent_runs')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
