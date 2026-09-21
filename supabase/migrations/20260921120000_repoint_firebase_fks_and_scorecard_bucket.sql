-- ============================================================================
-- 1. Repoint legacy firebaseUid foreign keys at User.id
--
-- drills.creator_id, drill_assignments.coach_id/player_id and
-- session_enrollments.player_id referenced User."firebaseUid", a leftover from
-- the Firebase era that is null for every user. The app writes Supabase auth
-- ids (User.id), so every drill template, drill assignment and coaching
-- enrollment insert failed the foreign key. All four tables were empty when
-- this ran, so no data is affected. Constraint names are kept, so PostgREST
-- embeds such as User!session_enrollments_player_id_fkey keep working.
--
-- 2. Create the scorecard-images bucket
--
-- SupabaseStorageService.uploadScorecardImage writes to
-- scorecard-images/scorecards/<uid>/<roundId>.jpg, but the bucket never
-- existed, so every upload failed.
-- ============================================================================

do $$
declare
  fk record;
begin
  for fk in
    select * from (values
      ('drills',              'drills_creator_id_fkey',              'creator_id'),
      ('drill_assignments',   'drill_assignments_coach_id_fkey',     'coach_id'),
      ('drill_assignments',   'drill_assignments_player_id_fkey',    'player_id'),
      ('session_enrollments', 'session_enrollments_player_id_fkey',  'player_id')
    ) as t(tbl, conname, col)
  loop
    execute format('alter table public.%I drop constraint if exists %I', fk.tbl, fk.conname);
    execute format(
      'alter table public.%I add constraint %I foreign key (%I) references public."User"(id) on delete cascade',
      fk.tbl, fk.conname, fk.col);
  end loop;
end;
$$;


insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'scorecard-images', 'scorecard-images', true,
  10 * 1024 * 1024,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update
  set file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "scorecard_images_own_insert" on storage.objects;
create policy "scorecard_images_own_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'scorecard-images'
    and (storage.foldername(name))[1] = 'scorecards'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "scorecard_images_own_update" on storage.objects;
create policy "scorecard_images_own_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'scorecard-images'
    and (storage.foldername(name))[1] = 'scorecards'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "scorecard_images_own_delete" on storage.objects;
create policy "scorecard_images_own_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'scorecard-images'
    and (storage.foldername(name))[1] = 'scorecards'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
