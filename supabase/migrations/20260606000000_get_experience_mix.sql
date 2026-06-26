CREATE OR REPLACE FUNCTION get_caddie_experience_mix(p_club_id UUID)
RETURNS TABLE(level text, count bigint) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(INITCAP(experience_level), 'Unknown') AS level, 
    COUNT(*) AS count
  FROM caddies
  WHERE club_id = p_club_id AND is_active = true
  GROUP BY COALESCE(INITCAP(experience_level), 'Unknown');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
