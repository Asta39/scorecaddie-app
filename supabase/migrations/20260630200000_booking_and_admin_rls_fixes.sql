-- Migration for RLS policies
-- 1. Casual Tee Time Bookings
ALTER TABLE "public"."casual_tee_time_bookings" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can insert bookings" ON "public"."casual_tee_time_bookings" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Users can view their own bookings" ON "public"."casual_tee_time_bookings" FOR SELECT TO authenticated USING (auth.uid()::text = player_id::text);
CREATE POLICY "Users can update their own bookings" ON "public"."casual_tee_time_bookings" FOR UPDATE TO authenticated USING (auth.uid()::text = player_id::text);
CREATE POLICY "Users can delete their own bookings" ON "public"."casual_tee_time_bookings" FOR DELETE TO authenticated USING (auth.uid()::text = player_id::text);

-- 2. Casual Tee Time Players
ALTER TABLE "public"."casual_tee_time_players" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can insert players" ON "public"."casual_tee_time_players" FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Users can view players in their bookings" ON "public"."casual_tee_time_players" FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM casual_tee_time_bookings b
    WHERE b.id::text = casual_tee_time_players.booking_id::text AND b.player_id::text = auth.uid()::text
  )
  OR user_id::text = auth.uid()::text
);
CREATE POLICY "Users can update players in their bookings" ON "public"."casual_tee_time_players" FOR UPDATE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM casual_tee_time_bookings b
    WHERE b.id::text = casual_tee_time_players.booking_id::text AND b.player_id::text = auth.uid()::text
  )
);
CREATE POLICY "Users can delete players in their bookings" ON "public"."casual_tee_time_players" FOR DELETE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM casual_tee_time_bookings b
    WHERE b.id::text = casual_tee_time_players.booking_id::text AND b.player_id::text = auth.uid()::text
  )
);

-- 3. Player Club Memberships UPDATE by Club Admin
CREATE POLICY "Club admins can update memberships" ON "public"."player_club_memberships" FOR UPDATE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM club_admins ca
    WHERE ca.club_id::text = player_club_memberships.club_id::text AND ca.user_id::text = auth.uid()::text
  )
);
