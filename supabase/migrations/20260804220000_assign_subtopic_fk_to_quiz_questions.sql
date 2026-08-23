-- Migration: Assign sub_topics FK to all quiz-question rows
-- Reads real IDs from de_mobile_app.topics and de_mobile_app.subtopics,
-- then UPDATEs quiz-question rows to assign the correct sub_topics FK.
-- Split logic: SQL/DataFrame keywords → Spark SQL/DataFrame subtopic,
--              everything else → Spark Core subtopic.
-- This migration is idempotent (safe to run multiple times).

DO $$
DECLARE
  v_topic_id       BIGINT;
  v_core_id        BIGINT;
  v_sqldataframe_id BIGINT;
  v_updated_core   INT;
  v_updated_sql    INT;
BEGIN

  -- ── Step 1: Resolve Apache Spark topic ID ──────────────────────────────────
  SELECT id INTO v_topic_id
  FROM de_mobile_app.topics
  WHERE name = 'Apache Spark'
  LIMIT 1;

  IF v_topic_id IS NULL THEN
    RAISE NOTICE 'Apache Spark topic not found in de_mobile_app.topics — skipping migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Apache Spark topic ID: %', v_topic_id;

  -- ── Step 2: Resolve Spark Core subtopic ID ─────────────────────────────────
  SELECT id INTO v_core_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id
    AND (
      name ILIKE '%spark core%'
      OR name ILIKE '%sparkcore%'
      OR (name ILIKE '%core%' AND name NOT ILIKE '%sql%' AND name NOT ILIKE '%dataframe%')
    )
  LIMIT 1;

  IF v_core_id IS NULL THEN
    RAISE NOTICE 'Spark Core subtopic not found — skipping migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Spark Core subtopic ID: %', v_core_id;

  -- ── Step 3: Resolve Spark SQL/DataFrame subtopic ID ────────────────────────
  SELECT id INTO v_sqldataframe_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id
    AND (
      name ILIKE '%sql%'
      OR name ILIKE '%dataframe%'
      OR name ILIKE '%data frame%'
      OR name ILIKE '%spark sql%'
    )
  LIMIT 1;

  IF v_sqldataframe_id IS NULL THEN
    RAISE NOTICE 'Spark SQL/DataFrame subtopic not found — skipping migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Spark SQL/DataFrame subtopic ID: %', v_sqldataframe_id;

  -- ── Step 4: Assign Spark SQL/DataFrame subtopic to matching questions ───────
  -- Keywords that indicate SQL/DataFrame content
  UPDATE de_mobile_app."quiz-question"
  SET sub_topics = v_sqldataframe_id
  WHERE topic = v_topic_id
    AND (
      question ILIKE '%dataframe%'
      OR question ILIKE '%data frame%'
      OR question ILIKE '%spark sql%'
      OR question ILIKE '%sparksql%'
      OR question ILIKE '%dataset%'
      OR question ILIKE '%catalyst%'
      OR question ILIKE '%tungsten%'
      OR question ILIKE '%sql context%'
      OR question ILIKE '%sqlcontext%'
      OR question ILIKE '%hive context%'
      OR question ILIKE '%hivecontext%'
      OR question ILIKE '%structured streaming%'
      OR question ILIKE '%structuredstreaming%'
      OR question ILIKE '%schema%'
      OR question ILIKE '%parquet%'
      OR question ILIKE '%orc%'
      OR question ILIKE '%avro%'
      OR question ILIKE '%json format%'
      OR question ILIKE '%createorreplacetempview%'
      OR question ILIKE '%temp view%'
      OR question ILIKE '%tempview%'
      OR question ILIKE '%select * from%'
      OR question ILIKE '%spark.sql%'
      OR question ILIKE '%window function%'
      OR question ILIKE '%groupby%'
      OR question ILIKE '%group by%'
      OR question ILIKE '%join%'
      OR question ILIKE '%filter%'
      OR question ILIKE '%withcolumn%'
      OR question ILIKE '%agg(%'
      OR question ILIKE '%aggregate%'
    );

  GET DIAGNOSTICS v_updated_sql = ROW_COUNT;
  RAISE NOTICE 'Assigned % question(s) to Spark SQL/DataFrame (id=%)', v_updated_sql, v_sqldataframe_id;

  -- ── Step 5: Assign Spark Core subtopic to all remaining unassigned questions ─
  UPDATE de_mobile_app."quiz-question"
  SET sub_topics = v_core_id
  WHERE topic = v_topic_id
    AND sub_topics IS NULL;

  GET DIAGNOSTICS v_updated_core = ROW_COUNT;
  RAISE NOTICE 'Assigned % question(s) to Spark Core (id=%)', v_updated_core, v_core_id;

  RAISE NOTICE 'Migration complete. Total assigned: % SQL/DF + % Core = % questions.',
    v_updated_sql, v_updated_core, (v_updated_sql + v_updated_core);

END $$;
