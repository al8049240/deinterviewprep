-- Add tags column to user_flashcards table (was missing from initial schema)
ALTER TABLE de_mobile_app.user_flashcards
ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}'::text[];
