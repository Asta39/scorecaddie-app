-- Comprehensive Professional & Caddie fields standardization for User table
ALTER TABLE public."User"
  ADD COLUMN IF NOT EXISTS "phone" text,
  ADD COLUMN IF NOT EXISTS "whatsapp" text,
  ADD COLUMN IF NOT EXISTS "bio" text,
  ADD COLUMN IF NOT EXISTS "experience" integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "price" numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "personalityType" text,
  ADD COLUMN IF NOT EXISTS "coursesJson" text DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS "certificationUrl" text,
  ADD COLUMN IF NOT EXISTS "coachingLocation" text,
  ADD COLUMN IF NOT EXISTS "profileComplete" boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS "providerStatus" text DEFAULT 'OFFLINE',
  ADD COLUMN IF NOT EXISTS "handicapIndex" double precision DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "pfpVerified" boolean DEFAULT false;

-- Add snake_case aliases for common fields to prevent PostgREST errors
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'personality_type') THEN
        ALTER TABLE public."User" ADD COLUMN "personality_type" text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'courses_json') THEN
        ALTER TABLE public."User" ADD COLUMN "courses_json" text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'provider_status') THEN
        ALTER TABLE public."User" ADD COLUMN "provider_status" text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'handicap_index') THEN
        ALTER TABLE public."User" ADD COLUMN "handicap_index" double precision;
    END IF;
END $$;

-- Update permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public."User" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."User" TO anon;

SELECT 'User table professional fields updated!' as status;
