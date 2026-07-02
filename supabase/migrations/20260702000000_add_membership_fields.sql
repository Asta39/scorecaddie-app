-- Add membership_number and renewal_date to player_club_memberships
-- membership_number is backfilled from club_member_roster where available
-- renewal_date is future-proofed for subscription payment tracking

ALTER TABLE player_club_memberships
  ADD COLUMN IF NOT EXISTS membership_number text,
  ADD COLUMN IF NOT EXISTS renewal_date date;

-- Backfill membership_number from club_member_roster where email matches
UPDATE player_club_memberships pcm
SET membership_number = cmr.membership_number
FROM club_member_roster cmr
JOIN "User" u ON lower(u.email) = lower(cmr.email)
WHERE pcm.player_id = u.id
  AND pcm.club_id = cmr.club_id
  AND cmr.membership_number IS NOT NULL
  AND pcm.membership_number IS NULL;
