-- Migration: Create quiz_attempts and quiz_user_answers tables
-- Schema: de_mobile_app
-- NOTE: de_mobile_app."quiz-answer" is NOT modified by this migration.

-- ============================================================
-- 1. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS de_mobile_app.quiz_attempts (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    topic_id         TEXT        NOT NULL,
    topic_name       TEXT        NOT NULL,
    total_questions  INTEGER     NOT NULL CHECK (total_questions >= 0),
    correct_answers  INTEGER     NOT NULL CHECK (correct_answers >= 0),
    duration_seconds INTEGER     NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS de_mobile_app.quiz_user_answers (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id      UUID        NOT NULL REFERENCES de_mobile_app.quiz_attempts(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    question_id     TEXT        NOT NULL,
    category        TEXT,
    difficulty      TEXT,
    selected_answer INTEGER,
    correct_answer  INTEGER     NOT NULL,
    is_correct      BOOLEAN     NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 2. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS quiz_attempts_user_id_idx
    ON de_mobile_app.quiz_attempts (user_id);

CREATE INDEX IF NOT EXISTS quiz_attempts_created_at_idx
    ON de_mobile_app.quiz_attempts (created_at);

CREATE INDEX IF NOT EXISTS quiz_attempts_topic_id_idx
    ON de_mobile_app.quiz_attempts (topic_id);

CREATE INDEX IF NOT EXISTS quiz_user_answers_user_id_idx
    ON de_mobile_app.quiz_user_answers (user_id);

CREATE INDEX IF NOT EXISTS quiz_user_answers_attempt_id_idx
    ON de_mobile_app.quiz_user_answers (attempt_id);

CREATE INDEX IF NOT EXISTS quiz_user_answers_question_id_idx
    ON de_mobile_app.quiz_user_answers (question_id);

CREATE INDEX IF NOT EXISTS quiz_user_answers_created_at_idx
    ON de_mobile_app.quiz_user_answers (created_at);

-- ============================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE de_mobile_app.quiz_attempts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.quiz_user_answers  ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. RLS POLICIES — quiz_attempts
-- ============================================================

DROP POLICY IF EXISTS "quiz_attempts_select_own"  ON de_mobile_app.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts_insert_own"  ON de_mobile_app.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts_update_own"  ON de_mobile_app.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts_delete_own"  ON de_mobile_app.quiz_attempts;

CREATE POLICY "quiz_attempts_select_own"
    ON de_mobile_app.quiz_attempts
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "quiz_attempts_insert_own"
    ON de_mobile_app.quiz_attempts
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "quiz_attempts_update_own"
    ON de_mobile_app.quiz_attempts
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "quiz_attempts_delete_own"
    ON de_mobile_app.quiz_attempts
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================
-- 5. RLS POLICIES — quiz_user_answers
-- ============================================================

DROP POLICY IF EXISTS "quiz_user_answers_select_own"  ON de_mobile_app.quiz_user_answers;
DROP POLICY IF EXISTS "quiz_user_answers_insert_own"  ON de_mobile_app.quiz_user_answers;
DROP POLICY IF EXISTS "quiz_user_answers_update_own"  ON de_mobile_app.quiz_user_answers;
DROP POLICY IF EXISTS "quiz_user_answers_delete_own"  ON de_mobile_app.quiz_user_answers;

CREATE POLICY "quiz_user_answers_select_own"
    ON de_mobile_app.quiz_user_answers
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "quiz_user_answers_insert_own"
    ON de_mobile_app.quiz_user_answers
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "quiz_user_answers_update_own"
    ON de_mobile_app.quiz_user_answers
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "quiz_user_answers_delete_own"
    ON de_mobile_app.quiz_user_answers
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
