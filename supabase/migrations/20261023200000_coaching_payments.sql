-- How players pay a coach, and a receipt for every payment the coach records.
--
-- payment_methods: what the coach accepts for a session, e.g.
--   [{"type":"send_money","number":"0712345678","name":"SACE"},
--    {"type":"paybill","number":"247247","account":"COACH1","name":"SACE"}]
-- Players copy these into M-Pesa; the app never moves money.
--
-- coaching_payments: one row per payment the coach records, with the pasted
-- M-Pesa message and its code. The code is unique per coach so the same
-- payment can't be counted twice.

alter table public.coaching_sessions
  add column if not exists payment_methods jsonb not null default '[]'::jsonb;

create table if not exists public.coaching_payments (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.session_enrollments(id) on delete cascade,
  session_id uuid,
  coach_id text not null default (auth.uid())::text,
  player_id text,
  amount numeric not null check (amount > 0),
  method text not null check (method in ('MPESA', 'CASH', 'BANK')),
  reference text,
  message text check (char_length(message) <= 1000),
  created_at timestamptz not null default now()
);

create unique index if not exists coaching_payments_reference_idx
  on public.coaching_payments (coach_id, reference) where reference is not null;
create index if not exists coaching_payments_enrollment_idx on public.coaching_payments (enrollment_id);

alter table public.coaching_payments enable row level security;

drop policy if exists "Coach and player read payments" on public.coaching_payments;
create policy "Coach and player read payments" on public.coaching_payments for select
  using ((select auth.uid())::text in (coach_id, player_id));

drop policy if exists "Coach records payments for own sessions" on public.coaching_payments;
create policy "Coach records payments for own sessions" on public.coaching_payments for insert
  with check (
    coach_id = (select auth.uid())::text
    and exists (
      select 1 from public.session_enrollments e
      join public.coaching_sessions s on s.id = e.session_id
      where e.id = coaching_payments.enrollment_id and s.coach_id = (select auth.uid())::text
    )
  );

grant select, insert on public.coaching_payments to authenticated;
notify pgrst, 'reload schema';
