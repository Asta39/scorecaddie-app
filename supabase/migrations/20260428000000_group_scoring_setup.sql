-- Enable Realtime for the new scores table
BEGIN;

-- 1. Create GroupRoundScore table
CREATE TABLE IF NOT EXISTS "GroupRoundScore" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "groupRoundId" UUID NOT NULL REFERENCES "GroupRound"("id") ON DELETE CASCADE,
    "participantId" UUID NOT NULL REFERENCES "GroupRoundParticipant"("id") ON DELETE CASCADE,
    "userId" TEXT NOT NULL REFERENCES "User"("id"),
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
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'GroupRoundScore') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE "GroupRoundScore";
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'GroupRoundParticipant') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE "GroupRoundParticipant";
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'GroupRound') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE "GroupRound";
  END IF;
END $$;


-- 5. RLS Policies for GroupRoundScore
ALTER TABLE "GroupRoundScore" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view group scores"
ON "GroupRoundScore" FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM "GroupRoundParticipant"
        WHERE "groupRoundId" = "GroupRoundScore"."groupRoundId"
        AND "userId" = auth.uid()::text
    )
);

CREATE POLICY "Scorekeeper/Captain can manage group scores"
ON "GroupRoundScore" FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM "GroupRound"
        WHERE "id" = "GroupRoundScore"."groupRoundId"
        AND "captainId" = auth.uid()::text
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM "GroupRound"
        WHERE "id" = "GroupRoundScore"."groupRoundId"
        AND "captainId" = auth.uid()::text
    )
);

COMMIT;
