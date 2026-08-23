-- Migration: Add user_id to user_flashcards and enable RLS with policy
-- Timestamp: 20260822200000

-- 1. Add the user_id column to user_flashcards (linking it to auth.users)
ALTER TABLE "de_mobile_app"."user_flashcards"
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. Enable Row Level Security (RLS)
ALTER TABLE "de_mobile_app"."user_flashcards" ENABLE ROW LEVEL SECURITY;

-- 3. Create a policy so users can only manage their own cards
-- (also allows unauthenticated saves where user_id IS NULL for backward compatibility)
DROP POLICY IF EXISTS "Allow users to manage their own custom flashcards" ON "de_mobile_app"."user_flashcards";
CREATE POLICY "Allow users to manage their own custom flashcards"
ON "de_mobile_app"."user_flashcards"
AS PERMISSIVE
FOR ALL
TO public
USING (auth.uid() = user_id OR user_id IS NULL)
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
