-- RPC for deleting user account correctly
-- This deletes the user from the public."User" table and the auth side.
-- Note: auth side deletion usually requires service_role or an edge function.
-- For a basic implementation, we trigger a delete on the public user table, 
-- and the auth side should be handled by the user themselves or an edge function.
-- Here we'll create an RPC that helps cleanup.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Delete from public."User" table
  -- We assume auth.uid() is the user calling this.
  DELETE FROM public."User" WHERE id = auth.uid()::text OR "firebaseUid" = auth.uid()::text;
  
  -- 2. Delete other related data if needed (cascade usually handles this)
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
