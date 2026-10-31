-- Restock — las tiendas nuevas nacen sin stock.
--
-- Antes, `handle_new_user` copiaba todo el catálogo global a
-- `store_products`. Ahora el catálogo se consulta desde el buscador y cada
-- tienda construye su stock comprando a sus proveedores. Las tiendas que ya
-- existen conservan su stock: esta migración no borra nada.
--
-- Se puede ejecutar más de una vez sin problema.

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
