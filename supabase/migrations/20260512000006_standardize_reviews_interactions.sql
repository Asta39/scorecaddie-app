-- Standardize Review table columns to snake_case for better compatibility
DO $$
DECLARE
    rec record;
    old_col_lower text;
BEGIN
    FOR rec IN (
        VALUES 
            ('providerId', 'provider_id'),
            ('playerId', 'player_id'),
            ('playerName', 'player_name'),
            ('playerAvatar', 'player_avatar')
    ) LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = rec.column1) THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = rec.column2) THEN
                EXECUTE format('ALTER TABLE public."Review" RENAME COLUMN "%s" TO %I', rec.column1, rec.column2);
            END IF;
        END IF;

        old_col_lower := lower(rec.column1);
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = old_col_lower) THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Review' AND column_name = rec.column2) THEN
                EXECUTE format('ALTER TABLE public."Review" RENAME COLUMN %I TO %I', old_col_lower, rec.column2);
            END IF;
        END IF;
    END LOOP;
END $$;

-- Standardize interactions table too while we are at it
DO $$
DECLARE
    rec record;
    old_col_lower text;
BEGIN
    FOR rec IN (
        VALUES 
            ('providerId', 'provider_id'),
            ('playerId', 'player_id')
    ) LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = rec.column1) THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = rec.column2) THEN
                EXECUTE format('ALTER TABLE public."interactions" RENAME COLUMN "%s" TO %I', rec.column1, rec.column2);
            END IF;
        END IF;

        old_col_lower := lower(rec.column1);
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = old_col_lower) THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'interactions' AND column_name = rec.column2) THEN
                EXECUTE format('ALTER TABLE public."interactions" RENAME COLUMN %I TO %I', old_col_lower, rec.column2);
            END IF;
        END IF;
    END LOOP;
END $$;

GRANT ALL ON TABLE public."Review" TO authenticated, anon, service_role;
GRANT ALL ON TABLE public."interactions" TO authenticated, anon, service_role;

SELECT 'Review and Interactions tables standardized!' as status;
