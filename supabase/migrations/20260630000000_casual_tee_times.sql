-- 1. Unify "Course" and "courses"
-- Add missing columns to the main "Course" table
ALTER TABLE public."Course"
ADD COLUMN IF NOT EXISTS caddie_fee NUMERIC DEFAULT 1000,
ADD COLUMN IF NOT EXISTS latitude NUMERIC,
ADD COLUMN IF NOT EXISTS longitude NUMERIC;

-- Insert the Kenyan courses into "Course" if they don't exist
INSERT INTO public."Course" (id, name, location, "holesCount", "par18", caddie_fee, latitude, longitude, "createdAt", "updatedAt")
VALUES
  ('royal-nairobi', 'Royal Nairobi Golf Club', 'Nairobi', 18, 72, 1000, -1.2989, 36.7914, now(), now()),
  ('karen-cc', 'Karen Country Club', 'Nairobi', 18, 72, 1200, -1.3533, 36.7117, now(), now()),
  ('muthaiga-gc', 'Muthaiga Golf Club', 'Nairobi', 18, 71, 1200, -1.2483, 36.8333, now(), now()),
  ('windsor-gc', 'Windsor Golf Hotel & Country Club', 'Nairobi', 18, 72, 1500, -1.2104, 36.8770, now(), now()),
  ('sigona-gc', 'Sigona Golf Club', 'Kikuyu', 18, 72, 1000, -1.2333, 36.6500, now(), now()),
  ('vet-lab', 'Vet Lab Sports Club', 'Kabete', 18, 72, 1000, -1.2667, 36.7333, now(), now()),
  ('thika-greens', 'Thika Greens Golf Resort', 'Thika', 18, 72, 1200, -1.0167, 37.0833, now(), now()),
  ('limuru-cc', 'Limuru Country Club', 'Limuru', 18, 72, 1000, -1.1167, 36.6333, now(), now()),
  ('nyeri-gc', 'Nyeri Golf Club', 'Nyeri', 18, 72, 1000, -0.4245, 36.9423, now(), now()),
  ('nyali-gc', 'Nyali Golf & Country Club', 'Mombasa', 18, 71, 1000, -4.0333, 39.7167, now(), now()),
  ('mombasa-gc', 'Mombasa Golf Club', 'Mombasa', 9, 71, 800, -4.0667, 39.6667, now(), now()),
  ('vipingo-ridge', 'Vipingo Ridge', 'Kilifi', 18, 72, 1500, -3.8242, 39.7997, now(), now()),
  ('nakuru-gc', 'Nakuru Golf Club', 'Nakuru', 18, 73, 800, -0.2833, 36.0683, now(), now()),
  ('eldoret-gc', 'Eldoret Golf Club', 'Eldoret', 18, 71, 1000, 0.5143, 35.2697, now(), now())
ON CONFLICT (id) DO NOTHING;

-- Drop the old "courses" table (ensure no foreign keys depend on it first)
DROP TABLE IF EXISTS public."courses" CASCADE;

-- 2. Create course_tee_time_settings
CREATE TABLE IF NOT EXISTS public.course_tee_time_settings (
    course_id text PRIMARY KEY REFERENCES public."Course"(id) ON DELETE CASCADE,
    tee_interval_minutes integer DEFAULT 10,
    first_tee_time time DEFAULT '06:30:00',
    last_tee_time time DEFAULT '18:00:00',
    max_players_per_slot integer DEFAULT 4,
    advance_booking_days integer DEFAULT 14,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Insert default settings for all courses
INSERT INTO public.course_tee_time_settings (course_id)
SELECT id FROM public."Course"
ON CONFLICT (course_id) DO NOTHING;

-- 3. Create course_blocks (for admin overrides/maintenance)
CREATE TABLE IF NOT EXISTS public.course_blocks (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id text REFERENCES public."Course"(id) ON DELETE CASCADE,
    block_date date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    reason text,
    created_at timestamptz DEFAULT now()
);

-- 4. Create casual_tee_time_bookings
CREATE TABLE IF NOT EXISTS public.casual_tee_time_bookings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id text REFERENCES public."Course"(id) ON DELETE CASCADE,
    player_id text REFERENCES public."User"(id) ON DELETE CASCADE,
    booking_date date NOT NULL,
    tee_time time NOT NULL,
    status text DEFAULT 'CONFIRMED', -- 'CONFIRMED', 'CANCELLED'
    payment_status text DEFAULT 'PENDING', -- 'PENDING', 'PAID_AT_SHOP'
    created_at timestamptz DEFAULT now()
);

-- Create a table for the specific guests/players in a booking
CREATE TABLE IF NOT EXISTS public.casual_tee_time_players (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id uuid REFERENCES public.casual_tee_time_bookings(id) ON DELETE CASCADE,
    user_id text REFERENCES public."User"(id) ON DELETE SET NULL, -- Null if non-member guest
    custom_name text, -- For family/guests not in DB
    is_guest boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- 5. RPC to get available tee times
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
            v_first_time::timestamp, 
            v_last_time::timestamp, 
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
        g.t_slot AS time_slot,
        GREATEST(v_max_players - COALESCE(bc.booked_players, 0), 0)::integer AS remaining_capacity,
        CASE WHEN EXISTS (
            SELECT 1 FROM blocks bl 
            WHERE g.t_slot >= bl.start_time AND g.t_slot < bl.end_time
        ) THEN true ELSE false END AS is_blocked,
        (SELECT reason FROM blocks bl WHERE g.t_slot >= bl.start_time AND g.t_slot < bl.end_time LIMIT 1) AS block_reason
    FROM generated_slots g
    LEFT JOIN booked_counts bc ON g.t_slot = bc.tee_time
    ORDER BY g.t_slot;
END;
$$ LANGUAGE plpgsql;
