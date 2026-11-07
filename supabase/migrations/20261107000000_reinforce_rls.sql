-- Restock — refuerzo de RLS / defensa en profundidad
-- Ejecutar en Supabase SQL Editor o con `supabase db push`.
-- Idempotente: se puede ejecutar más de una vez.

-- ---------------------------------------------------------------------------
-- 1) catalog_imports: solo el backend (service_role) debe leer/escribir.
--    La app cliente no consulta esta tabla.
-- ---------------------------------------------------------------------------
drop policy if exists "catalog_imports_select_admin" on public.catalog_imports;
drop policy if exists "catalog_imports_insert_service" on public.catalog_imports;

-- Sin policies para authenticated/anon: RLS deniega por defecto.
-- service_role omite RLS en Supabase, por lo que el backend sigue operando.

-- ---------------------------------------------------------------------------
-- 2) spending_rules: límites razonables (defensa ante abuso directo de la API)
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'spending_rules_non_negative_check'
      and conrelid = 'public.spending_rules'::regclass
  ) then
    alter table public.spending_rules
      add constraint spending_rules_non_negative_check check (
        max_per_order >= 0
        and monthly_limit >= 0
        and require_approval_above >= 0
      );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3) orders: al INSERT desde cliente, limpiar campos sensibles.
--    El backend (service_role) puede insertar cualquier campo.
--    La RLS ya limita status a draft/pending_approval y exige propiedad.
-- ---------------------------------------------------------------------------
create or replace function public.protect_order_insert()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  -- El cliente no debe poder fijar campos de aprobación/pago/agente.
  new.approval_by := null;
  new.approval_at := null;
  new.payment_provider := null;
  new.payment_payout_id := null;
  new.payment_status := null;
  new.payment_at := null;
  new.authorized_at := null;
  new.delivered_at := null;
  new.received_total := null;
  new.payment_authorization_id := null;
  new.payment_capture_id := null;
  new.invoice_id := null;
  new.agent_run_id := null;

  -- Fuerza estados seguros en inserts de cliente.
  if new.status not in ('draft', 'pending_approval') then
    new.status := 'draft';
  end if;

  return new;
end;
$$;

drop trigger if exists orders_protect_insert on public.orders;
create trigger orders_protect_insert
before insert on public.orders
for each row execute function public.protect_order_insert();

-- ---------------------------------------------------------------------------
-- 4) order_items: solo permitir inserts cuando el pedido es editable por cliente
--    (draft/pending_approval) y pertenece al dueño. Defensa en profundidad
--    además de la RLS de propiedad.
-- ---------------------------------------------------------------------------
create or replace function public.protect_order_item_insert()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  order_status public.order_status;
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  select o.status into order_status
  from public.orders o
  where o.id = new.order_id;

  if order_status is null then
    raise exception 'Pedido no encontrado.';
  end if;

  if order_status not in ('draft', 'pending_approval') then
    raise exception 'No se pueden modificar líneas de un pedido en estado %.', order_status;
  end if;

  return new;
end;
$$;

drop trigger if exists order_items_protect_insert on public.order_items;
create trigger order_items_protect_insert
before insert on public.order_items
for each row execute function public.protect_order_item_insert();

-- ---------------------------------------------------------------------------
-- 5) stores: evitar que el dueño se reasigne (WITH CHECK ya lo cubre, pero
--    explícito). Mantener update_own porque la app puede editar perfil/ajustes.
-- ---------------------------------------------------------------------------
-- (sin cambios de policy: stores_update_own ya exige owner_id = auth.uid())

-- ---------------------------------------------------------------------------
-- 6) Notas de revisión (no aplicadas automáticamente aquí)
-- ---------------------------------------------------------------------------
-- - suppliers/products: SELECT para authenticated (catálogo compartido). OK si
--   es intencional; no hay policies de escritura para clientes.
-- - spending_rules: el dueño puede actualizar sus reglas vía cliente (flujo
--   legítimo de ajustes). El backend/agente deben seguir validando límites al
--   ejecutar pagos.
-- - stores.paypal_merchant_email: editable por el dueño. Revisar si este campo
--   afecta flujos de pago; si es sensible, mover su actualización al backend.
-- - orders/order_items creados por cliente: el backend recalcula importes antes
--   de pagar (guard_order_amount). Mantener esa validación server-side.
