import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

export interface AuthUser {
  id: string;
  email?: string;
}

export async function verifySupabaseToken(token: string): Promise<AuthUser> {
  const { data, error } = await supabaseAdmin.auth.getUser(token);

  if (error || !data.user) {
    throw new Error('Token de Supabase inválido');
  }

  return {
    id: data.user.id,
    email: data.user.email ?? undefined,
  };
}
