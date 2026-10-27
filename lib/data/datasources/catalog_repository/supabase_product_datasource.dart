import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProductDatasource {
  final SupabaseClient _client;
  final Dio _dio;

  SupabaseProductDatasource(this._client, this._dio);

  /// El stock y el umbral viven en `store_products`; el resto del producto en
  /// `products`. Se piden juntos y se aplana para que el modelo no cambie.
  static const _inventorySelect =
      'stock, low_stock_threshold, products!inner(*)';

  Future<List<Map<String, dynamic>>> getBySupplier(
    String storeId,
    String supplierId,
  ) async {
    final rows = await _client
        .from('store_products')
        .select(_inventorySelect)
        .eq('store_id', storeId)
        .eq('products.supplier_id', supplierId);
    final products = rows.map(_flatten).toList()
      ..sort(
        (a, b) => (a['name'] as String).toLowerCase().compareTo(
          (b['name'] as String).toLowerCase(),
        ),
      );
    return products;
  }

  Future<Map<String, dynamic>?> getByUid(String storeId, String uid) async {
    final row = await _client
        .from('store_products')
        .select(_inventorySelect)
        .eq('store_id', storeId)
        .eq('product_uid', uid)
        .maybeSingle();
    return row == null ? null : _flatten(row);
  }

  Future<List<Map<String, dynamic>>> getByUids(
    String storeId,
    List<String> uids,
  ) async {
    if (uids.isEmpty) return const [];
    final rows = await _client
        .from('store_products')
        .select(_inventorySelect)
        .eq('store_id', storeId)
        .inFilter('product_uid', uids);
    return rows.map(_flatten).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStock(String storeId) async {
    final rows = await _client
        .from('store_products')
        .select(_inventorySelect)
        .eq('store_id', storeId)
        .eq('products.active', true);
    final products =
        rows.map(_flatten).where((row) {
          final stock = (row['stock'] as num?)?.toInt() ?? 0;
          final threshold = (row['low_stock_threshold'] as num?)?.toInt() ?? 0;
          return stock <= threshold;
        }).toList()..sort(
          (a, b) => ((a['stock'] as num?)?.toInt() ?? 0).compareTo(
            (b['stock'] as num?)?.toInt() ?? 0,
          ),
        );
    return products;
  }

  /// El catálogo solo se escribe con service_role, así que pasa por la API.
  Future<void> updateStock(String storeId, String uid, int stock) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/catalog/products/$uid/stock',
        data: {'store_id': storeId, 'stock': stock},
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map<String, dynamic> ? data['error'] : null;
      throw Exception(message ?? '');
    }
  }

  /// Convierte `{ stock, low_stock_threshold, products: {...} }` en el mapa
  /// plano del producto con el stock de esta tienda.
  Map<String, dynamic> _flatten(Map<String, dynamic> row) {
    final product = Map<String, dynamic>.from(row['products'] as Map);
    product['stock'] = row['stock'];
    product['low_stock_threshold'] = row['low_stock_threshold'];
    return product;
  }
}
