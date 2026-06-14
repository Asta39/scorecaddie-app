-- ROBUST MIGRATION: Standardize Booking table columns to snake_case
-- This script handles cases where columns might be double-quoted or case-insensitive.

DO $$
DECLARE
    rec record;
    old_col_lower text;
BEGIN
    FOR rec IN (
        VALUES 
            ('playerId', 'player_id'),
            ('providerId', 'provider_id'),
            ('bookingDate', 'booking_date'),
            ('roundType', 'round_type'),
            ('initiatedVia', 'initiated_via'),
            ('startTime', 'start_time'),
            ('endTime', 'end_time'),
            ('durationMinutes', 'duration_minutes'),
            ('amountPaid', 'amount_paid'),
            ('paymentMethod', 'payment_method')
    ) LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = rec.column1) THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = rec.column2) THEN
                EXECUTE format('ALTER TABLE public."Booking" RENAME COLUMN "%s" TO %s', rec.column1, rec.column2);
            END IF;
        END IF;

        old_col_lower := lower(rec.column1);
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = old_col_lower) THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Booking' AND column_name = rec.column2) THEN
                EXECUTE format('ALTER TABLE public."Booking" RENAME COLUMN %I TO %I', old_col_lower, rec.column2);
            END IF;
        END IF;
    END LOOP;
END $$;

SELECT 'Booking table standardized to snake_case successfully!' as status;
