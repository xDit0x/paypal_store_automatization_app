# Restock

Reposición automática para tiendas: un agente de IA revisa el stock, prepara
pedidos a tus proveedores y los paga con PayPal, siempre dentro de las reglas
de gasto que tú marcas.

- **App (Flutter)** en `lib/`: iOS, Android y web. Usa la `anon key` de
  Supabase y RLS; cada usuario solo ve su tienda.
- **Backend (Fastify + TypeScript)** en `server/`: es el único que mueve
  dinero. Guarda los secretos (PayPal, IA, `service_role`), recalcula el
  importe de cada pedido desde el catálogo y vuelve a comprobar tus reglas
  antes de pagar.
- **Esquema y RLS** en `supabase/migrations/`.

## Puesta en marcha

```bash
# 1. Dependencias
flutter pub get
cd server && npm ci && cd ..

# 2. Variables de entorno (copia los ejemplos y rellénalos)
cp .env.example .env                 # Flutter -> dart_defines.json
cp server/.env.example server/.env   # backend

# 3. Backend
cd server && npm run dev              # http://localhost:3000

# 4. App
flutter run --dart-define-from-file=dart_defines.json
```

`.env`, `dart_defines.json` y `server/.env` están en `.gitignore`: **nunca**
subas claves al repositorio.

### Si tras añadir un paquete nativo falla al arrancar

Un error del tipo `Couldn't resolve native function '...'` con
`Available native assets: package:objective_c/objective_c.dylib` significa que
el build está reutilizando un manifiesto de native assets antiguo. Un hot
restart **no** vuelve a compilar esos assets: hace falta un build limpio.

```bash
flutter clean && flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

## Antes de publicar

- `ALLOWED_ORIGINS` con los orígenes reales (en producción el CORS bloquea
  cualquier otro) y `AGENT_API_URL` con **https**.
- La CSP de `web/index.html` debe incluir el dominio del backend.
- Aplica las migraciones de `supabase/migrations/` en el SQL Editor de Supabase.
- `server/.dockerignore` evita que `.env` entre en la imagen.

Ver `SECURITY.md` para el aviso de vulnerabilidades y las reglas del repo.
