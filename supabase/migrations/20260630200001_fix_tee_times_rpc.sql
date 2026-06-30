CREATE OR REPLACE FUNCTION get_available_tee_times(p_course_id text, p_date date)
RETURNS TABLE (
    time_slot time,
    remaining_capacity integer,
    is_blocked boolean,
    block_reason text
) AS $$
DECLARE
    v_first_time time;
    v_last_time time;
    v_interval integer;
    v_max_players integer;
BEGIN
    -- Get settings for the course
    SELECT first_tee_time, last_tee_time, tee_interval_minutes, max_players_per_slot
    INTO v_first_time, v_last_time, v_interval, v_max_players
    FROM course_tee_time_settings
    WHERE course_id = p_course_id;

    IF NOT FOUND THEN
        v_first_time := '06:30:00'::time;
        v_last_time := '18:00:00'::time;
        v_interval := 10;
        v_max_players := 4;
    END IF;

    RETURN QUERY
    WITH generated_slots AS (
        SELECT generate_series(
            (p_date + v_first_time)::timestamp, 
            (p_date + v_last_time)::timestamp, 
            (v_interval || ' minutes')::interval
        )::time AS t_slot
    ),
    booked_counts AS (
        SELECT 
            b.tee_time, 
            COUNT(p.id) AS booked_players
        FROM casual_tee_time_bookings b
        LEFT JOIN casual_tee_time_players p ON p.booking_id = b.id
        WHERE b.course_id = p_course_id 
          AND b.booking_date = p_date
          AND b.status = 'CONFIRMED'
        GROUP BY b.tee_time
    ),
    blocks AS (
        SELECT 
            start_time, 
            end_time, 
            reason
        FROM course_blocks
        WHERE course_id = p_course_id
          AND block_date = p_date
    )
    SELECT 
        gs.t_slot,
        (v_max_players - COALESCE(bc.booked_players, 0))::integer AS remaining_capacity,
        CASE WHEN bl.start_time IS NOT NULL THEN true ELSE false END AS is_blocked,
        bl.reason AS block_reason
    FROM generated_slots gs
    LEFT JOIN booked_counts bc ON gs.t_slot = bc.tee_time
    LEFT JOIN blocks bl ON gs.t_slot >= bl.start_time AND gs.t_slot <= bl.end_time;
END;
$$ LANGUAGE plpgsql;
