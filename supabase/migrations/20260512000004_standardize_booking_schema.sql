-- Standardize Booking table columns to snake_case for better compatibility
-- We use a safe approach:

DO $$
BEGIN
    -- Standardize playerId -> player_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'playerId') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'player_id') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "playerId" TO player_id';
    END IF;

    -- Standardize providerId -> provider_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'providerId') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'provider_id') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "providerId" TO provider_id';
    END IF;

    -- Standardize bookingDate -> booking_date
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'bookingDate') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'booking_date') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "bookingDate" TO booking_date';
    END IF;

    -- Standardize roundType -> round_type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'roundType') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'round_type') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "roundType" TO round_type';
    END IF;

    -- Standardize initiatedVia -> initiated_via
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'initiatedVia') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'initiated_via') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "initiatedVia" TO initiated_via';
    END IF;

    -- Standardize startTime -> start_time
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'startTime') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'start_time') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "startTime" TO start_time';
    END IF;

    -- Standardize endTime -> end_time
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'endTime') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'end_time') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "endTime" TO end_time';
    END IF;

    -- Standardize durationMinutes -> duration_minutes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'durationMinutes') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'duration_minutes') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "durationMinutes" TO duration_minutes';
    END IF;

    -- Standardize amountPaid -> amount_paid
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'amountPaid') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'amount_paid') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "amountPaid" TO amount_paid';
    END IF;

    -- Standardize paymentMethod -> payment_method
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'paymentMethod') AND
       NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'payment_method') THEN
        EXECUTE 'ALTER TABLE public."Booking" RENAME COLUMN "paymentMethod" TO payment_method';
    END IF;
END $$;

SELECT 'Booking table standardized to snake_case!' as status;
