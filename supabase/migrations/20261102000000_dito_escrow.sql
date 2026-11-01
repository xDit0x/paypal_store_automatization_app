-- Restock — pago retenido hasta la entrega (escrow con PayPal)
--
-- El pedido se autoriza al aprobarlo, pero el dinero no se cobra hasta que
-- la tienda confirma qué ha recibido. Si llega incompleto, se captura solo
-- lo recibido.
--
-- Se puede ejecutar más de una vez sin problema.

-- Estados nuevos del pedido.
alter type public.order_status add value if not exists 'authorized';
alter type public.order_status add value if not exists 'partially_delivered';
alter type public.order_status add value if not exists 'delivered';
alter type public.order_status add value if not exists 'claimed';
alter type public.order_status add value if not exists 'refunded';

-- Datos del pago retenido.
alter table public.orders
  add column if not exists payment_authorization_id text,
  add column if not exists payment_capture_id text,
  add column if not exists authorized_at timestamptz,
  add column if not exists delivered_at timestamptz,
  add column if not exists received_total numeric(12, 2);

-- Líneas de entrega: qué llegó de cada producto.
create table if not exists public.order_delivery_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_uid text not null,
  qty_ordered integer not null check (qty_ordered > 0),
  qty_received integer not null default 0 check (qty_received >= 0),
  created_at timestamptz not null default now(),
  unique (order_id, product_uid)
);

create index if not exists order_delivery_items_order_id_idx
  on public.order_delivery_items(order_id);

-- RLS: la tienda dueña del pedido puede consultar sus entregas. Las
-- escrituras las hace el servidor con service_role.
alter table public.order_delivery_items enable row level security;

drop policy if exists "order_delivery_items_select_own" on public.order_delivery_items;
create policy "order_delivery_items_select_own"
  on public.order_delivery_items for select
  using (
    exists (
      select 1
      from public.orders o
      join public.stores s on s.id = o.store_id
      where o.id = order_delivery_items.order_id and s.owner_id = auth.uid()
    )
  );
