-- Migration: Refactor Apache Spark quiz module — canonical topic_id = 758910
-- Timestamp: 20260804160000
--
-- Goals:
--   1. Ensure Apache Spark topic exists with id = 758910
--   2. Ensure Spark Core and Spark SQL/DataFrame subtopics exist under topic_id = 758910
--   3. Upsert all Spark questions into quiz-question with topic = 758910 and correct sub_topics FK
--   4. Upsert all Spark answers into quiz-answer linked to their question_id
--   5. Ensure public-read RLS policies on topics, subtopics, quiz-question, quiz-answer

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Ensure RLS is enabled on all relevant tables
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE de_mobile_app.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.subtopics ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app."quiz-question" ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app."quiz-answer" ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Public-read RLS policies (idempotent)
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public_read_topics" ON de_mobile_app.topics;
CREATE POLICY "public_read_topics"
  ON de_mobile_app.topics FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "public_read_subtopics" ON de_mobile_app.subtopics;
CREATE POLICY "public_read_subtopics"
  ON de_mobile_app.subtopics FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "public_read_quiz_question" ON de_mobile_app."quiz-question";
CREATE POLICY "public_read_quiz_question"
  ON de_mobile_app."quiz-question" FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "public_read_quiz_answer" ON de_mobile_app."quiz-answer";
CREATE POLICY "public_read_quiz_answer"
  ON de_mobile_app."quiz-answer" FOR SELECT TO public USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Upsert topic, subtopics, questions, AND answers — all inside one DO block
--    so FK constraints are satisfied within the same transaction
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_spark_core_id  BIGINT;
  v_spark_df_id    BIGINT;
BEGIN

  -- Remove any existing Apache Spark topic that does NOT have id = 758910
  DELETE FROM de_mobile_app.topics
  WHERE name = 'Apache Spark' AND id <> 758910;

  -- Insert canonical Apache Spark topic with id = 758910
  INSERT INTO de_mobile_app.topics (id, name, description, icon)
  VALUES (758910, 'Apache Spark', 'Apache Spark distributed computing and big data processing', 'bolt')
  ON CONFLICT (id) DO UPDATE
    SET name        = 'Apache Spark',
        description = 'Apache Spark distributed computing and big data processing',
        icon        = 'bolt';

  -- ── Subtopics ──────────────────────────────────────────────────────────────

  -- Spark Core subtopic
  INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
  VALUES (758910, 'Spark Core', 'RDDs, transformations, actions, SparkContext, partitioning, and core Spark internals')
  ON CONFLICT DO NOTHING;

  SELECT id INTO v_spark_core_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = 758910 AND name = 'Spark Core'
  LIMIT 1;

  -- Spark SQL/DataFrame subtopic
  INSERT INTO de_mobile_app.subtopics (topic_id, name, description)
  VALUES (758910, 'Spark SQL/DataFrame', 'DataFrames, Catalyst Optimizer, Spark SQL, Spark Connect, AQE, and query optimization')
  ON CONFLICT DO NOTHING;

  -- Also update any old "Spark Dataframe/SQL" subtopic name to the canonical name
  UPDATE de_mobile_app.subtopics
  SET name = 'Spark SQL/DataFrame'
  WHERE topic_id = 758910 AND name = 'Spark Dataframe/SQL';

  SELECT id INTO v_spark_df_id
  FROM de_mobile_app.subtopics
  WHERE topic_id = 758910 AND name = 'Spark SQL/DataFrame'
  LIMIT 1;

  RAISE NOTICE 'Apache Spark topic_id=758910, Spark Core subtopic_id=%, Spark SQL/DataFrame subtopic_id=%',
    v_spark_core_id, v_spark_df_id;

  -- ── Update any existing quiz-question rows that already point to the old topic id ──
  UPDATE de_mobile_app."quiz-question"
  SET topic = 758910
  WHERE topic IN (
    SELECT id FROM de_mobile_app.topics WHERE name = 'Apache Spark'
  ) AND topic <> 758910;

  -- ── Upsert Spark Core questions ────────────────────────────────────────────

  -- spark_q1: Lazy transformations
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q1', 758910, v_spark_core_id, 'mcq', 'middle',
     'Which Spark transformation is "lazy" — meaning it does not execute immediately?',
     'filter() is a transformation in Spark and is lazy — it builds the execution plan (DAG) but does not run until an action (like collect() or count()) is called. Actions trigger the actual computation.',
     'Lazy evaluation and the DAG execution model are core Spark interview topics. Be ready to explain the difference between transformations and actions.',
     'Transformations (map, filter, select, groupBy) = lazy. Actions (collect, count, show, write) = trigger execution. This design enables Spark to optimize the full DAG before running.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'middle',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q2: cache() purpose
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q2', 758910, v_spark_core_id, 'mcq', 'middle',
     'What is the purpose of cache() in PySpark?',
     'cache() persists a DataFrame in memory (default storage level: MEMORY_AND_DISK). It avoids recomputing the same transformation DAG on repeated actions, significantly improving performance for iterative workloads.',
     'Know when to use cache() vs persist() and the different StorageLevel options (MEMORY_ONLY, MEMORY_AND_DISK, DISK_ONLY). Interviewers often ask about trade-offs.',
     'Use cache() when a DataFrame is reused multiple times in the same job. Always call unpersist() when done to free executor memory and avoid OOM errors.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'middle',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q3: Shuffle cost
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q3', 758910, v_spark_core_id, 'mcq', 'senior',
     'What is a Spark "shuffle" and why is it expensive?',
     'A shuffle occurs when Spark needs to redistribute data across partitions — for example during groupBy, join, or distinct operations. It involves serialization, network I/O between executors, and disk writes, making it the most expensive operation in a Spark job.',
     'Shuffle optimization is a key performance tuning topic. Be prepared to explain how to minimize shuffles and what metrics to look at in the Spark UI (shuffle read/write bytes).',
     'Minimize shuffles by using broadcast joins for small tables, pre-partitioning data on join keys with repartition(), and avoiding wide transformations when narrow ones suffice.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'senior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q4: repartition() vs coalesce()
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q4', 758910, v_spark_core_id, 'mcq', 'middle',
     'What does repartition() do in PySpark and how does it differ from coalesce()?',
     'repartition() performs a full shuffle to redistribute data into the specified number of partitions — it can increase or decrease partition count. coalesce() only reduces partitions by merging adjacent ones without a shuffle, making it more efficient when reducing partition count.',
     'repartition vs coalesce is a classic Spark performance question. Know when to use each and the performance implications of triggering a full shuffle.',
     'repartition(n) = full shuffle, use when increasing partitions or needing even distribution. coalesce(n) = no shuffle, use only when reducing partitions to avoid the shuffle overhead.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'middle',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q5: RDD vs DataFrame
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q5', 758910, v_spark_core_id, 'mcq', 'junior',
     'What is the key difference between an RDD and a DataFrame in Apache Spark?',
     'An RDD (Resilient Distributed Dataset) is the low-level, untyped distributed collection in Spark with no schema. A DataFrame is a higher-level abstraction built on top of RDDs with a named column schema, enabling the Catalyst optimizer to generate efficient query plans automatically.',
     'RDD vs DataFrame is a foundational Spark question. Interviewers want to know you understand the evolution of the Spark API and when you would choose one over the other.',
     'Prefer DataFrames/Datasets for most workloads — they benefit from Catalyst optimization and Tungsten execution. Use RDDs only when you need fine-grained control over data partitioning or custom serialization.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'junior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q6: Master/Worker architecture
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q6', 758910, v_spark_core_id, 'mcq', 'middle',
     'In Spark''s Master/Worker architecture, what is the role of the Driver?',
     'The Driver is the process that runs the main() function of the Spark application. It creates the SparkContext, builds the DAG of transformations, negotiates resources with the Cluster Manager, and coordinates task execution on Executors. It is the brain of the Spark application.',
     'Understanding the Driver, Executor, and Cluster Manager roles is essential for Spark architecture questions. Be ready to explain what happens when the Driver fails.',
     'The Driver holds the SparkContext and the DAG scheduler. Executors run tasks and store data. If the Driver dies, the entire application fails — design for Driver fault tolerance in production.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'middle',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q7: Memory management (Execution vs Storage)
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q7', 758910, v_spark_core_id, 'mcq', 'senior',
     'In Spark''s Unified Memory Management model, what are the two main memory regions within executor memory?',
     'Spark''s Unified Memory Manager divides executor memory into Execution Memory (used for shuffles, joins, sorts, aggregations) and Storage Memory (used for caching/persisting RDDs and DataFrames). Both regions share a unified pool and can borrow from each other dynamically.',
     'Memory management is a senior-level Spark topic. Know the spark.memory.fraction and spark.memory.storageFraction configs and how to tune them for cache-heavy vs compute-heavy workloads.',
     'If you see OOM errors during shuffles, increase spark.memory.fraction. If cached DataFrames are being evicted too aggressively, increase spark.memory.storageFraction.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_core_id,
        type         = 'mcq',
        difficulty   = 'senior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- ── Upsert Spark SQL/DataFrame questions ──────────────────────────────────

  -- spark_q8: Broadcast join
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q8', 758910, v_spark_df_id, 'mcq', 'senior',
     'What is a broadcast join in Spark and when should you use it?',
     'A broadcast join copies the smaller DataFrame to every executor node, eliminating the need to shuffle the large DataFrame. This makes it much faster for joins between a large table and a small lookup table. Spark automatically uses broadcast join when the smaller table is below spark.sql.autoBroadcastJoinThreshold (default 10 MB).',
     'Broadcast join optimization is a must-know for Spark performance interviews. Be ready to explain the threshold config and how to force a broadcast hint.',
     'Use broadcast() hint: df_large.join(broadcast(df_small), ...). Increase spark.sql.autoBroadcastJoinThreshold for larger lookup tables. Avoid broadcasting tables > 200 MB to prevent executor OOM.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_df_id,
        type         = 'mcq',
        difficulty   = 'senior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q9: Catalyst Optimizer
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q9', 758910, v_spark_df_id, 'mcq', 'senior',
     'What is the Catalyst Optimizer in Spark SQL?',
     'The Catalyst Optimizer is Spark SQL''s query optimization framework. It takes a logical plan (from your DataFrame/SQL query), applies rule-based and cost-based optimizations (predicate pushdown, column pruning, join reordering), and produces an optimized physical plan for execution.',
     'Catalyst is a key differentiator of Spark SQL over raw RDDs. Interviewers may ask you to explain the phases: Analysis → Logical Optimization → Physical Planning → Code Generation.',
     'Use df.explain(True) to see the full Catalyst plan including parsed, analyzed, optimized logical, and physical plans. This is invaluable for debugging slow queries.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_df_id,
        type         = 'mcq',
        difficulty   = 'senior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q10: Adaptive Query Execution (AQE)
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q10', 758910, v_spark_df_id, 'mcq', 'senior',
     'What does Adaptive Query Execution (AQE) do in Spark 3.x?',
     'AQE (enabled by default in Spark 3.x via spark.sql.adaptive.enabled=true) re-optimizes query plans at runtime based on actual data statistics collected during execution. Key features: dynamic coalescing of shuffle partitions, dynamic switching of join strategies, and skew join optimization.',
     'AQE is a Spark 3.x feature that frequently comes up in senior interviews. Know the three main AQE features and how they address common performance problems.',
     'AQE eliminates the need to manually set spark.sql.shuffle.partitions for most workloads. It dynamically coalesces small shuffle partitions and handles data skew automatically — enable it in all Spark 3.x jobs.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_df_id,
        type         = 'mcq',
        difficulty   = 'senior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q11: Spark Connect
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q11', 758910, v_spark_df_id, 'mcq', 'senior',
     'What is Spark Connect (introduced in Spark 3.4) and what problem does it solve?',
     'Spark Connect introduces a decoupled client-server architecture for Apache Spark. It provides a thin client that communicates with a remote Spark server over gRPC, allowing lightweight clients (IDEs, notebooks, microservices) to submit Spark jobs without embedding the full Spark runtime locally.',
     'Spark Connect is a newer topic that appears in senior/staff-level interviews. Know that it decouples the client from the server, enables remote connectivity, and improves stability by isolating client failures from the Spark cluster.',
     'Spark Connect enables IDE-native Spark development without a local Spark installation. It also improves cluster stability — a crashing client no longer takes down the Spark session on the server.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_df_id,
        type         = 'mcq',
        difficulty   = 'senior',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  -- spark_q12: DataFrame SQL query
  INSERT INTO de_mobile_app."quiz-question"
    (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
  VALUES
    ('spark_q12', 758910, v_spark_df_id, 'mcq', 'middle',
     'How do you run a SQL query on a Spark DataFrame?',
     'To run SQL on a DataFrame, first register it as a temporary view using df.createOrReplaceTempView("view_name"), then use spark.sql("SELECT ... FROM view_name") to query it. The result is a new DataFrame. Global temporary views (createOrReplaceGlobalTempView) are accessible across SparkSessions.',
     'This is a common practical question. Know the difference between createOrReplaceTempView (session-scoped) and createOrReplaceGlobalTempView (application-scoped, accessed via global_temp.view_name).',
     'Temporary views are session-scoped and dropped when the SparkSession ends. Use global temp views when you need to share a view across multiple SparkSessions in the same application.')
  ON CONFLICT (question_id) DO UPDATE
    SET topic        = 758910,
        sub_topics   = v_spark_df_id,
        type         = 'mcq',
        difficulty   = 'middle',
        question     = EXCLUDED.question,
        explaination = EXCLUDED.explaination,
        interview_tips = EXCLUDED.interview_tips,
        pro_tips     = EXCLUDED.pro_tips;

  RAISE NOTICE 'All Spark questions upserted successfully under topic_id=758910';

  -- ─────────────────────────────────────────────────────────────────────────
  -- 4. Upsert answers for all Spark Core questions
  --    These are inside the DO block so questions are guaranteed to exist
  -- ─────────────────────────────────────────────────────────────────────────

  -- spark_q1 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q1_o1', 'spark_q1', 'collect()', false, 1),
    ('spark_q1_o2', 'spark_q1', 'filter()', true,  2),
    ('spark_q1_o3', 'spark_q1', 'count()', false, 3),
    ('spark_q1_o4', 'spark_q1', 'show()', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q2 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q2_o1', 'spark_q2', 'Writes the DataFrame to disk as a Parquet file', false, 1),
    ('spark_q2_o2', 'spark_q2', 'Stores the DataFrame in memory to avoid recomputation on repeated access', true, 2),
    ('spark_q2_o3', 'spark_q2', 'Compresses the DataFrame to reduce shuffle data size', false, 3),
    ('spark_q2_o4', 'spark_q2', 'Broadcasts the DataFrame to all worker nodes for join optimization', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q3 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q3_o1', 'spark_q3', 'A shuffle reorders partitions alphabetically to improve sort performance', false, 1),
    ('spark_q3_o2', 'spark_q3', 'A shuffle moves data across the network between executors to redistribute it by key', true, 2),
    ('spark_q3_o3', 'spark_q3', 'A shuffle compresses data before writing to HDFS', false, 3),
    ('spark_q3_o4', 'spark_q3', 'A shuffle merges small files into larger ones to reduce metadata overhead', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q4 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q4_o1', 'spark_q4', 'Reduces the number of partitions by merging adjacent ones without a shuffle', false, 1),
    ('spark_q4_o2', 'spark_q4', 'Increases or decreases partitions by performing a full shuffle of the data', true, 2),
    ('spark_q4_o3', 'spark_q4', 'Splits a single large partition into two equal halves', false, 3),
    ('spark_q4_o4', 'spark_q4', 'Reorders rows within each partition by a specified column', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q5 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q5_o1', 'spark_q5', 'An RDD has a named column schema; a DataFrame is an untyped distributed collection', false, 1),
    ('spark_q5_o2', 'spark_q5', 'An RDD is the low-level untyped API; a DataFrame adds a schema and Catalyst optimization', true, 2),
    ('spark_q5_o3', 'spark_q5', 'An RDD runs on the Driver; a DataFrame runs on Executors', false, 3),
    ('spark_q5_o4', 'spark_q5', 'An RDD supports SQL queries directly; a DataFrame does not', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q6 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q6_o1', 'spark_q6', 'It stores cached DataFrames and manages storage memory on each Executor', false, 1),
    ('spark_q6_o2', 'spark_q6', 'It runs the main() function, builds the DAG, and coordinates task execution on Executors', true, 2),
    ('spark_q6_o3', 'spark_q6', 'It allocates CPU and memory resources to Executors on behalf of the Cluster Manager', false, 3),
    ('spark_q6_o4', 'spark_q6', 'It receives shuffle data from other Executors and writes it to HDFS', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q7 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q7_o1', 'spark_q7', 'Driver Memory and Executor Memory', false, 1),
    ('spark_q7_o2', 'spark_q7', 'Execution Memory and Storage Memory', true, 2),
    ('spark_q7_o3', 'spark_q7', 'Heap Memory and Off-Heap Memory', false, 3),
    ('spark_q7_o4', 'spark_q7', 'Shuffle Memory and Cache Memory', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- ─────────────────────────────────────────────────────────────────────────
  -- 5. Upsert answers for all Spark SQL/DataFrame questions
  -- ─────────────────────────────────────────────────────────────────────────

  -- spark_q8 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q8_o1', 'spark_q8', 'A join that sends query results to all connected BI tools simultaneously', false, 1),
    ('spark_q8_o2', 'spark_q8', 'A join where a small DataFrame is copied to every executor to avoid shuffling the large DataFrame', true, 2),
    ('spark_q8_o3', 'spark_q8', 'A join that runs across multiple Spark clusters in parallel', false, 3),
    ('spark_q8_o4', 'spark_q8', 'A join that caches both DataFrames in memory before execution', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q9 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q9_o1', 'spark_q9', 'A runtime JIT compiler that converts DataFrame operations to native machine code', false, 1),
    ('spark_q9_o2', 'spark_q9', 'A query optimization framework that transforms logical plans into optimized physical execution plans', true, 2),
    ('spark_q9_o3', 'spark_q9', 'A cost-based optimizer that selects the cheapest storage format for each DataFrame', false, 3),
    ('spark_q9_o4', 'spark_q9', 'A scheduler that assigns tasks to Executors based on data locality', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q10 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q10_o1', 'spark_q10', 'It pre-compiles all SQL queries to native code before the job starts', false, 1),
    ('spark_q10_o2', 'spark_q10', 'It re-optimizes query plans at runtime using actual data statistics collected during execution', true, 2),
    ('spark_q10_o3', 'spark_q10', 'It automatically scales the number of Executors based on CPU utilization', false, 3),
    ('spark_q10_o4', 'spark_q10', 'It caches intermediate shuffle results to disk to speed up stage retries', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q11 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q11_o1', 'spark_q11', 'A new DataFrame API that replaces RDDs in Spark 3.4', false, 1),
    ('spark_q11_o2', 'spark_q11', 'A decoupled client-server architecture that lets lightweight clients submit Spark jobs over gRPC without embedding the full Spark runtime', true, 2),
    ('spark_q11_o3', 'spark_q11', 'A protocol for connecting Spark to external databases via JDBC', false, 3),
    ('spark_q11_o4', 'spark_q11', 'A feature that connects multiple Spark clusters into a single logical cluster', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  -- spark_q12 answers
  INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
    ('spark_q12_o1', 'spark_q12', 'Call df.sql("SELECT ...") directly on the DataFrame object', false, 1),
    ('spark_q12_o2', 'spark_q12', 'Register the DataFrame as a temp view with createOrReplaceTempView(), then use spark.sql()', true, 2),
    ('spark_q12_o3', 'spark_q12', 'Convert the DataFrame to an RDD first, then call rdd.sql()', false, 3),
    ('spark_q12_o4', 'spark_q12', 'Use df.query() with a SQL string passed as a parameter', false, 4)
  ON CONFLICT (option_id) DO UPDATE
    SET option_text = EXCLUDED.option_text,
        is_correct  = EXCLUDED.is_correct,
        "order"     = EXCLUDED."order";

  RAISE NOTICE 'All Spark answers upserted successfully';

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Migration failed: %', SQLERRM;
END $$;
