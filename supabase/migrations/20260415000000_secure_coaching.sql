-- ============================================================
-- Phase 1 & 3: Security, Capacity, and Drill Assignments
-- ============================================================

-- 1. Create Drill Assignments table for Coach-Player linkage
CREATE TABLE IF NOT EXISTS public.drill_assignments (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  drill_id uuid NOT NULL, -- References a drill template (we'll add coach_id to drills next)
  coach_id text NOT NULL REFERENCES public."User"(firebaseUid),
  player_id text NOT NULL REFERENCES public."User"(firebaseUid),
  assigned_at timestamptz DEFAULT now(),
  notes text,
  status text DEFAULT 'active', -- 'active' | 'completed' | 'archived'
  UNIQUE(drill_id, player_id)
);

-- 2. Enhance Drills table in Supabase (assuming it exists or creating it if not)
-- Note: Drills might be in public.drills or another table. 
-- Based on the Flutter code, let's ensure we have a drills table that supports templates.
CREATE TABLE IF NOT EXISTS public.drills (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  creator_id text REFERENCES public."User"(firebaseUid),
  name text NOT NULL,
  description text,
  category text DEFAULT 'General',
  difficulty text DEFAULT 'Medium',
  duration_minutes int DEFAULT 30,
  icon text DEFAULT 'target',
  is_template boolean DEFAULT false, -- If true, this is a coach's master drill
  created_at timestamptz DEFAULT now()
);

-- 3. Secure Coaching Sessions RLS
ALTER TABLE public.coaching_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Coaches manage their sessions" ON public.coaching_sessions;
CREATE POLICY "Coaches manage their sessions"
  ON public.coaching_sessions FOR ALL
  TO authenticated
  USING (coach_id = auth.uid()::text OR coach_id = (select firebaseUid from public."User" where id = auth.uid()))
  WITH CHECK (coach_id = auth.uid()::text OR coach_id = (select firebaseUid from public."User" where id = auth.uid()));

DROP POLICY IF EXISTS "Anyone can read sessions" ON public.coaching_sessions;
CREATE POLICY "Anyone can read sessions"
  ON public.coaching_sessions FOR SELECT
  USING (status = 'active');

-- 4. Secure Enrollments RLS
ALTER TABLE public.session_enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all on session_enrollments" ON public.session_enrollments;
CREATE POLICY "Players see own enrollments"
  ON public.session_enrollments FOR SELECT
  USING (player_id = auth.uid()::text OR player_id = (select firebaseUid from public."User" where id = auth.uid()));

CREATE POLICY "Coaches see their session enrollments"
  ON public.session_enrollments FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.coaching_sessions 
    WHERE id = session_id AND coach_id = (select firebaseUid from public."User" where id = auth.uid())
  ));

-- 5. Atomic Enrollment RPC with Capacity Check
CREATE OR REPLACE FUNCTION public.enroll_player_in_session(
  p_session_id uuid,
  p_player_id text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_players int;
  v_current_count int;
  v_enrollment_id uuid;
  v_price numeric;
  v_terms text;
  v_amount_paid numeric := 0;
  v_payment_status text := 'unpaid';
BEGIN
  -- 1. Check capacity
  SELECT max_players, price_per_session, payment_terms 
  INTO v_max_players, v_price, v_terms
  FROM public.coaching_sessions 
  WHERE id = p_session_id;

  SELECT count(*) INTO v_current_count 
  FROM public.session_enrollments 
  WHERE session_id = p_session_id AND status = 'active';

  IF v_current_count >= v_max_players THEN
    RAISE EXCEPTION 'Session is full';
  END IF;

  -- 2. Check if already enrolled
  IF EXISTS (SELECT 1 FROM public.session_enrollments WHERE session_id = p_session_id AND player_id = p_player_id) THEN
    RAISE EXCEPTION 'Already enrolled in this session';
  END IF;

  -- 3. Calculate initial payment
  IF v_terms = 'upfront' THEN
    v_amount_paid := v_price;
    v_payment_status := 'fully_paid';
  ELSIF v_terms = 'split' THEN
    v_amount_paid := v_price / 2;
    v_payment_status := 'partial';
  END IF;

  -- 4. Insert enrollment
  INSERT INTO public.session_enrollments (
    session_id, player_id, amount_paid, payment_status, status, payment_method
  ) VALUES (
    p_session_id, p_player_id, v_amount_paid, v_payment_status, 'active', 'SIMULATED'
  )
  RETURNING id INTO v_enrollment_id;

  RETURN v_enrollment_id;
END;
$$;

-- 6. Secure Drill Assignments RLS
ALTER TABLE public.drill_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Coaches manage assignments"
  ON public.drill_assignments FOR ALL
  USING (coach_id = (select firebaseUid from public."User" where id = auth.uid()));

CREATE POLICY "Players read assigned drills"
  ON public.drill_assignments FOR SELECT
  USING (player_id = (select firebaseUid from public."User" where id = auth.uid()));

GRANT EXECUTE ON FUNCTION public.enroll_player_in_session TO authenticated;
