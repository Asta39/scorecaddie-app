-- Migration: Phase 4 Automation (Payments, Handicap History, Notifications)
-- Adds STK push payment flow fields, unmatched payments, and WHS-compliant handicap revisions.

-- 1. Extend `competitions` for M-Pesa payments
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS entry_fee_kes numeric(10,2);
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS mpesa_payment_type text CHECK (mpesa_payment_type IN ('paybill', 'till', 'send_money'));
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS mpesa_paybill_number text;
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS mpesa_account_number text;
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS mpesa_till_number text;
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS mpesa_recipient_name text;
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS mpesa_instructions text;
ALTER TABLE public.competitions ADD COLUMN IF NOT EXISTS payment_deadline timestamptz;

-- 2. Extend `competition_entries` for payment tracking
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS mpesa_reference_name text;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS mpesa_phone_number text;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS payment_status text NOT NULL DEFAULT 'pending'
  CHECK (payment_status IN ('not_required', 'pending', 'approved', 'underpaid', 'rejected', 'stk_failed', 'stk_dismissed'));
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS approved_by text REFERENCES public."User"("id");
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS payment_notes text;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS paystack_reference text UNIQUE;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS stk_initiated_at timestamptz;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS mpesa_transaction_id text;
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS mpesa_confirmed_amount numeric(10,2);
ALTER TABLE public.competition_entries ADD COLUMN IF NOT EXISTS mpesa_confirmed_at timestamptz;

-- 3. Unmatched Payments Reconciliation Table
CREATE TABLE IF NOT EXISTS public.unmatched_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  paystack_reference text,
  amount_cents int,
  metadata jsonb,
  resolved boolean DEFAULT false,
  received_at timestamptz DEFAULT now()
);
ALTER TABLE public.unmatched_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins view unmatched payments" ON public.unmatched_payments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public."User" WHERE id = auth.uid()::text AND role = 'super_admin')
  );

-- 4. Handicap Revisions Table (WHS Compliant)
CREATE TABLE IF NOT EXISTS public.handicap_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id text NOT NULL REFERENCES public."User"("id") ON DELETE CASCADE,
  
  -- The round that triggered this revision (null for manual/admin adjustments)
  score_id uuid REFERENCES public."Round"("id"),
  competition_id uuid REFERENCES competitions(id),

  -- The actual index values
  previous_handicap_index numeric(4,1) NOT NULL,
  new_handicap_index numeric(4,1) NOT NULL,

  -- The 20 differentials used in this calculation
  differentials_used numeric(4,1)[] NOT NULL,
  differentials_count int NOT NULL,  -- how many were used (8 of 20, 20 of 20, etc)

  -- WHS calculation details
  average_of_best numeric(5,2) NOT NULL,
  adjustment_factor numeric(3,2) NOT NULL, -- always 0.96 in WHS
  soft_cap_applied boolean DEFAULT false,
  hard_cap_applied boolean DEFAULT false,
  exceptional_reduction boolean DEFAULT false,

  -- What triggered the change
  revision_type text NOT NULL CHECK (revision_type IN (
    'score_posted',       
    'competition_result', 
    'manual_admin',       
    'initial',            
    'hdid_import',        
    'annual_review',      
    'committee_review'    
  )),

  -- For manual/committee adjustments — why
  revision_notes text,
  revised_by text REFERENCES public."User"("id"), -- null for automatic

  -- When
  effective_date date NOT NULL DEFAULT current_date,
  created_at timestamptz DEFAULT now()
);

-- Indexes for handicap_revisions
CREATE INDEX IF NOT EXISTS idx_handicap_revisions_player_desc ON public.handicap_revisions(player_id, created_at desc);
CREATE INDEX IF NOT EXISTS idx_handicap_revisions_player_effective ON public.handicap_revisions(player_id, effective_date desc);
CREATE INDEX IF NOT EXISTS idx_handicap_revisions_comp ON public.handicap_revisions(competition_id) WHERE competition_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_handicap_revisions_score ON public.handicap_revisions(score_id) WHERE score_id IS NOT NULL;

-- RLS for handicap_revisions
ALTER TABLE public.handicap_revisions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "player sees own handicap history"
  ON public.handicap_revisions FOR SELECT
  USING (player_id = auth.uid()::text);

CREATE POLICY "club admin sees member history"
  ON public.handicap_revisions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM player_club_memberships player_m
      JOIN player_club_memberships admin_m ON player_m.club_id = admin_m.club_id
      JOIN public."User" admin ON admin.id = admin_m.player_id
      WHERE player_m.player_id = handicap_revisions.player_id
      AND admin.id = auth.uid()::text
      AND admin.role = 'club_admin'
      AND player_m.status = 'active'
      AND admin_m.status = 'active'
    )
  );

CREATE POLICY "system inserts revisions"
  ON public.handicap_revisions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public."User"
      WHERE id = auth.uid()::text
      AND role IN ('super_admin', 'club_admin')
    )
    -- Also allowing service_role (edge functions bypass RLS natively if configured)
  );

-- Ensure User has handicap_updated_at (if not already present)
ALTER TABLE public."User" ADD COLUMN IF NOT EXISTS handicap_updated_at timestamptz;

-- 5. Atomic Handicap Update RPC
CREATE OR REPLACE FUNCTION apply_handicap_revision(
  p_player_id text,
  p_score_id uuid,
  p_competition_id uuid,
  p_previous_index numeric,
  p_new_index numeric,
  p_differentials numeric[],
  p_differentials_count int,
  p_average_of_best numeric,
  p_adjustment_factor numeric,
  p_soft_cap_applied boolean,
  p_hard_cap_applied boolean,
  p_exceptional_reduction boolean,
  p_revision_type text,
  p_revision_notes text DEFAULT null,
  p_revised_by text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Update the player's current index
  UPDATE public."User"
  SET 
    "handicapIndex" = p_new_index,
    handicap_updated_at = now()
  WHERE id = p_player_id;

  -- 2. Write the revision record
  INSERT INTO handicap_revisions (
    player_id,
    score_id,
    competition_id,
    previous_handicap_index,
    new_handicap_index,
    differentials_used,
    differentials_count,
    average_of_best,
    adjustment_factor,
    soft_cap_applied,
    hard_cap_applied,
    exceptional_reduction,
    revision_type,
    revision_notes,
    revised_by,
    effective_date
  ) VALUES (
    p_player_id,
    p_score_id,
    p_competition_id,
    p_previous_index,
    p_new_index,
    p_differentials,
    p_differentials_count,
    p_average_of_best,
    p_adjustment_factor,
    p_soft_cap_applied,
    p_hard_cap_applied,
    p_exceptional_reduction,
    p_revision_type,
    p_revision_notes,
    p_revised_by,
    current_date
  );
END;
$$;
