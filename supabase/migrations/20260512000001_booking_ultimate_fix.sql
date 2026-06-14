-- THE ULTIMATE BOOKING TABLE FIX
-- This script ensures the table exists and has exactly the columns the app expects.

DO $$
BEGIN
    -- 1. Standardize Table Name (ensure it is "Booking")
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'booking') THEN
        ALTER TABLE public.booking RENAME TO "Booking";
    END IF;
    
    -- 2. Create the table if it doesn't exist at all
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Booking') THEN
        CREATE TABLE public."Booking" (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            player_id text,
            provider_id text,
            booking_date timestamptz DEFAULT now(),
            status text DEFAULT 'PENDING',
            round_type text DEFAULT 'EIGHTEEN_HOLES',
            initiated_via text DEFAULT 'CHAT',
            start_time timestamptz,
            end_time timestamptz,
            duration_minutes integer,
            amount_paid numeric,
            payment_method text,
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now()
        );
    END IF;
END $$;

-- 3. Ensure every single column exists with the EXACT name the app is looking for
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "player_id" text;
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "provider_id" text;
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "booking_date" timestamptz DEFAULT now();
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'PENDING';
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "round_type" text DEFAULT 'EIGHTEEN_HOLES';
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "initiated_via" text DEFAULT 'CHAT';
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "start_time" timestamptz;
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "end_time" timestamptz;
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "duration_minutes" integer;
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "amount_paid" numeric;
ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "payment_method" text;

-- 4. DATA MIGRATION: If you had data in old columns, move it to the new ones
DO $$
BEGIN
    -- Move data to provider_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'providerId') THEN
        UPDATE public."Booking" SET provider_id = "providerId" WHERE provider_id IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'providerid') THEN
        UPDATE public."Booking" SET provider_id = providerid WHERE provider_id IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'caddieId') THEN
        UPDATE public."Booking" SET provider_id = "caddieId" WHERE provider_id IS NULL;
    END IF;

    -- Move data to player_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'playerId') THEN
        UPDATE public."Booking" SET player_id = "playerId" WHERE player_id IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'playerid') THEN
        UPDATE public."Booking" SET player_id = playerid WHERE player_id IS NULL;
    END IF;
END $$;

-- 5. Finalize Permissions
GRANT ALL ON TABLE public."Booking" TO authenticated, anon, service_role;

SELECT 'Booking table is now fully synchronized with the app!' as status;
