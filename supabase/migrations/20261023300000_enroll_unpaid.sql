-- Booking a coaching session no longer marks the player paid.
--
-- enroll_player_in_session simulated a payment: on "upfront" sessions it set
-- amount_paid to the full price and payment_status to fully_paid (half for
-- "split"), with payment_method 'SIMULATED'. Real money goes through M-Pesa
-- outside the app and the coach records it from the confirmation message, so
-- every booking starts unpaid. Keeps the security guard added in
-- 20260921100000_security_hardening.

create or replace function public.enroll_player_in_session(
  p_session_id uuid,
  p_player_id text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max_players int;
  v_current_count int;
  v_enrollment_id uuid;
begin -- SECURITY_GUARD
  if coalesce(auth.role(), '') <> 'service_role' and not public.is_caller(p_player_id) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;

  select max_players into v_max_players from public.coaching_sessions where id = p_session_id;

  select count(*) into v_current_count
  from public.session_enrollments
  where session_id = p_session_id and status = 'active';

  if v_current_count >= v_max_players then
    raise exception 'Session is full';
  end if;

  if exists (select 1 from public.session_enrollments where session_id = p_session_id and player_id = p_player_id) then
    raise exception 'Already enrolled in this session';
  end if;

  insert into public.session_enrollments (session_id, player_id, amount_paid, payment_status, status, payment_method)
  values (p_session_id, p_player_id, 0, 'unpaid', 'active', 'N/A')
  returning id into v_enrollment_id;

  return v_enrollment_id;
end;
$$;

-- Undo the simulated payments: only rows the old function marked, and only
-- where the coach hasn't recorded a real payment since.
do $$
begin
  if to_regclass('public.coaching_payments') is null then
    update public.session_enrollments
    set amount_paid = 0, payment_status = 'unpaid', payment_method = 'N/A'
    where payment_method = 'SIMULATED';
  else
    update public.session_enrollments e
    set amount_paid = 0, payment_status = 'unpaid', payment_method = 'N/A'
    where e.payment_method = 'SIMULATED'
      and not exists (select 1 from public.coaching_payments p where p.enrollment_id = e.id);
  end if;
end;
$$;
