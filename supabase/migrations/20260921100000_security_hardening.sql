-- ============================================================================
-- Security hardening (audit 2026-09-21)
--
-- The anon key ships inside the mobile app, so anything the `anon` role can do
-- is effectively public. The audit found:
--
--   1. `allow_all` policies (ALL, USING true, WITH CHECK true, for anon +
--      authenticated) on User, Round, HoleScore, PlayerStat, Course, Tee and
--      CourseHole. Postgres ORs permissive policies, so these overrode every
--      narrower rule: anyone, signed in or not, could read, edit or delete
--      every row in those tables.
--   2. User.role writable by the user (own-row policy) and by anyone (via #1),
--      with nothing guarding it. The super-admin portal trusts
--      User.role = 'super_admin', so any player could promote themselves and
--      drive the service-role admin API.
--   3. 23 SECURITY DEFINER functions executable by anon, several with no
--      caller check at all (set any handicap, mark any enrollment paid, act as
--      any coach, enroll anyone).
--
-- This migration closes those, keeps every working app flow working, and is
-- safe to re-run.
-- ============================================================================


-- ── 0. Caller-identity helper ───────────────────────────────────────────────
-- Coaching tables store either the auth uid or the legacy firebaseUid, so
-- "is this id me?" has to accept both.
create or replace function public.is_caller(p_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_id is not null and (
    p_id = auth.uid()::text
    or p_id = (select u."firebaseUid" from public."User" u where u.id = auth.uid()::text)
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public."User" u
    where u.id = auth.uid()::text and lower(u.role::text) = 'super_admin'
  );
$$;


-- ── 1. Privileged-role guard on User ────────────────────────────────────────
-- Only the service role (portal admin API) and definer functions such as
-- handle_new_user may grant or revoke super_admin / club_admin. A normal
-- client trying to change a privileged role keeps the old value rather than
-- erroring, so an ordinary profile sync (which always sends `role`) still
-- saves every other field.
create or replace function public.guard_user_privileged_role()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  privileged constant text[] := array['super_admin', 'club_admin'];
begin
  if current_user in ('postgres', 'service_role', 'supabase_admin')
     or coalesce(auth.role(), '') = 'service_role' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if lower(new.role::text) = any (privileged) then
      raise exception 'Not allowed to assign role %', new.role using errcode = '42501';
    end if;
  elsif new.role is distinct from old.role
        and (lower(new.role::text) = any (privileged) or lower(old.role::text) = any (privileged)) then
    new.role := old.role;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_user_privileged_role on public."User";
create trigger trg_guard_user_privileged_role
  before insert or update on public."User"
  for each row execute function public.guard_user_privileged_role();


-- ── 2. Remove the wide-open policies ────────────────────────────────────────
drop policy if exists "allow_all" on public."User";
drop policy if exists "allow_all" on public."Round";
drop policy if exists "allow_all" on public."HoleScore";
drop policy if exists "allow_all" on public."PlayerStat";
drop policy if exists "allow_all" on public."Course";
drop policy if exists "allow_all" on public."Tee";
drop policy if exists "allow_all" on public."CourseHole";

-- User: anyone could insert arbitrary users; anon could read everyone's
-- email and phone. Signed-in users keep read access (marketplace, friends,
-- leaderboards) and full control of their own row.
drop policy if exists "Anyone can insert users" on public."User";
drop policy if exists "Public profiles are viewable by everyone" on public."User";

-- Round / HoleScore: open inserts, open updates, anon reads.
drop policy if exists "Anyone can insert rounds" on public."Round";
drop policy if exists "Anyone can update rounds" on public."Round";
drop policy if exists "Anyone can read rounds" on public."Round";
drop policy if exists "Enable select for users based on userId" on public."Round";
drop policy if exists "Anyone can insert hole scores" on public."HoleScore";
drop policy if exists "Anyone can read hole scores" on public."HoleScore";

-- Course data: open update / insert for everyone.
drop policy if exists "auth_update_courses" on public."Course";
drop policy if exists "auth_insert_tees" on public."Tee";
drop policy if exists "auth_insert_holes" on public."CourseHole";


-- ── 3. Custom courses: owned by whoever created them ────────────────────────
-- Players can add courses the app doesn't know. Those rows had no owner, so
-- the only way to let the app sync them was to let everyone write every
-- course. Record the creator and scope writes to unverified courses they own.
-- Official / club-verified courses stay writable only by their club admin
-- (existing *_admin_* policies) and the service role.
alter table public."Course" add column if not exists "createdBy" text default (auth.uid())::text;

drop policy if exists "course_owner_insert" on public."Course";
create policy "course_owner_insert" on public."Course"
  for insert to authenticated
  with check ("createdBy" = auth.uid()::text and coalesce("dataVerified", false) = false);

drop policy if exists "course_owner_update" on public."Course";
create policy "course_owner_update" on public."Course"
  for update to authenticated
  using ("createdBy" = auth.uid()::text and coalesce("dataVerified", false) = false)
  with check ("createdBy" = auth.uid()::text and coalesce("dataVerified", false) = false);

create or replace function public.owns_custom_course(p_course_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public."Course" c
    where c.id = p_course_id
      and c."createdBy" = auth.uid()::text
      and coalesce(c."dataVerified", false) = false
  );
$$;

drop policy if exists "tee_owner_write" on public."Tee";
create policy "tee_owner_write" on public."Tee"
  for all to authenticated
  using (public.owns_custom_course("courseId"))
  with check (public.owns_custom_course("courseId"));

drop policy if exists "coursehole_owner_write" on public."CourseHole";
create policy "coursehole_owner_write" on public."CourseHole"
  for all to authenticated
  using (public.owns_custom_course("courseId"))
  with check (public.owns_custom_course("courseId"));


-- ── 4. Competition rounds written on a player's behalf ──────────────────────
-- The competition scan-submit screen saves a player's round as
-- `comp_<competition_id>_<player_id>`, submitted by a fellow entrant (the
-- marker) or the club admin. Allow exactly that round id, nothing broader.
create or replace function public.can_write_competition_round(p_round_id text, p_user_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_round_id like 'comp\_%' and (
    exists (
      select 1
      from public.competition_entries me
      join public.competition_entries them on them.competition_id = me.competition_id
      where me.player_id = auth.uid()::text
        and them.player_id = p_user_id
        and p_round_id = 'comp_' || me.competition_id::text || '_' || p_user_id
    )
    or exists (
      select 1
      from public.competitions c
      join public.club_admins ca on ca.club_id = c.club_id
      join public.competition_entries e on e.competition_id = c.id and e.player_id = p_user_id
      where ca.user_id = auth.uid()
        and p_round_id = 'comp_' || c.id::text || '_' || p_user_id
    )
  );
$$;

drop policy if exists "round_competition_insert" on public."Round";
create policy "round_competition_insert" on public."Round"
  for insert to authenticated
  with check (public.can_write_competition_round(id, "userId"));

drop policy if exists "round_competition_update" on public."Round";
create policy "round_competition_update" on public."Round"
  for update to authenticated
  using (public.can_write_competition_round(id, "userId"))
  with check (public.can_write_competition_round(id, "userId"));

create or replace function public.can_write_round_holes(p_round_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public."Round" r
    where r.id = p_round_id
      and public.can_write_competition_round(r.id, r."userId")
  );
$$;

drop policy if exists "holescore_competition_insert" on public."HoleScore";
create policy "holescore_competition_insert" on public."HoleScore"
  for insert to authenticated
  with check (public.can_write_round_holes("roundId"));

drop policy if exists "holescore_competition_update" on public."HoleScore";
create policy "holescore_competition_update" on public."HoleScore"
  for update to authenticated
  using (public.can_write_round_holes("roundId"))
  with check (public.can_write_round_holes("roundId"));


-- ── 5. Tables that had RLS on but no policies ───────────────────────────────
-- Booking: caddie/coach bookings. With zero policies every insert failed.
drop policy if exists "booking_player_insert" on public."Booking";
create policy "booking_player_insert" on public."Booking"
  for insert to authenticated
  with check (player_id = auth.uid()::text);

drop policy if exists "booking_parties_read" on public."Booking";
create policy "booking_parties_read" on public."Booking"
  for select to authenticated
  using (player_id = auth.uid()::text or provider_id = auth.uid()::text or "caddieId" = auth.uid()::text);

drop policy if exists "booking_parties_update" on public."Booking";
create policy "booking_parties_update" on public."Booking"
  for update to authenticated
  using (player_id = auth.uid()::text or provider_id = auth.uid()::text or "caddieId" = auth.uid()::text)
  with check (player_id = auth.uid()::text or provider_id = auth.uid()::text or "caddieId" = auth.uid()::text);

-- drills: coach drill templates. With zero policies coaches could neither
-- create nor read them, which broke the coach Drills tab.
drop policy if exists "drills_read" on public.drills;
create policy "drills_read" on public.drills
  for select to authenticated
  using (true);

drop policy if exists "drills_creator_write" on public.drills;
create policy "drills_creator_write" on public.drills
  for all to authenticated
  using (public.is_caller(creator_id))
  with check (public.is_caller(creator_id));


-- ── 6. admin_notifications: scope to the admin's own club ───────────────────
-- Previously SELECT and UPDATE were `true` for every signed-in user.
drop policy if exists "Admins can view their club notifications" on public.admin_notifications;
create policy "Admins can view their club notifications" on public.admin_notifications
  for select to authenticated
  using (
    club_id in (select ca.club_id::text from public.club_admins ca where ca.user_id = auth.uid())
    or public.is_super_admin()
  );

drop policy if exists "Admins can update their club notifications" on public.admin_notifications;
create policy "Admins can update their club notifications" on public.admin_notifications
  for update to authenticated
  using (
    club_id in (select ca.club_id::text from public.club_admins ca where ca.user_id = auth.uid())
    or public.is_super_admin()
  )
  with check (
    club_id in (select ca.club_id::text from public.club_admins ca where ca.user_id = auth.uid())
    or public.is_super_admin()
  );


-- ── 7. Narrow RPCs for the two cross-user writes the app legitimately needs ─
-- Profile view counter on someone else's profile. Previously a direct
-- UPDATE on another user's row, which only worked because of allow_all.
create or replace function public.increment_profile_views(p_user_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public."User"
  set views = coalesce(views, 0) + 1
  where id = p_user_id
    and p_user_id <> auth.uid()::text;
$$;

-- Flag a caddie/coach as booked. Only the player who holds a booking with
-- them may do this, and only the status field is touched.
create or replace function public.mark_provider_booked(p_provider_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public."Booking" b
    where b.player_id = auth.uid()::text
      and (b.provider_id = p_provider_id or b."caddieId" = p_provider_id)
  ) then
    raise exception 'No booking with this provider' using errcode = '42501';
  end if;

  update public."User"
  set "providerStatus" = 'BOOKED'
  where id = p_provider_id
    and lower(role::text) in ('caddie', 'coach');
end;
$$;


-- ── 8. Caller checks inside existing SECURITY DEFINER functions ─────────────
-- Injected right after the body's BEGIN, so the rest of each function is
-- untouched. A marker comment makes this idempotent.
create or replace function pg_temp.guard_function(p_signature text, p_check text)
returns void
language plpgsql
as $$
declare
  def text;
begin
  def := pg_get_functiondef(p_signature::regprocedure);
  if position('SECURITY_GUARD' in def) > 0 then
    return;
  end if;
  def := regexp_replace(def, '\mBEGIN\M', 'BEGIN -- SECURITY_GUARD' || E'\n  ' || p_check, 'i');
  execute def;
end;
$$;

do $$
declare
  deny constant text := 'RAISE EXCEPTION ''Not authorized'' USING ERRCODE = ''42501'';';
  svc  constant text := 'coalesce(auth.role(), '''') <> ''service_role'' AND ';
begin
  -- Only the coach themselves can create a session under their name.
  perform pg_temp.guard_function(
    'public.create_coaching_session(text,text,text,integer,numeric,integer,text,integer[],text,integer,date,text,text,text,text,text,text)',
    'IF ' || svc || 'NOT public.is_caller(p_coach_id) THEN ' || deny || ' END IF;');

  -- Only the session's own coach can edit it.
  perform pg_temp.guard_function(
    'public.update_coaching_session(uuid,text,text,text,integer,numeric,integer,text,integer[],text,integer,date,text,text,text,text,text,text)',
    'IF ' || svc || '(NOT public.is_caller(p_coach_id) OR NOT EXISTS (SELECT 1 FROM public.coaching_sessions s WHERE s.id = p_session_id AND public.is_caller(s.coach_id))) THEN ' || deny || ' END IF;');

  -- Players enroll themselves only.
  perform pg_temp.guard_function(
    'public.enroll_player_in_session(uuid,text)',
    'IF ' || svc || 'NOT public.is_caller(p_player_id) THEN ' || deny || ' END IF;');

  -- Only the coach running the session records payments against it.
  perform pg_temp.guard_function(
    'public.record_payment(uuid,numeric,text)',
    'IF ' || svc || 'NOT EXISTS (SELECT 1 FROM public.session_enrollments e JOIN public.coaching_sessions s ON s.id = e.session_id WHERE e.id = p_enrollment_id AND public.is_caller(s.coach_id)) THEN ' || deny || ' END IF;');

  -- Only the coach running the session can complete its occurrences.
  perform pg_temp.guard_function(
    'public.complete_occurrence(uuid)',
    'IF ' || svc || 'NOT EXISTS (SELECT 1 FROM public.session_occurrences o JOIN public.coaching_sessions s ON s.id = o.session_id WHERE o.id = p_occurrence_id AND public.is_caller(s.coach_id)) THEN ' || deny || ' END IF;');

  -- Onboarding looks up the caller's own email only; no probing others'.
  perform pg_temp.guard_function(
    'public.match_user_to_clubs(text)',
    'IF ' || svc || 'lower(coalesce(user_email, '''')) <> lower(coalesce(auth.jwt() ->> ''email'', '''')) THEN ' || deny || ' END IF;');

  -- Club dashboard stats: that club's admins (or a super admin) only.
  perform pg_temp.guard_function(
    'public.get_attendance_history(uuid,integer)',
    'IF ' || svc || 'NOT (public.is_super_admin() OR EXISTS (SELECT 1 FROM public.club_admins ca WHERE ca.user_id = auth.uid() AND ca.club_id = p_club_id)) THEN ' || deny || ' END IF;');

  perform pg_temp.guard_function(
    'public.get_caddie_experience_mix(uuid)',
    'IF ' || svc || 'NOT (public.is_super_admin() OR EXISTS (SELECT 1 FROM public.club_admins ca WHERE ca.user_id = auth.uid() AND ca.club_id = p_club_id)) THEN ' || deny || ' END IF;');
end;
$$;


-- ── 9. Function EXECUTE privileges ──────────────────────────────────────────
-- Postgres grants EXECUTE to PUBLIC by default, so revoke from PUBLIC and anon
-- and grant back only what signed-in clients actually call.
do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef
  loop
    execute format('revoke execute on function %s from public, anon', f.sig);
    execute format('grant execute on function %s to authenticated', f.sig);
  end loop;
end;
$$;

-- Not callable by clients at all: server-side only, or trigger functions.
do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'apply_handicap_revision',      -- no client caller; handicap changes go through the server
        'get_due_reminders',            -- edge function (service role) only
        'handle_new_user',
        'trigger_new_competition_webhook',
        'trigger_new_post_webhook',
        'trigger_underpaid_admin_notification',
        'guard_user_privileged_role'
      )
  loop
    execute format('revoke execute on function %s from public, anon, authenticated', f.sig);
  end loop;
end;
$$;


-- ── 10. Pin search_path on every function the advisor flagged ───────────────
do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%'
      )
      and p.proname in (
        'get_caddie_experience_mix', 'trigger_new_competition_webhook', 'trigger_new_post_webhook',
        'trigger_underpaid_admin_notification', 'trg_competition_results_calc_fn',
        'enroll_player_in_session', 'get_attendance_history', 'get_user_home_club', 'handle_new_user',
        'flag_caddie_deactivation', 'set_updated_at', 'set_restaurant_updated_at',
        'delete_user_account', 'trg_competition_results_rank_stmt', 'update_competition_ranks',
        'calculate_competition_score', 'apply_handicap_revision', 'check_tee_time_availability',
        'get_available_tee_times'
      )
  loop
    execute format('alter function %s set search_path = public', f.sig);
  end loop;
end;
$$;


-- ── 11. Views must respect the querying user's RLS ──────────────────────────
alter view if exists public.player_home_club set (security_invoker = true);
alter view if exists public.competition_leaderboard set (security_invoker = true);


-- ── 12. Table privileges: defence in depth behind RLS ───────────────────────
-- Earlier migrations ran GRANT ALL ... TO anon, leaving RLS as the only
-- barrier. Signed-out clients only ever read public data (courses, tees,
-- marketplace caddies, platform config). TRUNCATE bypasses RLS entirely, so
-- no client role gets it.
revoke insert, update, delete, truncate, references, trigger
  on all tables in schema public from anon;
revoke truncate, references, trigger
  on all tables in schema public from authenticated;
