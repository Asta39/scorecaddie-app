-- Add gir column to HoleScore table
ALTER TABLE "HoleScore" ADD COLUMN IF NOT EXISTS "gir" BOOLEAN;

-- Update existing rows (optional, default to null or false)
-- UPDATE "HoleScore" SET "gir" = false WHERE "gir" IS NULL;

-- Enable permissions if needed (though already granted in previous migrations)
GRANT SELECT, INSERT, UPDATE ON "HoleScore" TO authenticated;

-- Success message
SELECT 'GIR column added to HoleScore table ⛳' AS status;
