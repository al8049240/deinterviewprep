-- Migration: Fix Spark question mappings and migrate legacy questions
-- Ensures all questions in quiz-question are correctly linked to
-- Apache Spark (topic_id=758910) with proper Spark Core / Spark SQL/DataFrame subtopics.

DO $$
DECLARE
  v_topic_id       BIGINT := 758910;
  v_core_id        BIGINT;
  v_df_id          BIGINT;
  v_q              RECORD;
  v_new_q_id       TEXT;
  v_opt_id         TEXT;
  v_opt            RECORD;
  v_subtopic_name  TEXT;
BEGIN

  -- ── 1. Ensure Apache Spark topic exists with canonical id ──────────────────
  INSERT INTO de_mobile_app.topics (id, name, description, icon)
  VALUES (
    v_topic_id,
    'Apache Spark',
    'Distributed data processing framework for big data analytics',
    'spark'
  )
  ON CONFLICT (name) DO UPDATE
    SET id = EXCLUDED.id,
        description = EXCLUDED.description;

  -- ── 2. Upsert Spark Core subtopic ─────────────────────────────────────────
  -- Check if it already exists
  SELECT id INTO v_core_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id AND name = 'Spark Core'
  LIMIT 1;

  IF v_core_id IS NULL THEN
    INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
    VALUES (
      v_topic_id,
      'Spark Core',
      'RDDs, execution model, master/worker architecture, memory management, shuffling'
    )
    RETURNING id INTO v_core_id;
  END IF;

  -- ── 3. Upsert Spark SQL/DataFrame subtopic ────────────────────────────────
  SELECT id INTO v_df_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id AND name IN ('Spark SQL/DataFrame', 'Spark DataFrame/SQL')
  LIMIT 1;

  IF v_df_id IS NULL THEN
    INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
    VALUES (
      v_topic_id,
      'Spark SQL/DataFrame',
      'DataFrames, Catalyst Optimizer, SQL queries, Spark Connect, AQE'
    )
    RETURNING id INTO v_df_id;
  ELSE
    -- Normalise name to canonical form
    UPDATE de_mobile_app.subtopics
    SET name = 'Spark SQL/DataFrame'
    WHERE id = v_df_id AND name != 'Spark SQL/DataFrame';
  END IF;

  RAISE NOTICE 'topic_id=%, spark_core_id=%, spark_df_id=%', v_topic_id, v_core_id, v_df_id;

  -- ── 4. Fix existing quiz-question rows: set topic + sub_topics ────────────
  -- Assign sub_topics based on question content keywords.
  -- Questions about RDD, execution model, master/worker, memory, shuffle → Spark Core
  -- Questions about DataFrame, SQL, Catalyst, AQE, Spark Connect → Spark SQL/DataFrame
  -- Default unmatched questions to Spark Core.

  FOR v_q IN
    SELECT question_id, question
    FROM de_mobile_app."quiz-question"
  LOOP
    -- Determine subtopic from question text
    IF v_q.question ~* '(dataframe|data frame|catalyst|spark sql|spark connect|aqe|adaptive query|structured api|dataset api|spark\.sql|createorreplacetempview|registertemptable|sparksession\.sql|sql query|sql queries|sql context|hivecontext|thriftserver|jdbc.*spark|spark.*jdbc|parquet|orc.*spark|spark.*orc|delta lake|iceberg.*spark|spark.*iceberg)'
    THEN
      v_subtopic_name := 'Spark SQL/DataFrame';
      UPDATE de_mobile_app."quiz-question"
      SET topic = v_topic_id, sub_topics = v_df_id
      WHERE question_id = v_q.question_id;
    ELSE
      v_subtopic_name := 'Spark Core';
      UPDATE de_mobile_app."quiz-question"
      SET topic = v_topic_id, sub_topics = v_core_id
      WHERE question_id = v_q.question_id;
    END IF;
  END LOOP;

  RAISE NOTICE 'Updated existing quiz-question rows with topic/subtopic FKs';

  -- ── 5. Migrate legacy questions into quiz-question ────────────────────────
  -- Only migrate rows that are not already present (by question_id).
  -- Assign subtopics based on the legacy sub_topics text field and question content.

  FOR v_q IN
    SELECT
      lq.question_id,
      lq.topic,
      lq.sub_topics,
      lq.type,
      lq.difficulty,
      lq.question,
      lq.explanation,
      lq.interview_tips,
      lq.pro_tips
    FROM de_mobile_app."quiz-question-legacy" lq
    WHERE NOT EXISTS (
      SELECT 1 FROM de_mobile_app."quiz-question" q
      WHERE q.question_id = lq.question_id
    )
  LOOP
    -- Determine subtopic for legacy question
    IF v_q.sub_topics ~* '(dataframe|data frame|sql|catalyst|aqe|spark connect|structured)'
       OR v_q.question ~* '(dataframe|data frame|catalyst|spark sql|spark connect|aqe|adaptive query|structured api|dataset api|spark\.sql|createorreplacetempview|sparksession\.sql|sql query|sql queries|sql context|hivecontext|thriftserver|parquet|orc.*spark|spark.*orc)'
    THEN
      v_subtopic_name := 'Spark SQL/DataFrame';
      INSERT INTO de_mobile_app."quiz-question" (
        question_id, topic, sub_topics, type, difficulty,
        question, explaination, interview_tips, pro_tips
      ) VALUES (
        v_q.question_id,
        v_topic_id,
        v_df_id,
        COALESCE(v_q.type, 'multiple_choice'),
        COALESCE(v_q.difficulty, 'medium'),
        v_q.question,
        v_q.explanation,
        v_q.interview_tips,
        v_q.pro_tips
      )
      ON CONFLICT (question_id) DO UPDATE
        SET topic = EXCLUDED.topic,
            sub_topics = EXCLUDED.sub_topics,
            explaination = EXCLUDED.explaination;
    ELSE
      v_subtopic_name := 'Spark Core';
      INSERT INTO de_mobile_app."quiz-question" (
        question_id, topic, sub_topics, type, difficulty,
        question, explaination, interview_tips, pro_tips
      ) VALUES (
        v_q.question_id,
        v_topic_id,
        v_core_id,
        COALESCE(v_q.type, 'multiple_choice'),
        COALESCE(v_q.difficulty, 'medium'),
        v_q.question,
        v_q.explanation,
        v_q.interview_tips,
        v_q.pro_tips
      )
      ON CONFLICT (question_id) DO UPDATE
        SET topic = EXCLUDED.topic,
            sub_topics = EXCLUDED.sub_topics,
            explaination = EXCLUDED.explaination;
    END IF;
  END LOOP;

  RAISE NOTICE 'Legacy question migration complete';

  -- ── 6. Migrate legacy answers for newly migrated questions ────────────────
  -- Copy quiz-answer-legacy rows for questions now in quiz-question,
  -- skipping any option_id already present in quiz-answer.

  FOR v_opt IN
    SELECT
      la.option_id,
      la.question_id,
      la.option_text,
      la.is_correct,
      la."order"
    FROM de_mobile_app."quiz-answer-legacy" la
    WHERE EXISTS (
      SELECT 1 FROM de_mobile_app."quiz-question" q
      WHERE q.question_id = la.question_id
    )
    AND NOT EXISTS (
      SELECT 1 FROM de_mobile_app."quiz-answer" a
      WHERE a.option_id = la.option_id
    )
  LOOP
    INSERT INTO de_mobile_app."quiz-answer" (
      option_id, question_id, option_text, is_correct, "order"
    ) VALUES (
      v_opt.option_id,
      v_opt.question_id,
      v_opt.option_text,
      COALESCE(v_opt.is_correct, false),
      v_opt."order"
    )
    ON CONFLICT (option_id) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Legacy answer migration complete';

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Migration failed: %', SQLERRM;
END $$;
