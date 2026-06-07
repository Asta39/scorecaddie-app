-- Standardize Review table columns to snake_case for better compatibility
DO $$
BEGIN
    -- 1. Standardize providerId -> provider_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'providerId') THEN
        ALTER TABLE public."Review" RENAME COLUMN "providerId" TO provider_id;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'providerid') THEN
        ALTER TABLE public."Review" RENAME COLUMN providerid TO provider_id;
    END IF;

    -- 2. Standardize playerId -> player_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerId') THEN
        ALTER TABLE public."Review" RENAME COLUMN "playerId" TO player_id;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerid') THEN
        ALTER TABLE public."Review" RENAME COLUMN playerid TO player_id;
    END IF;

    -- 3. Standardize playerName -> player_name
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerName') THEN
        ALTER TABLE public."Review" RENAME COLUMN "playerName" TO player_name;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playername') THEN
        ALTER TABLE public."Review" RENAME COLUMN playername TO player_name;
    END IF;

    -- 4. Standardize playerAvatar -> player_avatar
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playerAvatar') THEN
        ALTER TABLE public."Review" RENAME COLUMN "playerAvatar" TO player_avatar;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = 'playeravatar') THEN
        ALTER TABLE public."Review" RENAME COLUMN playeravatar TO player_avatar;
    END IF;
END $$;

-- Standardize interactions table too while we are at it
DO $$
BEGIN
    -- providerId -> provider_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = 'providerId') THEN
        ALTER TABLE public."interactions" RENAME COLUMN "providerId" TO provider_id;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = 'providerid') THEN
        ALTER TABLE public."interactions" RENAME COLUMN providerid TO provider_id;
    END IF;

    -- playerId -> player_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = 'playerId') THEN
        ALTER TABLE public."interactions" RENAME COLUMN "playerId" TO player_id;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = 'playerid') THEN
        ALTER TABLE public."interactions" RENAME COLUMN playerid TO player_id;
    END IF;
END $$;

GRANT ALL ON TABLE public."Review" TO authenticated, anon, service_role;
GRANT ALL ON TABLE public."interactions" TO authenticated, anon, service_role;

SELECT 'Review and Interactions tables standardized!' as status;
