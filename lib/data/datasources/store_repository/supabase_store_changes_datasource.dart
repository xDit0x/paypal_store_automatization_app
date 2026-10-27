import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Escucha en tiempo real los cambios de una tienda con Supabase Realtime.
///
/// Requiere que las tablas estén en la publicación `supabase_realtime`
/// (ver supabase/migrations/20261027000002_realtime.sql). Supabase aplica las
/// reglas RLS, así que cada usuario solo recibe los cambios de su tienda.
class SupabaseStoreChangesDatasource {
  final SupabaseClient _client;
  SupabaseStoreChangesDatasource(this._client);

  static const _tables = ['orders', 'store_products', 'agent_runs'];

  Stream<void> watch(String storeId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        var created = _client.channel('restock-store-$storeId');
        for (final table in _tables) {
          created = created.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'store_id',
              value: storeId,
            ),
            callback: (_) {
              if (!controller.isClosed) controller.add(null);
            },
          );
        }
        channel = created.subscribe();
      },
      onCancel: () async {
        final current = channel;
        channel = null;
        if (current != null) await _client.removeChannel(current);
      },
    );

    return controller.stream;
  }
}
