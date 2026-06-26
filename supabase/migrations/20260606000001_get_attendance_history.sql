CREATE OR REPLACE FUNCTION get_attendance_history(p_club_id UUID, p_days INT DEFAULT 90)
RETURNS TABLE(date text, attendance bigint) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    to_char(a.date, 'YYYY-MM-DD') AS date,
    COUNT(*)::bigint AS attendance
  FROM caddie_attendance a
  WHERE a.club_id = p_club_id
    AND a.date >= CURRENT_DATE - p_days
    AND a.time_in IS NOT NULL
    AND a.is_absent = false
  GROUP BY a.date
  ORDER BY a.date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
