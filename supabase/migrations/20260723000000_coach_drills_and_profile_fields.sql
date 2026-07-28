-- ============================================================
-- Coach mini-app repair
--
-- Three PGRST200 "could not find a relationship" errors were breaking the
-- coach Drills and Students screens outright:
--
--   1. public.drill_steps was NEVER created in Supabase. It only ever existed
--      in the local Drift database, so `drills(*, drill_steps(count))` could
--      never resolve.
--   2. drill_assignments.drill_id was declared as a bare uuid with no foreign
--      key to drills (see 20260415000000_secure_coaching.sql, which even left
--      a TODO comment about it), so `drill_assignments(*, drill:drills(*))`
--      could never resolve.
--   3. session_enrollments.player_id had no resolvable FK to "User", so the
--      explicit `User!session_enrollments_player_id_fkey` hint failed.
--
-- Also adds the professional-profile columns that ApiService.syncProfile
-- accepts as parameters but silently dropped, because no column existed to
-- write them into.
-- ============================================================

-- ── 1. drill_steps ──────────────────────────────────────────
create table if not exists public.drill_steps (
  id uuid primary key default gen_random_uuid(),
  drill_id uuid not null references public.drills(id) on delete cascade,
  instruction text not null,
  balls_required integer not null default 10,
  step_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_drill_steps_drill on public.drill_steps(drill_id);

alter table public.drill_steps enable row level security;

-- Steps are readable by anyone signed in (players need to see drills assigned
-- to them); only the drill's creator may modify them.
drop policy if exists "drill_steps_read" on public.drill_steps;
create policy "drill_steps_read" on public.drill_steps
  for select to authenticated
  using (true);

drop policy if exists "drill_steps_creator_write" on public.drill_steps;
create policy "drill_steps_creator_write" on public.drill_steps
  for all to authenticated
  using (
    drill_id in (
      select d.id from public.drills d
      where d.creator_id = auth.uid()::text
         or d.creator_id = (select "firebaseUid" from public."User" where id = auth.uid()::text)
    )
  )
  with check (
    drill_id in (
      select d.id from public.drills d
      where d.creator_id = auth.uid()::text
         or d.creator_id = (select "firebaseUid" from public."User" where id = auth.uid()::text)
    )
  );

-- ── 2. drill_assignments.drill_id -> drills.id ──────────────
-- Drop any orphaned assignments first, otherwise adding the FK fails.
delete from public.drill_assignments a
where not exists (select 1 from public.drills d where d.id = a.drill_id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'drill_assignments_drill_id_fkey'
      and conrelid = 'public.drill_assignments'::regclass
  ) then
    alter table public.drill_assignments
      add constraint drill_assignments_drill_id_fkey
      foreign key (drill_id) references public.drills(id) on delete cascade;
  end if;
end $$;

-- ── 3. session_enrollments.player_id -> "User" ──────────────
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'session_enrollments_player_id_fkey'
      and conrelid = 'public.session_enrollments'::regclass
  ) then
    -- Clear rows whose player_id matches no User, so the FK can be added.
    delete from public.session_enrollments e
    where not exists (
      select 1 from public."User" u where u."firebaseUid" = e.player_id
    );

    alter table public.session_enrollments
      add constraint session_enrollments_player_id_fkey
      foreign key (player_id) references public."User"("firebaseUid") on delete cascade;
  end if;
end $$;

-- ── 4. Professional profile columns that were silently dropped ──
alter table public."User"
  add column if not exists "hasCertification" boolean default false,
  add column if not exists "certificationName" text,
  add column if not exists "specializations" text,
  add column if not exists "targetAudience" text;
