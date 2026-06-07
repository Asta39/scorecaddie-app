-- Standardize Booking table columns to snake_case for better compatibility
ALTER TABLE public."Booking"
  RENAME COLUMN "playerId" TO "player_id";
ALTER TABLE public."Booking"
  RENAME COLUMN "providerId" TO "provider_id";
ALTER TABLE public."Booking"
  RENAME COLUMN "bookingDate" TO "booking_date";
ALTER TABLE public."Booking"
  RENAME COLUMN "roundType" TO "round_type";
ALTER TABLE public."Booking"
  RENAME COLUMN "initiatedVia" TO "initiated_via";
ALTER TABLE public."Booking"
  RENAME COLUMN "startTime" TO "start_time";
ALTER TABLE public."Booking"
  RENAME COLUMN "endTime" TO "end_time";
ALTER TABLE public."Booking"
  RENAME COLUMN "durationMinutes" TO "duration_minutes";
ALTER TABLE public."Booking"
  RENAME COLUMN "amountPaid" TO "amount_paid";
ALTER TABLE public."Booking"
  RENAME COLUMN "paymentMethod" TO "payment_method";

-- Handle potential case-sensitivity issues if columns were created with quotes
-- or if they already existed in lowercase/snake_case.
-- The above RENAME commands will fail if the columns don't exist exactly as quoted.
-- So we use a safer approach:

DO $$
BEGIN
    -- Standardize playerId -> player_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'playerId') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "playerId" TO player_id;
    END IF;

    -- Standardize providerId -> provider_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'providerId') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "providerId" TO provider_id;
    END IF;

    -- Standardize bookingDate -> booking_date
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'bookingDate') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "bookingDate" TO booking_date;
    END IF;

    -- Standardize roundType -> round_type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'roundType') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "roundType" TO round_type;
    END IF;

    -- Standardize initiatedVia -> initiated_via
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'initiatedVia') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "initiatedVia" TO initiated_via;
    END IF;

    -- Standardize startTime -> start_time
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'startTime') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "startTime" TO start_time;
    END IF;

    -- Standardize endTime -> end_time
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'endTime') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "endTime" TO end_time;
    END IF;

    -- Standardize durationMinutes -> duration_minutes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'durationMinutes') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "durationMinutes" TO duration_minutes;
    END IF;

    -- Standardize amountPaid -> amount_paid
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'amountPaid') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "amountPaid" TO amount_paid;
    END IF;

    -- Standardize paymentMethod -> payment_method
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'paymentMethod') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "paymentMethod" TO payment_method;
    END IF;
END $$;

SELECT 'Booking table standardized to snake_case!' as status;
