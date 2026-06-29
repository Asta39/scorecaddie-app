-- ============================================================
-- Migration: fix_friend_rls
-- Purpose  : Re-enable Row Level Security on `"Round"` and
--            `"HoleScore"` that was temporarily disabled to
--            work around friend-visibility issues.
--            Adds proper friend-aware SELECT policies so friends
--            can see each other's scores without opening the
--            tables to all authenticated users.
-- Affects  : scorecaddie-app Supabase project (mobile backend)
-- Date     : 2026-06-27
-- ============================================================

-- ─── 1. Re-enable RLS ────────────────────────────────────────────────────────

ALTER TABLE "Round" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "HoleScore" ENABLE ROW LEVEL SECURITY;

-- ─── 2. Drop any existing open / conflicting policies safely ─────────────────

DROP POLICY IF EXISTS "Allow all" ON "Round";
DROP POLICY IF EXISTS "Enable read access for all users" ON "Round";
DROP POLICY IF EXISTS "Allow all" ON "HoleScore";
DROP POLICY IF EXISTS "Enable read access for all users" ON "HoleScore";

-- ─── 3. Round: own rows ─────────────────────────────────────────────────────

CREATE POLICY "Round_select_own"
  ON "Round" FOR SELECT
  USING (auth.uid()::text = "userId");

CREATE POLICY "Round_insert_own"
  ON "Round" FOR INSERT
  WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Round_update_own"
  ON "Round" FOR UPDATE
  USING (auth.uid()::text = "userId")
  WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Round_delete_own"
  ON "Round" FOR DELETE
  USING (auth.uid()::text = "userId");

-- ─── 4. Round: friends can read ─────────────────────────────────────────────
-- "Friend" table uses camelCase because it was created before the snake_case
-- convention was established. The status column value is 'ACCEPTED'.

CREATE POLICY "Round_select_friends"
  ON "Round" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Friend" f
      WHERE f.status = 'ACCEPTED'
        AND (
          (f."userId"   = auth.uid()::text AND f."friendId" = "Round"."userId")
          OR
          (f."friendId" = auth.uid()::text AND f."userId"   = "Round"."userId")
        )
    )
  );

-- ─── 5. HoleScore: own rows ────────────────────────────────────────────────
-- HoleScore joins to Round to verify ownership.

CREATE POLICY "HoleScore_select_own"
  ON "HoleScore" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Round" r
      WHERE r.id = "HoleScore"."roundId"
        AND r."userId" = auth.uid()::text
    )
  );

CREATE POLICY "HoleScore_insert_own"
  ON "HoleScore" FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "Round" r
      WHERE r.id = "HoleScore"."roundId"
        AND r."userId" = auth.uid()::text
    )
  );

CREATE POLICY "HoleScore_update_own"
  ON "HoleScore" FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM "Round" r
      WHERE r.id = "HoleScore"."roundId"
        AND r."userId" = auth.uid()::text
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "Round" r
      WHERE r.id = "HoleScore"."roundId"
        AND r."userId" = auth.uid()::text
    )
  );

CREATE POLICY "HoleScore_delete_own"
  ON "HoleScore" FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM "Round" r
      WHERE r.id = "HoleScore"."roundId"
        AND r."userId" = auth.uid()::text
    )
  );

-- ─── 6. HoleScore: friends can read ────────────────────────────────────────

CREATE POLICY "HoleScore_select_friends"
  ON "HoleScore" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Round" r
      JOIN "Friend" f ON (
        f.status = 'ACCEPTED'
        AND (
          (f."userId" = auth.uid()::text AND f."friendId" = r."userId")
          OR
          (f."friendId" = auth.uid()::text AND f."userId" = r."userId")
        )
      )
      WHERE r.id = "HoleScore"."roundId"
    )
  );

