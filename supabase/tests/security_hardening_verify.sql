-- Verifies 20260921100000_security_hardening.sql against the live database.
--
-- Run in the Supabase SQL editor (as postgres) AFTER applying the migration.
-- Each check impersonates a real anon or signed-in user and attempts an
-- action. Every write happens inside a sub-block that always rolls back, so
-- this changes nothing. Expect every row to read PASS.

create or replace function pg_temp.security_checks()
returns table(check_name text, result text)
language plpgsql
as $$
declare
  me     text;  -- an ordinary player
  other  text;  -- a different user
  course text;  -- an official (unowned) course
  n      int;
  r      text;
begin
  select u.id into me from public."User" u where lower(u.role::text) = 'player' limit 1;
  select u.id into other from public."User" u where u.id <> me limit 1;
  select c.id into course from public."Course" c where c."createdBy" is null limit 1;

  -- Impersonation helpers are inlined per check: set_config(..., true) is
  -- local to the sub-transaction, so it resets when the block rolls back.

  -- 1. Anonymous callers cannot read user rows (emails, phones).
  begin
    perform set_config('role', 'anon', true);
    select count(*) into n from public."User";
    r := case when n = 0 then 'PASS' else 'FAIL: anon read ' || n || ' users' end;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'anon cannot read User'; result := r; return next;

  -- 2. Anonymous callers cannot modify user rows.
  begin
    perform set_config('role', 'anon', true);
    update public."User" set name = 'x' where id = other;
    get diagnostics n = row_count;
    r := case when n = 0 then 'PASS' else 'FAIL: anon updated a user' end;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'anon cannot update User'; result := r; return next;

  -- 3. A player cannot promote themselves to super_admin.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    update public."User" set role = 'super_admin' where id = me;
    select case when lower(u.role::text) = 'super_admin' then 'FAIL: self-promotion worked' else 'PASS' end
      into r from public."User" u where u.id = me;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'player cannot self-promote to super_admin'; result := r; return next;

  -- 4. A player still CAN edit their own profile (normal sync must work).
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    update public."User" set "updatedAt" = now() where id = me;
    get diagnostics n = row_count;
    r := case when n = 1 then 'PASS' else 'FAIL: own profile update blocked' end;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'FAIL (' || sqlerrm || ')'; end if;
  end;
  check_name := 'player can update own profile'; result := r; return next;

  -- 5. A player cannot edit someone else's profile.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    update public."User" set name = 'hacked' where id = other;
    get diagnostics n = row_count;
    r := case when n = 0 then 'PASS' else 'FAIL: edited another user' end;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'player cannot update another user'; result := r; return next;

  -- 6. A player cannot edit someone else's rounds.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    update public."Round" set "totalScore" = 1 where "userId" <> me;
    get diagnostics n = row_count;
    r := case when n = 0 then 'PASS' else 'FAIL: edited ' || n || ' foreign rounds' end;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'player cannot update others'' rounds'; result := r; return next;

  -- 7. A player cannot edit an official course.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    update public."Course" set name = 'hacked' where id = course;
    get diagnostics n = row_count;
    r := case when n = 0 then 'PASS' else 'FAIL: edited official course' end;
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'player cannot update official course'; result := r; return next;

  -- 8. Nobody outside the server can rewrite a handicap.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    perform public.apply_handicap_revision(other, null, null, 0, -5, '{}', 0, 0, 0, false, false, false, 'manual');
    r := 'FAIL: handicap rewrite allowed';
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'apply_handicap_revision blocked for clients'; result := r; return next;

  -- 9. A player cannot look up another person's club memberships by email.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated', 'email', 'me@example.com')::text, true);
    perform * from public.match_user_to_clubs('someone-else@example.com');
    r := 'FAIL: email lookup allowed';
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'match_user_to_clubs limited to own email'; result := r; return next;

  -- 10. A player cannot mark someone's enrollment as paid.
  begin
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims', json_build_object('sub', me, 'role', 'authenticated')::text, true);
    perform public.record_payment((select e.id from public.session_enrollments e limit 1), 999999, 'CASH');
    r := 'FAIL: payment recorded by non-coach';
    raise exception 'rollback';
  exception when others then
    if sqlerrm <> 'rollback' then r := 'PASS (' || sqlerrm || ')'; end if;
  end;
  check_name := 'record_payment limited to the session coach'; result := r; return next;
end;
$$;

select * from pg_temp.security_checks();
