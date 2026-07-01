-- 20260701000000_autonomous_club_matching.sql

-- Wipe existing memberships as requested
DELETE FROM public.player_club_memberships;

-- Create the new club_member_roster table
CREATE TABLE IF NOT EXISTS public.club_member_roster (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    membership_number TEXT,
    handicap_index DECIMAL(4,1),
    role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player', 'coach')),
    status TEXT NOT NULL DEFAULT 'active',
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(club_id, email)
);

-- Index for fast lookup by email across all clubs
CREATE INDEX IF NOT EXISTS idx_club_member_roster_email ON public.club_member_roster(email);

-- Enable RLS
ALTER TABLE public.club_member_roster ENABLE ROW LEVEL SECURITY;

-- Admins can manage their club's roster
CREATE POLICY "Admins can manage their club roster" ON public.club_member_roster
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.club_admins ca
            WHERE ca.club_id = club_member_roster.club_id
            AND ca.user_id = auth.uid()
        )
    );

-- Creating the secure RPC to match user to clubs
CREATE OR REPLACE FUNCTION public.match_user_to_clubs(user_email TEXT)
RETURNS TABLE (
    club_id UUID,
    club_name TEXT,
    role TEXT,
    handicap_index DECIMAL(4,1)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cmr.club_id,
        c.name AS club_name,
        cmr.role,
        cmr.handicap_index
    FROM 
        public.club_member_roster cmr
    JOIN 
        public.clubs c ON c.id = cmr.club_id
    WHERE 
        cmr.email = user_email
        AND cmr.status = 'active';
END;
$$;
