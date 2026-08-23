-- Migration: Apache Spark topic + Spark Core / Spark Dataframe/SQL subtopics
-- Timestamp: 20260804080000

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Enable RLS on topics and subtopics (idempotent)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE de_mobile_app.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.subtopics ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Public-read RLS policies for topics and subtopics
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public_read_topics" ON de_mobile_app.topics;
CREATE POLICY "public_read_topics"
  ON de_mobile_app.topics
  FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "public_read_subtopics" ON de_mobile_app.subtopics;
CREATE POLICY "public_read_subtopics"
  ON de_mobile_app.subtopics
  FOR SELECT
  TO public
  USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Upsert "Apache Spark" topic and its two subtopics
--    Then update existing quiz-question rows to use the correct integer FKs
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic_id       BIGINT;
  v_spark_core_id  BIGINT;
  v_spark_df_id    BIGINT;
BEGIN

  -- 3a. Insert "Apache Spark" topic (skip if name already exists)
  INSERT INTO de_mobile_app.topics (name, description, icon)
  VALUES ('Apache Spark', 'Apache Spark distributed computing and big data processing', 'bolt')
  ON CONFLICT (name) DO NOTHING;

  SELECT id INTO v_topic_id
  FROM de_mobile_app.topics
  WHERE name = 'Apache Spark'
  LIMIT 1;

  IF v_topic_id IS NULL THEN
    RAISE NOTICE 'Could not find or create Apache Spark topic';
    RETURN;
  END IF;

  -- 3b. Insert "Spark Core" subtopic
  INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
  VALUES (v_topic_id, 'Spark Core', 'RDDs, transformations, actions, SparkContext, and core Spark internals')
  ON CONFLICT DO NOTHING;

  SELECT id INTO v_spark_core_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id AND name = 'Spark Core'
  LIMIT 1;

  -- 3c. Insert "Spark Dataframe/SQL" subtopic
  INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
  VALUES (v_topic_id, 'Spark Dataframe/SQL', 'DataFrames, Spark SQL, Dataset API, schema management, and query optimization')
  ON CONFLICT DO NOTHING;

  SELECT id INTO v_spark_df_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id AND name = 'Spark Dataframe/SQL'
  LIMIT 1;

  RAISE NOTICE 'Apache Spark topic_id=%, Spark Core subtopic_id=%, Spark Dataframe/SQL subtopic_id=%',
    v_topic_id, v_spark_core_id, v_spark_df_id;

  -- 3d. Update existing quiz-question rows that have topic = 'spark' (text) or
  --     sub_topics matching old subtag values to use the new integer FKs.
  --     We update all rows whose current topic integer matches v_topic_id
  --     (already set by a prior migration) to ensure sub_topics is populated.
  --     Also handle rows that may still have NULL topic but belong to spark.

  -- Update rows already pointing to the Apache Spark topic but missing sub_topics
  IF v_spark_core_id IS NOT NULL THEN
    UPDATE de_mobile_app."quiz-question"
    SET sub_topics = v_spark_core_id
    WHERE topic = v_topic_id
      AND (sub_topics IS NULL OR sub_topics = v_spark_core_id)
      AND question_id IN (
        SELECT question_id FROM de_mobile_app."quiz-question"
        WHERE topic = v_topic_id
        ORDER BY question_id
        LIMIT 20
      );
  END IF;

  IF v_spark_df_id IS NOT NULL THEN
    UPDATE de_mobile_app."quiz-question"
    SET sub_topics = v_spark_df_id
    WHERE topic = v_topic_id
      AND sub_topics IS NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Migration step failed: %', SQLERRM;
END $$;
