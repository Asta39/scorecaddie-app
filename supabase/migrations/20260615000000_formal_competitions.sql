-- =============================================================================
-- PHASE 2: FORMAL CLUB COMPETITIONS MODULE
-- Depends on: player_club_memberships (Phase 1)
-- =============================================================================

-- =============================================================================
-- 1. COMPETITIONS TABLE
-- =============================================================================
create table competitions (
  id uuid primary key default gen_random_uuid(),
  club_id text not null references public."Course"(id) on delete cascade,
  name text not null,
  description text,
  competition_type text not null default 'strokeplay'
    check (competition_type in ('strokeplay', 'stableford', 'matchplay', 'betterball', 'foursome', 'bogey')),
  status text not null default 'upcoming'
    check (status in ('upcoming', 'open_for_entry', 'in_progress', 'closed', 'completed', 'cancelled')),
  start_date date not null,
  end_date date,
  entry_deadline timestamptz,
  entry_fee numeric(10, 2) default 0,
  currency text default 'ZAR',
  rules_config jsonb not null default '{
    "handicap_allowance_pct": 100,
    "max_handicap": 36,
    "flights": [],
    "tiebreaker": "countback"
  }'::jsonb,
  created_by text references public."User"(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger competitions_updated_at
  before update on competitions
  for each row execute function set_updated_at();

-- =============================================================================
-- 2. COMPETITION_ENTRIES TABLE
-- =============================================================================
create table competition_entries (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references competitions(id) on delete cascade,
  player_id text not null references public."User"(id) on delete cascade,
  unique(competition_id, player_id),
  playing_handicap numeric(4, 1),
  flight_name text,
  tee_color text,
  entry_status text not null default 'pending'
    check (entry_status in ('pending', 'confirmed', 'withdrawn', 'disqualified')),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid', 'waived', 'refunded')),
  confirmed_by text references public."User"(id),
  confirmed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create trigger competition_entries_updated_at
  before update on competition_entries
  for each row execute function set_updated_at();

create index competition_entries_competition_id_idx on competition_entries(competition_id);
create index competition_entries_player_id_idx on competition_entries(player_id);

-- =============================================================================
-- 3. STARTING_SHEETS TABLE
-- =============================================================================
create table starting_sheets (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references competitions(id) on delete cascade,
  entry_id uuid not null references competition_entries(id) on delete cascade,
  unique(competition_id, entry_id),
  tee_time timestamptz not null,
  tee_number integer not null default 1,
  group_number integer not null,
  round_number integer not null default 1,
  created_at timestamptz default now()
);

create index starting_sheets_competition_id_idx on starting_sheets(competition_id);
create index starting_sheets_tee_time_idx on starting_sheets(competition_id, tee_time);

-- =============================================================================
-- 4. COMPETITION_RESULTS TABLE
-- =============================================================================
create table competition_results (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references competitions(id) on delete cascade,
  entry_id uuid not null references competition_entries(id) on delete cascade,
  player_id text not null references public."User"(id) on delete cascade,
  unique(competition_id, player_id),
  round_number integer not null default 1,
  gross_score integer,
  net_score numeric(5, 1),
  stableford_points integer,
  position integer,
  scorecard jsonb,
  result_status text not null default 'active'
    check (result_status in ('active', 'dsq', 'dnf', 'wdr')),
  certified boolean not null default false,
  certified_by text references public."User"(id),
  certified_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create trigger competition_results_updated_at
  before update on competition_results
  for each row execute function set_updated_at();

create index competition_results_competition_id_idx on competition_results(competition_id);
create index competition_results_position_idx on competition_results(competition_id, position);

-- =============================================================================
-- 5. ROW LEVEL SECURITY
-- =============================================================================

-- -- COMPETITIONS --------------------------------------------------------------
alter table competitions enable row level security;

create policy "members can view their club competitions"
  on competitions for select
  using (
    exists (
      select 1 from player_club_memberships pcm
      where pcm.player_id = auth.uid()::text
      and pcm.club_id = competitions.club_id
      and pcm.status = 'active'
    )
  );

create policy "club admin manages competitions"
  on competitions for all
  using (
    exists (
      select 1 from public."User" u
      join player_club_memberships pcm on pcm.player_id = u.id
      where u.id = auth.uid()::text
      and u.role in ('club_admin', 'super_admin')
      and pcm.club_id = competitions.club_id
      and pcm.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public."User" u
      join player_club_memberships pcm on pcm.player_id = u.id
      where u.id = auth.uid()::text
      and u.role in ('club_admin', 'super_admin')
      and pcm.club_id = competitions.club_id
      and pcm.status = 'active'
    )
  );

-- -- COMPETITION ENTRIES -------------------------------------------------------
alter table competition_entries enable row level security;

create policy "members can view entries for their club competitions"
  on competition_entries for select
  using (
    exists (
      select 1 from competitions c
      join player_club_memberships pcm on pcm.club_id = c.club_id
      where c.id = competition_entries.competition_id
      and pcm.player_id = auth.uid()::text
      and pcm.status = 'active'
    )
  );

create policy "player can enter open competitions"
  on competition_entries for insert
  with check (
    player_id = auth.uid()::text
    and exists (
      select 1 from competitions c
      join player_club_memberships pcm on pcm.club_id = c.club_id
      where c.id = competition_entries.competition_id
      and c.status = 'open_for_entry'
      and pcm.player_id = auth.uid()::text
      and pcm.status = 'active'
    )
  );

create policy "player can withdraw own entry"
  on competition_entries for update
  using (player_id = auth.uid()::text)
  with check (
    player_id = auth.uid()::text
    and entry_status = 'withdrawn'
  );

create policy "club admin manages entries"
  on competition_entries for all
  using (
    exists (
      select 1 from competitions c
      join public."User" u on u.id = auth.uid()::text
      join player_club_memberships pcm on pcm.player_id = u.id and pcm.club_id = c.club_id
      where c.id = competition_entries.competition_id
      and u.role in ('club_admin', 'super_admin')
      and pcm.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from competitions c
      join public."User" u on u.id = auth.uid()::text
      join player_club_memberships pcm on pcm.player_id = u.id and pcm.club_id = c.club_id
      where c.id = competition_entries.competition_id
      and u.role in ('club_admin', 'super_admin')
      and pcm.status = 'active'
    )
  );

-- -- STARTING SHEETS -----------------------------------------------------------
alter table starting_sheets enable row level security;

create policy "members can view starting sheets"
  on starting_sheets for select
  using (
    exists (
      select 1 from competitions c
      join player_club_memberships pcm on pcm.club_id = c.club_id
      where c.id = starting_sheets.competition_id
      and pcm.player_id = auth.uid()::text
      and pcm.status = 'active'
    )
  );

create policy "club admin manages starting sheets"
  on starting_sheets for all
  using (
    exists (
      select 1 from competitions c
      join public."User" u on u.id = auth.uid()::text
      join player_club_memberships pcm on pcm.player_id = u.id and pcm.club_id = c.club_id
      where c.id = starting_sheets.competition_id
      and u.role in ('club_admin', 'super_admin')
      and pcm.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from competitions c
      join public."User" u on u.id = auth.uid()::text
      join player_club_memberships pcm on pcm.player_id = u.id and pcm.club_id = c.club_id
      where c.id = starting_sheets.competition_id
      and u.role in ('club_admin', 'super_admin')
      and pcm.status = 'active'
    )
  );

-- -- COMPETITION RESULTS -------------------------------------------------------
alter table competition_results enable row level security;

create policy "members can view results"
  on competition_results for select
  using (
    exists (
      select 1 from competitions c
      join player_club_memberships pcm on pcm.club_id = c.club_id
      where c.id = competition_results.competition_id
      and pcm.player_id = auth.uid()::text
      and pcm.status = 'active'
    )
  );

create policy "player can submit own scorecard"
  on competition_results for insert
  with check (
    player_id = auth.uid()::text
    and exists (
      select 1 from competitions c
      where c.id = competition_results.competition_id
      and c.status = 'in_progress'
    )
  );

create policy "player can update own uncertified scorecard"
  on competition_results for update
  using (
    player_id = auth.uid()::text
    and certified = false
  )
  with check (
    player_id = auth.uid()::text
    and certified = false
  );

create policy "club admin manages results"
  on competition_results for all
  using (
    exists (
      select 1 from competitions c
      join public."User" u on u.id = auth.uid()::text
      join player_club_memberships pcm on pcm.player_id = u.id and pcm.club_id = c.club_id
      where c.id = competition_results.competition_id
      and u.role in ('club_admin', 'super_admin')
      and pcm.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from competitions c
      join public."User" u on u.id = auth.uid()::text
      join player_club_memberships pcm on pcm.player_id = u.id and pcm.club_id = c.club_id
      where c.id = competition_results.competition_id
      and u.role in ('club_admin', 'super_admin')
      and pcm.status = 'active'
    )
  );

-- =============================================================================
-- 6. REALTIME
-- =============================================================================
alter publication supabase_realtime add table competition_results;
alter publication supabase_realtime add table competitions;

-- =============================================================================
-- 7. CONVENIENCE VIEWS
-- =============================================================================

-- Live leaderboard
create or replace view competition_leaderboard as
select
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
from competition_results cr
join public."User" u on u.id = cr.player_id
join competitions c on c.id = cr.competition_id
join competition_entries ce on ce.id = cr.entry_id
order by cr.competition_id, cr.position asc nulls last, cr.net_score asc nulls last;

alter view competition_leaderboard set (security_invoker = true);

-- Starting sheet with player details
create or replace view competition_starting_sheet as
select
  ss.competition_id,
  c.name as competition_name,
  c.start_date,
  ss.round_number,
  ss.tee_time,
  ss.tee_number,
  ss.group_number,
  ce.player_id,
  u.name as full_name,
  u."handicapIndex" as handicap_index,
  ce.playing_handicap,
  ce.tee_color,
  ce.flight_name,
  ce.entry_status
from starting_sheets ss
join competition_entries ce on ce.id = ss.entry_id
join public."User" u on u.id = ce.player_id
join competitions c on c.id = ss.competition_id
order by ss.competition_id, ss.round_number, ss.tee_time, ss.group_number;

alter view competition_starting_sheet set (security_invoker = true);

select 'Phase 2: Competitions schema created successfully' as status;
