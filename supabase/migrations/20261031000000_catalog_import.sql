-- Fase 1 — Catálogo de proveedores: importador y RLS

-- 1. suppliers.code
alter table public.suppliers
add column if not exists code text unique;

-- 2. catalog_imports
create table if not exists public.catalog_imports (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  source text not null,
  result_json jsonb not null default '{}',
  created_at timestamptz not null default now(),
  errors_json jsonb not null default '[]'
);

create index if not exists catalog_imports_supplier_id_idx on public.catalog_imports(supplier_id);

-- 3. RLS en catalog_imports
alter table public.catalog_imports enable row level security;

-- lectura (admin) — cualquier autenticado puede leer el registro de importación
drop policy if exists "catalog_imports_select_admin" on public.catalog_imports;
create policy "catalog_imports_select_admin"
  on public.catalog_imports for select
  to authenticated
  using (true);

-- inserción (servicio) — solo el servicio_role puede añadir registros
drop policy if exists "catalog_imports_insert_service" on public.catalog_imports;
create policy "catalog_imports_insert_service"
  on public.catalog_imports for insert
  to service_role
  with check (true);
