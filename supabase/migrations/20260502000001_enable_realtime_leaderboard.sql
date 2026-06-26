-- ============================================================
-- Enable Realtime for Leaderboard Tables
-- ============================================================

DO $$
BEGIN
  -- Enable realtime for public."Round"
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'Round'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."Round";
  END IF;

  -- Enable realtime for public."User"
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'User'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."User";
  END IF;
END $$;

SELECT 'Realtime enabled for Round and User tables! 📡⛳' AS status;
