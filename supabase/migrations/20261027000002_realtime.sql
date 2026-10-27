-- Restock — tiempo real
--
-- La app escucha los cambios de pedidos, stock y ejecuciones del agente para
-- actualizarse sola (por ejemplo, cuando la revisión automática de las 9:00
-- crea un pedido). Supabase Realtime respeta RLS: cada usuario solo recibe los
-- cambios de su propia tienda.
--
-- Se puede ejecutar más de una vez sin problema.

do $$
declare
  t text;
begin
  foreach t in array array['orders', 'store_products', 'agent_runs'] loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end
$$;
