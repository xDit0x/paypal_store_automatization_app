import type { FastifyInstance } from 'fastify';

import { supabaseAdmin } from '../../../infrastructure/supabase/supabase_client.js';
import { authenticate } from '../auth.js';
import { createRateLimiter } from '../rate_limit.js';

interface StockBody {
  stock?: unknown;
}

interface ProductRow {
  uid: string;
  name: string;
  stock: number;
}

// El catálogo solo se escribe desde el servidor (service_role). La app pide
// aquí el cambio de stock de un producto.
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

      // Solo usuarios con una tienda pueden tocar el catálogo.
      const { data: stores, error: storesError } = await supabaseAdmin
        .from('stores')
        .select('id')
        .eq('owner_id', user.id)
        .limit(1);

      if (storesError) {
        request.log.error(storesError);
        return reply.code(500).send({ error: 'No se pudo comprobar la tienda.' });
      }
      if (!stores || stores.length === 0) {
        return reply.code(403).send({ error: 'No tienes ninguna tienda.' });
      }

      try {
        const { data, error } = await supabaseAdmin
          .from('products')
          .update({ stock })
          .eq('uid', request.params.uid)
          .select('uid, name, stock')
          .maybeSingle();

        if (error) {
          throw new Error(`No se pudo actualizar el stock: ${error.message}`);
        }
        if (!data) {
          return reply.code(404).send({ error: 'Producto no encontrado.' });
        }

        const product = data as unknown as ProductRow;
        request.log.info(
          {
            user: user.id,
            product: product.uid,
            stock: product.stock,
          },
          'stock actualizado',
        );

        return reply.send({
          uid: product.uid,
          name: product.name,
          stock: product.stock,
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
