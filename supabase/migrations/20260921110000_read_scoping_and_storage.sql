-- ============================================================================
-- Read scoping + storage hardening (audit 2026-09-21, part 2)
--
-- Several tables were readable by anyone, including signed-out callers using
-- the anon key that ships in the app:
--   - session_enrollments: every enrollment, with amount_paid and
--     payment_method, for every coaching session
--   - session_attendance: every attendance record
--   - session_occurrences: every session schedule
--   - club_posts: members-only club news, readable by anyone
-- And storage let any signed-in user upload anywhere in user_assets, with no
-- size or file-type limits on the public buckets.
--
-- Safe to re-run.
-- ============================================================================


-- Also defined in 20260921100000_security_hardening.sql. Repeated so this
-- migration can be applied on its own or in either order.
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
revoke execute on function public.is_caller(text) from public, anon;
grant execute on function public.is_caller(text) to authenticated;


-- ── 1. Coaching data ────────────────────────────────────────────────────────
-- Existing policies already cover the legitimate readers: players see their
-- own enrollments, coaches see their sessions' enrollments and manage
-- attendance.
drop policy if exists "Anyone can read enrollments" on public.session_enrollments;

drop policy if exists "Anyone can read attendance" on public.session_attendance;
drop policy if exists "Players read own attendance" on public.session_attendance;
create policy "Players read own attendance" on public.session_attendance
  for select to authenticated
  using (public.is_caller(player_id));

-- Schedules stay visible to signed-in players browsing sessions, not to the
-- anonymous public.
drop policy if exists "Anyone can read occurrences" on public.session_occurrences;
drop policy if exists "Signed-in users read occurrences" on public.session_occurrences;
create policy "Signed-in users read occurrences" on public.session_occurrences
  for select to authenticated
  using (true);

-- The session booking screen shows who has joined and whether the session is
-- full. It used to read raw enrollment rows (payment fields included) for
-- that. This returns only what the screen shows, and only for sessions open
-- for booking.
create or replace function public.get_session_roster(p_session_id uuid)
returns table (player_id text, name text, "avatarUrl" text)
language sql
stable
security definer
set search_path = public
as $$
  select e.player_id, u.name, u."avatarUrl"
  from public.session_enrollments e
  join public.coaching_sessions s on s.id = e.session_id
  left join public."User" u on u."firebaseUid" = e.player_id or u.id = e.player_id
  where e.session_id = p_session_id
    and e.status = 'active'
    and s.status = 'active';
$$;

revoke execute on function public.get_session_roster(uuid) from public, anon;
grant execute on function public.get_session_roster(uuid) to authenticated;


-- ── 2. Club posts: members and admins only ──────────────────────────────────
-- club_posts_view (active members + the club's admins) remains; this blanket
-- policy overrode it.
drop policy if exists "Public can view club posts" on public.club_posts;


-- ── 3. Storage: user_assets ─────────────────────────────────────────────────
-- The app uploads to profiles/<uid>/... and providers/<uid>/certs/..., so the
-- owner is the SECOND folder. The old update policy compared the FIRST folder
-- to the uid and so never matched, and the insert policy allowed any path.
drop policy if exists "Authenticated Upload" on storage.objects;
drop policy if exists "user_assets_own_insert" on storage.objects;
create policy "user_assets_own_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'user_assets'
    and (storage.foldername(name))[1] in ('profiles', 'providers')
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "Own File Update" on storage.objects;
create policy "Own File Update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'user_assets'
    and (storage.foldername(name))[1] in ('profiles', 'providers')
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "user_assets_own_delete" on storage.objects;
create policy "user_assets_own_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'user_assets'
    and (storage.foldername(name))[1] in ('profiles', 'providers')
    and (storage.foldername(name))[2] = auth.uid()::text
  );


-- ── 4. Storage: size and type limits on public buckets ──────────────────────
-- Limits sit comfortably above today's largest objects (user_assets 391 kB,
-- club-assets 2.9 MB, caddie-photos 4.7 MB, menu-pdfs 15 MB). SVG is
-- deliberately excluded: served from a public bucket it can carry script.
update storage.buckets
set file_size_limit = 5 * 1024 * 1024,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
where id = 'user_assets';

update storage.buckets
set file_size_limit = 10 * 1024 * 1024,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
where id in ('caddie-photos', 'club-assets');

update storage.buckets
set file_size_limit = 25 * 1024 * 1024,
    allowed_mime_types = array['application/pdf']
where id = 'menu-pdfs';
