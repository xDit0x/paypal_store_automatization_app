import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import { env, requireSupabaseEnv } from '../../config/env.js';

function createSupabaseAdmin(): SupabaseClient {
  requireSupabaseEnv();

  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

export const supabaseAdmin = createSupabaseAdmin();
