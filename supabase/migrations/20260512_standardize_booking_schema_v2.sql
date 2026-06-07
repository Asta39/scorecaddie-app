-- ROBUST MIGRATION: Standardize Booking table columns to snake_case
-- This script handles cases where columns might be double-quoted or case-insensitive.

DO $$
BEGIN
    -- 1. Standardize playerId -> player_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'playerId') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "playerId" TO player_id;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'playerid') THEN
        ALTER TABLE public."Booking" RENAME COLUMN playerid TO player_id;
    END IF;

    -- 2. Standardize providerId -> provider_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'providerId') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "providerId" TO provider_id;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'providerid') THEN
        ALTER TABLE public."Booking" RENAME COLUMN providerid TO provider_id;
    END IF;

    -- 3. Standardize bookingDate -> booking_date
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'bookingDate') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "bookingDate" TO booking_date;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'bookingdate') THEN
        ALTER TABLE public."Booking" RENAME COLUMN bookingdate TO booking_date;
    END IF;

    -- 4. Standardize roundType -> round_type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'roundType') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "roundType" TO round_type;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'roundtype') THEN
        ALTER TABLE public."Booking" RENAME COLUMN roundtype TO round_type;
    END IF;

    -- 5. Standardize initiatedVia -> initiated_via
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'initiatedVia') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "initiatedVia" TO initiated_via;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'initiatedvia') THEN
        ALTER TABLE public."Booking" RENAME COLUMN initiatedvia TO initiated_via;
    END IF;

    -- 6. Standardize startTime -> start_time
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'startTime') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "startTime" TO start_time;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'starttime') THEN
        ALTER TABLE public."Booking" RENAME COLUMN starttime TO start_time;
    END IF;

    -- 7. Standardize endTime -> end_time
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'endTime') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "endTime" TO end_time;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'endtime') THEN
        ALTER TABLE public."Booking" RENAME COLUMN endtime TO end_time;
    END IF;

    -- 8. Standardize durationMinutes -> duration_minutes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'durationMinutes') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "durationMinutes" TO duration_minutes;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'durationminutes') THEN
        ALTER TABLE public."Booking" RENAME COLUMN durationminutes TO duration_minutes;
    END IF;

    -- 9. Standardize amountPaid -> amount_paid
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'amountPaid') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "amountPaid" TO amount_paid;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'amountpaid') THEN
        ALTER TABLE public."Booking" RENAME COLUMN amountpaid TO amount_paid;
    END IF;

    -- 10. Standardize paymentMethod -> payment_method
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'paymentMethod') THEN
        ALTER TABLE public."Booking" RENAME COLUMN "paymentMethod" TO payment_method;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = 'paymentmethod') THEN
        ALTER TABLE public."Booking" RENAME COLUMN paymentmethod TO payment_method;
    END IF;
END $$;

SELECT 'Booking table standardized to snake_case successfully!' as status;
