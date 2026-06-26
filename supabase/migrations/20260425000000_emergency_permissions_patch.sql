-- ============================================================
-- EMERGENCY PERMISSIONS & INTEGRITY PATCH
-- Run this in the Supabase SQL Editor ONCE.
-- Fixes: 42501 Unauthorized, duplicate rows, empty PlayerStat/HoleScore.
-- ============================================================

-- ── 1. GRANT core table permissions ────────────────────────

-- User table (profile sync)
GRANT SELECT, INSERT, UPDATE ON "User" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "User" TO anon;

-- Round data
GRANT SELECT, INSERT, UPDATE ON "Round" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "HoleScore" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "PlayerStat" TO authenticated;

-- Course / Tee reference data
GRANT SELECT, INSERT, UPDATE ON "Course" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "Course" TO anon;
GRANT SELECT, INSERT, UPDATE ON "Tee" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "Tee" TO anon;
GRANT SELECT, INSERT, UPDATE ON "CourseHole" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "CourseHole" TO anon;

-- Marketplace tables
GRANT SELECT, INSERT, UPDATE ON "Booking" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "Message" TO authenticated;
GRANT SELECT, INSERT, UPDATE ON "Inquiry" TO authenticated;

-- ── 2. Disable RLS on read-only reference tables ───────────
-- These are KGU-seeded tables, not user-specific, so RLS is unnecessary.

ALTER TABLE IF EXISTS "Course" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "Tee" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "CourseHole" DISABLE ROW LEVEL SECURITY;

-- ── 3. Deduplicate PlayerStat before adding UNIQUE constraint ──────────
-- The sync bug generated a new UUID row every 10 seconds.
-- Keep only the most recently recorded row per user, delete the rest.

DELETE FROM "PlayerStat"
WHERE id NOT IN (
  SELECT DISTINCT ON ("userId") id
  FROM "PlayerStat"
  ORDER BY "userId", "recordedAt" DESC NULLS LAST, id DESC
);

-- Now safe to add the unique constraint.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'PlayerStat'
    AND constraint_type = 'UNIQUE'
    AND constraint_name = 'playerstats_userid_unique'
  ) THEN
    ALTER TABLE "PlayerStat" ADD CONSTRAINT playerstats_userid_unique UNIQUE ("userId");
  END IF;
END $$;

-- ── 4. Deduplicate HoleScore before adding UNIQUE constraint ───────────
-- Without this, upsert onConflict:'roundId,holeNumber' fails and
-- hole scores accumulate as duplicates.
-- Keep the row with the highest id (most recent insert) per (roundId, holeNumber).

DELETE FROM "HoleScore"
WHERE id NOT IN (
  SELECT DISTINCT ON ("roundId", "holeNumber") id
  FROM "HoleScore"
  ORDER BY "roundId", "holeNumber", id DESC
);

-- Now safe to add the unique constraint.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'HoleScore'
    AND constraint_type = 'UNIQUE'
    AND constraint_name = 'holescore_round_hole_unique'
  ) THEN
    ALTER TABLE "HoleScore" ADD CONSTRAINT holescore_round_hole_unique UNIQUE ("roundId", "holeNumber");
  END IF;
END $$;

-- ── 5. Deduplicate Course table by name ────────────────────
-- Keeps the oldest (MIN id) row per course name.
-- Must delete orphaned CourseHole rows FIRST to satisfy the FK constraint.

-- Step 5a: Remove CourseHole rows that belong to duplicate Course rows
-- (i.e. any course that is NOT the keeper for its name group).
DELETE FROM "CourseHole"
WHERE "courseId" IN (
  SELECT id FROM "Course"
  WHERE id NOT IN (
    SELECT MIN(id)
    FROM "Course"
    GROUP BY name
  )
);

-- Step 5b: Now safe to delete the duplicate Course rows.
DELETE FROM "Course"
WHERE id NOT IN (
  SELECT MIN(id)
  FROM "Course"
  GROUP BY name
);

-- ── 6. Ensure firebaseUid column exists on User ────────────
ALTER TABLE IF EXISTS "User"
  ADD COLUMN IF NOT EXISTS "firebaseUid" TEXT;

-- Index for fast lookups by firebaseUid (used heavily by getProfile)
CREATE INDEX IF NOT EXISTS idx_user_firebase_uid
  ON "User"("firebaseUid");

-- ── 7. Ensure Round.id has a unique constraint ─────────────
-- Required for onConflict:'id' in syncRound to work correctly.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'Round'
    AND constraint_type = 'UNIQUE'
    AND constraint_name = 'round_id_unique'
  ) THEN
    ALTER TABLE "Round" ADD CONSTRAINT round_id_unique UNIQUE ("id");
  END IF;
END $$;

-- ── Done! ────────────────────────────────────────────────────
SELECT 'Emergency patch applied successfully 🏌️' AS status;
