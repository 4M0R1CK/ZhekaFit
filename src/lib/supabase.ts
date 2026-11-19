import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const publishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!url || !publishableKey) {
  throw new Error('Supabase config is missing. Copy .env.example to .env.local and set project credentials.')
}

export const supabase = createClient(url, publishableKey)
