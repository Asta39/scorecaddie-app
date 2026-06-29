-- Function to check available slots for a given course, date, and tee time
CREATE OR REPLACE FUNCTION check_tee_time_availability(
  p_course_id TEXT,
  p_booking_date DATE,
  p_tee_time TIME,
  p_max_capacity INTEGER DEFAULT 4
) RETURNS INTEGER AS $$
DECLARE
  v_booked_players INTEGER;
BEGIN
  -- Count total players (host + guests) booked for this exact slot
  SELECT COALESCE(SUM(1 + (
    SELECT COUNT(*) FROM casual_tee_time_players 
    WHERE booking_id = b.id
  )), 0)
  INTO v_booked_players
  FROM casual_tee_time_bookings b
  WHERE b.course_id = p_course_id
    AND b.booking_date = p_booking_date
    AND b.tee_time = p_tee_time
    AND b.status != 'CANCELLED';

  -- Return remaining capacity
  RETURN GREATEST(0, p_max_capacity - v_booked_players);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
