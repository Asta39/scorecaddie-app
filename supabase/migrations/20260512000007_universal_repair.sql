-- THE UNIVERSAL DATABASE REPAIR SCRIPT (V4)
-- This script fixes every table and column to ensure total compatibility with the new Caddie app.

DO $$
BEGIN
    -- 1. FIX USER TABLE
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "phone" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "whatsapp" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "bio" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "experience" integer DEFAULT 0;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "price" numeric DEFAULT 0;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "personalityType" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "coursesJson" text DEFAULT '[]';
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "certificationUrl" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "coachingLocation" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "profileComplete" boolean DEFAULT false;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "providerStatus" text DEFAULT 'OFFLINE';
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "handicapIndex" double precision DEFAULT 0;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "pfpVerified" boolean DEFAULT false;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "avatarUrl" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "pfpType" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "specializations" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "targetAudience" text;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "rating" numeric DEFAULT 5.0;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "totalReviews" integer DEFAULT 0;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "totalBookings" integer DEFAULT 0;
    ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS "views" integer DEFAULT 0;

    -- 2. FIX BOOKING TABLE
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
    ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "provider_id" text;
    ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "player_id" text;
    ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "booking_date" timestamptz DEFAULT now();
    ALTER TABLE public."Booking" ADD COLUMN IF NOT EXISTS "amount_paid" numeric;

    -- 3. FIX REVIEW TABLE
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Review') THEN
        CREATE TABLE public."Review" (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            provider_id text,
            player_id text,
            player_name text DEFAULT 'Golfer',
            player_avatar text,
            rating integer DEFAULT 5,
            comment text,
            "createdAt" timestamptz DEFAULT now()
        );
    END IF;
    ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "provider_id" text;
    ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "player_id" text;
    ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "player_name" text;

    -- 4. FIX INTERACTIONS TABLE
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'interactions') THEN
        CREATE TABLE public."interactions" (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            player_id text,
            provider_id text,
            type text,
            status text DEFAULT 'pending',
            "lastPromptedAt" timestamptz,
            timestamp timestamptz DEFAULT now()
        );
    END IF;
    ALTER TABLE public."interactions" ADD COLUMN IF NOT EXISTS "player_id" text;
    ALTER TABLE public."interactions" ADD COLUMN IF NOT EXISTS "provider_id" text;

END $$;

-- 5. Set Global Permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, anon, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;

-- 6. Enable Realtime (safely)
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
  ALTER PUBLICATION supabase_realtime ADD TABLE public."User";
  ALTER PUBLICATION supabase_realtime ADD TABLE public."Booking";
  ALTER PUBLICATION supabase_realtime ADD TABLE public."Review";
  ALTER PUBLICATION supabase_realtime ADD TABLE public."interactions";
COMMIT;

SELECT 'DATABASE REPAIRED SUCCESSFULLY! 🚀' as status;
