-- Datos de demostración para Restock.
-- La tienda se crea automáticamente al registrar un usuario (trigger handle_new_user).

insert into public.suppliers (id, name, paypal_email, category, active)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'Distribuidora Andina',
    'pagos@andina.example',
    'Abarrotes',
    true
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'Café Global',
    'pagos@cafeglobal.example',
    'Bebidas',
    true
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    'Limpieza Total',
    'pagos@limpiezatotal.example',
    'Limpieza',
    true
  )
on conflict (id) do nothing;

insert into public.products (
  uid,
  supplier_id,
  name,
  description,
  price,
  currency,
  stock,
  low_stock_threshold,
  unit,
  active
)
values
  (
    'PRD-000001',
    '11111111-1111-4111-8111-111111111111',
    'Leche entera 1L',
    'Leche entera UHT en brick de 1 litro.',
    1.15,
    'EUR',
    6,
    10,
    'unidad',
    true
  ),
  (
    'PRD-000002',
    '11111111-1111-4111-8111-111111111111',
    'Pan de molde 500g',
    'Pan de molde blanco en bolsa de 500 gramos.',
    2.10,
    'EUR',
    18,
    8,
    'unidad',
    true
  ),
  (
    'PRD-000003',
    '11111111-1111-4111-8111-111111111111',
    'Arroz redondo 1kg',
    'Arroz redondo envasado de 1 kilogramo.',
    1.45,
    'EUR',
    4,
    12,
    'unidad',
    true
  ),
  (
    'PRD-000004',
    '22222222-2222-4222-8222-222222222222',
    'Café molido 250g',
    'Café molido natural en paquete de 250 gramos.',
    4.80,
    'EUR',
    22,
    6,
    'unidad',
    true
  ),
  (
    'PRD-000005',
    '22222222-2222-4222-8222-222222222222',
    'Café en grano 1kg',
    'Café en grano de tueste medio, 1 kilogramo.',
    18.90,
    'EUR',
    3,
    5,
    'unidad',
    true
  ),
  (
    'PRD-000006',
    '22222222-2222-4222-8222-222222222222',
    'Agua mineral 1.5L',
    'Botella de agua mineral de 1,5 litros.',
    0.55,
    'EUR',
    40,
    20,
    'unidad',
    true
  ),
  (
    'PRD-000007',
    '33333333-3333-4333-8333-333333333333',
    'Detergente 1L',
    'Detergente líquido para ropa, 1 litro.',
    3.20,
    'EUR',
    7,
    10,
    'unidad',
    true
  ),
  (
    'PRD-000008',
    '33333333-3333-4333-8333-333333333333',
    'Jabón líquido 500ml',
    'Jabón líquido para manos, 500 mililitros.',
    2.75,
    'EUR',
    25,
    8,
    'unidad',
    true
  ),
  (
    'PRD-000009',
    '33333333-3333-4333-8333-333333333333',
    'Papel higiénico 8 rollos',
    'Paquete de 8 rollos de papel higiénico.',
    4.10,
    'EUR',
    12,
    10,
    'paquete',
    true
  ),
  (
    'PRD-000010',
    '33333333-3333-4333-8333-333333333333',
    'Lejía 2L',
    'Lejía desinfectante en botella de 2 litros.',
    1.95,
    'EUR',
    9,
    10,
    'unidad',
    true
  )
on conflict (uid) do nothing;
