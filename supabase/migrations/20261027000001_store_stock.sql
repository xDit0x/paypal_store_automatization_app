-- Restock — stock por tienda
--
-- El catálogo (productos, proveedores y precios) sigue siendo compartido, pero
-- el stock y el umbral de aviso pasan a ser de cada tienda. `products.stock` y
-- `products.low_stock_threshold` quedan como valores iniciales para las tiendas
-- nuevas.

create table if not exists public.store_products (
  store_id uuid not null references public.stores (id) on delete cascade,
  product_uid text not null references public.products (uid) on delete cascade,
  stock integer not null default 0 check (stock >= 0),
  low_stock_threshold integer not null default 0 check (low_stock_threshold >= 0),
  updated_at timestamptz not null default now(),
  primary key (store_id, product_uid)
);

create index if not exists store_products_store_id_idx
  on public.store_products (store_id);
create index if not exists store_products_stock_idx
  on public.store_products (stock);

drop trigger if exists store_products_set_updated_at on public.store_products;
create trigger store_products_set_updated_at
before update on public.store_products
for each row execute function public.set_updated_at();

-- Las tiendas que ya existen arrancan con el stock que veían en el catálogo.
insert into public.store_products (
  store_id,
  product_uid,
  stock,
  low_stock_threshold
)
select s.id, p.uid, p.stock, p.low_stock_threshold
from public.stores s
cross join public.products p
on conflict (store_id, product_uid) do nothing;

alter table public.store_products enable row level security;

drop policy if exists "store_products_select_own" on public.store_products;
create policy "store_products_select_own"
  on public.store_products for select
  to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = store_products.store_id and s.owner_id = auth.uid()
    )
  );

-- Las altas de tienda copian el stock inicial del catálogo.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_store_id uuid;
begin
  insert into public.stores (
    owner_id,
    name,
    notification_email,
    paypal_merchant_email
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'store_name', 'Mi tienda'),
    new.email,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'paypal_merchant_email', '')), '')
  )
  returning id into new_store_id;

  insert into public.spending_rules (store_id)
  values (new_store_id);

  insert into public.store_products (
    store_id,
    product_uid,
    stock,
    low_stock_threshold
  )
  select new_store_id, p.uid, p.stock, p.low_stock_threshold
  from public.products p;

  return new;
end;
$$;
