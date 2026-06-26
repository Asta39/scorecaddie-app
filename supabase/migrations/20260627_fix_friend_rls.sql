-- ============================================================
-- Migration: fix_friend_rls
-- Purpose  : Re-enable Row Level Security on `rounds` and
--            `hole_scores` that was temporarily disabled to
--            work around friend-visibility issues.
--            Adds proper friend-aware SELECT policies so friends
--            can see each other's scores without opening the
--            tables to all authenticated users.
-- Affects  : scorecaddie-app Supabase project (mobile backend)
-- Date     : 2026-06-27
-- ============================================================

-- ─── 1. Re-enable RLS ────────────────────────────────────────────────────────

ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE hole_scores ENABLE ROW LEVEL SECURITY;

-- ─── 2. Drop any existing open / conflicting policies safely ─────────────────

DROP POLICY IF EXISTS "Allow all" ON rounds;
DROP POLICY IF EXISTS "Enable read access for all users" ON rounds;
DROP POLICY IF EXISTS "Allow all" ON hole_scores;
DROP POLICY IF EXISTS "Enable read access for all users" ON hole_scores;

-- ─── 3. Rounds: own rows ─────────────────────────────────────────────────────

CREATE POLICY "rounds_select_own"
  ON rounds FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "rounds_insert_own"
  ON rounds FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "rounds_update_own"
  ON rounds FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "rounds_delete_own"
  ON rounds FOR DELETE
  USING (auth.uid()::text = user_id);

-- ─── 4. Rounds: friends can read ─────────────────────────────────────────────
-- "Friend" table uses camelCase because it was created before the snake_case
-- convention was established. The status column value is 'ACCEPTED'.

CREATE POLICY "rounds_select_friends"
  ON rounds FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Friend" f
      WHERE f.status = 'ACCEPTED'
        AND (
          (f."userId"   = auth.uid()::text AND f."friendId" = rounds.user_id)
          OR
          (f."friendId" = auth.uid()::text AND f."userId"   = rounds.user_id)
        )
    )
  );

-- ─── 5. hole_scores: own rows ────────────────────────────────────────────────

CREATE POLICY "hole_scores_select_own"
  ON hole_scores FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "hole_scores_insert_own"
  ON hole_scores FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "hole_scores_update_own"
  ON hole_scores FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "hole_scores_delete_own"
  ON hole_scores FOR DELETE
  USING (auth.uid()::text = user_id);

-- ─── 6. hole_scores: friends can read ────────────────────────────────────────

CREATE POLICY "hole_scores_select_friends"
  ON hole_scores FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Friend" f
      WHERE f.status = 'ACCEPTED'
        AND (
          (f."userId"   = auth.uid()::text AND f."friendId" = hole_scores.user_id)
          OR
          (f."friendId" = auth.uid()::text AND f."userId"   = hole_scores.user_id)
        )
    )
  );

-- ─── NOTE ─────────────────────────────────────────────────────────────────────
-- If the `hole_scores` table does not have a `user_id` column (some schemas
-- join via `round_id` → `rounds.user_id` instead), replace `hole_scores.user_id`
-- with a subquery:
--
--   EXISTS (
--     SELECT 1 FROM rounds r
--     WHERE r.id = hole_scores.round_id
--       AND (auth.uid()::text = r.user_id OR <friend check on r.user_id>)
--   )
--
-- Verify against your actual schema before applying.
-- ─────────────────────────────────────────────────────────────────────────────
