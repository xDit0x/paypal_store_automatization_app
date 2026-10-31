-- Restock — fuentes de catálogo por API de proveedores
--
-- Permite registrar la URL y credenciales de sincronización de cada proveedor
-- para actualizar su catálogo y precios automáticamente.
--
-- Se puede ejecutar más de una vez sin problema.

create table if not exists public.supplier_catalog_sources (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  kind text not null default 'json' check (kind in ('api', 'csv', 'json')),
  url text not null,
  token_env text, -- Nombre de la variable de entorno que guarda el token del proveedor
  etag text,
  last_sync_at timestamptz,
  last_status text,
  last_error text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (supplier_id, url)
);

create index if not exists supplier_catalog_sources_supplier_id_idx
  on public.supplier_catalog_sources(supplier_id);

drop trigger if exists supplier_catalog_sources_set_updated_at on public.supplier_catalog_sources;
create trigger supplier_catalog_sources_set_updated_at
before update on public.supplier_catalog_sources
for each row execute function public.set_updated_at();

-- RLS: sin políticas públicas, solo accesible con service_role (backend).
alter table public.supplier_catalog_sources enable row level security;
