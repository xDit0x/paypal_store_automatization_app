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
    // Consulta el catálogo global (products) para permitir pedidos de
    // productos que aún no están en stock de la tienda.
    final rows = await _client
        .from('products')
        .select(
          'id, uid, supplier_id, name, description, price, currency, stock, low_stock_threshold, unit, image_url, active, suppliers!inner(name)',
        )
        .inFilter('uid', uids)
        .eq('active', true);
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r as Map);
      final sup = (r['suppliers'] as Map?) ?? {};
      map['supplier_name'] = sup['name'] ?? 'Proveedor';
      map['supplier_id'] = r['supplier_id'];
      map['in_inventory'] = false;
      return map;
    }).toList();
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

  Future<List<Map<String, dynamic>>> searchCatalog({
    required String storeId,
    String? query,
    String? supplierId,
  }) async {
    var queryBuilder = _client
        .from('products')
        .select(
          'id, uid, supplier_id, name, description, price, currency, stock, '
          'low_stock_threshold, unit, image_url, active, suppliers!inner(name)',
        )
        .eq('active', true);
    if (supplierId != null && supplierId.isNotEmpty) {
      queryBuilder = queryBuilder.eq('supplier_id', supplierId);
    }
    if (query != null && query.trim().isNotEmpty) {
      // Se quitan los caracteres que rompen la sintaxis del filtro `or`.
      final q = query
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[,()%]'), ' ')
          .trim();
      if (q.isNotEmpty) {
        queryBuilder = queryBuilder.or('name.ilike.%$q%,uid.ilike.%$q%');
      }
    }
    final rows = await queryBuilder;

    // Stock de esta tienda: `store_products` guarda el stock por tienda.
    final uids = [for (final row in rows) row['uid'] as String];
    final inventory = <String, Map<String, dynamic>>{};
    if (uids.isNotEmpty) {
      final stockRows = await _client
          .from('store_products')
          .select('product_uid, stock, low_stock_threshold')
          .eq('store_id', storeId)
          .inFilter('product_uid', uids);
      for (final row in stockRows) {
        inventory[row['product_uid'] as String] = row;
      }
    }

    return rows.map((r) {
      final map = Map<String, dynamic>.from(r as Map);
      final sup = (r['suppliers'] as Map?) ?? {};
      final uid = r['uid'] as String;
      final stock = inventory[uid];
      map['supplier_name'] = sup['name'] ?? 'Proveedor';
      map['in_inventory'] = stock != null;
      if (stock != null) {
        map['stock'] = stock['stock'];
        map['low_stock_threshold'] = stock['low_stock_threshold'];
      }
      return map;
    }).toList()..sort(
      (a, b) => (a['name'] as String).toLowerCase().compareTo(
        (b['name'] as String).toLowerCase(),
      ),
    );
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
