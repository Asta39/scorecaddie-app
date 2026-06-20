-- =============================================================================
-- COMPETITION SCORING AND RANKING TRIGGERS
-- Calculates Strokeplay, Stableford, and Bogey scores automatically
-- based on CourseHole pars and handicap indexes.
-- Keeps leaderboard rankings synchronized.
-- =============================================================================

CREATE OR REPLACE FUNCTION calculate_competition_score(
  p_competition_id UUID,
  p_entry_id UUID,
  p_player_id TEXT,
  p_scorecard JSONB
)
RETURNS RECORD AS $$
DECLARE
  v_comp_type TEXT;
  v_club_id TEXT;
  v_playing_handicap NUMERIC;
  v_gross_score INT := 0;
  v_net_score NUMERIC := 0;
  v_stableford_points INT := 0;
  
  v_hole_record RECORD;
  v_strokes INT;
  v_par INT;
  v_hole_num INT;
  v_handicap_index INT;
  
  v_strokes_received INT;
  v_ph_abs INT;
  v_strokes_base INT;
  v_strokes_extra INT;
  v_net_hole_score INT;
  v_points INT;
  
  v_result RECORD;
BEGIN
  -- Get competition details
  SELECT competition_type, club_id INTO v_comp_type, v_club_id
  FROM competitions WHERE id = p_competition_id;
  
  -- Get playing handicap from entry
  SELECT playing_handicap INTO v_playing_handicap
  FROM competition_entries WHERE id = p_entry_id;
  
  IF v_playing_handicap IS NULL THEN
    v_playing_handicap := 0;
  END IF;

  -- Iterate through scorecard holes
  FOR v_hole_record IN SELECT * FROM jsonb_to_recordset(p_scorecard) AS x(hole INT, strokes INT, par INT) LOOP
    v_hole_num := v_hole_record.hole;
    v_strokes := v_hole_record.strokes;
    v_par := v_hole_record.par;
    
    IF v_strokes IS NOT NULL AND v_strokes > 0 THEN
      v_gross_score := v_gross_score + v_strokes;
      
      -- Look up hole's handicap index (stroke index) from CourseHole
      SELECT "handicapIndex" INTO v_handicap_index
      FROM public."CourseHole"
      WHERE "courseId" = v_club_id AND "holeNumber" = v_hole_num;
      
      IF v_handicap_index IS NULL THEN
        -- Fallback to hole number
        v_handicap_index := v_hole_num;
      END IF;
      
      -- Allocate strokes according to WHS rules
      IF v_playing_handicap >= 0 THEN
        v_strokes_base := FLOOR(v_playing_handicap / 18)::INT;
        v_strokes_extra := MOD(ROUND(v_playing_handicap)::INT, 18);
        v_strokes_received := v_strokes_base;
        IF v_handicap_index <= v_strokes_extra THEN
          v_strokes_received := v_strokes_received + 1;
        END IF;
      ELSE
        v_ph_abs := ABS(ROUND(v_playing_handicap))::INT;
        v_strokes_base := FLOOR(v_ph_abs / 18)::INT;
        v_strokes_extra := MOD(v_ph_abs, 18);
        v_strokes_received := -v_strokes_base;
        -- Plus golfer gives back strokes starting from easiest holes (18, 17...)
        IF (19 - v_handicap_index) <= v_strokes_extra THEN
          v_strokes_received := v_strokes_received - 1;
        END IF;
      END IF;
      
      v_net_hole_score := v_strokes - v_strokes_received;
      
      IF v_comp_type IN ('stableford', 'betterball') THEN
        -- Stableford points: 2 points for net par, +1 for each stroke under, minimum 0
        v_points := 2 + (v_par - v_net_hole_score);
        IF v_points < 0 THEN
          v_points := 0;
        END IF;
        v_stableford_points := v_stableford_points + v_points;
      ELSIF v_comp_type = 'bogey' THEN
        -- Bogey/Par points: Net Birdie or better (+1), Net Par (0), Net Bogey or worse (-1)
        IF v_net_hole_score < v_par THEN
          v_stableford_points := v_stableford_points + 1;
        ELSIF v_net_hole_score > v_par THEN
          v_stableford_points := v_stableford_points - 1;
        END IF;
      END IF;
    END IF;
  END LOOP;
  
  v_net_score := v_gross_score - v_playing_handicap;
  
  -- If not a points format, stableford_points is null
  IF v_comp_type NOT IN ('stableford', 'betterball', 'bogey') THEN
    v_stableford_points := NULL;
  END IF;
  
  SELECT v_gross_score AS gross_score, v_net_score AS net_score, v_stableford_points AS stableford_points INTO v_result;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_competition_results_calc_fn() RETURNS TRIGGER AS $$
DECLARE
  v_calc RECORD;
BEGIN
  IF NEW.scorecard IS NOT NULL AND jsonb_array_length(NEW.scorecard) > 0 THEN
    SELECT gross_score, net_score, stableford_points 
    FROM calculate_competition_score(NEW.competition_id, NEW.entry_id, NEW.player_id, NEW.scorecard)
    AS (gross_score INT, net_score NUMERIC, stableford_points INT)
    INTO v_calc;
    
    NEW.gross_score := v_calc.gross_score;
    NEW.net_score := v_calc.net_score;
    NEW.stableford_points := v_calc.stableford_points;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_competition_results_calc ON competition_results;

CREATE TRIGGER trg_competition_results_calc
  BEFORE INSERT OR UPDATE OF scorecard ON competition_results
  FOR EACH ROW EXECUTE FUNCTION trg_competition_results_calc_fn();

CREATE OR REPLACE FUNCTION update_competition_ranks(p_competition_id UUID) RETURNS VOID AS $$
DECLARE
  v_comp_type TEXT;
  v_result RECORD;
  v_position INT := 1;
  v_prev_score NUMERIC;
  v_prev_stableford INT;
  v_rank_counter INT := 0;
BEGIN
  -- Get competition type
  SELECT competition_type INTO v_comp_type
  FROM competitions WHERE id = p_competition_id;
  
  IF v_comp_type IN ('stableford', 'betterball', 'bogey') THEN
    -- Sort by stableford_points DESC (highest wins)
    FOR v_result IN 
      SELECT id, stableford_points, net_score 
      FROM competition_results 
      WHERE competition_id = p_competition_id AND result_status = 'active'
      ORDER BY stableford_points DESC NULLS LAST, net_score ASC NULLS LAST, gross_score ASC NULLS LAST
    LOOP
      v_rank_counter := v_rank_counter + 1;
      IF v_prev_stableford IS NOT NULL AND v_result.stableford_points < v_prev_stableford THEN
        v_position := v_rank_counter;
      END IF;
      
      UPDATE competition_results
      SET position = v_position
      WHERE id = v_result.id;
      
      v_prev_stableford := v_result.stableford_points;
    END LOOP;
  ELSE
    -- Sort by net_score ASC (lowest wins) for strokeplay, matchplay, foursome
    FOR v_result IN 
      SELECT id, net_score 
      FROM competition_results 
      WHERE competition_id = p_competition_id AND result_status = 'active'
      ORDER BY net_score ASC NULLS LAST, gross_score ASC NULLS LAST
    LOOP
      v_rank_counter := v_rank_counter + 1;
      IF v_prev_score IS NOT NULL AND v_result.net_score > v_prev_score THEN
        v_position := v_rank_counter;
      END IF;
      
      UPDATE competition_results
      SET position = v_position
      WHERE id = v_result.id;
      
      v_prev_score := v_result.net_score;
    END LOOP;
  END IF;
  
  -- Set position to NULL for non-active results
  UPDATE competition_results
  SET position = NULL
  WHERE competition_id = p_competition_id AND result_status != 'active';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_competition_results_rank_stmt() RETURNS TRIGGER AS $$
DECLARE
  v_comp_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_comp_id := OLD.competition_id;
  ELSE
    v_comp_id := NEW.competition_id;
  END IF;
  
  PERFORM update_competition_ranks(v_comp_id);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_competition_results_rank ON competition_results;

CREATE TRIGGER trg_competition_results_rank
  AFTER INSERT OR UPDATE OF gross_score, net_score, stableford_points, result_status OR DELETE ON competition_results
  FOR EACH ROW EXECUTE FUNCTION trg_competition_results_rank_stmt();

CREATE OR REPLACE VIEW competition_leaderboard AS
SELECT
  cr.competition_id,
  cr.position,
  cr.player_id,
  u.name as full_name,
  u."handicapIndex" as handicap_index,
  ce.playing_handicap,
  ce.flight_name,
  cr.gross_score,
  cr.net_score,
  cr.stableford_points,
  cr.result_status,
  cr.certified,
  c.competition_type,
  c.name as competition_name,
  c.status as competition_status,
  c.start_date
FROM competition_results cr
JOIN public."User" u ON u.id = cr.player_id
JOIN competitions c ON c.id = cr.competition_id
JOIN competition_entries ce ON ce.id = cr.entry_id
ORDER BY 
  cr.competition_id, 
  cr.position ASC NULLS LAST,
  CASE 
    WHEN c.competition_type IN ('stableford', 'betterball', 'bogey') THEN -cr.stableford_points 
    ELSE cr.net_score 
  END ASC NULLS LAST;
