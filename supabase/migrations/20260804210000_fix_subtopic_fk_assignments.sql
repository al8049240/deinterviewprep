-- Fix subtopic FK assignments on quiz-question rows
-- This migration ensures:
-- 1. Apache Spark topic exists at id=758910
-- 2. Spark Core and Spark SQL/DataFrame subtopics exist under topic_id=758910
-- 3. All quiz-question rows have correct topic and sub_topics integer FKs

-- Step 1: Ensure Apache Spark topic exists
INSERT INTO de_mobile_app.topics (id, name, description)
VALUES (758910, 'Apache Spark', 'Apache Spark distributed computing framework')
ON CONFLICT (name) DO UPDATE SET id = 758910;

-- Step 2: Upsert subtopics with fixed IDs so we know them
-- Use fixed IDs to avoid random ID generation issues
DO $$
BEGIN
  -- Delete any existing subtopics for topic 758910 that don't have our target names
  -- to avoid duplicates, then re-insert with known IDs
  
  -- Insert Spark Core with id=100001 if not already present with that id
  IF NOT EXISTS (
    SELECT 1 FROM de_mobile_app.subtopics 
    WHERE topic_id = 758910 AND name = 'Spark Core'
  ) THEN
    -- Remove any row with id=100001 first to avoid PK conflict
    DELETE FROM de_mobile_app.subtopics WHERE id = 100001;
    INSERT INTO de_mobile_app.subtopics (id, topic_id, name, description)
    VALUES (100001, 758910, 'Spark Core', 'Core Apache Spark concepts: RDDs, transformations, actions, and architecture');
  ELSE
    -- Update the existing row to have id=100001
    UPDATE de_mobile_app.subtopics 
    SET id = 100001
    WHERE topic_id = 758910 AND name = 'Spark Core' AND id != 100001;
  END IF;

  -- Insert Spark SQL/DataFrame with id=100002 if not already present
  IF NOT EXISTS (
    SELECT 1 FROM de_mobile_app.subtopics 
    WHERE topic_id = 758910 AND name = 'Spark SQL/DataFrame'
  ) THEN
    DELETE FROM de_mobile_app.subtopics WHERE id = 100002;
    INSERT INTO de_mobile_app.subtopics (id, topic_id, name, description)
    VALUES (100002, 758910, 'Spark SQL/DataFrame', 'Spark SQL, DataFrames, and structured data processing');
  ELSE
    UPDATE de_mobile_app.subtopics 
    SET id = 100002
    WHERE topic_id = 758910 AND name = 'Spark SQL/DataFrame' AND id != 100002;
  END IF;
END $$;

-- Step 3: Update all quiz-question rows to have correct topic FK
UPDATE de_mobile_app."quiz-question"
SET topic = 758910
WHERE topic IS NULL OR topic != 758910;

-- Step 4: Assign sub_topics FK based on question content keywords
-- Spark SQL/DataFrame questions: contain SQL, DataFrame, Dataset, SparkSession, schema keywords
UPDATE de_mobile_app."quiz-question"
SET sub_topics = 100002
WHERE topic = 758910
  AND (
    sub_topics IS NULL OR sub_topics NOT IN (100001, 100002)
  )
  AND (
    lower(question) LIKE '%dataframe%'
    OR lower(question) LIKE '%spark sql%'
    OR lower(question) LIKE '%dataset%'
    OR lower(question) LIKE '%sparksession%'
    OR lower(question) LIKE '%sql%'
    OR lower(question) LIKE '%schema%'
    OR lower(question) LIKE '%structured%'
    OR lower(question) LIKE '%parquet%'
    OR lower(question) LIKE '%json%'
    OR lower(question) LIKE '%csv%'
    OR lower(question) LIKE '%hive%'
    OR lower(question) LIKE '%catalog%'
    OR lower(question) LIKE '%table%'
    OR lower(question) LIKE '%column%'
    OR lower(question) LIKE '%row%'
    OR lower(question) LIKE '%select%'
    OR lower(question) LIKE '%filter%'
    OR lower(question) LIKE '%groupby%'
    OR lower(question) LIKE '%group by%'
    OR lower(question) LIKE '%join%'
    OR lower(question) LIKE '%aggregate%'
    OR lower(question) LIKE '%window function%'
    OR lower(question) LIKE '%udf%'
    OR lower(question) LIKE '%user-defined%'
  );

-- Step 5: Assign remaining unassigned questions to Spark Core
UPDATE de_mobile_app."quiz-question"
SET sub_topics = 100001
WHERE topic = 758910
  AND (sub_topics IS NULL OR sub_topics NOT IN (100001, 100002));

-- Step 6: Fix any rows that already had sub_topics set to old random IDs
-- (rows where sub_topics is not NULL but not one of our known IDs)
UPDATE de_mobile_app."quiz-question"
SET sub_topics = 100001
WHERE topic = 758910
  AND sub_topics IS NOT NULL
  AND sub_topics NOT IN (100001, 100002)
  AND NOT (
    lower(question) LIKE '%dataframe%'
    OR lower(question) LIKE '%spark sql%'
    OR lower(question) LIKE '%dataset%'
    OR lower(question) LIKE '%sparksession%'
    OR lower(question) LIKE '%sql%'
    OR lower(question) LIKE '%schema%'
    OR lower(question) LIKE '%structured%'
    OR lower(question) LIKE '%parquet%'
    OR lower(question) LIKE '%json%'
    OR lower(question) LIKE '%csv%'
    OR lower(question) LIKE '%hive%'
    OR lower(question) LIKE '%catalog%'
    OR lower(question) LIKE '%table%'
    OR lower(question) LIKE '%column%'
    OR lower(question) LIKE '%row%'
    OR lower(question) LIKE '%select%'
    OR lower(question) LIKE '%filter%'
    OR lower(question) LIKE '%groupby%'
    OR lower(question) LIKE '%group by%'
    OR lower(question) LIKE '%join%'
    OR lower(question) LIKE '%aggregate%'
    OR lower(question) LIKE '%window function%'
    OR lower(question) LIKE '%udf%'
    OR lower(question) LIKE '%user-defined%'
  );
