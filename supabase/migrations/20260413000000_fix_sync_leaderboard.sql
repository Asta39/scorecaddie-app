-- ============================================================
-- Supabase Schema & Leaderboard Fix (Comprehensive v2)
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Ensure User table has ALL necessary columns for Leaderboard and Social
CREATE TABLE IF NOT EXISTS public."User" (
    "id" text PRIMARY KEY,
    "firebaseUid" text UNIQUE,
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
  ADD COLUMN IF NOT EXISTS "firebaseUid" text UNIQUE,
  ADD COLUMN IF NOT EXISTS "isProvisional" boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS "handicapOrigin" text DEFAULT 'Calculated',
  ADD COLUMN IF NOT EXISTS "fcmToken" text;

-- 1.5 Create Course, Tee, and CourseHole reference tables
CREATE TABLE IF NOT EXISTS public."Course" (
    "id" text PRIMARY KEY,
    "name" text NOT NULL,
    "location" text,
    "city" text,
    "region" text,
    "holesCount" integer,
    "par18" integer,
    "updatedAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."Tee" (
    "id" text PRIMARY KEY,
    "courseId" text NOT NULL REFERENCES public."Course"("id") ON DELETE CASCADE,
    "name" text NOT NULL,
    "gender" text,
    "courseRating" double precision,
    "slopeRating" double precision,
    "par" integer,
    "yardage" integer
);

CREATE TABLE IF NOT EXISTS public."CourseHole" (
    "id" text PRIMARY KEY,
    "courseId" text NOT NULL REFERENCES public."Course"("id") ON DELETE CASCADE,
    "teeId" text REFERENCES public."Tee"("id") ON DELETE CASCADE,
    "holeNumber" integer NOT NULL,
    "par" integer NOT NULL,
    "handicapIndex" integer,
    "distance" integer,
    "updatedAt" timestamp with time zone DEFAULT now()
);

-- 1.6 Create Marketplace tables
CREATE TABLE IF NOT EXISTS public."Booking" (
    "id" text PRIMARY KEY,
    "playerId" text REFERENCES public."User"("id"),
    "providerId" text REFERENCES public."User"("id"),
    "bookingDate" timestamp with time zone,
    "roundType" text,
    "initiatedVia" text,
    "startTime" text,
    "endTime" text,
    "durationMinutes" integer,
    "amountPaid" double precision,
    "paymentMethod" text,
    "status" text DEFAULT 'pending',
    "updatedAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."Message" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "bookingId" text REFERENCES public."Booking"("id") ON DELETE CASCADE,
    "senderId" text REFERENCES public."User"("id"),
    "receiverId" text REFERENCES public."User"("id"),
    "content" text,
    "createdAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."Inquiry" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" text REFERENCES public."User"("id"),
    "providerId" text REFERENCES public."User"("id"),
    "status" text DEFAULT 'open',
    "createdAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."Review" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "bookingId" text REFERENCES public."Booking"("id"),
    "reviewerId" text REFERENCES public."User"("id"),
    "revieweeId" text REFERENCES public."User"("id"),
    "rating" integer,
    "comment" text,
    "createdAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."interactions" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" text REFERENCES public."User"("id"),
    "targetId" text REFERENCES public."User"("id"),
    "type" text,
    "createdAt" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."tee_time_reminder" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "local_id" text NOT NULL,
    "user_id" text NOT NULL REFERENCES public."User"("id"),
    "reminder_date" timestamp with time zone,
    "notify_before_minutes" integer,
    "notes" text,
    "is_active" boolean DEFAULT true,
    "fcm_token" text,
    "created_at" timestamp with time zone DEFAULT now(),
    UNIQUE ("user_id", "local_id")
);

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
    "syncId" text,
    "createdAt" timestamp with time zone DEFAULT now(),
    "updatedAt" timestamp with time zone DEFAULT now(),
    UNIQUE("roundId", "holeNumber")
);

-- 3.5 Create PlayerStat table
CREATE TABLE IF NOT EXISTS public."PlayerStat" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" text NOT NULL REFERENCES public."User"("id") ON DELETE CASCADE,
    "handicapIndex" double precision,
    "avgScore" double precision,
    "fairwayHitPct" double precision,
    "girPct" double precision,
    "avgPutts" double precision,
    "recordedAt" timestamp with time zone DEFAULT now(),
    CONSTRAINT playerstats_userid_unique UNIQUE ("userId")
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
ALTER TABLE public."PlayerStat" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Course" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Tee" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."CourseHole" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Booking" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Message" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Inquiry" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Review" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."interactions" ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public."Friend" ENABLE ROW LEVEL SECURITY;

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
USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

-- 10. POLICIES: PlayerStat
DROP POLICY IF EXISTS "Player stats are viewable by everyone" ON public."PlayerStat";
CREATE POLICY "Player stats are viewable by everyone" ON public."PlayerStat" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can manage own stats" ON public."PlayerStat";
CREATE POLICY "Users can manage own stats" ON public."PlayerStat" FOR ALL TO authenticated 
USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

-- 11. POLICIES: Course Reference Data
DROP POLICY IF EXISTS "Courses are viewable by everyone" ON public."Course";
CREATE POLICY "Courses are viewable by everyone" ON public."Course" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Tees are viewable by everyone" ON public."Tee";
CREATE POLICY "Tees are viewable by everyone" ON public."Tee" FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "CourseHoles are viewable by everyone" ON public."CourseHole";
CREATE POLICY "CourseHoles are viewable by everyone" ON public."CourseHole" FOR SELECT TO authenticated USING (true);

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
