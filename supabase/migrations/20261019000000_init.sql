-- Restock — esquema inicial
-- Ejecutar en el SQL Editor de Supabase o con `supabase db push`.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$
begin
  create type public.order_status as enum (
    'draft',
    'pending_approval',
    'approved',
    'paying',
    'paid',
    'invoiced',
    'completed',
    'rejected',
    'payment_failed'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.order_creator as enum ('user', 'agent');
exception
  when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- stores / spending rules
-- ---------------------------------------------------------------------------
create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  currency text not null default 'EUR',
  paypal_merchant_email text,
  notification_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stores_owner_id_idx on public.stores (owner_id);

create table if not exists public.spending_rules (
  store_id uuid primary key references public.stores (id) on delete cascade,
  max_per_order numeric(12, 2) not null default 200,
  monthly_limit numeric(12, 2) not null default 800,
  require_approval_above numeric(12, 2) not null default 50,
  allowed_supplier_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- catálogo
-- ---------------------------------------------------------------------------
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  paypal_email text,
  category text,
  logo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  uid text not null unique,
  supplier_id uuid not null references public.suppliers (id) on delete cascade,
  name text not null,
  description text,
  price numeric(12, 2) not null check (price >= 0),
  currency text not null default 'EUR',
  stock integer not null default 0 check (stock >= 0),
  low_stock_threshold integer not null default 0 check (low_stock_threshold >= 0),
  unit text not null default 'unidad',
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_supplier_id_idx
  on public.products (supplier_id);
create index if not exists products_stock_idx
  on public.products (stock);

-- ---------------------------------------------------------------------------
-- pedidos
-- ---------------------------------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  supplier_id uuid not null references public.suppliers (id) on delete restrict,
  created_by_type public.order_creator not null default 'user',
  created_by_id uuid references auth.users (id) on delete set null,
  subtotal numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  status public.order_status not null default 'draft',
  approval_by uuid references auth.users (id) on delete set null,
  approval_at timestamptz,
  payment_provider text,
  payment_payout_id text,
  payment_status text,
  payment_at timestamptz,
  invoice_id uuid,
  agent_run_id uuid,
  idempotency_key text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_store_id_idx on public.orders (store_id);
create index if not exists orders_supplier_id_idx on public.orders (supplier_id);
create index if not exists orders_status_idx on public.orders (status);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_uid text not null references public.products (uid) on delete restrict,
  name text not null,
  qty integer not null check (qty > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  line_total numeric(12, 2) not null check (line_total >= 0),
  created_at timestamptz not null default now()
);

create index if not exists order_items_order_id_idx
  on public.order_items (order_id);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete cascade,
  number text not null unique,
  pdf_url text,
  status text not null default 'pending',
  sent_to text,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  provider text not null,
  model text not null,
  tool_calls jsonb not null default '[]'::jsonb,
  decision text,
  confidence numeric(5, 2),
  created_at timestamptz not null default now()
);

create index if not exists agent_runs_store_id_idx
  on public.agent_runs (store_id);

alter table public.orders
  add constraint orders_invoice_id_fkey
  foreign key (invoice_id) references public.invoices (id) on delete set null;

alter table public.orders
  add constraint orders_agent_run_id_fkey
  foreign key (agent_run_id) references public.agent_runs (id) on delete set null;

-- ---------------------------------------------------------------------------
-- triggers updated_at
-- ---------------------------------------------------------------------------
drop trigger if exists stores_set_updated_at on public.stores;
create trigger stores_set_updated_at
before update on public.stores
for each row execute function public.set_updated_at();

drop trigger if exists spending_rules_set_updated_at on public.spending_rules;
create trigger spending_rules_set_updated_at
before update on public.spending_rules
for each row execute function public.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- alta automática de tienda al registrarse
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_store_id uuid;
begin
  insert into public.stores (owner_id, name, notification_email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'store_name', 'Mi tienda'),
    new.email
  )
  returning id into new_store_id;

  insert into public.spending_rules (store_id)
  values (new_store_id);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.stores enable row level security;
alter table public.spending_rules enable row level security;
alter table public.suppliers enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.invoices enable row level security;
alter table public.agent_runs enable row level security;

-- stores
create policy "stores_select_own"
  on public.stores for select
  to authenticated
  using (owner_id = auth.uid());

create policy "stores_insert_own"
  on public.stores for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy "stores_update_own"
  on public.stores for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "stores_delete_own"
  on public.stores for delete
  to authenticated
  using (owner_id = auth.uid());

-- spending rules
create policy "spending_rules_select_own"
  on public.spending_rules for select
  to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = spending_rules.store_id and s.owner_id = auth.uid()
    )
  );

create policy "spending_rules_update_own"
  on public.spending_rules for update
  to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = spending_rules.store_id and s.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.stores s
      where s.id = spending_rules.store_id and s.owner_id = auth.uid()
    )
  );

-- catálogo: lectura para autenticados; escritura solo con service_role
create policy "suppliers_select_authenticated"
  on public.suppliers for select
  to authenticated
  using (true);

create policy "products_select_authenticated"
  on public.products for select
  to authenticated
  using (true);

-- orders
create policy "orders_select_own"
  on public.orders for select
  to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = orders.store_id and s.owner_id = auth.uid()
    )
  );

create policy "orders_insert_own"
  on public.orders for insert
  to authenticated
  with check (
    exists (
      select 1 from public.stores s
      where s.id = orders.store_id and s.owner_id = auth.uid()
    )
    and (created_by_id is null or created_by_id = auth.uid())
  );

create policy "orders_update_own"
  on public.orders for update
  to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = orders.store_id and s.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.stores s
      where s.id = orders.store_id and s.owner_id = auth.uid()
    )
  );

-- order items
create policy "order_items_select_own"
  on public.order_items for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      join public.stores s on s.id = o.store_id
      where o.id = order_items.order_id and s.owner_id = auth.uid()
    )
  );

create policy "order_items_insert_own"
  on public.order_items for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.orders o
      join public.stores s on s.id = o.store_id
      where o.id = order_items.order_id and s.owner_id = auth.uid()
    )
  );

create policy "order_items_delete_own"
  on public.order_items for delete
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      join public.stores s on s.id = o.store_id
      where o.id = order_items.order_id and s.owner_id = auth.uid()
    )
  );

-- invoices
create policy "invoices_select_own"
  on public.invoices for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      join public.stores s on s.id = o.store_id
      where o.id = invoices.order_id and s.owner_id = auth.uid()
    )
  );

-- agent runs: lectura para el dueño; escritura solo con service_role
create policy "agent_runs_select_own"
  on public.agent_runs for select
  to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = agent_runs.store_id and s.owner_id = auth.uid()
    )
  );
