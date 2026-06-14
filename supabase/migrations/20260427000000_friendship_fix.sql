-- ============================================================
-- Friendship & Social Infrastructure Migration (FIXED v4 - TOTAL CLEANUP)
-- Run this in the Supabase SQL Editor
-- This version addresses broken policies in OTHER migrations that cause errors
-- ============================================================

-- 1. Fix the suspected broken policy in the existing 'secure_coaching' logic
-- We've identified that 'public.User.id' is TEXT, so 'id = auth.uid()' in existing policies fails.
DO $$
BEGIN
    -- Fix coaching policies if they exist
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Coaches can view their own sessions' AND tablename = 'CoachingSession') THEN
        DROP POLICY "Coaches can view their own sessions" ON public."CoachingSession";
        CREATE POLICY "Coaches can view their own sessions" ON public."CoachingSession"
        USING (coach_id = auth.uid()::text OR coach_id = (select "firebaseUid" from public."User" where id = auth.uid()::text));
    END IF;

    -- Add more global fixes for the User table if needed
    -- The error 'uuid = text' often ripples through all policies on a table.
END $$;

-- 2. Create or Update the Friend table
CREATE TABLE IF NOT EXISTS public."Friend" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "userId" text NOT NULL,
    "friendId" text NOT NULL,
    "status" text NOT NULL DEFAULT 'PENDING',
    "createdAt" timestamp with time zone DEFAULT now(),
    "updatedAt" timestamp with time zone DEFAULT now(),
    UNIQUE("userId", "friendId")
);

-- 3. Ensure User table has correct structure for social features
-- We use id TEXT to match your legacy schema
CREATE TABLE IF NOT EXISTS public."User" (
    "id" text PRIMARY KEY,
    "name" text,
    "avatarUrl" text,
    "handicapIndex" double precision DEFAULT 0.0,
    "skillLevel" text DEFAULT 'Amateur',
    "playStyle" text DEFAULT 'Mixed',
    "updatedAt" timestamp with time zone DEFAULT now()
);

-- 4. Enable RLS
ALTER TABLE public."Friend" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."User" ENABLE ROW LEVEL SECURITY;

-- 5. Friendship Table Policies (Unified TEXT Comparison)
DROP POLICY IF EXISTS "Users can view their own friendships" ON public."Friend";
CREATE POLICY "Users can view their own friendships" 
ON public."Friend" FOR SELECT 
TO authenticated 
USING (auth.uid()::text = "userId"::text OR auth.uid()::text = "friendId"::text);

DROP POLICY IF EXISTS "Users can send friend requests" ON public."Friend";
CREATE POLICY "Users can send friend requests" 
ON public."Friend" FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid()::text = "userId"::text);

DROP POLICY IF EXISTS "Users can update their friendships" ON public."Friend";
CREATE POLICY "Users can update their friendships" 
ON public."Friend" FOR UPDATE 
TO authenticated 
USING (auth.uid()::text = "userId"::text OR auth.uid()::text = "friendId"::text)
WITH CHECK (auth.uid()::text = "userId"::text OR auth.uid()::text = "friendId"::text);

DROP POLICY IF EXISTS "Users can delete their friendships" ON public."Friend";
CREATE POLICY "Users can delete their friendships" 
ON public."Friend" FOR DELETE 
TO authenticated 
USING (auth.uid()::text = "userId"::text OR auth.uid()::text = "friendId"::text);

-- 6. User Table Policies (Unified TEXT Comparison)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public."User";
CREATE POLICY "Profiles are viewable by everyone" 
ON public."User" FOR SELECT 
TO authenticated 
USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public."User";
CREATE POLICY "Users can update own profile" 
ON public."User" FOR UPDATE 
TO authenticated 
USING (auth.uid()::text = id::text);

DROP POLICY IF EXISTS "Users can insert own profile" ON public."User";
CREATE POLICY "Users can insert own profile" 
ON public."User" FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid()::text = id::text);

-- 7. Enable Realtime
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'Friend') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."Friend";
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'User') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."User";
  END IF;
END $$;

-- ── Done! ────────────────────────────────────────────────────
SELECT 'Social fix migration applied (v4 TOTAL CLEANUP)! 🏌️‍♂️🤝' AS status;
