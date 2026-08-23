-- Migration: Fix Apache Spark questions — insert with correct integer topic/sub_topics FKs
-- The original migration used topic = 'spark' (text) which failed silently on the integer FK column.
-- This migration resolves the Apache Spark topic ID and subtopic IDs, then inserts/upserts
-- all 5 Spark questions and their answers with the correct relational integer FKs.

DO $$
DECLARE
  v_topic_id       BIGINT;
  v_spark_core_id  BIGINT;
  v_spark_df_id    BIGINT;
BEGIN

  -- Resolve Apache Spark topic ID
  SELECT id INTO v_topic_id
  FROM de_mobile_app.topics
  WHERE name = 'Apache Spark'
  LIMIT 1;

  IF v_topic_id IS NULL THEN
    RAISE NOTICE 'Apache Spark topic not found — inserting it now';
    INSERT INTO de_mobile_app.topics (name, description, icon)
    VALUES ('Apache Spark', 'Apache Spark distributed computing and big data processing', 'bolt')
    ON CONFLICT (name) DO NOTHING;

    SELECT id INTO v_topic_id
    FROM de_mobile_app.topics
    WHERE name = 'Apache Spark'
    LIMIT 1;
  END IF;

  IF v_topic_id IS NULL THEN
    RAISE NOTICE 'Could not resolve Apache Spark topic ID — aborting';
    RETURN;
  END IF;

  -- Resolve Spark Core subtopic ID
  SELECT id INTO v_spark_core_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id AND name = 'Spark Core'
  LIMIT 1;

  IF v_spark_core_id IS NULL THEN
    INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
    VALUES (v_topic_id, 'Spark Core', 'RDDs, transformations, actions, SparkContext, and core Spark internals')
    ON CONFLICT DO NOTHING;

    SELECT id INTO v_spark_core_id
    FROM de_mobile_app.subtopics
    WHERE topic_id = v_topic_id AND name = 'Spark Core'
    LIMIT 1;
  END IF;

  -- Resolve Spark Dataframe/SQL subtopic ID
  SELECT id INTO v_spark_df_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = v_topic_id AND name = 'Spark Dataframe/SQL'
  LIMIT 1;

  IF v_spark_df_id IS NULL THEN
    INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
    VALUES (v_topic_id, 'Spark Dataframe/SQL', 'DataFrames, Spark SQL, Dataset API, schema management, and query optimization')
    ON CONFLICT DO NOTHING;

    SELECT id INTO v_spark_df_id
    FROM de_mobile_app.subtopics
    WHERE topic_id = v_topic_id AND name = 'Spark Dataframe/SQL'
    LIMIT 1;
  END IF;

  RAISE NOTICE 'Resolved: topic_id=%, spark_core_id=%, spark_df_id=%', v_topic_id, v_spark_core_id, v_spark_df_id;

  -- ── Insert / upsert Spark Core questions (spark_q1, spark_q2, spark_q3, spark_q4) ──

  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q1', v_topic_id, v_spark_core_id, 'mcq', 'middle',
     'Which Spark transformation is "lazy" — meaning it does not execute immediately?',
     'filter() is a transformation in Spark and is lazy — it builds the execution plan but does not run until an action (like collect() or count()) is called.',
     'Lazy evaluation and the DAG execution model are core Spark interview topics.',
     'Transformations (map, filter, select) = lazy. Actions (collect, count, show) = trigger execution.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic = v_topic_id,
        sub_topics = v_spark_core_id,
        type = 'mcq',
        difficulty = 'middle';

  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q2', v_topic_id, v_spark_core_id, 'mcq', 'middle',
     'What is the purpose of cache() in PySpark?',
     'cache() persists a DataFrame in memory (default storage level: MEMORY_AND_DISK). It avoids recomputing the same transformation DAG on repeated actions.',
     'Know when to use cache() vs persist() and the different storage levels.',
     'Use cache() when a DataFrame is used multiple times. Call unpersist() when done to free memory.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic = v_topic_id,
        sub_topics = v_spark_core_id,
        type = 'mcq',
        difficulty = 'middle';

  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q3', v_topic_id, v_spark_core_id, 'mcq', 'senior',
     'What is a Spark "shuffle" and why is it expensive?',
     'A shuffle occurs when Spark needs to redistribute data across partitions (e.g., during groupBy, join, distinct). It involves network I/O and disk writes, making it the most expensive operation.',
     'Shuffle optimization is a key performance tuning topic in Spark interviews.',
     'Minimize shuffles by using broadcast joins for small tables, partitioning data on join keys.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic = v_topic_id,
        sub_topics = v_spark_core_id,
        type = 'mcq',
        difficulty = 'senior';

  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q4', v_topic_id, v_spark_core_id, 'mcq', 'middle',
     'What does repartition() do in PySpark?',
     'repartition() performs a full shuffle to redistribute data into the specified number of partitions. Use coalesce() instead when only reducing partitions to avoid the shuffle.',
     'repartition vs coalesce is a classic Spark performance question.',
     'repartition(n) = full shuffle. coalesce(n) = no shuffle (use to reduce partitions efficiently).')
  ON CONFLICT (question_id) DO UPDATE
    SET topic = v_topic_id,
        sub_topics = v_spark_core_id,
        type = 'mcq',
        difficulty = 'middle';

  -- ── Insert / upsert Spark Dataframe/SQL question (spark_q5) ──

  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q5', v_topic_id, v_spark_df_id, 'mcq', 'senior',
     'What is a broadcast join in Spark?',
     'A broadcast join copies the smaller DataFrame to every executor node. This eliminates the shuffle of the large DataFrame, making it much faster for small-large table joins.',
     'Broadcast join optimization is a must-know for Spark performance interviews.',
     'Use broadcast() hint when joining a large table with a small lookup table (< 10 MB by default).')
  ON CONFLICT (question_id) DO UPDATE
    SET topic = v_topic_id,
        sub_topics = v_spark_df_id,
        type = 'mcq',
        difficulty = 'senior';

  RAISE NOTICE 'Spark questions upserted successfully';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Migration failed: %', SQLERRM;
END $$;

-- ── Insert / upsert answers for all 5 Spark questions ──

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q1_o1','spark_q1','collect()',false,1),
('spark_q1_o2','spark_q1','filter()',true,2),
('spark_q1_o3','spark_q1','count()',false,3),
('spark_q1_o4','spark_q1','show()',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q2_o1','spark_q2','Writes the DataFrame to disk as a Parquet file',false,1),
('spark_q2_o2','spark_q2','Stores the DataFrame in memory to avoid recomputation on repeated access',true,2),
('spark_q2_o3','spark_q2','Compresses the DataFrame to reduce shuffle data size',false,3),
('spark_q2_o4','spark_q2','Broadcasts the DataFrame to all worker nodes for join optimization',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q3_o1','spark_q3','A shuffle reorders partitions alphabetically to improve sort performance',false,1),
('spark_q3_o2','spark_q3','A shuffle moves data across the network between executors to redistribute it by key',true,2),
('spark_q3_o3','spark_q3','A shuffle compresses data before writing to HDFS',false,3),
('spark_q3_o4','spark_q3','A shuffle merges small files into larger ones to reduce metadata overhead',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q4_o1','spark_q4','Reduces the number of partitions by merging adjacent ones without a shuffle',false,1),
('spark_q4_o2','spark_q4','Increases or decreases partitions by performing a full shuffle of the data',true,2),
('spark_q4_o3','spark_q4','Splits a single large partition into two equal halves',false,3),
('spark_q4_o4','spark_q4','Reorders rows within each partition by a specified column',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q5_o1','spark_q5','A join that sends query results to all connected BI tools simultaneously',false,1),
('spark_q5_o2','spark_q5','A join where a small DataFrame is copied to every executor to avoid shuffling the large DataFrame',true,2),
('spark_q5_o3','spark_q5','A join that runs across multiple Spark clusters in parallel',false,3),
('spark_q5_o4','spark_q5','A join that caches both DataFrames in memory before execution',false,4)
ON CONFLICT (option_id) DO NOTHING;
