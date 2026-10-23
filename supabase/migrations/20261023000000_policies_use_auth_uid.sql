-- Coaching and drill policies matched the signed-in user through
-- "User"."firebaseUid". That column is private now (no SELECT for
-- authenticated), so every query these policies guard failed with
-- "permission denied for table User". Firebase is gone; ids are the
-- Supabase auth uid, so match on that alone. Applied by hand on 2026-10-23.

drop policy if exists "Coaches manage their sessions" on public.coaching_sessions;
create policy "Coaches manage their sessions" on public.coaching_sessions for all
  using (coach_id = (select auth.uid())::text)
  with check (coach_id = (select auth.uid())::text);

drop policy if exists "Coaches manage assignments" on public.drill_assignments;
create policy "Coaches manage assignments" on public.drill_assignments for all
  using (coach_id = (select auth.uid())::text);
drop policy if exists "Players read assigned drills" on public.drill_assignments;
create policy "Players read assigned drills" on public.drill_assignments for select
  using (player_id = (select auth.uid())::text);

drop policy if exists "drill_steps_creator_write" on public.drill_steps;
create policy "drill_steps_creator_write" on public.drill_steps for all
  using (drill_id in (select d.id from public.drills d where d.creator_id = (select auth.uid())::text))
  with check (drill_id in (select d.id from public.drills d where d.creator_id = (select auth.uid())::text));

drop policy if exists "Coaches manage attendance" on public.session_attendance;
create policy "Coaches manage attendance" on public.session_attendance for all
  using (exists (select 1 from public.session_occurrences o
         join public.coaching_sessions s on s.id = o.session_id
         where o.id = session_attendance.occurrence_id and s.coach_id = (select auth.uid())::text));

drop policy if exists "Coaches see their session enrollments" on public.session_enrollments;
create policy "Coaches see their session enrollments" on public.session_enrollments for select
  using (exists (select 1 from public.coaching_sessions s
         where s.id = session_enrollments.session_id and s.coach_id = (select auth.uid())::text));
drop policy if exists "Players see own enrollments" on public.session_enrollments;
create policy "Players see own enrollments" on public.session_enrollments for select
  using (player_id = (select auth.uid())::text);
drop policy if exists "Players can enroll" on public.session_enrollments;
create policy "Players can enroll" on public.session_enrollments for insert
  with check (player_id = (select auth.uid())::text);

drop policy if exists "Coaches manage their occurrences" on public.session_occurrences;
create policy "Coaches manage their occurrences" on public.session_occurrences for all
  using (exists (select 1 from public.coaching_sessions s
         where s.id = session_occurrences.session_id and s.coach_id = (select auth.uid())::text));
