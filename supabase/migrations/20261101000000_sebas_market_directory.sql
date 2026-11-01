-- Stocky — directorio de distribuidores para el estudio de mercado (Sebas)
--
-- El Asistente busca aquí cuando el dueño quiere añadir un producto nuevo:
-- compara distribuidores de varios países por coste real puesto en tienda
-- (precio, envío, cambio de moneda y aranceles), plazo y valoración.
--
-- Los distribuidores son FICTICIOS (dominios .example) y sirven para la demo.
-- Se puede ejecutar más de una vez sin problema.

create table if not exists public.market_distributors (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  country text not null,
  city text,
  currency text not null default 'EUR',
  paypal_email text,
  website text,
  rating numeric(2, 1) not null default 4.0,
  lead_days integer not null default 3 check (lead_days >= 0),
  shipping_base numeric(12, 2) not null default 0 check (shipping_base >= 0),
  shipping_per_unit numeric(12, 4) not null default 0 check (shipping_per_unit >= 0),
  free_shipping_over numeric(12, 2),
  duty_rate numeric(5, 4) not null default 0 check (duty_rate >= 0),
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.market_offers (
  id uuid primary key default gen_random_uuid(),
  distributor_id uuid not null references public.market_distributors (id) on delete cascade,
  sku text not null,
  product_key text not null,
  name text not null,
  keywords text[] not null default '{}',
  unit text not null default 'unidad',
  price numeric(12, 2) not null check (price > 0),
  min_qty integer not null default 1 check (min_qty > 0),
  pack_size integer not null default 1 check (pack_size > 0),
  notes text,
  created_at timestamptz not null default now(),
  unique (distributor_id, sku)
);

create index if not exists market_offers_product_key_idx on public.market_offers (product_key);

create table if not exists public.market_searches (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  query text not null,
  region text not null,
  monthly_quantity integer,
  results jsonb not null default '[]',
  web_results jsonb not null default '[]',
  adopted_offer_id uuid,
  adopted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists market_searches_store_id_idx on public.market_searches (store_id);

alter table public.market_distributors enable row level security;
alter table public.market_offers enable row level security;
alter table public.market_searches enable row level security;

drop policy if exists "market_distributors_select_authenticated" on public.market_distributors;
create policy "market_distributors_select_authenticated"
  on public.market_distributors for select to authenticated using (true);

drop policy if exists "market_offers_select_authenticated" on public.market_offers;
create policy "market_offers_select_authenticated"
  on public.market_offers for select to authenticated using (true);

drop policy if exists "market_searches_select_own" on public.market_searches;
create policy "market_searches_select_own"
  on public.market_searches for select to authenticated
  using (
    exists (
      select 1 from public.stores s
      where s.id = market_searches.store_id and s.owner_id = auth.uid()
    )
  );

-- Datos de demostración ------------------------------------------------------

insert into public.market_distributors
  (code, name, country, city, currency, paypal_email, website, rating, lead_days, shipping_base, shipping_per_unit, free_shipping_over, duty_rate, description)
values
  ('horta-verda', 'Horta Verda Distribucions', 'ES', 'Valencia', 'EUR', 'pagos@hortaverda.example', 'https://hortaverda.example', 4.6, 2, 9.0, 0.0, 150.0, 0.0, 'Distribuidor de bebidas vegetales y envases para hostelería en la Comunidad Valenciana.'),
  ('castellana', 'Mayoristas Castellana', 'ES', 'Madrid', 'EUR', 'pagos@mayoristascastellana.example', 'https://mayoristascastellana.example', 4.3, 1, 6.0, 0.0, 120.0, 0.0, 'Cash & carry para cafeterías en Madrid con entrega en 24 h.'),
  ('fermentats-raval', 'Fermentats del Raval', 'ES', 'Barcelona', 'EUR', 'pagos@fermentatsraval.example', 'https://fermentatsraval.example', 4.5, 2, 8.0, 0.0, 100.0, 0.0, 'Kombucha artesanal y bebidas fermentadas de Barcelona.'),
  ('tueste-lavapies', 'Tueste Lavapiés', 'ES', 'Madrid', 'EUR', 'pagos@tuestelavapies.example', 'https://tuestelavapies.example', 4.8, 2, 7.0, 0.0, 90.0, 0.0, 'Tostador de café de especialidad de origen único.'),
  ('hojas-triana', 'Hojas de Triana', 'ES', 'Sevilla', 'EUR', 'pagos@hojastriana.example', 'https://hojastriana.example', 4.4, 2, 5.0, 0.0, 80.0, 0.0, 'Tés e infusiones para hostelería.'),
  ('douro-bebidas', 'Douro Bebidas Lda', 'PT', 'Oporto', 'EUR', 'pagos@dourobebidas.example', 'https://dourobebidas.example', 4.4, 4, 18.0, 0.05, null, 0.0, 'Mayorista portugués de bebidas vegetales.'),
  ('embalagens-atlantico', 'Embalagens Atlântico', 'PT', 'Lisboa', 'EUR', 'pagos@embalagensatlantico.example', 'https://embalagensatlantico.example', 4.2, 5, 20.0, 0.0, 250.0, 0.0, 'Envases compostables para restauración.'),
  ('brasserie-vivante', 'Brasserie Vivante', 'FR', 'Lyon', 'EUR', 'pagos@brasserievivante.example', 'https://brasserievivante.example', 4.6, 5, 22.0, 0.0, 200.0, 0.0, 'Kombucha y bebidas fermentadas ecológicas.'),
  ('maison-the-marais', 'Maison Thé Marais', 'FR', 'París', 'EUR', 'pagos@maisonthemarais.example', 'https://maisonthemarais.example', 4.5, 3, 12.0, 0.0, 150.0, 0.0, 'Importador de tés japoneses y matcha.'),
  ('hafen-naturkost', 'Hafen Naturkost GmbH', 'DE', 'Hamburgo', 'EUR', 'pagos@hafennaturkost.example', 'https://hafennaturkost.example', 4.7, 6, 25.0, 0.0, 400.0, 0.0, 'Gran mayorista ecológico del norte de Europa.'),
  ('torrefazione-navigli', 'Torrefazione Navigli', 'IT', 'Milán', 'EUR', 'pagos@torrefazionenavigli.example', 'https://torrefazionenavigli.example', 4.6, 4, 15.0, 0.0, 180.0, 0.0, 'Tostadero italiano de café de especialidad.'),
  ('haven-fermentatie', 'Haven Fermentatie BV', 'NL', 'Róterdam', 'EUR', 'pagos@havenfermentatie.example', 'https://havenfermentatie.example', 4.4, 4, 20.0, 0.0, 180.0, 0.0, 'Bebidas fermentadas para el mercado europeo.'),
  ('zielona-hurt', 'Zielona Hurt Sp. z o.o.', 'PL', 'Poznań', 'PLN', 'pagos@zielonahurt.example', 'https://zielonahurt.example', 4.1, 5, 120.0, 0.2, null, 0.0, 'Mayorista polaco de bebidas vegetales y envases a precio bajo.'),
  ('westcountry-brew', 'Westcountry Brew Co.', 'GB', 'Bristol', 'GBP', 'pagos@westcountrybrew.example', 'https://westcountrybrew.example', 4.2, 7, 35.0, 0.0, null, 0.08, 'Kombucha británica (fuera de la UE: aduana e IVA a la importación).'),
  ('finca-alto-aburra', 'Finca Alto Aburrá', 'CO', 'Medellín', 'USD', 'pagos@fincaaltoaburra.example', 'https://fincaaltoaburra.example', 4.7, 14, 85.0, 0.0, null, 0.075, 'Productor colombiano de café verde y tostado, venta directa.'),
  ('uji-midori', 'Uji Midori Tea Garden', 'JP', 'Uji (Kioto)', 'JPY', 'pagos@ujimidori.example', 'https://ujimidori.example', 4.9, 10, 6000.0, 0.0, null, 0.0, 'Productor japonés de matcha ceremonial (acuerdo UE-Japón: sin arancel).')
on conflict (code) do nothing;

insert into public.market_offers
  (distributor_id, sku, product_key, name, keywords, unit, price, min_qty, pack_size, notes)
values
  ((select id from public.market_distributors where code = 'horta-verda'), 'oat-barista', 'oat-barista', 'Bebida de avena barista 1 L', array['avena','barista','bebida de avena','leche de avena','leche vegetal','oat','oat milk','oat drink','vegetal']::text[], 'L', 1.45, 24, 12, 'Marca propia, espuma estable para latte.'),
  ((select id from public.market_distributors where code = 'horta-verda'), 'compostable-cups', 'compostable-cups', 'Vasos compostables 12 oz (caja de 1000)', array['vasos','vaso','compostable','compostables','cups','12oz','12 oz','desechable','envases']::text[], 'caja', 62.0, 1, 1, 'Certificado EN 13432.'),
  ((select id from public.market_distributors where code = 'castellana'), 'oat-barista', 'oat-barista', 'Bebida de avena barista 1 L', array['avena','barista','bebida de avena','leche de avena','leche vegetal','oat','oat milk','oat drink','vegetal']::text[], 'L', 1.52, 12, 6, 'Entrega en 24 h en Madrid.'),
  ((select id from public.market_distributors where code = 'castellana'), 'coffee-beans', 'coffee-beans', 'Café de especialidad en grano 1 kg', array['cafe','café','grano','especialidad','coffee','beans','arabica','arábica','tueste','tostado']::text[], 'kg', 21.9, 3, 1, 'Blend 100 % arábica.'),
  ((select id from public.market_distributors where code = 'fermentats-raval'), 'kombucha', 'kombucha', 'Kombucha 330 ml', array['kombucha','te fermentado','té fermentado','fermented tea','bebida fermentada']::text[], 'botella', 1.65, 24, 24, 'Sabores: jengibre, frutos rojos y limón.'),
  ((select id from public.market_distributors where code = 'tueste-lavapies'), 'coffee-beans', 'coffee-beans', 'Café de especialidad en grano 1 kg', array['cafe','café','grano','especialidad','coffee','beans','arabica','arábica','tueste','tostado']::text[], 'kg', 19.5, 5, 1, 'Origen Etiopía, tueste semanal.'),
  ((select id from public.market_distributors where code = 'hojas-triana'), 'matcha', 'matcha', 'Matcha 100 g', array['matcha','te verde','té verde','green tea','te matcha','té matcha']::text[], 'lata', 21.0, 5, 1, 'Grado culinario premium.'),
  ((select id from public.market_distributors where code = 'douro-bebidas'), 'oat-barista', 'oat-barista', 'Bebida de avena barista 1 L', array['avena','barista','bebida de avena','leche de avena','leche vegetal','oat','oat milk','oat drink','vegetal']::text[], 'L', 1.2, 48, 12, 'Avena de cultivo ibérico.'),
  ((select id from public.market_distributors where code = 'embalagens-atlantico'), 'compostable-cups', 'compostable-cups', 'Vasos compostables 12 oz (caja de 1000)', array['vasos','vaso','compostable','compostables','cups','12oz','12 oz','desechable','envases']::text[], 'caja', 55.0, 2, 1, 'Tapas compatibles aparte.'),
  ((select id from public.market_distributors where code = 'brasserie-vivante'), 'kombucha', 'kombucha', 'Kombucha 330 ml', array['kombucha','te fermentado','té fermentado','fermented tea','bebida fermentada']::text[], 'botella', 1.4, 48, 24, 'Ecológica certificada.'),
  ((select id from public.market_distributors where code = 'maison-the-marais'), 'matcha', 'matcha', 'Matcha 100 g', array['matcha','te verde','té verde','green tea','te matcha','té matcha']::text[], 'lata', 18.5, 10, 1, 'Importado de Uji, grado ceremonial.'),
  ((select id from public.market_distributors where code = 'hafen-naturkost'), 'oat-barista', 'oat-barista', 'Bebida de avena barista 1 L', array['avena','barista','bebida de avena','leche de avena','leche vegetal','oat','oat milk','oat drink','vegetal']::text[], 'L', 1.08, 120, 12, 'Ecológica, palé mixto posible.'),
  ((select id from public.market_distributors where code = 'hafen-naturkost'), 'coffee-beans', 'coffee-beans', 'Café de especialidad en grano 1 kg', array['cafe','café','grano','especialidad','coffee','beans','arabica','arábica','tueste','tostado']::text[], 'kg', 18.4, 10, 1, 'Ecológico y comercio justo.'),
  ((select id from public.market_distributors where code = 'hafen-naturkost'), 'compostable-cups', 'compostable-cups', 'Vasos compostables 12 oz (caja de 1000)', array['vasos','vaso','compostable','compostables','cups','12oz','12 oz','desechable','envases']::text[], 'caja', 58.0, 2, 1, 'Gran volumen.'),
  ((select id from public.market_distributors where code = 'torrefazione-navigli'), 'coffee-beans', 'coffee-beans', 'Café de especialidad en grano 1 kg', array['cafe','café','grano','especialidad','coffee','beans','arabica','arábica','tueste','tostado']::text[], 'kg', 17.9, 10, 1, 'Tueste italiano medio-oscuro.'),
  ((select id from public.market_distributors where code = 'haven-fermentatie'), 'kombucha', 'kombucha', 'Kombucha 330 ml', array['kombucha','te fermentado','té fermentado','fermented tea','bebida fermentada']::text[], 'botella', 1.35, 48, 24, 'Baja en azúcar.'),
  ((select id from public.market_distributors where code = 'zielona-hurt'), 'oat-barista', 'oat-barista', 'Bebida de avena barista 1 L', array['avena','barista','bebida de avena','leche de avena','leche vegetal','oat','oat milk','oat drink','vegetal']::text[], 'L', 4.6, 96, 12, 'Precio en zlotys.'),
  ((select id from public.market_distributors where code = 'zielona-hurt'), 'compostable-cups', 'compostable-cups', 'Vasos compostables 12 oz (caja de 1000)', array['vasos','vaso','compostable','compostables','cups','12oz','12 oz','desechable','envases']::text[], 'caja', 230.0, 3, 1, 'Precio en zlotys.'),
  ((select id from public.market_distributors where code = 'westcountry-brew'), 'kombucha', 'kombucha', 'Kombucha 330 ml', array['kombucha','te fermentado','té fermentado','fermented tea','bebida fermentada']::text[], 'botella', 1.15, 72, 24, 'Precio en libras.'),
  ((select id from public.market_distributors where code = 'finca-alto-aburra'), 'coffee-beans', 'coffee-beans', 'Café de especialidad en grano 1 kg', array['cafe','café','grano','especialidad','coffee','beans','arabica','arábica','tueste','tostado']::text[], 'kg', 13.5, 30, 1, 'Precio en dólares, café de altura.'),
  ((select id from public.market_distributors where code = 'uji-midori'), 'matcha', 'matcha', 'Matcha 100 g', array['matcha','te verde','té verde','green tea','te matcha','té matcha']::text[], 'lata', 2400.0, 20, 1, 'Precio en yenes, cosecha de primavera.')
on conflict (distributor_id, sku) do nothing;
