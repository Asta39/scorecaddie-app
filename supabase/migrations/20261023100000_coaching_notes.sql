-- Notes between a coach and a player. The app has no chat: they phone each
-- other, and write here what should be remembered. Only the two of them can
-- read a note; only its author can delete it; a note can only be written
-- between a coach and a player who share a session.

create table if not exists public.coaching_notes (
  id uuid primary key default gen_random_uuid(),
  coach_id text not null,
  player_id text not null,
  author_id text not null default (auth.uid())::text,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists coaching_notes_pair_idx on public.coaching_notes (coach_id, player_id, created_at desc);

alter table public.coaching_notes enable row level security;

drop policy if exists "Coach and player read their notes" on public.coaching_notes;
create policy "Coach and player read their notes" on public.coaching_notes for select
  using ((select auth.uid())::text in (coach_id, player_id));

drop policy if exists "Coach and player write notes" on public.coaching_notes;
create policy "Coach and player write notes" on public.coaching_notes for insert
  with check (
    author_id = (select auth.uid())::text
    and author_id in (coach_id, player_id)
    and exists (
      select 1 from public.session_enrollments e
      join public.coaching_sessions s on s.id = e.session_id
      where e.player_id = coaching_notes.player_id and s.coach_id = coaching_notes.coach_id
    )
  );

drop policy if exists "Authors delete their notes" on public.coaching_notes;
create policy "Authors delete their notes" on public.coaching_notes for delete
  using (author_id = (select auth.uid())::text);

grant select, insert, delete on public.coaching_notes to authenticated;
