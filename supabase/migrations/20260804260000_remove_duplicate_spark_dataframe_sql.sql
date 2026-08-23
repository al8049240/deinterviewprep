-- Migration: Remove duplicate "Spark Dataframe/SQL" subtopic
-- Keep: "DataFrame & SQL" in de_mobile_app."subtopics-legacy" (has 22 questions)
-- Remove: "Spark Dataframe/SQL" in de_mobile_app.subtopics (0 questions, older entry)

DO $$
DECLARE
  v_spark_id   BIGINT;
  v_old_sub_id BIGINT;
BEGIN

  -- Find the Apache Spark topic id in the non-legacy subtopics table
  SELECT id INTO v_spark_id
  FROM de_mobile_app.topics
  WHERE name = 'Apache Spark'
  LIMIT 1;

  IF v_spark_id IS NOT NULL THEN
    -- Find the old duplicate subtopic
    SELECT id INTO v_old_sub_id
    FROM de_mobile_app.subtopics
    WHERE topic_id = v_spark_id
      AND name = 'Spark Dataframe/SQL'
    LIMIT 1;

    IF v_old_sub_id IS NOT NULL THEN
      -- Nullify any quiz-question rows pointing to this subtopic
      UPDATE de_mobile_app."quiz-question"
      SET sub_topics = NULL
      WHERE sub_topics = v_old_sub_id;

      -- Delete the duplicate subtopic
      DELETE FROM de_mobile_app.subtopics
      WHERE id = v_old_sub_id;

      RAISE NOTICE 'Deleted duplicate subtopic "Spark Dataframe/SQL" (id=%) from de_mobile_app.subtopics', v_old_sub_id;
    ELSE
      RAISE NOTICE '"Spark Dataframe/SQL" subtopic not found in de_mobile_app.subtopics — nothing to delete.';
    END IF;
  ELSE
    RAISE NOTICE 'Apache Spark topic not found in de_mobile_app.subtopics — nothing to delete.';
  END IF;

  -- Also remove from subtopics-legacy if a duplicate "Spark Dataframe/SQL" exists there
  -- (keep "DataFrame & SQL" which has 22 questions)
  DELETE FROM de_mobile_app."subtopics-legacy"
  WHERE name = 'Spark Dataframe/SQL';

  RAISE NOTICE 'Cleanup complete. "DataFrame & SQL" (22 questions) is the only remaining DataFrame subtopic.';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Migration failed: %', SQLERRM;
END $$;
