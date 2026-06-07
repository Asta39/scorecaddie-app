-- ============================================================
-- Group Round WHS Integration Migration
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Add WHS metadata columns to GroupRoundParticipant
ALTER TABLE IF EXISTS public."GroupRoundParticipant"
  ADD COLUMN IF NOT EXISTS "teeId" integer,
  ADD COLUMN IF NOT EXISTS "handicapBefore" double precision,
  ADD COLUMN IF NOT EXISTS "handicapAfter" double precision,
  ADD COLUMN IF NOT EXISTS "scoreDifferential" double precision,
  ADD COLUMN IF NOT EXISTS "adjustedGrossScore" integer,
  ADD COLUMN IF NOT EXISTS "totalScore" integer,
  ADD COLUMN IF NOT EXISTS "scoreVsPar" integer;

-- 2. Add course metadata to GroupRound if missing
ALTER TABLE IF EXISTS public."GroupRound"
  ADD COLUMN IF NOT EXISTS "courseName" text,
  ADD COLUMN IF NOT EXISTS "holesPlayed" integer DEFAULT 18,
  ADD COLUMN IF NOT EXISTS "coursePar" integer;

-- 3. Grant permissions
GRANT SELECT, INSERT, UPDATE ON "GroupRound" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "GroupRoundParticipant" TO authenticated;

-- 4. Initial update query helper (Optional)
SELECT 'Group Round WHS migration applied successfully 🏌️⛳' AS status;
