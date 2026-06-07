-- Migration 3: Update RPC functions for coaching marketplace

-- 0. Drop existing functions to avoid "not unique" errors during Grant
DO $$ 
DECLARE 
    r RECORD;
BEGIN 
    FOR r IN (
        SELECT oid::regprocedure AS sig 
        FROM pg_proc 
        WHERE proname IN ('create_coaching_session', 'update_coaching_session')
    ) LOOP 
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE'; 
    END LOOP; 
END $$;

-- 1. Update create_coaching_session
create or replace function public.create_coaching_session(
  p_coach_id text,
  p_name text,
  p_description text,
  p_max_players int,
  p_price_per_session numeric,
  p_duration_minutes int,
  p_location text,
  p_days_of_week int[],
  p_start_time text,
  p_weeks int,
  p_start_date date,
  p_payment_terms text,
  p_session_type text default 'Group',
  p_location_area text default 'Driving Range',
  p_target_skill_level text default 'All',
  p_prerequisites text default '',
  p_cancellation_policy text default '24h notice required'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_id uuid;
  v_current_date date;
  v_end_date date;
  v_dow int;
  v_pg_dow int;
begin
  insert into public.coaching_sessions (
    coach_id, name, description, location,
    max_players, price_per_session, duration_minutes,
    days_of_week, start_time, start_date, weeks, payment_terms,
    session_type, location_area, target_skill_level, prerequisites, cancellation_policy
  ) values (
    p_coach_id, p_name, p_description, p_location,
    p_max_players, p_price_per_session, p_duration_minutes,
    p_days_of_week, p_start_time::time, p_start_date, p_weeks, p_payment_terms,
    p_session_type, p_location_area, p_target_skill_level, p_prerequisites, p_cancellation_policy
  )
  returning id into v_session_id;

  v_end_date := p_start_date + (p_weeks * 7);
  v_current_date := p_start_date;

  while v_current_date <= v_end_date loop
    v_pg_dow := extract(dow from v_current_date)::int;
    v_dow := case when v_pg_dow = 0 then 7 else v_pg_dow end;

    if v_dow = any(p_days_of_week) then
      insert into public.session_occurrences (session_id, date)
      values (v_session_id, v_current_date);
    end if;

    v_current_date := v_current_date + 1;
  end loop;

  return v_session_id;
end;
$$;

-- 2. Update update_coaching_session
create or replace function public.update_coaching_session(
  p_session_id uuid,
  p_coach_id text,
  p_name text,
  p_description text,
  p_max_players int,
  p_price_per_session numeric,
  p_duration_minutes int,
  p_location text,
  p_days_of_week int[],
  p_start_time text,
  p_weeks int,
  p_payment_terms text,
  p_session_type text default 'Group',
  p_location_area text default 'Driving Range',
  p_target_skill_level text default 'All',
  p_prerequisites text default '',
  p_cancellation_policy text default '24h notice required'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_start_time time;
  v_old_days_of_week int[];
  v_old_weeks int;
  v_start_date date;
  v_end_date date;
  v_generate_occurrences boolean := false;
  v_current_date date;
  v_pg_dow int;
  v_dow int;
begin
  -- Ensure the session belongs to the coach
  select days_of_week, start_time, weeks, start_date
  into v_old_days_of_week, v_old_start_time, v_old_weeks, v_start_date
  from public.coaching_sessions
  where id = p_session_id and coach_id = p_coach_id;

  if not found then
    raise exception 'Session not found or not owned by coach';
  end if;

  -- Check if schedule changed
  if (v_old_days_of_week != p_days_of_week) or 
     (v_old_start_time != p_start_time::time) or 
     (v_old_weeks != p_weeks) then
    v_generate_occurrences := true;
  end if;

  -- Update session record
  update public.coaching_sessions set
    name = p_name,
    description = p_description,
    max_players = p_max_players,
    price_per_session = p_price_per_session,
    duration_minutes = p_duration_minutes,
    location = p_location,
    days_of_week = p_days_of_week,
    start_time = p_start_time::time,
    weeks = p_weeks,
    payment_terms = p_payment_terms,
    session_type = p_session_type,
    location_area = p_location_area,
    target_skill_level = p_target_skill_level,
    prerequisites = p_prerequisites,
    cancellation_policy = p_cancellation_policy,
    updated_at = now()
  where id = p_session_id;

  -- If schedule changed, clear future occurrences and recreate
  if v_generate_occurrences then
    delete from public.session_occurrences 
    where session_id = p_session_id and status = 'upcoming';

    if current_date > v_start_date then
      v_current_date := current_date;
    else
      v_current_date := v_start_date;
    end if;
     
    v_end_date := v_start_date + (p_weeks * 7);

    while v_current_date <= v_end_date loop
      v_pg_dow := extract(dow from v_current_date)::int;
      v_dow := case when v_pg_dow = 0 then 7 else v_pg_dow end;

      if v_dow = any(p_days_of_week) then
        insert into public.session_occurrences (session_id, date)
        values (p_session_id, v_current_date);
      end if;

      v_current_date := v_current_date + 1;
    end loop;
  end if;
end;
$$;

-- Grant permissions again
grant execute on function public.create_coaching_session to anon, authenticated;
grant execute on function public.update_coaching_session to anon, authenticated;

NOTIFY pgrst, 'reload schema';
