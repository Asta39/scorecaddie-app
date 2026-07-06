-- Add missing columns to competition_entries
ALTER TABLE competition_entries
ADD COLUMN IF NOT EXISTS mpesa_phone_number text,
ADD COLUMN IF NOT EXISTS preferred_time_window text,
ADD COLUMN IF NOT EXISTS paystack_reference text;
