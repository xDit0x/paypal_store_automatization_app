-- Restock — endurecer el acceso a los pedidos.
--
-- El cliente (con la anon key) no debe poder tocar el importe ni el estado de
-- un pedido: el importe decide cuánto se paga con PayPal. Los pedidos los
-- crea y paga el backend con service_role, y el propio backend recalcula el
-- importe desde el catálogo antes de pagar (guard_order_amount.ts).

-- ---------------------------------------------------------------------------
-- policies
-- ---------------------------------------------------------------------------
-- El cliente no actualiza pedidos: aprobar, rechazar y pagar pasan por la API.
drop policy if exists "orders_update_own" on public.orders;

-- Las líneas de un pedido tampoco se borran desde el cliente.
drop policy if exists "order_items_delete_own" on public.order_items;

-- Si se reinserta, solo se admiten pedidos en borrador o pendientes de
-- aprobación: nunca "aprobado", "pagado" o "completado".
drop policy if exists "orders_insert_own" on public.orders;
create policy "orders_insert_own"
  on public.orders for insert
  to authenticated
  with check (
    exists (
      select 1 from public.stores s
      where s.id = orders.store_id and s.owner_id = auth.uid()
    )
    and status in ('draft', 'pending_approval')
    and (created_by_id is null or created_by_id = auth.uid())
    and agent_run_id is null
  );

-- ---------------------------------------------------------------------------
-- trigger: los importes y el estado solo los cambia el servidor
-- ---------------------------------------------------------------------------
create or replace function public.protect_order_amount()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  if new.total is distinct from old.total
    or new.subtotal is distinct from old.subtotal
    or new.status is distinct from old.status
    or new.approval_by is distinct from old.approval_by
    or new.approval_at is distinct from old.approval_at
    or new.payment_provider is distinct from old.payment_provider
    or new.payment_payout_id is distinct from old.payment_payout_id
    or new.payment_status is distinct from old.payment_status
    or new.payment_at is distinct from old.payment_at
    or new.invoice_id is distinct from old.invoice_id then
    raise exception
      'El importe y el estado de un pedido solo los puede cambiar el servidor.';
  end if;

  return new;
end;
$$;

drop trigger if exists orders_protect_amount on public.orders;
create trigger orders_protect_amount
before update on public.orders
for each row execute function public.protect_order_amount();
