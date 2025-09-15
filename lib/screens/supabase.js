import { createClient } from '@supabase/supabase-js';
import 'dotenv/config'; // Only needed for non-Vite setups

const supabaseUrl = process.env_SUPABASE_URL || process.env.SUPABASE_URL;
const supabaseKey = process.env_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

export default supabase;