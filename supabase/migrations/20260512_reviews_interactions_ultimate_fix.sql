-- THE FINAL REVIEWS & INTERACTIONS FIX
-- This script creates the tables if they are missing and standardizes them.

DO $$
BEGIN
    -- 1. Create Review table if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Review') THEN
        CREATE TABLE public."Review" (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            provider_id text NOT NULL,
            player_id text NOT NULL,
            player_name text NOT NULL DEFAULT 'Golfer',
            player_avatar text,
            rating integer NOT NULL DEFAULT 5,
            comment text NOT NULL DEFAULT '',
            "createdAt" timestamptz DEFAULT now()
        );
    END IF;

    -- 2. Create interactions table if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'interactions') THEN
        CREATE TABLE public."interactions" (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            player_id text NOT NULL,
            provider_id text NOT NULL,
            type text NOT NULL,
            status text DEFAULT 'pending',
            "lastPromptedAt" timestamptz,
            timestamp timestamptz DEFAULT now()
        );
    END IF;
END $$;

-- 3. Standardize Column Names (snake_case)
ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "provider_id" text;
ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "player_id" text;
ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "player_name" text;
ALTER TABLE public."Review" ADD COLUMN IF NOT EXISTS "player_avatar" text;

ALTER TABLE public."interactions" ADD COLUMN IF NOT EXISTS "player_id" text;
ALTER TABLE public."interactions" ADD COLUMN IF NOT EXISTS "provider_id" text;

-- 4. Sync data from old columns if they existed
DO $$
BEGIN
    -- Review Table
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'providerId') THEN
        UPDATE public."Review" SET provider_id = "providerId" WHERE provider_id IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerId') THEN
        UPDATE public."Review" SET player_id = "playerId" WHERE player_id IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerName') THEN
        UPDATE public."Review" SET player_name = "playerName" WHERE player_name IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerAvatar') THEN
        UPDATE public."Review" SET player_avatar = "playerAvatar" WHERE player_avatar IS NULL;
    END IF;

    -- Interactions Table
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = 'providerId') THEN
        UPDATE public."interactions" SET provider_id = "providerId" WHERE provider_id IS NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = 'playerId') THEN
        UPDATE public."interactions" SET player_id = "playerId" WHERE player_id IS NULL;
    END IF;
END $$;

-- 5. Set Permissions
GRANT ALL ON TABLE public."Review" TO authenticated, anon, service_role;
GRANT ALL ON TABLE public."interactions" TO authenticated, anon, service_role;

SELECT 'Review and Interactions tables are now perfectly synced!' as status;
