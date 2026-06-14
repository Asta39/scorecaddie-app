-- Add missing Professional/Caddie columns to the User table
ALTER TABLE public."User"
  ADD COLUMN IF NOT EXISTS "bio" text,
  ADD COLUMN IF NOT EXISTS "personalityType" text,
  ADD COLUMN IF NOT EXISTS "coursesJson" text DEFAULT '[]';

-- Update permissions just in case
GRANT SELECT, INSERT, UPDATE, DELETE ON public."User" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."User" TO anon;

SELECT 'Caddie profile schema updates applied!' AS status;
