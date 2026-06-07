-- Migration 2: Add metadata fields for high-fidelity coaching marketplace

-- 1. Update User table with coach profile fields
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "bio" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "rating" DOUBLE PRECISION DEFAULT 5.0;

-- 2. Update coaching_sessions table with rich metadata
ALTER TABLE "coaching_sessions" ADD COLUMN IF NOT EXISTS "session_type" TEXT DEFAULT 'group';
ALTER TABLE "coaching_sessions" ADD COLUMN IF NOT EXISTS "location_area" TEXT;
ALTER TABLE "coaching_sessions" ADD COLUMN IF NOT EXISTS "target_skill_level" TEXT DEFAULT 'all';
ALTER TABLE "coaching_sessions" ADD COLUMN IF NOT EXISTS "prerequisites" TEXT;
ALTER TABLE "coaching_sessions" ADD COLUMN IF NOT EXISTS "cancellation_policy" TEXT;

-- 3. Ensure foreign keys for session_enrollments are explicit for easier joining
-- This helps when we query "*, player:User(*)"
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'session_enrollments_player_id_fkey'
    ) THEN
        ALTER TABLE "session_enrollments" 
        ADD CONSTRAINT "session_enrollments_player_id_fkey" 
        FOREIGN KEY ("player_id") REFERENCES "User"("id") ON DELETE CASCADE;
    END IF;
END $$;
