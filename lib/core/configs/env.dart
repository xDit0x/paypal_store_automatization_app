class Env {
  const Env._();

  // Valores por defecto para la demo del hackathon. Se pueden sobreescribir
  // con --dart-define o --dart-define-from-file para desarrollo local.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aafoxkojkxkepqmolwva.supabase.co',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhZm94a29qa3hrZXBxbW9sd3ZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0MTQzMTIsImV4cCI6MjEwNzk5MDMxMn0.V-5Z_G1N8Hf4qbetvruAr_fHTBObJwB-Wk-VeOd-q70',
  );
  static const String agentApiUrl = String.fromEnvironment(
    'AGENT_API_URL',
    defaultValue: 'https://stocky-app-theta.vercel.app/api',
  );
  static const String demoEmail = String.fromEnvironment('DEMO_EMAIL');
  static const String demoPassword = String.fromEnvironment('DEMO_PASSWORD');

  static String get supabaseKey => supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
