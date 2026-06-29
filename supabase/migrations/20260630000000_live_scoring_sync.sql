-- =============================================================================
-- LIVE SCORING SYNC
-- Synchronizes HoleScore and GroupRoundScore with competition_results
-- to power real-time Live Leaderboards.
-- =============================================================================

CREATE OR REPLACE FUNCTION sync_live_competition_score()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id TEXT;
  v_comp_id UUID;
  v_round_id UUID;
  v_scorecard JSONB;
BEGIN
  -- Determine userId and roundId based on the table being updated
  IF TG_TABLE_NAME = 'GroupRoundScore' THEN
    v_user_id := NEW."userId";
    -- For GroupRoundScore we aggregate based on the groupRoundId
    v_round_id := NEW."groupRoundId";
  ELSIF TG_TABLE_NAME = 'HoleScore' THEN
    -- For HoleScore, we need to fetch userId from the Round table
    SELECT "userId" INTO v_user_id FROM public."Round" WHERE id = NEW."roundId";
    v_round_id := NEW."roundId";
  END IF;

  -- Find if this user is actively playing in a competition
  SELECT competition_id INTO v_comp_id
  FROM competition_results
  WHERE player_id = v_user_id AND result_status = 'active'
  LIMIT 1;

  -- If they are playing in a competition, build their scorecard and update it
  IF v_comp_id IS NOT NULL THEN
    
    IF TG_TABLE_NAME = 'GroupRoundScore' THEN
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'hole', "holeNumber",
          'strokes', "strokes",
          -- Note: par isn't stored in GroupRoundScore by default, but we can default to 4 or fetch it.
          -- Wait, we need par for stableford. Let's fetch it from CourseHole.
          'par', (
            SELECT "par" FROM public."CourseHole" ch
            JOIN public."GroupRound" gr ON gr."courseId" = ch."courseId"
            WHERE gr.id = NEW."groupRoundId" AND ch."holeNumber" = grs."holeNumber"
            LIMIT 1
          )
        )
      ), '[]'::jsonb) INTO v_scorecard
      FROM public."GroupRoundScore" grs
      WHERE "groupRoundId" = v_round_id AND "userId" = v_user_id AND "strokes" > 0;
      
    ELSIF TG_TABLE_NAME = 'HoleScore' THEN
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'hole', "holeNumber",
          'strokes', "score",
          'par', "par"
        )
      ), '[]'::jsonb) INTO v_scorecard
      FROM public."HoleScore"
      WHERE "roundId" = v_round_id AND "score" > 0;
    END IF;

    -- Update the competition_results scorecard
    UPDATE competition_results
    SET scorecard = v_scorecard
    WHERE competition_id = v_comp_id AND player_id = v_user_id AND result_status = 'active';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trg_sync_live_competition_score_grs ON public."GroupRoundScore";
DROP TRIGGER IF EXISTS trg_sync_live_competition_score_hs ON public."HoleScore";

-- Create triggers
CREATE TRIGGER trg_sync_live_competition_score_grs
AFTER INSERT OR UPDATE ON public."GroupRoundScore"
FOR EACH ROW EXECUTE FUNCTION sync_live_competition_score();

CREATE TRIGGER trg_sync_live_competition_score_hs
AFTER INSERT OR UPDATE ON public."HoleScore"
FOR EACH ROW EXECUTE FUNCTION sync_live_competition_score();

-- Expose competition_leaderboard to Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE competition_results;
