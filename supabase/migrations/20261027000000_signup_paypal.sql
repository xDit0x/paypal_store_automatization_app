-- Restock — correo de PayPal al crear la cuenta
--
-- El alta de tienda lee `paypal_merchant_email` de los metadatos del usuario
-- (lo envía la app en el registro, es opcional). Sin esta columna rellena el
-- backend no puede pagar pedidos: `fulfill_order` lanza
-- «Falta paypal_merchant_email en la tienda».

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

  return new;
end;
$$;
