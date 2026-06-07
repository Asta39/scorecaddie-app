-- ============================================================
-- Advanced Performance Indices for Leaderboard Optimization
-- ============================================================

-- 1. Composite indices for the "Course" tab leaderboard
-- These cover filtering by courseId and playedAt, while ordering by score/net
CREATE INDEX IF NOT EXISTS idx_round_course_played_gross 
ON public."Round"("courseId", "playedAt" DESC, "totalScore" DESC);

CREATE INDEX IF NOT EXISTS idx_round_course_played_net 
ON public."Round"("courseId", "playedAt" DESC, "totalNet" ASC);

-- 2. Composite indices for the "Global" and "Friends" tab leaderboards
-- These cover filtering by playedAt (time period) and ordering by score/net
CREATE INDEX IF NOT EXISTS idx_round_played_gross 
ON public."Round"("playedAt" DESC, "totalScore" DESC);

CREATE INDEX IF NOT EXISTS idx_round_played_net 
ON public."Round"("playedAt" DESC, "totalNet" ASC);

-- 3. Optimized index for Friend retrieval
-- The query uses: .or('userId.eq.$currentUserId,friendId.eq.$currentUserId').eq('status', 'ACCEPTED')
-- We want indices that support both sides of the OR for ACCEPTED friends
CREATE INDEX IF NOT EXISTS idx_friend_user_accepted 
ON public."Friend"("userId", "status") 
WHERE "status" = 'ACCEPTED';

CREATE INDEX IF NOT EXISTS idx_friend_friend_accepted 
ON public."Friend"("friendId", "status") 
WHERE "status" = 'ACCEPTED';

-- 4. Covered index for User joins
-- Speeds up the inner join User(name, avatarUrl, handicapIndex, isProvisional, handicapOrigin)
CREATE INDEX IF NOT EXISTS idx_user_leaderboard_data 
ON public."User"("id") 
INCLUDE ("name", "avatarUrl", "handicapIndex", "isProvisional", "handicapOrigin");

-- Done!
SELECT 'Advanced leaderboard indices applied! 🏌️‍♂️🔥' AS status;
