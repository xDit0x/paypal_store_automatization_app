# Stocky

**Automatic restocking for stores: an AI agent checks stock, prepares orders to
your suppliers and pays them with PayPal, always within the spending rules you
set.**

It participates in the [PayPal AI Hackathon](https://devpost.com/) using the
**PayPal** API (Sandbox) and a **Groq** AI model.

| Layer | Technology | What it provides |
|---|---|---|
| **App** | Flutter (web, Android, iOS) | A single codebase for the jury and the APK. Reads Supabase with the `anon key` and **RLS**: each user only sees their own store. |
| **Backend** | TypeScript + Fastify (Node 22) | The **only** component that moves money. Stores the secrets (PayPal, AI, `service_role`), recalculates each order from the catalog and re-checks your spending rules before paying. |
| **Data** | Supabase (Postgres + Auth + Realtime) | Schema and RLS policies in `supabase/migrations/`. |
| **AI** | Groq (`groq-sdk`) with swappable adapter | The agent uses *tool calling* against the real catalog. Switching models is changing an environment variable. |
| **Payments** | PayPal Orders + Payouts + Invoicing (Sandbox) | Buyer authorization, supplier payout and official invoice. |
| **Deploy** | Vercel (web + Functions) + Supabase | One domain for frontend and API: `https://stocky-app-theta.vercel.app`. |

---

## 🚀 Try it in 30 seconds (no install)

**Demo URL:** <https://stocky-app-theta.vercel.app>

| | |
|---|---|
| **User** | `demo@restock.dev` |
| **Password** | `Restock2026!` |

> The demo uses **PayPal Sandbox**: no real money moves. Payments are visible at
> <https://sandbox.paypal.com>.

### Suggested walkthrough for the jury

1. **Sign in** with the account above (the app is in Spanish and English; you
   can switch languages on the login screen itself).
2. Open the **Assistant** tab and tap the suggestion **"Revisa el stock ahora"**
   (or type "check my stock"). The agent reads the store's real catalog,
   decides what to restock and **creates the order** — with the AI choosing the
   product and the supplier.
3. Open the **Orders** tab: you'll see the order created by the agent, marked
   **"Lo preparó el agente"**, with the detail of what it decided.
4. Tap **"Aprobar y pagar con PayPal"**. If the amount exceeds your spending
   rules, the agent explains it and **leaves the order pending**: you decide.
5. **PayPal Sandbox** opens for authorization. Once authorized, the app returns
   to PayPal, confirms the status and reflects it in the order.
6. On delivery you can register the delivery note (photo or manual) and the app
   computes what's left to charge. The **invoice** is generated and sent by email.

You can also ask the agent things like *"how much have I spent?"* or
*"what do I have pending approval?"*, and use **voice** (dictation with Whisper
on the server and text-to-speech).

---

## 🖥️ Run it locally

### Requirements

- Flutter 3.47.7 (stable)
- Node.js 22
- A Supabase project and a PayPal Sandbox account

### 1. Dependencies

```bash
git clone https://github.com/xDit0x/paypal_store_automatization_app.git
cd paypal_store_automatization_app
flutter pub get
cd server && npm ci && cd ..
```

### 2. Environment variables

```bash
cp .env.example .env                 # Flutter -> dart_defines.json
cp server/.env.example server/.env   # backend
```

Fill `server/.env` with your keys (**never committed**, they're in `.gitignore`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...        # backend only
GROQ_API_KEY=gsk_...                 # https://console.groq.com
PAYPAL_CLIENT_ID=...                 # https://developer.paypal.com (sandbox)
PAYPAL_CLIENT_SECRET=...
PAYPAL_BASE_URL=https://api-m.sandbox.paypal.com
RESEND_API_KEY=...                   # optional: invoice emails
ALLOWED_ORIGINS=http://localhost:3000
```

And `dart_defines.json` for the app:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "...",
  "AGENT_API_URL": "http://localhost:3000"
}
```

### 3. Database

Apply the files in `supabase/migrations/` in the Supabase **SQL Editor**, then
`supabase/seed.sql` (suppliers, catalog with UID, sample data).

```bash
cd server
npm run demo:user      # creates the demo account
npm run reset:demo -- --yes   # (optional) leaves the demo in a clean state
```

### 4. Backend and app

```bash
# Terminal 1 — backend at http://localhost:3000
cd server && npm run dev

# Terminal 2 — app
flutter run --dart-define-from-file=dart_defines.json
```

### 5. Publish the web app (optional)

```bash
flutter build web --no-web-resources-cdn \
  --dart-define-from-file=dart_defines.json

python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

> `--no-web-resources-cdn` forces Flutter to serve CanvasKit and fonts **from
> the build itself** instead of `gstatic.com`. Essential on networks without
> access to Google Fonts.

### Emulator or physical device (Android / iOS)

The app and backend are the same as on web; only how the app points at the
backend and how it's packaged change.

#### 1. Prepare `dart_defines.json` for the device

The backend runs on your machine (or on Vercel). The device can't use the
host's `localhost`, so adjust `AGENT_API_URL`:

| Where the app runs | `AGENT_API_URL` value |
|---|---|
| Android emulator | `http://10.0.2.2:3000` (host alias in the emulator) |
| iOS / macOS simulator | `http://localhost:3000` |
| Physical device (same Wi-Fi) | `http://YOUR_LAN_IP:3000` (e.g. `http://192.168.18.134:3000`) |
| Production (Vercel) | `/api` or `https://stocky-app-theta.vercel.app/api` |

Example for the Android emulator (`dart_defines.json`):

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "AGENT_API_URL": "http://10.0.2.2:3000"
}
```

> 🔒 **Security**: `dart_defines.json` is in `.gitignore`. **Never** commit it
> or share it: it contains the `anon key`. Pass it through a secure channel (or
> use individual `--dart-define` flags in the terminal).

#### 2. Start the backend on the host

```bash
cd server && npm run dev   # http://localhost:3000
```

The backend listens on `0.0.0.0:3000` (configured in `src/index.ts`), so it's
reachable from the emulator and the local network.

#### 3. Launch the app on the emulator

```bash
# List available devices
flutter devices

# Android emulator (make sure it's booted)
flutter run -d emulator-5554 \
  --dart-define-from-file=dart_defines.json

# iOS simulator
flutter run -d "iPhone 15" \
  --dart-define-from-file=dart_defines.json
```

> On mobile, UID scanning by QR/barcode uses the real device camera; in the
> emulator the camera is virtual and scanning may not work. Test that part on a
> physical device.

#### 4. Package the APK (to deliver to the jury)

```bash
flutter build apk --release \
  --dart-define-from-file=dart_defines.json

# The APK ends up at:
# build/app/outputs/flutter-apk/app-release.apk
```

Upload it as a **GitHub release** (don't commit it: `build/` is in
`.gitignore`). Reviewers install it with:
```
adb install app-release.apk
```
or by opening it directly on the phone.

#### 5. Security notes for the emulator

- The Supabase `anon key` is public by design and ships inside the app binary;
  the real protection is **RLS** in Postgres. Even so, never publish
  `dart_defines.json` or the backend `.env`.
- If you use a physical device on a shared network, remember the backend is
  exposed on port 3000 of your machine while `npm run dev` is running. Stop it
  when you finish testing.
- For production, point `AGENT_API_URL` at `https://stocky-app-theta.vercel.app/api`
  (or your own domain) and don't leave the local backend exposed.

---

## 🧠 How the agent works

The agent **proposes**; the code **validates**. Today the model exposes a single
tool — `create_restock_order(supplier_id, items[])` — and all validation
(prices, stock, spending rules, idempotency) happens in the backend, which reads
the real catalog from Supabase.

Guardrails:

- **Prices and stock** come from Supabase, never from the model.
- Per-order limit, monthly limit and allowed-supplier list.
- **Mandatory approval** above the configured threshold.
- `idempotencyKey` on every payment: no double charges.
- Every run is recorded (`agent_runs`) with model, tools and decision.
- If the model fails or returns invalid data, it falls back to a deterministic flow.

### Backend API

| Method | Route | Use |
|---|---|---|
| `POST` | `/agent/run` | Runs the agent for a store |
| `POST` | `/orders/:id/approve` | Approves and triggers payment |
| `POST` | `/orders/:id/reject` | Rejects the order |
| `GET` | `/orders/:id/status` | Payment and invoice status |
| `GET` | `/orders/:id/amount` | Amount recalculated from the catalog |
| `GET` | `/orders/:id/approve-url` | PayPal authorization link |
| `POST` | `/orders/:id/confirm-auth` | Confirmation after authorizing on PayPal |
| `POST` | `/orders/:id/capture` | Capture after confirming delivery |
| `POST` | `/orders/:id/refund` | Refund |
| `GET` | `/assistant/message` | Conversation with the assistant |
| `GET` | `/health` | Health check |

> Catalog reads and `draft` orders go straight to Supabase (RLS). **Actions that
> move money always go through the backend** with `service_role`.

---

## 🔐 Security

- The client (Flutter) uses **only** the Supabase `anon key` and RLS: each user
  only sees and touches their own store's data.
- `SUPABASE_SERVICE_ROLE_KEY`, `PAYPAL_CLIENT_SECRET` and `GROQ_API_KEY` live
  **only** in the backend (Vercel environment variables). They are not compiled
  into the web app and are not pushed to the repository.
- Verification of the **Supabase JWT** on every protected endpoint and
  **PayPal signature** verification on webhooks.
- **CSP** in `web/index.html` (`default-src 'self'`), per-IP and per-user
  **rate limiting**, and **idempotency** on payments and invoices.
- CI runs `flutter analyze`, `flutter test`, `tsc`, the server tests and a
  secret scan with **gitleaks** on every push.

See `SECURITY.md` for the vulnerability disclosure policy and repo rules.

---

## 🚀 Deploy

The repository already includes the **Vercel** configuration (`vercel.json`,
`api/index.ts` and `.vercelignore`):

- **Backend**: a Function in `api/index.ts` that reuses the Fastify server
  (`server/src`) and routes `/api/*` to the server routes.
- **Frontend**: the `build/web` build is served as static assets on the same
  domain, so the app calls `/api` (same origin, no CORS).

```bash
npm i -g vercel
vercel --prod
```

Environment variables required in Vercel (Production): `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`, `GROQ_API_KEY`, `PAYPAL_CLIENT_ID`,
`PAYPAL_CLIENT_SECRET`, `PAYPAL_BASE_URL`, `RESEND_API_KEY`, `NODE_ENV`,
`ALLOWED_ORIGINS`, `PUBLIC_BASE_URL`, `APP_URL`.

---

## 🧪 Tests

```bash
flutter test              # app tests
cd server && npm test     # backend tests
cd server && npm run typecheck
```

## 📄 License

MIT. See `LICENSE`.

---

---

# Stocky (Español)

**Reposición automática para tiendas: un agente de IA revisa el stock, prepara
pedidos a tus proveedores y los paga con PayPal, siempre dentro de las reglas
de gasto que tú marcas.**

Participa en el [PayPal AI Hackathon](https://devpost.com/) con la API de
**PayPal** (Sandbox) y un modelo de IA de **Groq**.

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
luego `supabase/seed.sql` (proveedores, catálogo con UID, datos de ejemplo).

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

### Emulador o dispositivo físico (Android / iOS)

La app y el backend son los mismos que en web; solo cambia cómo apunta la app
al backend y cómo se empaqueta.

#### 1. Prepara `dart_defines.json` para el dispositivo

El backend corre en tu máquina (o en Vercel). El dispositivo no puede usar
`localhost` del host, así que ajusta `AGENT_API_URL`:

| Dónde corre la app | Valor de `AGENT_API_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:3000` (alias del host en el emulador) |
| Simulador iOS / macOS | `http://localhost:3000` |
| Dispositivo físico (misma red Wi-Fi) | `http://TU_IP_LAN:3000` (ej. `http://192.168.18.134:3000`) |
| Producción (Vercel) | `/api` o `https://stocky-app-theta.vercel.app/api` |

Ejemplo para emulador Android (`dart_defines.json`):

```json
{
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_ANON_KEY": "tu-anon-key",
  "AGENT_API_URL": "http://10.0.2.2:3000"
}
```

> 🔒 **Seguridad**: `dart_defines.json` está en `.gitignore`. **Nunca** lo
> subas al repositorio ni lo compartas: contiene la `anon key`. Pásalo por
> un canal seguro (o usa `--dart-define` individual en la terminal).

#### 2. Arranca el backend en el host

```bash
cd server && npm run dev   # http://localhost:3000
```

El backend escucha en `0.0.0.0:3000` (configurado en `src/index.ts`), así que
es accesible desde el emulador y desde la red local.

#### 3. Lanza la app en el emulador

```bash
# Listar dispositivos disponibles
flutter devices

# Emulador Android (asegúrate de que esté arrancado)
flutter run -d emulator-5554 \
  --dart-define-from-file=dart_defines.json

# Simulador iOS
flutter run -d "iPhone 15" \
  --dart-define-from-file=dart_defines.json
```

> En móvil, el escaneo de UID por QR/código de barras usa la cámara real del
> dispositivo; en el emulador la cámara es virtual y el escaneo puede no
> funcionar. Para probar esa parte usa un dispositivo físico.

#### 4. Empaquetar la APK (para entregar al jurado)

```bash
flutter build apk --release \
  --dart-define-from-file=dart_defines.json

# La APK queda en:
# build/app/outputs/flutter-apk/app-release.apk
```

Súbela como **release de GitHub** (no la subas al repositorio: `build/` está
en `.gitignore`). Los revisores la instalan con:
```
adb install app-release.apk
```
o abriéndola directamente en el móvil.

#### 5. Notas de seguridad para el emulador

- La `anon key` de Supabase es pública por diseño y va en el binario de la
  app; la protección real la hace **RLS** en Postgres. Aun así, no publiques
  `dart_defines.json` ni el `.env` del backend.
- Si usas un dispositivo físico en una red compartida, recuerda que el backend
  queda expuesto en el puerto 3000 de tu máquina mientras `npm run dev` esté
  corriendo. Ciérralo cuando termines de probar.
- Para producción, apunta `AGENT_API_URL` a `https://stocky-app-theta.vercel.app/api`
  (o a tu dominio propio) y no dejes el backend local expuesto.

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
