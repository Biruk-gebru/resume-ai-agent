from supabase import create_client, Client
from app.config import SUPABASE_URL, SUPABASE_API_KEY

url : str = SUPABASE_URL
key : str = SUPABASE_API_KEY

# Initialize Supabase client
supabase: Client = create_client(url, key)
