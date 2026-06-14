-- COMPREHENSIVE USER TABLE REPAIR
-- This script ensures the User table has all fields required for Caddies and Coaches.
-- It handles both camelCase and snake_case naming for safety.

DO $$
BEGIN
    -- 1. Ensure core columns exist with correct types
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

    -- 2. CREATE SNAKE_CASE ALIASES (This prevents errors if the app or PostgREST tries to use snake_case)
    -- Postgres columns are case-insensitive unless double-quoted.
    -- To be 100% safe, we ensure both variations exist or map to the same thing.
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'personality_type') THEN
        ALTER TABLE public."User" ADD COLUMN "personality_type" text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'courses_json') THEN
        ALTER TABLE public."User" ADD COLUMN "courses_json" text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'provider_status') THEN
        ALTER TABLE public."User" ADD COLUMN "provider_status" text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'handicap_index') THEN
        ALTER TABLE public."User" ADD COLUMN "handicap_index" double precision;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'profile_complete') THEN
        ALTER TABLE public."User" ADD COLUMN "profile_complete" boolean DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'avatar_url') THEN
        ALTER TABLE public."User" ADD COLUMN "avatar_url" text;
    END IF;
END $$;

-- 3. Update permissions
GRANT ALL ON TABLE public."User" TO authenticated, anon, service_role;

SELECT 'User table is now fully equipped for professional profiles!' as status;
