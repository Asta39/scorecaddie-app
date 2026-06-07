-- ============================================================
-- Supabase Schema & Leaderboard Fix (Comprehensive v2)
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Ensure User table has ALL necessary columns for Leaderboard and Social
CREATE TABLE IF NOT EXISTS public."User" (
    "id" text PRIMARY KEY,
    "name" text,
    "avatarUrl" text,
    "handicapIndex" double precision DEFAULT 0.0,
    "skillLevel" text DEFAULT 'Amateur',
    "playStyle" text DEFAULT 'Mixed',
    "isProvisional" boolean DEFAULT true,
    "handicapOrigin" text DEFAULT 'Calculated',
    "fcmToken" text,
    "updatedAt" timestamp with time zone DEFAULT now()
);

-- Ensure all columns exist if table was already created partial
ALTER TABLE public."User" 
  ADD COLUMN IF NOT EXISTS "isProvisional" boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS "handicapOrigin" text DEFAULT 'Calculated',
  ADD COLUMN IF NOT EXISTS "fcmToken" text;

-- 2. Create the Round table if it doesn't exist (used by Leaderboard)
CREATE TABLE IF NOT EXISTS public."Round" (
    "id" uuid PRIMARY KEY, 
    "userId" text NOT NULL REFERENCES public."User"(id) ON DELETE CASCADE,
    "courseId" text NOT NULL,
    "courseName" text,
    "playedAt" timestamp with time zone DEFAULT now(),
    "totalScore" integer NOT NULL,
    "totalNet" integer,
    "scoreVsPar" integer,
    "holesPlayed" integer DEFAULT 18,
    "scoreDifferential" double precision,
    "handicapBefore" double precision,
    "handicapAfter" double precision,
    "adjustedGrossScore" integer,
    "coursePar" integer DEFAULT 72,
    "front9Score" integer,
    "back9Score" integer,
    "isGroup" boolean DEFAULT false,
    "syncId" text,
    "createdAt" timestamp with time zone DEFAULT now(),
    "updatedAt" timestamp with time zone DEFAULT now()
);

-- 3. Create HoleScore table (used by SyncService)
CREATE TABLE IF NOT EXISTS public."HoleScore" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "roundId" uuid REFERENCES public."Round"(id) ON DELETE CASCADE,
    "holeNumber" integer NOT NULL,
    "par" integer NOT NULL,
    "score" integer NOT NULL,
    "putts" integer,
    "fairwayHit" text,
    "penalties" integer,
    "gir" boolean,
    UNIQUE("roundId", "holeNumber")
);

-- 4. Create GroupRound Tables
CREATE TABLE IF NOT EXISTS public."GroupRound" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "roundCode" text UNIQUE NOT NULL,
    "captainId" text NOT NULL REFERENCES public."User"(id),
    "courseId" text NOT NULL,
    "courseName" text,
    "coursePar" integer DEFAULT 72,
    "holesPlayed" integer DEFAULT 18,
    "status" text DEFAULT 'PENDING',
    "scoringMode" text DEFAULT 'INDIVIDUAL_DEVICES',
    "createdAt" timestamp with time zone DEFAULT now(),
    "updatedAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."GroupRoundParticipant" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "groupRoundId" uuid REFERENCES public."GroupRound"(id) ON DELETE CASCADE,
    "userId" text NOT NULL REFERENCES public."User"(id),
    "status" text DEFAULT 'JOINED',
    "role" text DEFAULT 'PLAYER',
    "teeId" integer,
    "handicapBefore" double precision,
    "handicapAfter" double precision,
    "scores" jsonb DEFAULT '{}', -- Store hole scores in JSON for simplicity
    "joinedAt" timestamp with time zone DEFAULT now(),
    UNIQUE("groupRoundId", "userId")
);

-- 5. Enable RLS on everything
ALTER TABLE public."User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Round" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."HoleScore" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."GroupRound" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."GroupRoundParticipant" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Friend" ENABLE ROW LEVEL SECURITY;

-- 6. POLICIES: User (Profiles are public)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public."User";
CREATE POLICY "Profiles are viewable by everyone" ON public."User" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can manage own profile" ON public."User";
CREATE POLICY "Users can manage own profile" ON public."User" FOR ALL TO authenticated 
USING (auth.uid()::text = id::text) WITH CHECK (auth.uid()::text = id::text);

-- 7. POLICIES: Round (Leaderboard Visibility)
DROP POLICY IF EXISTS "Rounds are viewable by everyone" ON public."Round";
CREATE POLICY "Rounds are viewable by everyone" ON public."Round" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can manage own rounds" ON public."Round";
CREATE POLICY "Users can manage own rounds" ON public."Round" FOR ALL TO authenticated 
USING (auth.uid()::text = "userId"::text) WITH CHECK (auth.uid()::text = "userId"::text);

-- 8. POLICIES: HoleScore
DROP POLICY IF EXISTS "Hole scores are viewable by everyone" ON public."HoleScore";
CREATE POLICY "Hole scores are viewable by everyone" ON public."HoleScore" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can manage own hole scores" ON public."HoleScore";
CREATE POLICY "Users can manage own hole scores" ON public."HoleScore" FOR ALL TO authenticated 
USING (EXISTS (SELECT 1 FROM public."Round" WHERE public."Round".id = public."HoleScore"."roundId" AND public."Round"."userId" = auth.uid()::text));

-- 9. POLICIES: GroupRound
DROP POLICY IF EXISTS "Group rounds are viewable by everyone" ON public."GroupRound";
CREATE POLICY "Group rounds are viewable by everyone" ON public."GroupRound" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can create group rounds" ON public."GroupRound";
CREATE POLICY "Authenticated users can create group rounds" ON public."GroupRound" FOR INSERT TO authenticated WITH CHECK (auth.uid()::text = "captainId"::text);

-- 10. POLICIES: GroupRoundParticipant
DROP POLICY IF EXISTS "Participants are viewable by everyone" ON public."GroupRoundParticipant";
CREATE POLICY "Participants are viewable by everyone" ON public."GroupRoundParticipant" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can manage own participation" ON public."GroupRoundParticipant";
CREATE POLICY "Users can manage own participation" ON public."GroupRoundParticipant" FOR ALL TO authenticated 
USING (auth.uid()::text = "userId"::text) WITH CHECK (auth.uid()::text = "userId"::text);

-- 11. Enable Realtime
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'GroupRound') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."GroupRound";
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'GroupRoundParticipant') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."GroupRoundParticipant";
  END IF;
END $$;

-- Done!
SELECT 'Unified Supabase Schema Fix applied! 🏌️‍♂️🌍' AS status;
