-- Add 'notify' and 'notification_sent_at' columns to casual_tee_time_players
ALTER TABLE public.casual_tee_time_players
ADD COLUMN IF NOT EXISTS notify boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS notification_sent_at timestamptz;

-- Helper to get a user's home club
CREATE OR REPLACE FUNCTION get_user_home_club(p_user_id text)
RETURNS text AS $$
DECLARE
    v_club_name text;
BEGIN
    SELECT c.name INTO v_club_name
    FROM public.player_club_memberships pcm
    JOIN public."Course" c ON c.id = pcm.club_id
    WHERE pcm.player_id = p_user_id
      AND pcm.status = 'active'
    ORDER BY 
      CASE WHEN pcm.membership_type = 'full' THEN 1 ELSE 2 END,
      pcm.created_at ASC
    LIMIT 1;
    
    RETURN COALESCE(v_club_name, 'No Home Club');
END;
$$ LANGUAGE plpgsql;

-- Replace get_due_reminders() to work with the new casual bookings
CREATE OR REPLACE FUNCTION public.get_due_reminders()
RETURNS TABLE (
  id           uuid,
  user_id      text,
  notify_before_minutes int,
  notes        text,
  player_id    uuid
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    b.id,
    p.user_id,
    30 AS notify_before_minutes,
    c.name || ' at ' || to_char(b.tee_time, 'HH12:MI AM') AS notes,
    p.id AS player_id
  FROM public.casual_tee_time_bookings b
  JOIN public.casual_tee_time_players p ON p.booking_id = b.id
  JOIN public."Course" c ON c.id = b.course_id
  WHERE b.status = 'CONFIRMED'
    AND p.notify = true
    AND p.user_id IS NOT NULL
    AND p.notification_sent_at IS NULL
    -- Construct full timestamp in EAT (or local timezone assuming server is UTC)
    -- Actually, assuming booking_date and tee_time represent local time. We'll cast to timestamp.
    AND now() >= (b.booking_date + b.tee_time)::timestamp - interval '30 minutes'
    AND (b.booking_date + b.tee_time)::timestamp >= now() - interval '15 minutes';
$$;

GRANT EXECUTE ON FUNCTION public.get_due_reminders()
  TO postgres, service_role, authenticated, anon;
