-- Enable Realtime for Review and interactions tables
BEGIN;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'Review') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."Review";
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'interactions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public."interactions";
  END IF;
END $$;
COMMIT;

SELECT 'Realtime enabled for Review and Interactions!' as status;
