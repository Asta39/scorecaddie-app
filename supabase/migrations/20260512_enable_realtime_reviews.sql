-- Enable Realtime for Review and interactions tables
BEGIN;
  -- Remove if already exists to avoid errors
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public."Review";
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS public."interactions";
  
  -- Add tables to the realtime publication
  ALTER PUBLICATION supabase_realtime ADD TABLE public."Review";
  ALTER PUBLICATION supabase_realtime ADD TABLE public."interactions";
COMMIT;

SELECT 'Realtime enabled for Review and Interactions!' as status;
