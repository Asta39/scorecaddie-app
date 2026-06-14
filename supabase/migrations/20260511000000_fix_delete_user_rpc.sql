-- ============================================================
-- Fix: Complete cascading delete for user account cleanup
-- Replaces the incomplete delete_user_account RPC
-- Run this in the Supabase SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _user_id text := auth.uid()::text;
BEGIN
  -- 1. Delete group round scores
  DELETE FROM public."GroupRoundScore" WHERE "userId" = _user_id;

  -- 2. Delete group round participations
  DELETE FROM public."GroupRoundParticipant" WHERE "userId" = _user_id;

  -- 3. Delete hole scores (via rounds owned by user)
  DELETE FROM public."HoleScore" WHERE "roundId" IN (
    SELECT id FROM public."Round" WHERE "userId" = _user_id
  );

  -- 4. Delete rounds
  DELETE FROM public."Round" WHERE "userId" = _user_id;

  -- 5. Delete player stats
  DELETE FROM public."PlayerStat" WHERE "userId" = _user_id;

  -- 6. Delete friendships (both directions)
  DELETE FROM public."Friend" WHERE "userId" = _user_id OR "friendId" = _user_id;

  -- 7. Delete notifications
  DELETE FROM public."Notification" WHERE "userId" = _user_id;

  -- 8. Delete coaching session enrollments (as student)
  DELETE FROM public.session_enrollments WHERE student_id = _user_id;

  -- 9. Delete coaching session attendance (as student)
  DELETE FROM public.session_attendance WHERE student_id = _user_id;

  -- 10. Delete coaching sessions (as coach)
  DELETE FROM public.coaching_sessions WHERE coach_id = _user_id;

  -- 11. Delete drill assignments (as student)
  DELETE FROM public.drill_assignments WHERE student_id = _user_id;

  -- 12. Delete group rounds created by user
  DELETE FROM public."GroupRound" WHERE "captainId" = _user_id;

  -- 13. Finally, delete the User profile row
  DELETE FROM public."User" WHERE id = _user_id OR "firebaseUid" = _user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

SELECT 'delete_user_account RPC updated with full cascade! 🗑️' AS status;
