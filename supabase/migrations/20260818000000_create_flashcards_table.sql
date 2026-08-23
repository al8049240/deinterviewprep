-- Migration: Create flashcards table in de_mobile_app schema
-- Timestamp: 20260818000000

CREATE TABLE IF NOT EXISTS "de_mobile_app"."flashcards" (
    flashcard_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id BIGINT NOT NULL,
    subtopic_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT flashcards_topic_id_fkey
        FOREIGN KEY (topic_id)
        REFERENCES "de_mobile_app"."topics-legacy"(id),
    CONSTRAINT flashcards_subtopic_id_fkey
        FOREIGN KEY (subtopic_id)
        REFERENCES "de_mobile_app"."subtopics-legacy"(id)
);

-- Index for fast lookups by topic and subtopic
CREATE INDEX IF NOT EXISTS idx_flashcards_topic_id
    ON "de_mobile_app"."flashcards"(topic_id);

CREATE INDEX IF NOT EXISTS idx_flashcards_subtopic_id
    ON "de_mobile_app"."flashcards"(subtopic_id);

-- Enable Row Level Security
ALTER TABLE "de_mobile_app"."flashcards" ENABLE ROW LEVEL SECURITY;

-- Public read access (flashcards are read-only content)
DROP POLICY IF EXISTS "flashcards_public_read" ON "de_mobile_app"."flashcards";
CREATE POLICY "flashcards_public_read"
    ON "de_mobile_app"."flashcards"
    FOR SELECT
    TO public
    USING (true);
