import type { FastifyInstance } from 'fastify';

import { supabaseAdmin } from '../../../infrastructure/supabase/supabase_client.js';
import { authenticate } from '../auth.js';
import { createRateLimiter } from '../rate_limit.js';

interface StockBody {
  stock?: unknown;
  store_id?: unknown;
}

interface ProductRow {
  uid: string;
  name: string;
  low_stock_threshold: number;
}

interface InventoryRow {
  stock: number;
}

// El catálogo solo se escribe desde el servidor (service_role). La app pide
// aquí el cambio de stock de un producto en una tienda concreta.
export async function catalogRoutes(app: FastifyInstance): Promise<void> {
  const limiter = createRateLimiter({ windowMs: 60_000, max: 60 });

  app.patch<{ Params: { uid: string }; Body: StockBody }>(
    '/catalog/products/:uid/stock',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: 'Sesión no válida.' });
      }

      const { allowed, retryAfterSeconds } = limiter.check(user.id);
      if (!allowed) {
        reply.header('Retry-After', String(retryAfterSeconds));
        return reply
          .code(429)
          .send({ error: 'Demasiados cambios de stock. Espera un momento.' });
      }

      const stock = Number(request.body?.stock);
      if (!Number.isInteger(stock) || stock < 0) {
        return reply
          .code(400)
          .send({ error: 'El stock debe ser un número entero igual o mayor que 0.' });
      }

      const storeId =
        typeof request.body?.store_id === 'string' ? request.body.store_id : '';
      if (!storeId) {
        return reply.code(400).send({ error: 'Falta store_id.' });
      }

      // La tienda tiene que ser del usuario que hace el cambio. Así el stock
      // de una tienda no se puede tocar desde otra cuenta.
      const { data: store, error: storeError } = await supabaseAdmin
        .from('stores')
        .select('id')
        .eq('id', storeId)
        .eq('owner_id', user.id)
        .maybeSingle();

      if (storeError) {
        request.log.error(storeError);
        return reply.code(500).send({ error: 'No se pudo comprobar la tienda.' });
      }
      if (!store) {
        return reply
          .code(403)
          .send({ error: 'La tienda no existe o no es tuya.' });
      }

      try {
        const { data: product, error: productError } = await supabaseAdmin
          .from('products')
          .select('uid, name, low_stock_threshold')
          .eq('uid', request.params.uid)
          .maybeSingle();

        if (productError) {
          throw new Error(
            `No se pudo leer el producto: ${productError.message}`,
          );
        }
        if (!product) {
          return reply.code(404).send({ error: 'Producto no encontrado.' });
        }

        const catalogProduct = product as unknown as ProductRow;

        const { data: updated, error: updateError } = await supabaseAdmin
          .from('store_products')
          .update({ stock })
          .eq('store_id', storeId)
          .eq('product_uid', catalogProduct.uid)
          .select('stock')
          .maybeSingle();

        if (updateError) {
          throw new Error(`No se pudo actualizar el stock: ${updateError.message}`);
        }

        if (!updated) {
          // Producto añadido al catálogo después de crear la tienda: se crea
          // su fila de inventario con el umbral del catálogo.
          const { error: insertError } = await supabaseAdmin
            .from('store_products')
            .insert({
              store_id: storeId,
              product_uid: catalogProduct.uid,
              stock,
              low_stock_threshold: catalogProduct.low_stock_threshold,
            });

          if (insertError) {
            throw new Error(
              `No se pudo crear el stock: ${insertError.message}`,
            );
          }
        }

        const saved = (updated as InventoryRow | null)?.stock ?? stock;
        request.log.info(
          {
            user: user.id,
            store: storeId,
            product: catalogProduct.uid,
            stock: saved,
          },
          'stock actualizado',
        );

        return reply.send({
          uid: catalogProduct.uid,
          name: catalogProduct.name,
          stock: saved,
        });
      } catch (error) {
        request.log.error(error);
        return reply
          .code(500)
          .send({ error: 'No se pudo actualizar el stock del producto.' });
      }
    },
  );
}
