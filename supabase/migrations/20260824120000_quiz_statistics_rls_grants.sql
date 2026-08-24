-- ============================================================
-- Migration: Quiz Statistics RLS Policies & Schema Grants
-- Schema: de_mobile_app
-- Tables: quiz_attempts, quiz_user_answers
-- ============================================================

-- Grant schema usage to authenticated and anon roles
GRANT USAGE ON SCHEMA de_mobile_app TO authenticated;
GRANT USAGE ON SCHEMA de_mobile_app TO anon;

-- Grant table-level permissions for quiz_attempts
GRANT SELECT, INSERT, UPDATE, DELETE ON de_mobile_app.quiz_attempts TO authenticated;

-- Grant table-level permissions for quiz_user_answers
GRANT SELECT, INSERT, UPDATE, DELETE ON de_mobile_app.quiz_user_answers TO authenticated;

-- ── quiz_attempts RLS Policies ────────────────────────────────────────────────

ALTER TABLE de_mobile_app.quiz_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quiz_attempts_select_own" ON de_mobile_app.quiz_attempts;
CREATE POLICY "quiz_attempts_select_own"
  ON de_mobile_app.quiz_attempts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "quiz_attempts_insert_own" ON de_mobile_app.quiz_attempts;
CREATE POLICY "quiz_attempts_insert_own"
  ON de_mobile_app.quiz_attempts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "quiz_attempts_update_own" ON de_mobile_app.quiz_attempts;
CREATE POLICY "quiz_attempts_update_own"
  ON de_mobile_app.quiz_attempts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "quiz_attempts_delete_own" ON de_mobile_app.quiz_attempts;
CREATE POLICY "quiz_attempts_delete_own"
  ON de_mobile_app.quiz_attempts
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ── quiz_user_answers RLS Policies ───────────────────────────────────────────

ALTER TABLE de_mobile_app.quiz_user_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quiz_user_answers_select_own" ON de_mobile_app.quiz_user_answers;
CREATE POLICY "quiz_user_answers_select_own"
  ON de_mobile_app.quiz_user_answers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "quiz_user_answers_insert_own" ON de_mobile_app.quiz_user_answers;
CREATE POLICY "quiz_user_answers_insert_own"
  ON de_mobile_app.quiz_user_answers
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "quiz_user_answers_update_own" ON de_mobile_app.quiz_user_answers;
CREATE POLICY "quiz_user_answers_update_own"
  ON de_mobile_app.quiz_user_answers
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "quiz_user_answers_delete_own" ON de_mobile_app.quiz_user_answers;
CREATE POLICY "quiz_user_answers_delete_own"
  ON de_mobile_app.quiz_user_answers
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
