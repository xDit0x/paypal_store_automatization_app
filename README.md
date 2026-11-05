# Restock

**Reposición automática para tiendas: un agente de IA revisa el stock, prepara
pedidos a tus proveedores y los paga con PayPal, siempre dentro de las reglas
de gasto que tú marcas.**

La app se muestra como **Stocky** en la interfaz. Participa en el
[PayPal AI Hackathon](https://devpost.com/) con la API de **PayPal** (Sandbox)
y un modelo de IA de **Groq**.

| Capa | Tecnología | Qué aporta |
|---|---|---|
| **App** | Flutter (web, Android, iOS) | Una sola base de código para el jurado y la APK. Lee Supabase con la `anon key` y **RLS**: cada usuario solo ve su tienda. |
| **Backend** | TypeScript + Fastify (Node 22) | Es el **único** que mueve dinero. Guarda los secretos (PayPal, IA, `service_role`), recalcula el importe de cada pedido desde el catálogo y vuelve a comprobar tus reglas antes de pagar. |
| **Datos** | Supabase (Postgres + Auth + Realtime) | Esquema y políticas RLS en `supabase/migrations/`. |
| **IA** | Groq (`groq-sdk`) con adaptador intercambiable | El agente usa *tool calling* contra el catálogo real. Cambiar de modelo es cambiar una variable de entorno. |
| **Pagos** | PayPal Orders + Payouts + Invoicing (Sandbox) | Autorización del comprador, pago al proveedor y factura oficial. |
| **Despliegue** | Vercel (web + Functions) + Supabase | Un mismo dominio para el frontend y la API: `https://stocky-app-theta.vercel.app`. |

---

## 🚀 Probarlo en 30 segundos (sin instalar nada)

**URL de la demo:** <https://stocky-app-theta.vercel.app>

| | |
|---|---|
| **Usuario** | `demo@restock.dev` |
| **Contraseña** | `Restock2026!` |

> La demo usa **PayPal Sandbox**: no se mueve dinero real. Los pagos se ven en
> <https://sandbox.paypal.com>.

### Recorrido recomendado para el jurado

1. **Inicia sesión** con la cuenta de arriba (la app está en español e inglés;
   puedes cambiar de idioma en la propia pantalla de login).
2. Ve a la pestaña **Asistente** y pulsa la sugerencia **"Revisa el stock ahora"**
   (o escribe "revisa mi stock"). El agente consulta el catálogo real de la
   tienda, decide qué reponer y **crea el pedido** — con la IA decidiendo qué
   producto y a qué proveedor.
3. Abre la pestaña **Pedidos**: verás el pedido creado por el agente, con
   **"Lo preparó el agente"** y el detalle de lo que decidió.
4. Pulsa **"Aprobar y pagar con PayPal"**. Si el importe supera tus reglas de
   gasto, el propio agente lo explica y **deja el pedido pendiente**: tú decides.
5. Se abre **PayPal Sandbox** para autorizar el pago. Al autorizar, la app
   vuelve a PayPal, confirma el estado y lo refleja en el pedido.
6. En la entrega puedes registrar el albarán (foto o manual) y la app calcula
   lo que falta por cobrar. La **factura** se genera y se envía por email.

También puedes escribirle al agente cosas como *"¿cuánto llevo gastado?"* o
*"¿qué tengo por aprobar?"*, y usar la **voz** (dictado con Whisper en el
servidor y lectura en voz alta).

---

## 🖥️ Lanzarlo en local

### Requisitos

- Flutter 3.47.7 (estable)
- Node.js 22
- Un proyecto Supabase y una cuenta de PayPal Sandbox

### 1. Dependencias

```bash
git clone https://github.com/xDit0x/paypal_store_automatization_app.git
cd paypal_store_automatization_app
flutter pub get
cd server && npm ci && cd ..
```

### 2. Variables de entorno

```bash
cp .env.example .env                 # Flutter -> dart_defines.json
cp server/.env.example server/.env   # backend
```

Rellena `server/.env` con tus claves (**no se suben al repositorio**, están en
`.gitignore`):

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...        # solo backend
GROQ_API_KEY=gsk_...                 # https://console.groq.com
PAYPAL_CLIENT_ID=...                 # https://developer.paypal.com (sandbox)
PAYPAL_CLIENT_SECRET=...
PAYPAL_BASE_URL=https://api-m.sandbox.paypal.com
RESEND_API_KEY=...                   # opcional: envío de facturas
ALLOWED_ORIGINS=http://localhost:3000
```

Y `dart_defines.json` para la app:

```json
{
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_ANON_KEY": "...",
  "AGENT_API_URL": "http://localhost:3000"
}
```

### 3. Base de datos

Aplica los ficheros de `supabase/migrations/` en el **SQL Editor** de Supabase y
luego `supabase/seed.sql` (proveedores, catálogo con UID y datos de ejemplo).

```bash
cd server
npm run demo:user      # crea la cuenta demo
npm run reset:demo -- --yes   # (opcional) deja la demo en estado limpio
```

### 4. Backend y app

```bash
# Terminal 1 — backend en http://localhost:3000
cd server && npm run dev

# Terminal 2 — app
flutter run --dart-define-from-file=dart_defines.json
```

### 5. Publicar la web (opcional)

```bash
flutter build web --no-web-resources-cdn \
  --dart-define-from-file=dart_defines.json

python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

> `--no-web-resources-cdn` fuerza a Flutter a servir CanvasKit y las fuentes
> **desde el propio build**, en vez de `gstatic.com`. Es imprescindible en
> redes sin acceso a Google Fonts.

---

## 🧠 Cómo funciona el agente

El agente **propone**; el código **valida**. Hoy el modelo expone una única
herramienta — `create_restock_order(supplier_id, items[])` — y toda la
validación (precios, stock, reglas de gasto, idempotencia) ocurre en el
backend, que lee el catálogo real desde Supabase.

Guardrails:

- Los **precios y el stock** salen de Supabase, nunca del modelo.
- Límite por pedido, límite mensual y lista de proveedores permitidos.
- **Aprobación obligatoria** por encima del umbral configurado.
- `idempotencyKey` en cada pago: no se paga dos veces.
- Cada ejecución queda registrada (`agent_runs`) con modelo, herramientas y decisión.
- Si el modelo falla o devuelve datos inválidos, se cae a un flujo determinista.

### API del backend

| Método | Ruta | Uso |
|---|---|---|
| `POST` | `/agent/run` | Ejecuta el agente para una tienda |
| `POST` | `/orders/:id/approve` | Aprueba y dispara el pago |
| `POST` | `/orders/:id/reject` | Rechaza el pedido |
| `GET` | `/orders/:id/status` | Estado del pago y de la factura |
| `GET` | `/orders/:id/amount` | Importe recalculado desde el catálogo |
| `GET` | `/orders/:id/approve-url` | Enlace de autorización de PayPal |
| `POST` | `/orders/:id/confirm-auth` | Confirmación tras autorizar en PayPal |
| `POST` | `/orders/:id/capture` | Captura tras confirmar la entrega |
| `POST` | `/orders/:id/refund` | Reembolso |
| `POST` | `/orders/:id/reject` | Rechaza el pedido |
| `GET` | `/assistant/message` | Conversación con el asistente |
| `GET` | `/health` | Health check |

> Las lecturas de catálogo y los pedidos en `draft` van directas a Supabase
> (RLS). **Las acciones que mueven dinero pasan siempre por el backend** con
> `service_role`.

---

## 🔐 Seguridad

- El cliente (Flutter) usa **solo** la `anon key` de Supabase y RLS: cada
  usuario solo ve y toca los datos de su tienda.
- `SUPABASE_SERVICE_ROLE_KEY`, `PAYPAL_CLIENT_SECRET` y `GROQ_API_KEY` viven
  **solo** en el backend (variables de entorno de Vercel). No se compilan en la
  web ni se suben al repositorio.
- Verificación del **JWT de Supabase** en cada endpoint protegido y **firma de
  PayPal** verificada en los webhooks.
- **CSP** en `web/index.html` (`default-src 'self'`), *rate limiting* por IP y
  por usuario, e **idempotencia** en pagos y facturas.
- El CI corre `flutter analyze`, `flutter test`, `tsc`, los tests del servidor y
  un escaneo de secretos con **gitleaks** en cada push.

Ver `SECURITY.md` para el aviso de vulnerabilidades y las reglas del repo.

---

## 🚀 Despliegue

El repositorio ya incluye la configuración de **Vercel** (`vercel.json`,
`api/index.ts` y `.vercelignore`):

- **Backend**: una Function en `api/index.ts` que reutiliza el servidor Fastify
  (`server/src`) y enruta `/api/*` a las rutas del servidor.
- **Frontend**: el build de `build/web` se sirve como estático en el mismo
  dominio, de modo que la app llama a `/api` (mismo origen, sin CORS).

```bash
npm i -g vercel
vercel --prod
```

Variables de entorno necesarias en Vercel (Production): `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`, `GROQ_API_KEY`, `PAYPAL_CLIENT_ID`,
`PAYPAL_CLIENT_SECRET`, `PAYPAL_BASE_URL`, `RESEND_API_KEY`, `NODE_ENV`,
`ALLOWED_ORIGINS`, `PUBLIC_BASE_URL`, `APP_URL`.

---

## 🧪 Tests

```bash
flutter test              # tests de la app
cd server && npm test     # tests del backend
cd server && npm run typecheck
```

## 📄 Licencia

MIT. Ver `LICENSE`.
