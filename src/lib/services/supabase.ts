import { createClient } from "@supabase/supabase-js";

const supabaseURL = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseURL, supabaseKey);

export async function fetchLocations() {
    let locations = [];
    const { data, error } = await supabase.from('locations').select('*');
    if (error) {
        console.error('Error fetching locations:', error.message);
        return []
    }

    if (data) {
        locations = data;
    }

    return locations;
}