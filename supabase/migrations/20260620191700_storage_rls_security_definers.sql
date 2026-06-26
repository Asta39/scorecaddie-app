-- =============================================================================
-- STORAGE RLS SECURITY DEFINER FUNCTIONS & POLICIES
-- Resolves RLS violations when uploading assets to the club-assets bucket
-- by querying club_admins and profiles tables via SECURITY DEFINER functions.
-- =============================================================================

-- 1. Helper function for club admin check
CREATE OR REPLACE FUNCTION public.is_club_admin(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.club_admins
    WHERE user_id = p_user_id
      AND is_active = true
  ) OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = p_user_id
      AND role = 'super_admin'
  );
$$;

-- 2. Helper function for retrieving user's club_id
CREATE OR REPLACE FUNCTION public.get_user_club_id(p_user_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT club_id::text FROM public.club_admins
  WHERE user_id = p_user_id
  LIMIT 1;
$$;

-- 3. Drop existing policies
DROP POLICY IF EXISTS "club_admin_upload_assets" ON storage.objects;
DROP POLICY IF EXISTS "club_admin_update_assets" ON storage.objects;
DROP POLICY IF EXISTS "club_admin_delete_assets" ON storage.objects;
DROP POLICY IF EXISTS "club_admin_upload_photos" ON storage.objects;

-- 4. Recreate policies with the helper functions
CREATE POLICY "club_admin_upload_assets" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'club-assets'
    AND public.is_club_admin(auth.uid())
  );

CREATE POLICY "club_admin_update_assets" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'club-assets'
    AND public.is_club_admin(auth.uid())
  );

CREATE POLICY "club_admin_delete_assets" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'club-assets'
    AND public.is_club_admin(auth.uid())
  );

CREATE POLICY "club_admin_upload_photos" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'caddie-photos'
    AND (storage.foldername(name))[1] = public.get_user_club_id(auth.uid())
  );
