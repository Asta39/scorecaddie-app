-- Drop the NOT NULL constraint on entry_id to support vacant slots
ALTER TABLE starting_sheets ALTER COLUMN entry_id DROP NOT NULL;
