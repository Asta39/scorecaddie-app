-- Repair User."profileComplete" for accounts that had already onboarded.
--
-- ApiService.syncProfile upserted every field it was given, and the provider
-- sync path never passed profileComplete, so each coach/caddie sync wrote
-- "profileComplete" = null. On the next fresh login the app saw an
-- incomplete profile and sent existing users back to role selection.
--
-- The client now strips null fields before upserting. This restores the flag
-- for accounts with evidence of finished onboarding: a coach/caddie role
-- (only set by provider onboarding) or at least one recorded round.
-- Idempotent: only touches rows not already marked complete.

update public."User" u
set "profileComplete" = true
where coalesce(u."profileComplete", false) = false
  and (
    lower(u.role::text) in ('coach', 'caddie')
    or exists (select 1 from public."Round" r where r."userId" = u.id)
  );
