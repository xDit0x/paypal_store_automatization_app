import type { FastifyRequest } from 'fastify';

import {
  verifySupabaseToken,
  type AuthUser,
} from '../../application/auth/verify_supabase_token.js';

export async function authenticate(
  request: FastifyRequest,
): Promise<AuthUser | null> {
  const header = request.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;

  try {
    return await verifySupabaseToken(header.slice(7));
  } catch {
    return null;
  }
}
