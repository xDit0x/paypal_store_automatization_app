// Se carga antes de todos los tests (ver "test" en package.json).
// Valores falsos para que ningún test necesite el .env ni toque Supabase de
// verdad: así los tests pasan igual en tu Mac que en GitHub Actions.
process.env.SUPABASE_URL ??= 'https://example.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test-service-role-key';
process.env.GROQ_API_KEY ??= 'test-groq-key';
