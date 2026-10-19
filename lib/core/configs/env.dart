class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String agentApiUrl = String.fromEnvironment(
    'AGENT_API_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String demoEmail = String.fromEnvironment('DEMO_EMAIL');
  static const String demoPassword = String.fromEnvironment('DEMO_PASSWORD');

  static String get supabaseKey => supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
