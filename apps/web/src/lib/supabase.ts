import { createClient } from "@supabase/supabase-js";

type SupabaseClient = ReturnType<typeof createClient>;

let serviceClient: SupabaseClient | null = null;
let anonClient: SupabaseClient | null = null;

const getSupabaseUrl = () => {
  const url = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url) {
    throw new Error("SUPABASE_URL or NEXT_PUBLIC_SUPABASE_URL must be defined");
  }
  return url;
};

const getServiceKey = () => {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY must be defined for server operations");
  }
  return key;
};

const getAnonKey = () => {
  const key = process.env.SUPABASE_ANON_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!key) {
    throw new Error("SUPABASE_ANON_KEY must be defined");
  }
  return key;
};

export const getServiceSupabase = () => {
  if (!serviceClient) {
    serviceClient = createClient(getSupabaseUrl(), getServiceKey(), {
      auth: {
        persistSession: false
      }
    });
  }
  return serviceClient;
};

export const getAnonSupabase = () => {
  if (!anonClient) {
    anonClient = createClient(getSupabaseUrl(), getAnonKey(), {
      auth: {
        persistSession: false
      }
    });
  }
  return anonClient;
};
