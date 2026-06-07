-- Tee Time Reminders Table
-- Run this in Supabase SQL Editor

-- Create the table
CREATE TABLE IF NOT EXISTS tee_time_reminder (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  local_id INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  reminder_date TIMESTAMPTZ NOT NULL,
  notify_before_minutes INTEGER DEFAULT 30,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, local_id)
);

-- Enable RLS
ALTER TABLE tee_time_reminder ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own reminders
CREATE POLICY "Users can view own reminders" ON tee_time_reminder
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own reminders" ON tee_time_reminder
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own reminders" ON tee_time_reminder
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own reminders" ON tee_time_reminder
  FOR DELETE USING (auth.uid()::text = user_id);

-- Add index for efficient queries
CREATE INDEX idx_tee_time_reminder_user_active 
ON tee_time_reminder (user_id, is_active) 
WHERE is_active = true;

CREATE INDEX idx_tee_time_reminder_date 
ON tee_time_reminder (reminder_date) 
WHERE is_active = true;