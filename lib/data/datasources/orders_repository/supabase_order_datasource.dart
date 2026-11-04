import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _orderSelect = '*, order_items(*)';

/// Estados en los que el dinero ya está comprometido o cobrado.
const _spentStatuses = [
  'authorized',
  'delivered',
  'partially_delivered',
  'paid',
  'invoiced',
  'completed',
];

/// Un pedido recién aprobado aún no ha movido dinero, pero en cuanto el
/// servidor crea la orden de PayPal el importe queda comprometido y la app ya
/// lo presenta como pagado. Se cuenta solo si existe esa orden.
bool _isCommittedButUnpaid(Map<String, dynamic> row) {
  if (row['status'] != 'approved') return true;
  final payoutId = row['payment_payout_id'];
  return payoutId is String && payoutId.isNotEmpty;
}

/// Fecha con la que un pedido entra en el gasto del mes: el cobro real, la
/// autorización, la aprobación o, en último caso, su creación. Si se usa solo
/// `created_at`, un pedido aprobado el mes pasado y cobrado este no aparecería.
DateTime? _spentOn(Map<String, dynamic> row) {
  for (final key in [
    'payment_at',
    'authorized_at',
    'approval_at',
    'created_at',
  ]) {
    final value = row[key];
    if (value is! String || value.isEmpty) continue;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return null;
}

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
        .select(
          'status, total, received_total, payment_payout_id, '
          'created_at, approval_at, authorized_at, payment_at',
        )
        .eq('store_id', storeId)
        .inFilter('status', [..._spentStatuses, 'approved']);
    return rows.fold<double>(0, (sum, row) {
      if (!_isCommittedButUnpaid(row)) return sum;
      final spentOn = _spentOn(row);
      if (spentOn == null || spentOn.isBefore(since)) return sum;

      // En una entrega parcial solo se ha cobrado lo que llegó.
      final captured = (row['received_total'] as num?)?.toDouble();
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      return sum + (captured ?? total);
    });
  }

  Future<void> approve(String orderId) async {
    await _dio.post<Map<String, dynamic>>('/orders/$orderId/approve', data: {});
  }

  /// Enlace de PayPal para autorizar el importe de un pedido aprobado.
  Future<String?> authorizationUrl(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId/approve-url',
    );
    final url = response.data?['approve_url'];
    return url is String && url.isNotEmpty ? url : null;
  }

  Future<void> confirmAuthorization(String orderId) async {
    await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/confirm-auth',
      data: const <String, dynamic>{},
    );
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
