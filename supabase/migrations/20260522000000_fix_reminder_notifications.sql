-- ============================================================
-- Migration: Fix tee_time_reminder permissions & create get_due_reminders()
-- Problem:  Edge Function fails with "permission denied for schema public"
--           because table-level GRANTs are missing and the RPC function
--           get_due_reminders() does not exist.
-- ============================================================

-- 1. Grant table-level permissions so the service_role (used by Edge Functions)
--    and authenticated users can access the table.
GRANT ALL ON TABLE public.tee_time_reminder
  TO postgres, service_role, authenticated, anon;

-- 2. Create (or replace) the get_due_reminders() function.
--    A reminder is "due" when:
--      now() >= (reminder_date - notify_before_minutes)
--    We also add a 15-minute safety window so reminders that just barely
--    passed the trigger window are still picked up.
CREATE OR REPLACE FUNCTION public.get_due_reminders()
RETURNS TABLE (
  id           uuid,
  user_id      text,
  reminder_date timestamptz,
  notify_before_minutes int,
  notes        text,
  fcm_token    text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    r.id,
    r.user_id,
    r.reminder_date,
    r.notify_before_minutes,
    r.notes,
    r.fcm_token
  FROM public.tee_time_reminder r
  WHERE r.is_active = true
    AND now() >= (r.reminder_date - (r.notify_before_minutes * interval '1 minute'))
    AND r.reminder_date >= now() - interval '15 minutes';
$$;

-- 3. Grant execute on the function to required roles.
GRANT EXECUTE ON FUNCTION public.get_due_reminders()
  TO postgres, service_role, authenticated, anon;
