-- Add useForAnalytics column to GroupRound
ALTER TABLE "GroupRound" ADD COLUMN IF NOT EXISTS "useForAnalytics" BOOLEAN DEFAULT TRUE;

-- Success message
SELECT 'useForAnalytics column added to GroupRound table 📊' AS status;
