-- ============================================================
-- Migration: Add RLS policies to tee_time_reminder
-- Fixes: "permission denied for table tee_time_reminder" on sync
-- ============================================================

-- Enable RLS on the table
ALTER TABLE tee_time_reminder ENABLE ROW LEVEL SECURITY;

-- Users can only read their own reminders
CREATE POLICY "Users can view own tee_time_reminders"
  ON tee_time_reminder
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only insert reminders for themselves
CREATE POLICY "Users can insert own tee_time_reminders"
  ON tee_time_reminder
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own reminders
CREATE POLICY "Users can update own tee_time_reminders"
  ON tee_time_reminder
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own reminders
CREATE POLICY "Users can delete own tee_time_reminders"
  ON tee_time_reminder
  FOR DELETE
  USING (auth.uid() = user_id);
