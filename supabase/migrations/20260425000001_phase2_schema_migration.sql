-- ============================================================
-- Phase 2: Supabase Schema Migration (WHS, Social, Notifications)
-- Run this in the Supabase SQL Editor
-- ============================================================

-- 1. CLEAN SLATE: Truncate existing user data to ensure a fresh Supabase start
TRUNCATE TABLE public."User" CASCADE;

-- 2. Augment "Round" table for WHS tracking
ALTER TABLE IF EXISTS public."Round" 
  ADD COLUMN IF NOT EXISTS "scoreDifferential" numeric(5,1),
  ADD COLUMN IF NOT EXISTS "handicapBefore" numeric(5,1),
  ADD COLUMN IF NOT EXISTS "handicapAfter" numeric(5,1);

-- 3. Group Rounds & Participants
CREATE TABLE IF NOT EXISTS public."GroupRound" (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "roundCode" TEXT UNIQUE NOT NULL,
  "captainId" TEXT NOT NULL,
  "courseId" TEXT NOT NULL,
  status TEXT DEFAULT 'PENDING',
  "scoringMode" TEXT DEFAULT 'INDIVIDUAL_DEVICES',
  "createdAt" timestamptz DEFAULT now(),
  "updatedAt" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."GroupRoundParticipant" (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "groupRoundId" uuid REFERENCES public."GroupRound"(id) ON DELETE CASCADE,
  "userId" TEXT NOT NULL,
  "status" TEXT DEFAULT 'JOINED',
  "role" TEXT DEFAULT 'PLAYER',
  "joinedAt" timestamptz DEFAULT now(),
  UNIQUE("groupRoundId", "userId")
);

-- 4. Friend Requests & Relationships
CREATE TABLE IF NOT EXISTS public."Friend" (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "friendId" TEXT NOT NULL,
  "status" TEXT DEFAULT 'PENDING', -- PENDING, ACCEPTED, BLOCKED
  "createdAt" timestamptz DEFAULT now(),
  "updatedAt" timestamptz DEFAULT now(),
  UNIQUE("userId", "friendId")
);

-- 5. Leaderboards
CREATE TABLE IF NOT EXISTS public."Leaderboard" (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  "groupRoundId" uuid REFERENCES public."GroupRound"(id) ON DELETE CASCADE NULL,
  "startDate" timestamptz DEFAULT now(),
  "endDate" timestamptz,
  "status" TEXT DEFAULT 'ACTIVE',
  "createdAt" timestamptz DEFAULT now()
);

-- 6. Notifications (FCM Bridge)
CREATE TABLE IF NOT EXISTS public."Notification" (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "userId" TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  "dataJson" TEXT,
  "isRead" BOOLEAN DEFAULT false,
  "createdAt" timestamptz DEFAULT now()
);

-- 7. Add FCM Token target on User
ALTER TABLE IF EXISTS public."User" 
  ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

-- 8. Setup basic open permissions for now until Phase 4 (RLS lockdown)
GRANT SELECT, INSERT, UPDATE, DELETE ON public."GroupRound" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."GroupRoundParticipant" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."Friend" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."Leaderboard" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."Notification" TO authenticated;

SELECT 'Phase 2 Migration successfully generated and applied!' as Status;
