# Plan del proyecto — Restock

> App Flutter (web + móvil) para automatizar pedidos de reposición a empresas/proveedores.
> Los productos se identifican por UID y un agente de IA ejecuta la compra y envía la factura.
> Participa en el **PayPal AI Hackathon** (Devpost), cierre **12 de noviembre de 2026, 21:00 CET**.

---

## 1. Contexto del hackathon

- **Requisito principal:** uso significativo de **PayPal** y de **IA**. Si se quita cualquiera de los dos, el proyecto no debe funcionar igual.
- **PayPal:** APIs en **Sandbox** (sin dinero real).
- **IA:** cualquier proveedor. Empezamos con **Groq/Gemini** (nivel gratuito) y dejamos el proveedor configurable para pasar a **Claude/GPT** solo si hace falta.
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
| Datos | **Firebase Auth + Cloud Firestore** | Rápido, tiempo real y ya conocido en `test_flutter` |
| Backend | **TypeScript + Fastify** en Render | PayPal, IA, facturas y webhooks con secretos del lado servidor |
| IA | Adaptador configurable (`groq`, `gemini`, `anthropic`, `openai`) | Empezar gratis y cambiar sin tocar el resto |
| Pagos | **PayPal Payouts** (principal) + **Invoicing** | Pago servidor-a-servidor automatizable; factura oficial |
| Factura PDF | `pdfkit` + almacenamiento temporal | Respaldo y descarga desde la app |
| Email | Resend o SendGrid | Envío de factura y avisos |
| Deploy | Render (backend) + Firebase Hosting (web) | URL pública para el jurado |
| API docs | OpenAPI + APIMatic | Contexto de PayPal y premio de sponsor |

### Por qué Firebase + backend TypeScript
- La app usa Firebase directamente para auth y datos: menos CRUD que programar y coincide con `test_flutter`.
- El backend TypeScript concentra lo sensible: `PAYPAL_CLIENT_SECRET`, claves de IA, firma de webhooks, generación de facturas y ejecución de pagos.
- El agente nunca vive en el cliente: el jurado no puede manipular precios ni reglas desde el navegador.
- Si más adelante se quiere un backend único con Postgres, las interfaces de repositorio de Flutter permiten cambiar la implementación sin rehacer la app.

---

## 4. Estructura Flutter (estilo `test_flutter`)

```
lib/
  main.dart
  firebase_options.dart
  core/
    configs/
      assets/app_images.dart
      theme/app_colors.dart
      theme/app_theme.dart
    constants/
    errors/failures.dart
    router/app_router.dart
    service_locator.dart
    usecases/use_case.dart
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
      auth_repository.dart
      supplier_repository.dart
      product_repository.dart
      order_repository.dart
      invoice_repository.dart
      settings_repository.dart
      agent_repository.dart
    usecases/
      auth/
      catalog/
      orders/
      agent/
      settings/
  data/
    models/            # fromJson/toJson de cada entidad
    datasources/
      remote/          # Firestore, backend del agente
    repositories/      # implementaciones de los repositorios
  presentation/
    blocs/
      auth/
      catalog/
      orders/
      agent/
      settings/
      theme/           # ThemeCubit hidratado
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
      app_shell.dart   # navegación responsive
      app_button.dart
      app_text_field.dart
      money_text.dart
      status_chip.dart
      empty_state.dart
      error_view.dart
      loading_view.dart
  common/
    helpers/is_dark_mode.dart
    widgets/util_snackbar.dart
```

### Patrones que se copian de `test_flutter`
- Separación `domain` / `data` / `presentation` / `core` / `common`.
- `UseCase<T, Params>` y `NoParams`.
- Repositorios abstractos en `domain`, implementaciones en `data`.
- `Either` para errores de negocio, sin lanzar excepciones hacia la UI.
- `GetIt` (`sl`) para registrar repositorios, casos de uso y cubits.
- `AuthGate` que decide splash / login / app según el estado de autenticación.
- `ThemeCubit` con `HydratedCubit<ThemeMode>`.
- `UtilSnackbar`, `PasswordTextField`, `RootPageAppBar` adaptados.
- `ScreenUtilInit(designSize: Size(375, 812))`.

### Diferencias justificadas
- **`go_router`** en lugar de `Navigator.push`: la app se entrega en web y necesita URLs/deep links.
- **Dio/HTTP** para el backend del agente, además de Firestore.
- **`AppShell` responsive**: sidebar en escritorio, bottom navigation en móvil.
- **Modelos con `fromJson`/`toJson` manuales** para mantener el estilo simple de `test_flutter` (sin `freezed` al inicio).

### Paquetes Flutter iniciales
```yaml
flutter_bloc, get_it, dartz, hydrated_bloc, flutter_screenutil,
firebase_core, firebase_auth, cloud_firestore, go_router, dio,
intl, url_launcher, mobile_scanner, pdf, printing, path_provider,
flutter_secure_storage
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
        approve_order.ts
        execute_payment.ts
        generate_invoice.ts
      auth/verify_firebase_token.ts
    infrastructure/
      paypal/
        paypal_client.ts
        payouts.ts
        invoicing.ts
        webhooks.ts
      ai/
        provider.ts
        groq_provider.ts
        gemini_provider.ts
        anthropic_provider.ts
        openai_provider.ts
      firebase/
        firestore_repository.ts
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

> Los pedidos en estado `draft` y la lectura de catálogo se hacen contra Firestore.
> Las acciones que mueven dinero pasan siempre por el backend.

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
- Precios y stock salen de Firestore, nunca del modelo.
- Límite por pedido, límite mensual y lista de proveedores permitidos.
- Aprobación obligatoria por encima del umbral configurado.
- `idempotencyKey` en cada pago para no pagar dos veces.
- Registro de cada ejecución (`AgentRun`) con modelo, herramientas y decisión.
- Si el modelo falla o devuelve datos inválidos, se cae a un flujo determinista.

### Proveedor de IA configurable
```env
AI_PROVIDER=groq
AI_MODEL=llama-3.3-70b-versatile
```
Cambiar a Claude u OpenAI es cambiar esas dos variables. Las reglas críticas no dependen del modelo.

---

## 6. Modelo de datos (Firestore)

### `stores/{storeId}`
```json
{
  "name": "Bodega Centro",
  "ownerUid": "firebase-uid",
  "currency": "EUR",
  "paypalMerchantEmail": "seller@example.com",
  "notificationEmail": "owner@example.com",
  "spendingRules": {
    "maxPerOrder": 200,
    "monthlyLimit": 800,
    "requireApprovalAbove": 50,
    "allowedSupplierIds": ["sup_1", "sup_2"]
  }
}
```

### `suppliers/{supplierId}`
```json
{
  "name": "Distribuidora Andina",
  "paypalEmail": "pagos@andina.example",
  "category": "Abarrotes",
  "logoUrl": "...",
  "active": true
}
```

### `products/{productId}`
```json
{
  "uid": "PRD-000123",
  "supplierId": "sup_1",
  "name": "Leche entera 1L",
  "description": "...",
  "price": 1.15,
  "currency": "EUR",
  "stock": 6,
  "lowStockThreshold": 10,
  "unit": "unidad",
  "imageUrl": "...",
  "active": true
}
```

### `orders/{orderId}`
```json
{
  "storeId": "store_1",
  "supplierId": "sup_1",
  "createdBy": { "type": "agent", "uid": null },
  "items": [
    { "productUid": "PRD-000123", "name": "Leche entera 1L", "qty": 24, "unitPrice": 1.15 }
  ],
  "subtotal": 27.6,
  "total": 27.6,
  "status": "pending_approval",
  "approval": { "by": "firebase-uid", "at": "timestamp" },
  "payment": { "provider": "paypal", "payoutId": "...", "status": "paid", "at": "timestamp" },
  "invoice": { "id": "...", "number": "INV-2026-001", "pdfUrl": "...", "sentAt": "timestamp" },
  "agentRunId": "run_1",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### `agent_runs/{runId}`
```json
{
  "storeId": "store_1",
  "orderId": "order_1",
  "provider": "groq",
  "model": "llama-3.3-70b-versatile",
  "toolCalls": [],
  "decision": "propose_order",
  "confidence": 0.92,
  "createdAt": "timestamp"
}
```

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

- Secretos solo en el backend (`PAYPAL_CLIENT_SECRET`, claves de IA, email). Nunca en Flutter ni en el repo.
- `.env` ignorado por git; `.env.example` documentado.
- Firebase Auth con email/contraseña + cuenta demo para el jurado.
- Verificación del **ID token de Firebase** en cada endpoint protegido.
- Firestore Rules: cada tienda solo accede a sus documentos; catálogo de solo lectura para autenticados.
- Verificación de la firma de los webhooks de PayPal.
- Idempotencia en pagos y facturas.
- Rate limiting en `/agent/run` y endpoints de pago.
- Auditoría de todas las acciones del agente.
- Nunca se guardan datos de tarjetas ni credenciales de PayPal en la app.

---

## 9. Plan por fases

### Fase 0 — Decisiones y cuentas (19–20 oct)
- [ ] Confirmar las decisiones pendientes de la sección 13.
- [ ] Crear proyecto Firebase (Auth + Firestore) y cuenta demo.
- [ ] Comprobar PayPal Sandbox: Payouts e Invoicing.
- [ ] Instalar el plugin de APIMatic y reclamar el mes gratuito.
- [ ] Crear `.env.example` y configurar Render.
- [ ] Publicar datos seed (proveedores, productos con UID, stock bajo).

### Semana 1 — Base de la app (21–25 oct)
- [ ] Scaffold Flutter con la estructura de la sección 4.
- [ ] Tema claro/oscuro, `ScreenUtil`, `ThemeCubit`, `AppShell` responsive.
- [ ] `AuthGate`, splash, login, registro y cuenta demo.
- [ ] DI con `get_it`, router con `go_router`.
- [ ] Modelos y repositorios de proveedores/productos.
- [ ] Dashboard inicial + catálogo + búsqueda/escaneo por UID.
- [ ] Backend: esqueleto Fastify, health check, verificación de token.
- [ ] Smoke test de PayPal (crear pago sandbox y ver webhook).

### Semana 2 — Pedido, agente y pago (26 oct–1 nov)
- [ ] Creación de pedido manual (carrito + validación de precios).
- [ ] Reglas de gasto y pantalla de aprobación.
- [ ] Agente con herramientas y proveedor configurable.
- [ ] Pago con PayPal Payouts + idempotencia.
- [ ] Factura con PayPal Invoicing + PDF de respaldo.
- [ ] Webhook de PayPal y actualización de estado en tiempo real.
- [ ] Historial, detalle y auditoría de pedidos.
- [ ] Pruebas de casos felices y fallos (sin saldo, pago duplicado, webhook inválido).
- [ ] Comparativa de modelos con 10 conversaciones (Groq vs Claude/GPT).

### Semana 3 — Pulido y entrega (2–8 nov)
- [ ] Responsive final (web, tablet, móvil).
- [ ] Estados vacíos, errores, loaders y accesibilidad.
- [ ] Deploy del backend en Render y de la web en Firebase Hosting.
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
| El modelo gratuito falla con tool calling | Validación determinista + fallback; cambiar a Claude/GPT solo para la demo |
| Firebase tarda en configurarse | Datasource mock en Flutter; backend con datos en memoria |
| Web Flutter pesa mucho | Assets ligeros, tree-shaking, evitar paquetes innecesarios |
| Falta de tiempo | Recortar escaneo QR, panel de proveedor, chat libre y notificaciones |
| El jurado no puede probar | Cuenta demo, datos seed, web pública, APK y README paso a paso |
| Webhook no llega en local | Túnel (ngrok) y endpoint de conciliación manual |
| Doble pago | Idempotencia y bloqueo por estado del pedido |

---

## 12. Decisiones pendientes de confirmar

1. **Perspectiva del producto:** tienda que compra a proveedores (recomendado, alineado con Restock) o clientes que compran a empresas.
2. **Datos:** Firebase Auth + Firestore (recomendado) o backend único TypeScript + Postgres.
3. **Pago:** PayPal Payouts (recomendado para automatización) o Orders API (requiere aprobación del comprador).
4. **Nombre:** mantener `store_automatization_app` en el paquete y usar **Restock** como marca, o renombrar todo a `restock`.
5. **Cuenta demo:** email y contraseña que se publicarán en el README.

---

## 13. Primeros pasos inmediatos

1. Confirmar las 5 decisiones de la sección 12.
2. Crear el proyecto Firebase y pegar `google-services.json` / `GoogleService-Info.plist` (sin subir secretos).
3. Implementar la estructura Flutter y el tema.
4. Crear el esqueleto del backend y el `.env.example`.
5. Cargar datos seed y hacer el primer pedido de prueba.
6. Probar un pago sandbox de extremo a extremo antes de construir la UI completa.
