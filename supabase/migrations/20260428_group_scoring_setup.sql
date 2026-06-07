-- Enable Realtime for the new scores table
BEGIN;

-- 1. Create GroupRoundScore table
CREATE TABLE IF NOT EXISTS "GroupRoundScore" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "groupRoundId" UUID NOT NULL REFERENCES "GroupRound"("id") ON DELETE CASCADE,
    "participantId" UUID NOT NULL REFERENCES "GroupRoundParticipant"("id") ON DELETE CASCADE,
    "userId" UUID NOT NULL REFERENCES "User"("id"),
    "holeNumber" INTEGER NOT NULL,
    "strokes" INTEGER DEFAULT 0,
    "putts" INTEGER DEFAULT 0,
    "fairwayHit" TEXT, -- 'Left', 'Hit', 'Right', 'N/A'
    "penalties" INTEGER DEFAULT 0,
    "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE("participantId", "holeNumber")
);

-- 2. Update GroupRoundParticipant Table
ALTER TABLE "GroupRoundParticipant" 
ADD COLUMN IF NOT EXISTS "certifiedAt" TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS "disputed" BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS "disputeNote" TEXT;

-- 3. Update GroupRound Table
ALTER TABLE "GroupRound"
ADD COLUMN IF NOT EXISTS "scoringMode" TEXT DEFAULT 'SINGLE_DEVICE', -- 'SINGLE_DEVICE' or 'INDIVIDUAL_DEVICES'
ADD COLUMN IF NOT EXISTS "isLocked" BOOLEAN DEFAULT FALSE;

-- 4. Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE "GroupRoundScore";
ALTER PUBLICATION supabase_realtime ADD TABLE "GroupRoundParticipant";
ALTER PUBLICATION supabase_realtime ADD TABLE "GroupRound";

-- 5. RLS Policies for GroupRoundScore
ALTER TABLE "GroupRoundScore" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view group scores"
ON "GroupRoundScore" FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM "GroupRoundParticipant"
        WHERE "groupRoundId" = "GroupRoundScore"."groupRoundId"
        AND "userId" = auth.uid()
    )
);

CREATE POLICY "Scorekeeper/Captain can manage group scores"
ON "GroupRoundScore" FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM "GroupRound"
        WHERE "id" = "GroupRoundScore"."groupRoundId"
        AND "captainId" = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM "GroupRound"
        WHERE "id" = "GroupRoundScore"."groupRoundId"
        AND "captainId" = auth.uid()
    )
);

COMMIT;
