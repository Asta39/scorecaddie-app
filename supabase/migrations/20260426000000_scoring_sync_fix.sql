-- ============================================================
-- Scoring & Sync Fix Migration
-- Run this in the Supabase SQL Editor
-- Adds missing columns to Round table and enriches data pipeline
-- ============================================================

-- 1. Add missing columns to Round table
-- These columns exist in the local Drift schema but were never added to Supabase.
ALTER TABLE IF EXISTS public."Round"
  ADD COLUMN IF NOT EXISTS "adjustedGrossScore" integer,
  ADD COLUMN IF NOT EXISTS "scoreVsPar" integer,
  ADD COLUMN IF NOT EXISTS "coursePar" integer,
  ADD COLUMN IF NOT EXISTS "courseName" text,
  ADD COLUMN IF NOT EXISTS "holesPlayed" integer DEFAULT 18,
  ADD COLUMN IF NOT EXISTS "front9Score" integer,
  ADD COLUMN IF NOT EXISTS "back9Score" integer,
  ADD COLUMN IF NOT EXISTS "totalNet" integer;

-- 2. Ensure HoleScore columns match the app's data model
-- gir (Boolean) already exists from Prisma. fairwayHit is text in the app.
-- The app sends 'Hit', 'Left', 'Right' as text, not the Prisma enum.
-- Alter the column type if it's still using the enum.
DO $$
BEGIN
  -- Check if fairwayHit is an enum type and convert to text if so
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'HoleScore'
    AND column_name = 'fairwayHit'
    AND data_type = 'USER-DEFINED'
  ) THEN
    ALTER TABLE "HoleScore" ALTER COLUMN "fairwayHit" TYPE TEXT USING "fairwayHit"::TEXT;
  END IF;
END $$;

-- 3. Ensure permissions for the new columns work
GRANT SELECT, INSERT, UPDATE ON "Round" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "HoleScore" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "PlayerStat" TO authenticated;

-- ── Done! ────────────────────────────────────────────────────
SELECT 'Scoring & Sync fix migration applied successfully 🏌️⛳' AS status;
