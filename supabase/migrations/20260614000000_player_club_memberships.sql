-- 1. Create the player_club_memberships junction table
create table player_club_memberships (
  id uuid primary key default gen_random_uuid(),
  player_id text not null references public."User"(id) on delete cascade,
  club_id text not null references public."Course"(id) on delete cascade,
  
  membership_type text not null default 'full' 
    check (membership_type in ('full', 'social', 'junior', 'guest', 'honorary')),
  
  -- home club flag — player has exactly one home club at a time
  is_home_club boolean not null default false,
  
  -- admin who approved/created this link (null = self-joined)
  approved_by text references public."User"(id),
  
  -- migration source — 'hdid', 'manual', 'self'
  source text default 'self',
  
  status text not null default 'active' 
    check (status in ('active', 'pending', 'suspended', 'resigned')),
  
  joined_at timestamptz default now(),
  created_at timestamptz default now(),
  
  -- a player can only have one record per club
  unique(player_id, club_id)
);

-- Partial unique index: only one active home club per player
create unique index one_home_club_per_player 
  on player_club_memberships(player_id) 
  where (is_home_club = true and status = 'active');

-- 2. Migrate existing data
-- SKIPPED: There was no existing club_id on the User table to migrate from.

-- 3. RLS policies
alter table player_club_memberships enable row level security;

-- SUPER ADMIN
create policy "super admin full access"
  on player_club_memberships
  for all
  using (
    exists (
      select 1 from public."User"
      where id = auth.uid()::text
      and role = 'super_admin'
    )
  );

-- CLUB ADMIN
create policy "club admin manages their club memberships"
  on player_club_memberships
  for all
  using (
    exists (
      select 1 from public."User" u
      join player_club_memberships pcm on pcm.player_id = u.id
      where u.id = auth.uid()::text
      and u.role = 'club_admin'
      and pcm.club_id = player_club_memberships.club_id
      and pcm.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public."User" u
      join player_club_memberships pcm on pcm.player_id = u.id
      where u.id = auth.uid()::text
      and u.role = 'club_admin'
      and pcm.club_id = player_club_memberships.club_id
      and pcm.status = 'active'
    )
  );

-- PLAYER
create policy "player manages own memberships"
  on player_club_memberships
  for all
  using (player_id = auth.uid()::text)
  with check (
    player_id = auth.uid()::text
    and status = 'pending'
  );

create policy "player sees clubmates"
  on player_club_memberships
  for select
  using (
    exists (
      select 1 from player_club_memberships as my_membership
      where my_membership.player_id = auth.uid()::text
      and my_membership.club_id = player_club_memberships.club_id
      and my_membership.status = 'active'
    )
  );

-- CADDIE
create policy "caddie sees club members"
  on player_club_memberships
  for select
  using (
    exists (
      select 1 from public."User" u
      join player_club_memberships pcm on pcm.player_id = u.id
      where u.id = auth.uid()::text
      and u.role = 'caddie'
      and pcm.club_id = player_club_memberships.club_id
      and pcm.status = 'active'
    )
  );

-- COACH
create policy "coach sees club members"
  on player_club_memberships
  for select
  using (
    exists (
      select 1 from public."User" u
      join player_club_memberships pcm on pcm.player_id = u.id
      where u.id = auth.uid()::text
      and u.role = 'coach'
      and pcm.club_id = player_club_memberships.club_id
      and pcm.status = 'active'
    )
  );

-- 4. Create club_member_directory view
create or replace view club_member_directory as
select
  pcm.club_id,
  pcm.player_id,
  pcm.is_home_club,
  pcm.joined_at,
  u.name as full_name,
  u."handicapIndex" as handicap_index,
  u."avatarUrl" as avatar_url
from player_club_memberships pcm
join public."User" u on u.id = pcm.player_id
where pcm.status = 'active';

alter view club_member_directory set (security_invoker = true);

-- 5. Create player_home_club view
create or replace view player_home_club as
select 
  u.id as player_id,
  u.name as full_name,
  u."handicapIndex" as handicap_index,
  pcm.club_id as home_club_id,
  c.name as home_club_name
from public."User" u
left join player_club_memberships pcm 
  on pcm.player_id = u.id 
  and pcm.is_home_club = true 
  and pcm.status = 'active'
left join public."Course" c on c.id = pcm.club_id;
