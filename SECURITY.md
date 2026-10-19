# Seguridad

## Qué reportar

Si encuentras una vulnerabilidad, escríbenos por privado (no abras un issue
público) con:

- Qué se puede hacer y con qué impacto (dinero, datos de otros usuarios, etc.).
- Pasos para reproducirlo.
- Tu correo de contacto.

Respondemos en menos de 72 horas.

## Cómo está repartida la responsabilidad

Restock es una app de reposición: un agente de IA prepara pedidos a los
proveedores de una tienda y PayPal los paga. Por eso hay dos caminos
deliberadamente separados:

- **El cliente** (Flutter) usa la `anon key` de Supabase y **RLS**: cada
  usuario solo ve y toca los datos de su tienda. Los secretos (PayPal, IA,
  `service_role`) viven **solo** en el backend.
- **El backend** (Fastify) es el único que mueve dinero. Antes de pagar
  recalcula el importe desde el catálogo y vuelve a comprobar las reglas de
  gasto, aunque el pedido lo haya creado el cliente.

## Reglas para el repositorio

- Ningún secreto en el código ni en el historial: `.env`, `dart_defines.json` y
  las claves de Supabase/Groq/PayPal van siempre por entorno.
- `SUPABASE_SERVICE_ROLE_KEY` **nunca** en el cliente.
- El CI de cada push corre `flutter analyze`, `flutter test`, `tsc`, los tests
  del servidor y un escaneo de secretos (gitleaks).
- Los cambios que afecten a RLS, a los imports o a los pagos necesitan
  revisión de otra persona.

## Dependencias

- Vulnerabilidades de dependencias: `npm audit` en `server/` y
  `flutter pub outdated` en la raíz.
- La versión de Node del backend es la 22 (la del `Dockerfile`).
