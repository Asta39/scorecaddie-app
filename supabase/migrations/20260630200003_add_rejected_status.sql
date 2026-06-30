ALTER TABLE "public"."player_club_memberships" DROP CONSTRAINT IF EXISTS "player_club_memberships_status_check";
ALTER TABLE "public"."player_club_memberships" ADD CONSTRAINT "player_club_memberships_status_check" CHECK (status IN ('active', 'pending', 'suspended', 'resigned', 'rejected'));
