-- ============================================================
-- Migration: Remove starter_code and dataset columns from
--            code_playground (keep only solution + requirement)
-- ============================================================

-- 1. Drop the foreign key constraint on dataset_id
ALTER TABLE de_mobile_app.code_playground
  DROP CONSTRAINT IF EXISTS code_playground_dataset_id_fkey;

-- 2. Drop starter_code column (the "code" field)
ALTER TABLE de_mobile_app.code_playground
  DROP COLUMN IF EXISTS starter_code;

-- 3. Drop dataset_id column (the "data" field)
ALTER TABLE de_mobile_app.code_playground
  DROP COLUMN IF EXISTS dataset_id;

-- 4. Drop verification_config and expected_results (no longer needed without code execution)
ALTER TABLE de_mobile_app.code_playground
  DROP COLUMN IF EXISTS verification_config;

ALTER TABLE de_mobile_app.code_playground
  DROP COLUMN IF EXISTS expected_results;
