-- Add gir column to GroupRoundScore
ALTER TABLE "GroupRoundScore" ADD COLUMN IF NOT EXISTS "gir" BOOLEAN;

-- Update existing rows to have gir as false if needed (optional)
-- UPDATE "GroupRoundScore" SET "gir" = false WHERE "gir" IS NULL;

-- Enable GIR in the Round table if missing (should be there from previous migrations)
ALTER TABLE "Round" ADD COLUMN IF NOT EXISTS "useForAnalytics" BOOLEAN DEFAULT TRUE;
