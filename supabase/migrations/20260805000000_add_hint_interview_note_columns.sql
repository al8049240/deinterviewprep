-- Migration: Add hint and interview_note columns to quiz-question table
-- Migrate existing interview_tips data into hint
-- interview_note starts as NULL for all existing rows

SET search_path TO de_mobile_app;

-- Step 1: Add new columns
ALTER TABLE "quiz-question"
  ADD COLUMN IF NOT EXISTS hint TEXT NULL,
  ADD COLUMN IF NOT EXISTS interview_note TEXT NULL;

-- Step 2: Migrate existing interview_tips data into hint
UPDATE "quiz-question"
SET hint = interview_tips
WHERE interview_tips IS NOT NULL AND interview_tips <> '';

-- Step 3: interview_note remains NULL for all existing rows (no action needed)

-- NOTE: interview_tips column is preserved until the application is fully updated.
-- After confirming the app uses hint/interview_note, run:
-- ALTER TABLE "quiz-question" DROP COLUMN interview_tips;
