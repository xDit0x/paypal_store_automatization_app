import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:store_automatization_app/core/configs/env.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static Future<void> initialize() async {
    if (!Env.hasSupabase) {
      throw StateError(
        'Faltan SUPABASE_URL y SUPABASE_ANON_KEY (o SUPABASE_PUBLISHABLE_KEY). '
        'Ejecuta la app con --dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
