import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInvoiceDatasource {
  final SupabaseClient _client;
  SupabaseInvoiceDatasource(this._client);

  Future<Map<String, dynamic>?> getByOrder(String orderId) async {
    return _client
        .from('invoices')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
  }
}
