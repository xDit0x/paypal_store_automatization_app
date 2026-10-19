# Plan del proyecto — Restock

> App Flutter (web + móvil) para automatizar pedidos de reposición a empresas/proveedores.
> Los productos se identifican por UID y un agente de IA ejecuta la compra y envía la factura.
> Participa en el **PayPal AI Hackathon** (Devpost), cierre **12 de noviembre de 2026, 21:00 CET**.

---

## 1. Contexto del hackathon

- **Requisito principal:** uso significativo de **PayPal** y de **IA**. Si se quita cualquiera de los dos, el proyecto no debe funcionar igual.
- **PayPal:** APIs en **Sandbox** (sin dinero real).
- **IA:** **Groq API** (nivel gratuito) para el agente, detrás de una interfaz configurable por si hace falta Claude/GPT más adelante.
- **Entrega:** repo público con licencia **MIT**, README, vídeo demo de 2–3 minutos, URL web funcional y APK como release de GitHub.
- **APIMatic:** plugin de contexto para la API de PayPal. Lo usaremos durante el desarrollo y lo documentaremos en el README.

---

## 2. Producto

### Nombre provisional
**Restock** (el paquete Flutter puede seguir llamándose `store_automatization_app`).

### Problema
Una tienda local repone stock manualmente: revisa existencias, busca productos en catálogos de proveedores, hace el pedido y paga. Es lento, propenso a errores y se olvidan reposiciones.

### Solución
Una plataforma B2B donde:

1. La tienda ve catálogos de empresas/proveedores.
2. Cada producto tiene un **UID** único (interno o escaneable por QR/código de barras).
3. La tienda crea un pedido manualmente o el **agente de IA** lo propone al detectar stock bajo.
4. El dueño aprueba el pedido (o se auto-aprueba si está dentro de sus reglas de gasto).
5. El bot paga al proveedor con **PayPal** y genera/envía la **factura** automáticamente.
6. Todo queda auditado: quién creó el pedido, qué decidió la IA, cuánto se pagó y en qué estado está.

### Roles
- **Dueño de tienda (usuario principal):** configura reglas de gasto, aprueba pedidos, ve facturas.
- **Empleado (opcional):** puede crear pedidos, pero no aprobar pagos.
- **Proveedor/empresa (catálogo):** en el MVP se simula con datos seed; no se construye su panel.
- **Agente de IA:** propone y ejecuta, pero nunca decide precios ni salta las reglas.

### Flujo principal de la demo
1. El dashboard muestra un producto con stock bajo.
2. Se pulsa **“Ejecutar agente”**.
3. El agente consulta catálogo y stock, propone un pedido y valida el presupuesto.
4. Si supera el límite, el pedido queda **pendiente de aprobación**; el dueño aprueba con un clic.
5. El backend paga al proveedor en **PayPal Sandbox**.
6. Se genera la factura, se envía por email y el pedido pasa a **completado**.
7. La app muestra el timeline completo: propuesta → aprobación → pago → factura.

### Alcance del MVP
- Registro/login y sesión persistente.
- Dashboard con stock bajo, presupuesto usado y pedidos pendientes.
- Proveedores y catálogo de productos con búsqueda/escaneo por UID.
- Creación de pedido manual y pedido propuesto por el agente.
- Reglas de gasto (máximo por pedido, límite mensual, umbral de aprobación).
- Aprobación/rechazo con un clic.
- Pago PayPal Sandbox y webhook de confirmación.
- Factura generada y enviada; descarga en PDF.
- Historial y detalle de pedidos con auditoría.
- Responsive real: móvil, tablet y web.

### Fuera del MVP (recortable)
- Panel completo para proveedores.
- Escaneo RFID/NFC físico (se deja la interfaz preparada).
- Chat conversacional libre con el agente.
- Notificaciones push nativas.
- Multi-tienda, multi-moneda y facturación fiscal real.
- Publicación en App Store / Google Play.

---

## 3. Arquitectura propuesta

### Stack
| Capa | Tecnología | Motivo |
|---|---|---|
| App | Flutter (Android, iOS, Web) | Un solo código; web + APK para el jurado |
| Estado | `flutter_bloc` / Cubits | Igual que `test_flutter` |
| DI | `get_it` | Igual que `test_flutter` |
| Resultados | `dartz` (`Either`) | Igual que `test_flutter` |
| Diseño | `flutter_screenutil` + tema claro/oscuro | Igual que `test_flutter` |
| Tema persistido | `hydrated_bloc` | Igual que `test_flutter` |
| Navegación | `go_router` | URLs reales en web y deep links; `AuthGate` sigue el patrón de `test_flutter` |
| Datos + Auth | **Supabase** (Postgres + Auth + Realtime + Storage) | Auth lista, SQL con RLS y realtime para el estado de pedidos |
| Backend | **TypeScript + Fastify** en Render | PayPal, IA, facturas y webhooks con secretos del lado servidor |
| IA | **Groq API** (`groq-sdk`) con adaptador intercambiable | Nivel gratuito, muy rápido, buen tool calling |
| Pagos | **PayPal Payouts** (principal) + **Invoicing** | Pago servidor-a-servidor automatizable; factura oficial |
| Factura PDF | `pdfkit` + Supabase Storage | Respaldo y descarga desde la app |
| Email | Resend o SendGrid | Envío de factura y avisos |
| Deploy | Render (backend + web estática) + Supabase (datos) | URL pública para el jurado |
| API docs | OpenAPI + APIMatic | Contexto de PayPal y premio de sponsor |

### Por qué Supabase + Groq + backend TypeScript
- Supabase da Auth, PostgreSQL con RLS, Realtime y Storage en un solo servicio; la app Flutter usa `supabase_flutter` directamente para login, catálogo y suscripciones al estado de pedidos.
- Groq es gratis para desarrollar y responde rápido; el agente vive detrás de una interfaz para poder cambiar de modelo.
- El backend TypeScript concentra lo sensible: `PAYPAL_CLIENT_SECRET`, clave de Groq, firma de webhooks, generación de facturas y ejecución de pagos.
- El agente nunca vive en el cliente: el jurado no puede manipular precios ni reglas desde el navegador.

---

## 4. Estructura Flutter (estilo `test_flutter`)

```
lib/
  main.dart
  core/
    configs/
      assets/app_images.dart
      supabase/supabase_config.dart
      theme/app_colors.dart
      theme/app_theme.dart
      usecases/use_case.dart
    constants/
    errors/failures.dart
    network/
    router/app_router.dart
    service_locator.dart
  domain/
    entities/
      store.dart
      supplier.dart
      product.dart
      order.dart
      order_item.dart
      invoice.dart
      spending_rules.dart
      agent_run.dart
    repositories/
      auth_repository/
      supplier_repository/
      product_repository/
      order_repository/
      invoice_repository/
      settings_repository/
      agent_repository/
    usecases/
      auth/
      catalog/
      orders/
      agent/
      settings/
  data/
    models/
    datasources/
      auth_repository/
      supplier_repository/
      product_repository/
      order_repository/
      invoice_repository/
      settings_repository/
      agent_repository/
    repositories/
      auth_repository/
      supplier_repository/
      product_repository/
      order_repository/
      invoice_repository/
      settings_repository/
      agent_repository/
  presentation/
    blocs/
      auth/
      catalog/
      orders/
      agent/
      settings/
      theme/
    pages/
      splash/
      auth/
      dashboard/
      suppliers/
      catalog/
      order/
      orders/
      invoices/
      settings/
    widgets/
  common/
    helpers/is_dark_mode.dart
    widgets/util_snackbar.dart
```

### Patrones que se copian de `test_flutter`
- Separación `domain` / `data` / `presentation` / `core` / `common`.
- `UseCase<T, Params>` y `NoParams` en `core/configs/usecases/`.
- Repositorios abstractos en `domain`, implementaciones en `data`.
- `Either` para errores de negocio, sin lanzar excepciones hacia la UI.
- `GetIt` (`sl`) para registrar repositorios, casos de uso y cubits.
- `AuthGate` que decide splash / login / app según el estado de autenticación.
- `ThemeCubit` con `HydratedCubit<ThemeMode>`.
- `UtilSnackbar`, `PasswordTextField`, `RootPageAppBar` adaptados.
- `ScreenUtilInit(designSize: Size(375, 812))`.

### Diferencias justificadas
- **`go_router`** en lugar de `Navigator.push`: la app se entrega en web y necesita URLs/deep links.
- **`supabase_flutter`** como datasource principal en vez de Firebase.
- **`core/network/`** para el cliente HTTP del backend del agente.
- **`AppShell` responsive**: sidebar en escritorio, bottom navigation en móvil.
- **Modelos con `fromJson`/`toJson` manuales** para mantener el estilo simple de `test_flutter` (sin `freezed` al inicio).

### Paquetes Flutter iniciales
```yaml
flutter_bloc, get_it, dartz, hydrated_bloc, flutter_screenutil,
supabase_flutter, go_router, dio, intl, url_launcher,
mobile_scanner, pdf, printing, path_provider, flutter_secure_storage
```

---

## 5. Backend TypeScript

```
server/
  src/
    config/env.ts
    domain/
      entities/
      repositories/
      rules/spending_rules.ts
    application/
      agent/
        agent_runner.ts
        tools/
        prompts/
      orders/
      auth/verify_supabase_token.ts
    infrastructure/
      paypal/
        paypal_client.ts
        payouts.ts
        invoicing.ts
        webhooks.ts
      ai/
        provider.ts
        groq_provider.ts
      supabase/
        supabase_client.ts
      email/
      invoice/pdf_generator.ts
    interfaces/http/
      routes/
      middlewares/
      server.ts
    jobs/
      poll_pending_orders.ts
  tests/
  .env.example
  package.json
  tsconfig.json
  Dockerfile
```

### Endpoints del backend
| Método | Ruta | Uso |
|---|---|---|
| `POST` | `/agent/run` | Ejecuta el agente para una tienda |
| `POST` | `/orders/:id/approve` | Aprueba y dispara el pago |
| `POST` | `/orders/:id/reject` | Rechaza el pedido |
| `GET` | `/orders/:id/status` | Estado del pago/factura |
| `GET` | `/invoices/:id/pdf` | Descarga la factura |
| `POST` | `/webhooks/paypal` | Confirmación de PayPal (firma verificada) |
| `GET` | `/health` | Health check de Render |

> Lectura de catálogo y pedidos en `draft` van directas a Supabase (RLS).
> Las acciones que mueven dinero pasan siempre por el backend con `service_role`.

### Herramientas del agente
1. `get_low_stock_products`
2. `search_product_by_uid`
3. `get_supplier_catalog`
4. `create_draft_order`
5. `validate_spending_rules`
6. `request_owner_approval`
7. `execute_paypal_payout`
8. `create_and_send_invoice`
9. `get_order_status`

### Guardrails
- La IA **propone**, el código **valida**.
- Precios y stock salen de Supabase, nunca del modelo.
- Límite por pedido, límite mensual y lista de proveedores permitidos.
- Aprobación obligatoria por encima del umbral configurado.
- `idempotencyKey` en cada pago para no pagar dos veces.
- Registro de cada ejecución (`AgentRun`) con modelo, herramientas y decisión.
- Si el modelo falla o devuelve datos inválidos, se cae a un flujo determinista.

### Proveedor de IA configurable
```env
AI_PROVIDER=groq
AI_MODEL=llama-3.3-70b-versatile
GROQ_API_KEY=gsk_...
```
Cambiar de modelo es cambiar esas variables. Las reglas críticas no dependen del modelo.

---

## 6. Modelo de datos (Supabase / PostgreSQL)

### `stores`
| Columna | Tipo | Nota |
|---|---|---|
| `id` | uuid pk | `gen_random_uuid()` |
| `owner_id` | uuid | referencia `auth.users(id)` |
| `name` | text | |
| `currency` | text | por defecto `EUR` |
| `paypal_merchant_email` | text | |
| `notification_email` | text | |
| `created_at` / `updated_at` | timestamptz | |

### `spending_rules`
`store_id` (pk, fk), `max_per_order`, `monthly_limit`, `require_approval_above`, `allowed_supplier_ids uuid[]`.

### `suppliers`
`id` (pk), `name`, `paypal_email`, `category`, `logo_url`, `active`.

### `products`
`id` (pk), `uid` (text único), `supplier_id` (fk), `name`, `description`, `price`, `currency`, `stock`, `low_stock_threshold`, `unit`, `image_url`, `active`.

### `orders`
`id` (pk), `store_id` (fk), `supplier_id` (fk), `created_by_type` (`user`/`agent`), `created_by_id` (uuid), `subtotal`, `total`, `status` (enum), `approval_by`, `approval_at`, `payment_provider`, `payment_payout_id`, `payment_status`, `payment_at`, `invoice_id`, `agent_run_id`, `created_at`, `updated_at`.

### `order_items`
`id` (pk), `order_id` (fk), `product_uid`, `name`, `qty`, `unit_price`, `line_total`.

### `invoices`
`id` (pk), `order_id` (fk), `number`, `pdf_url`, `status`, `sent_to`, `sent_at`, `created_at`.

### `agent_runs`
`id` (pk), `store_id` (fk), `order_id` (fk), `provider`, `model`, `tool_calls jsonb`, `decision`, `confidence`, `created_at`.

### Máquina de estados
```
draft
  └─> pending_approval
        ├─> approved ─> paying ─> paid ─> invoiced ─> completed
        ├─> rejected
        └─> payment_failed
```

---

## 7. UIDs de producto

- Cada producto tiene un `uid` único e inmutable (`PRD-000123`, UUID o SKU del proveedor).
- Búsqueda por UID en catálogo y en la pantalla de creación de pedido.
- En móvil, escaneo de **QR/código de barras** que contiene el UID (`mobile_scanner`).
- La interfaz `ProductRepository.findByUid(uid)` queda preparada para RFID/NFC en el futuro.
- El agente también busca por UID; así el pedido siempre referencia un producto real y un precio validado.

---

## 8. Seguridad

- Secretos solo en el backend (`PAYPAL_CLIENT_SECRET`, `GROQ_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, email). Nunca en Flutter ni en el repo.
- `.env` ignorado por git; `.env.example` documentado.
- Supabase Auth con email/contraseña + cuenta demo para el jurado.
- La app usa la `anon key` (pública) y **RLS**; el backend usa `service_role` (nunca en el cliente).
- Políticas RLS: cada tienda solo accede a sus pedidos; catálogo de solo lectura para autenticados.
- Verificación del **JWT de Supabase** en cada endpoint protegido.
- Verificación de la firma de los webhooks de PayPal.
- Idempotencia en pagos y facturas.
- Rate limiting en `/agent/run` y endpoints de pago.
- Auditoría de todas las acciones del agente.
- Nunca se guardan datos de tarjetas ni credenciales de PayPal en la app.

---

## 9. Plan por fases

### Fase 0 — Decisiones y cuentas (19–20 oct)
- [x] Decidir backend de datos y IA: **Supabase + Groq**.
- [ ] Crear proyecto Supabase (Auth + Postgres) y cuenta demo.
- [ ] Comprobar PayPal Sandbox: Payouts e Invoicing.
- [ ] Instalar el plugin de APIMatic y reclamar el mes gratuito.
- [ ] Comprobar la API de Groq con una llamada de prueba.
- [ ] Crear `.env.example` y configurar Render.
- [ ] Publicar datos seed (proveedores, productos con UID, stock bajo).

### Semana 1 — Base de la app (21–25 oct)
- [ ] Scaffold Flutter con la estructura de la sección 4.
- [ ] Tema claro/oscuro, `ScreenUtil`, `ThemeCubit`, `AppShell` responsive.
- [ ] `AuthGate`, splash, login, registro y cuenta demo con Supabase Auth.
- [ ] DI con `get_it`, router con `go_router`.
- [ ] Modelos y repositorios de proveedores/productos.
- [ ] Dashboard inicial + catálogo + búsqueda/escaneo por UID.
- [ ] Backend: esqueleto Fastify, health check, verificación de JWT de Supabase.
- [ ] Smoke test de PayPal (crear pago sandbox y ver webhook).

### Semana 2 — Pedido, agente y pago (26 oct–1 nov)
- [ ] Creación de pedido manual (carrito + validación de precios).
- [ ] Reglas de gasto y pantalla de aprobación.
- [ ] Agente con herramientas y Groq.
- [ ] Pago con PayPal Payouts + idempotencia.
- [ ] Factura con PayPal Invoicing + PDF de respaldo.
- [ ] Webhook de PayPal y actualización de estado en tiempo real (Supabase Realtime).
- [ ] Historial, detalle y auditoría de pedidos.
- [ ] Pruebas de casos felices y fallos (sin saldo, pago duplicado, webhook inválido).
- [ ] Comparativa de modelos con 10 conversaciones (Groq vs Claude/GPT).

### Semana 3 — Pulido y entrega (2–8 nov)
- [ ] Responsive final (web, tablet, móvil).
- [ ] Estados vacíos, errores, loaders y accesibilidad.
- [ ] Deploy del backend y de la web en Render.
- [ ] Build de APK y release en GitHub.
- [ ] README completo: arquitectura, setup, demo, PayPal, IA, APIMatic.
- [ ] Guion y grabación del vídeo (2–3 min).
- [ ] Prueba de extremo a extremo con una cuenta nueva.

### Semana 4 — Cierre (9–12 nov)
- [ ] Congelar features (solo bugs).
- [ ] Verificar URL, APK, repo público y licencia MIT.
- [ ] Revisar criterios de Devpost y form de entrega.
- [ ] Subir vídeo y enviar antes del **12 nov, 21:00 CET**.
- [ ] Plan B: vídeo grabado y demo local si un servicio falla.

---

## 10. Criterios de aceptación del MVP

La demo se considera terminada cuando un jurado puede:

1. Abrir la URL web (o instalar la APK).
2. Entrar con `demo@restock.app` / contraseña demo.
3. Ver stock bajo y presupuesto disponible.
4. Ejecutar el agente y ver la propuesta de pedido.
5. Aprobar el pedido con un clic.
6. Ver el pago completado en PayPal Sandbox.
7. Descargar/ver la factura generada y enviada.
8. Ver el timeline completo y el registro de auditoría.
9. Entender en el README qué parte es IA, qué parte es PayPal y cómo se usó APIMatic.

---

## 11. Riesgos y recortes

| Riesgo | Mitigación |
|---|---|
| Payouts no disponible en el sandbox/país | Plan B: Invoicing + Orders; dejar el proveedor de pago abstraído |
| Groq falla con tool calling | Validación determinista + fallback; cambiar de modelo solo para la demo |
| Supabase tarda en configurarse | Datasource mock en Flutter; backend con datos en memoria |
| Web Flutter pesa mucho | Assets ligeros, tree-shaking, evitar paquetes innecesarios |
| Falta de tiempo | Recortar escaneo QR, panel de proveedor, chat libre y notificaciones |
| El jurado no puede probar | Cuenta demo, datos seed, web pública, APK y README paso a paso |
| Webhook no llega en local | Túnel (ngrok) y endpoint de conciliación manual |
| Doble pago | Idempotencia y bloqueo por estado del pedido |

---

## 12. Decisiones

1. **Perspectiva del producto:** tienda que compra a proveedores (Restock).
2. **Datos:** **Supabase** (Postgres + Auth + Realtime). *(decidido)*
3. **IA:** **Groq** con adaptador intercambiable. *(decidido)*
4. **Pago:** PayPal Payouts (principal) o Orders API (requiere aprobación del comprador).
5. **Nombre:** mantener `store_automatization_app` en el paquete y usar **Restock** como marca.
6. **Cuenta demo:** email y contraseña que se publicarán en el README.

---

## 13. Primeros pasos inmediatos

1. Crear el proyecto Supabase y copiar `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
2. Ejecutar `supabase/migrations` y `supabase/seed.sql`.
3. Configurar `.env` del backend (`SUPABASE_SERVICE_ROLE_KEY`, `GROQ_API_KEY`, PayPal sandbox).
4. Implementar la estructura Flutter y el tema.
5. Cargar datos seed y hacer el primer pedido de prueba.
6. Probar un pago sandbox de extremo a extremo antes de construir la UI completa.
