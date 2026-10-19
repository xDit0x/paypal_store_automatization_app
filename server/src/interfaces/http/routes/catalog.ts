import type { FastifyInstance } from 'fastify';

import { supabaseAdmin } from '../../../infrastructure/supabase/supabase_client.js';
import { authenticate } from '../auth.js';

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
  app.patch<{ Params: { uid: string }; Body: StockBody }>(
    '/catalog/products/:uid/stock',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: 'Sesión no válida.' });
      }

      const stock = Number(request.body?.stock);
      if (!Number.isInteger(stock) || stock < 0) {
        return reply
          .code(400)
          .send({ error: 'El stock debe ser un número entero igual o mayor que 0.' });
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
        return reply.send({
          uid: product.uid,
          name: product.name,
          stock: product.stock,
        });
      } catch (error) {
        request.log.error(error);
        const message =
          error instanceof Error
            ? error.message
            : 'Error al actualizar el stock.';
        return reply.code(500).send({ error: message });
      }
    },
  );
}
