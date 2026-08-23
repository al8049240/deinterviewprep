-- User-generated content tables for DE Interview Prep
-- Allows users to create custom flashcards, real case scenarios, and developer experiences

-- 1. User custom flashcards
CREATE TABLE IF NOT EXISTS de_mobile_app.user_flashcards (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    front text NOT NULL,
    back text NOT NULL,
    category text NOT NULL DEFAULT 'Custom',
    created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE de_mobile_app.user_flashcards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_access_user_flashcards" ON de_mobile_app.user_flashcards;
CREATE POLICY "public_access_user_flashcards"
ON de_mobile_app.user_flashcards
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- 2. User custom real case scenarios
CREATE TABLE IF NOT EXISTS de_mobile_app.user_real_case_scenarios (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    category text NOT NULL DEFAULT 'Custom',
    tags text[] DEFAULT '{}'::text[],
    problem_statement text NOT NULL,
    solution_breakdown text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE de_mobile_app.user_real_case_scenarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_access_user_real_case_scenarios" ON de_mobile_app.user_real_case_scenarios;
CREATE POLICY "public_access_user_real_case_scenarios"
ON de_mobile_app.user_real_case_scenarios
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- 3. User custom developer experiences
CREATE TABLE IF NOT EXISTS de_mobile_app.user_developer_experiences (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    category_tag text NOT NULL DEFAULT 'Behavioral',
    situation text NOT NULL,
    task_description text NOT NULL,
    action_taken text NOT NULL,
    result_achieved text NOT NULL,
    key_takeaway text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE de_mobile_app.user_developer_experiences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_access_user_developer_experiences" ON de_mobile_app.user_developer_experiences;
CREATE POLICY "public_access_user_developer_experiences"
ON de_mobile_app.user_developer_experiences
FOR ALL
TO public
USING (true)
WITH CHECK (true);
