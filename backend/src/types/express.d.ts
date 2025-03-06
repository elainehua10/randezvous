import { SupabaseClient } from '@supabase/supabase-js';

declare module 'express-serve-static-core' {
  interface Request {
    supabase: SupabaseClient;
  }
}