-- ============================================================
-- Performance Indices for Leaderboard & Sync
-- ============================================================

-- 1. Round table indices for common filter/order columns
CREATE INDEX IF NOT EXISTS idx_round_userId ON public."Round"("userId");
CREATE INDEX IF NOT EXISTS idx_round_courseId ON public."Round"("courseId");
CREATE INDEX IF NOT EXISTS idx_round_playedAt ON public."Round"("playedAt");
CREATE INDEX IF NOT EXISTS idx_round_totalScore ON public."Round"("totalScore");
CREATE INDEX IF NOT EXISTS idx_round_totalNet ON public."Round"("totalNet");

-- 2. Friend table indices for social leaderboard
CREATE INDEX IF NOT EXISTS idx_friend_userId ON public."Friend"("userId");
CREATE INDEX IF NOT EXISTS idx_friend_friendId ON public."Friend"("friendId");
CREATE INDEX IF NOT EXISTS idx_friend_status ON public."Friend"("status");

-- 3. User table indices (mostly for joins)
CREATE INDEX IF NOT EXISTS idx_user_name ON public."User"("name");

-- 4. HoleScore indices (to speed up round details fetch)
CREATE INDEX IF NOT EXISTS idx_holescore_roundId ON public."HoleScore"("roundId");

-- 5. Enable index-only scans for common leaderboard queries by including userId
-- This helps when we do "select userId, totalScore from Round where courseId = ... order by totalScore"
CREATE INDEX IF NOT EXISTS idx_round_leaderboard_gross ON public."Round"("courseId", "totalScore") INCLUDE ("userId");
CREATE INDEX IF NOT EXISTS idx_round_leaderboard_net ON public."Round"("courseId", "totalNet") INCLUDE ("userId");

-- Done!
SELECT 'Performance indices applied! 🏌️‍♂️🚀' AS status;
