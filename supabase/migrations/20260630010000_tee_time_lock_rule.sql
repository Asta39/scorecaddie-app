-- 1. Create the function that enforces the tee time lock rule
CREATE OR REPLACE FUNCTION check_tee_time_lock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  comp_start_date date;
  rules_config jsonb;
  lock_hours int;
  lock_timestamp timestamptz;
  target_club_id text;
  is_admin boolean := false;
BEGIN
  -- We only care about changes to tee_time, tee_number, or group_number
  IF NEW.tee_time = OLD.tee_time AND NEW.tee_number = OLD.tee_number AND NEW.group_number = OLD.group_number THEN
    RETURN NEW;
  END IF;

  -- Get the competition's start_date, rules_config, and club_id
  SELECT start_date, c.rules_config, c.club_id INTO comp_start_date, rules_config, target_club_id
  FROM competitions c
  WHERE c.id = NEW.competition_id;

  -- Check if the current user is an admin of this club (bypass lock)
  SELECT true INTO is_admin 
  FROM public."Course" 
  WHERE id = target_club_id AND "createdById" = auth.uid();

  IF is_admin THEN
    RETURN NEW;
  END IF;

  -- Default to 24 hours if not set in rules_config
  lock_hours := COALESCE((rules_config->>'tee_time_lock_hours')::int, 24);

  -- Calculate the exact lock timestamp (start_date is assumed to be local midnight, we just treat it as UTC for comparison simplicity, 
  -- but generally subtracting the interval gives us the deadline).
  lock_timestamp := comp_start_date::timestamptz - make_interval(hours := lock_hours);

  -- If the current time is past the lock timestamp, reject the swap
  IF now() >= lock_timestamp THEN
    RAISE EXCEPTION 'Tee time modifications are closed for this competition. The deadline was % hours before the start date.', lock_hours;
  END IF;

  RETURN NEW;
END;
$$;

-- 2. Attach the trigger to the starting_sheets table
DROP TRIGGER IF EXISTS trg_enforce_tee_time_lock ON starting_sheets;
CREATE TRIGGER trg_enforce_tee_time_lock
  BEFORE UPDATE ON starting_sheets
  FOR EACH ROW
  EXECUTE FUNCTION check_tee_time_lock();

-- 3. Also prevent INSERTS or DELETES if the tee time lock is active
CREATE OR REPLACE FUNCTION check_tee_time_lock_insert_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  comp_start_date date;
  rules_config jsonb;
  lock_hours int;
  lock_timestamp timestamptz;
  target_comp_id uuid;
  target_club_id text;
  is_admin boolean := false;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_comp_id := OLD.competition_id;
  ELSE
    target_comp_id := NEW.competition_id;
  END IF;

  SELECT start_date, c.rules_config, c.club_id INTO comp_start_date, rules_config, target_club_id
  FROM competitions c
  WHERE c.id = target_comp_id;

  -- Check if the current user is an admin of this club (bypass lock)
  SELECT true INTO is_admin 
  FROM public."Course" 
  WHERE id = target_club_id AND "createdById" = auth.uid();

  IF is_admin THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    RETURN NEW;
  END IF;

  lock_hours := COALESCE((rules_config->>'tee_time_lock_hours')::int, 24);
  lock_timestamp := comp_start_date::timestamptz - make_interval(hours := lock_hours);

  IF now() >= lock_timestamp THEN
    RAISE EXCEPTION 'Starting sheet modifications are closed for this competition. The deadline was % hours before the start date.', lock_hours;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_tee_time_lock_insert_delete ON starting_sheets;
CREATE TRIGGER trg_enforce_tee_time_lock_insert_delete
  BEFORE INSERT OR DELETE ON starting_sheets
  FOR EACH ROW
  EXECUTE FUNCTION check_tee_time_lock_insert_delete();
