-- ============================================================
-- Migration: Add friend_code to public."User" table
-- Date: 2026-05-21
-- Purpose: Replace raw Auth UID exposure with secure, human-
--          readable friend codes for player discovery and QR codes.
-- ============================================================

ALTER TABLE public."User"
  ADD COLUMN IF NOT EXISTS "friendCode" TEXT UNIQUE;

-- Index for fast lookup during friend-add flow
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_friend_code
  ON public."User" ("friendCode")
  WHERE "friendCode" IS NOT NULL;
