-- ============================================================
-- Final Sync & Leaderboard Fix
-- ============================================================

-- 1. Add missing WHS, Identity, and Profile columns to the User table
ALTER TABLE public."User" 
  ADD COLUMN IF NOT EXISTS "email" text,
  ADD COLUMN IF NOT EXISTS "role" text DEFAULT 'PLAYER',
  ADD COLUMN IF NOT EXISTS "anchorIndex" double precision,
  ADD COLUMN IF NOT EXISTS "pfpType" text,
  ADD COLUMN IF NOT EXISTS "pfpVerified" boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS "providerStatus" text,
  ADD COLUMN IF NOT EXISTS "phone" text,
  ADD COLUMN IF NOT EXISTS "whatsapp" text,
  ADD COLUMN IF NOT EXISTS "experience" integer,
  ADD COLUMN IF NOT EXISTS "price" numeric,
  ADD COLUMN IF NOT EXISTS "certificationUrl" text,
  ADD COLUMN IF NOT EXISTS "coachingLocation" text,
  ADD COLUMN IF NOT EXISTS "profileComplete" boolean DEFAULT false;

-- 2. Ensure handicapIndex is double precision (matching the app's expectations)
-- We check existence first just in case
ALTER TABLE public."User" ALTER COLUMN "handicapIndex" TYPE double precision;

-- 3. Ensure permissions are set correctly for the User table
-- This is critical for the ApiService.syncProfile to work
GRANT SELECT, INSERT, UPDATE, DELETE ON public."User" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."User" TO anon;

-- 4. Enable Realtime for User table (needed for reactive leaderboard updates)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'User') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."User";
  END IF;
END $$;

-- Done!
SELECT 'Final sync and profile fixes applied! 🏌️‍♂️🚀' AS status;
