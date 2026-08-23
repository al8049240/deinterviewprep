-- Migration: Insert Spark Core questions spark_q6–spark_q25
-- Target tables: de_mobile_app."quiz-question-legacy-2" and de_mobile_app."quiz-answer-legacy-2"
-- Hardcoded: topic = 758910, sub_topics = 719060 (Spark Core)
-- Idempotent: ON CONFLICT DO NOTHING on all inserts

-- ── 1. Ensure RLS policies allow public read on the legacy-2 tables ──────────

ALTER TABLE de_mobile_app."quiz-question-legacy-2" ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app."quiz-answer-legacy-2" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_quiz_question_legacy2" ON de_mobile_app."quiz-question-legacy-2";
CREATE POLICY "public_read_quiz_question_legacy2"
  ON de_mobile_app."quiz-question-legacy-2" FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "public_read_quiz_answer_legacy2" ON de_mobile_app."quiz-answer-legacy-2";
CREATE POLICY "public_read_quiz_answer_legacy2"
  ON de_mobile_app."quiz-answer-legacy-2" FOR SELECT TO public USING (true);

-- ── 2. Ensure topic 758910 and subtopic 719060 exist in legacy tables ────────

ALTER TABLE de_mobile_app."topics-legacy" ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app."subtopics-legacy" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_topics_legacy" ON de_mobile_app."topics-legacy";
CREATE POLICY "public_read_topics_legacy"
  ON de_mobile_app."topics-legacy" FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "public_read_subtopics_legacy" ON de_mobile_app."subtopics-legacy";
CREATE POLICY "public_read_subtopics_legacy"
  ON de_mobile_app."subtopics-legacy" FOR SELECT TO public USING (true);

DO $$
BEGIN
  -- Ensure Apache Spark topic exists with id=758910 in topics-legacy
  INSERT INTO de_mobile_app."topics-legacy" (id, name, description, icon)
  VALUES (758910, 'Apache Spark', 'Apache Spark distributed computing and big data processing', 'bolt')
  ON CONFLICT (id) DO UPDATE
    SET name = 'Apache Spark',
        description = 'Apache Spark distributed computing and big data processing',
        icon = 'bolt';

  -- Ensure Spark Core subtopic exists with id=719060 in subtopics-legacy
  INSERT INTO de_mobile_app."subtopics-legacy" (id, topic_id, name, description)
  VALUES (719060, 758910, 'Spark Core', 'RDDs, transformations, actions, SparkContext, partitioning, and core Spark internals')
  ON CONFLICT (id) DO UPDATE
    SET name = 'Spark Core',
        topic_id = 758910;

END $$;

-- ── 3. Insert questions into quiz-question-legacy-2 ──────────────────────────

INSERT INTO de_mobile_app."quiz-question-legacy-2"
  (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_tips, pro_tips)
VALUES
  ('spark_q6',  758910, 719060, 'mcq',  'junior',
   'Why does a Spark application crash with a ''Driver Out-Of-Memory'' error when calling ''.collect()'' on a 100GB dataset?',
   'The ''.collect()'' action pulls every single partition of data from the distributed worker nodes and attempts to load them into the Driver''s single RAM pool. If the dataset size exceeds the Driver''s heap memory, the JVM fails. Actions like ''.take(n)'' or writing directly to storage keep data distributed.',
   'Evaluates awareness of the centralized Driver versus distributed Executors. Focuses on data movement bottlenecks.',
   'Use ''.collect()'' only for tiny samples during debugging. In production, write results to S3 or a DB to keep the load on executors.'),

  ('spark_q7',  758910, 719060, 'mcq',  'middle',
   'How does reducing ''spark.executor.cores'' specifically help resolve intermittent Out-Of-Memory (OOM) errors during shuffles?',
   'All tasks running on an executor share one pool of RAM. If 16 cores (tasks) fight for 64GB, each gets a small slice. Reducing to 4 cores gives each task a much larger 16GB slice, providing a safety buffer for data-heavy partitions during complex shuffles.',
   'Checks understanding of the core-to-memory ratio and concurrency management as a stability fix.',
   'Lowering the core count per executor is often more cost-effective for fixing heap space issues than scaling up total cluster RAM.'),

  ('spark_q8',  758910, 719060, 'mcq',  'senior',
   'What is the primary difference between ''Lineage'' and ''Checkpointing'' for achieving Spark fault tolerance?',
   'Lineage is a logical record of transformations used to recompute lost data. Checkpointing physically writes data to reliable storage and ''cuts'' the lineage graph, which is vital for long iterative jobs to prevent massive DAGs and slow recovery.',
   'Identifies the distinction between metadata tracking and physical data persistence. Focuses on DAG size impact.',
   'Use ''.checkpoint()'' in recursive loops or streaming jobs running for weeks to prevent lineage chains from crashing the Driver''s memory.'),

  ('spark_q9',  758910, 719060, 'mcma', 'junior',
   'Which of the following transformations are considered ''Narrow'' dependencies in Apache Spark Core? Select all that apply.',
   'Narrow dependencies occur when each partition of the parent RDD is used by at most one partition of the child RDD. Transformations like ''map'', ''filter'', and ''union'' fall into this category because they do not require data movement between executors.',
   'Assesses the ability to identify operations that keep data local. Focuses on the ''Shuffle'' boundary.',
   'Group narrow transformations together so Spark can pipeline them into a single stage, which is the most efficient processing path.'),

  ('spark_q10', 758910, 719060, 'mcq',  'middle',
   'When is it architecturally safer to choose ''Cluster Mode'' over ''Client Mode'' for production deployments?',
   'In Cluster Mode, the Driver process runs on a worker node inside the cluster. This ensures the job continues running even if the local machine that submitted the job loses connectivity or shuts down.',
   'Evaluates understanding of deployment stability and the ''single point of failure'' concept regarding the submitter machine.',
   'Reserve Client Mode for interactive notebooks. Scheduled production jobs require Cluster Mode to ensure reliability against local network hiccups.'),

  ('spark_q11', 758910, 719060, 'mcq',  'senior',
   'What specifically happens to an RDD partition if a worker node fails and the data was not cached?',
   'Spark consults the Lineage Graph (DAG) and re-runs the exact sequence of transformations from the last available parent or the original source to recreate only the missing partition. This recomputation makes Spark ''resilient''.',
   'Focuses on the concept of ''Recomputation''. Verifies if the candidate knows Spark does not need to restart the entire job.',
   'Even with lineage, recomputing is expensive. Use ''.persist()'' on critical intermediate stages to speed up recovery from node failures.'),

  ('spark_q12', 758910, 719060, 'mcq',  'junior',
   'What is the standard use case for Spark ''Accumulators'' in a distributed application?',
   'Accumulators are ''write-only'' variables for executors used to aggregate counters or metrics from workers back to the Driver. A common use is counting the number of corrupted or null rows across a massive dataset.',
   'Checks understanding of ''distributed shared variables''. Verifies knowledge that executors cannot read the accumulator''s value.',
   'Use accumulators for ''side-band'' data quality checks, such as incrementing an ''error_counter'' inside a map function to track bad records.'),

  ('spark_q13', 758910, 719060, 'mcq',  'middle',
   'What event specifically triggers the creation of a new ''Stage'' in a Spark execution plan?',
   'A new Stage is created at any ''Shuffle Boundary'', which occurs when a Wide Transformation (like ''groupBy'' or ''join'') is called. Spark splits the DAG here because it must wait for all tasks in the previous stage to finish before moving data.',
   'Look for the term ''Shuffle Boundary''. Candidate should explain that shuffles are hard stops in the execution timeline.',
   'Minimize unnecessary stages in the Spark UI. Every extra stage means data was written to disk and sent over the network.'),

  ('spark_q14', 758910, 719060, 'mcq',  'senior',
   'Why might you need to manually increase ''spark.executor.memoryOverhead'' for a PySpark job using heavy machine learning libraries?',
   'MemoryOverhead is used for VM internals, interned strings, and ''off-heap'' allocations like those used by Python or C++ libraries. If libraries like TensorFlow use more than the default 10% allocation, the Cluster Manager will kill the container.',
   'Evaluates knowledge of memory regions outside the standard JVM heap. Focuses on Python worker processes.',
   'If a PySpark job crashes with ''Container killed by YARN'' but the heap seems fine, increase memoryOverhead to provide a safety zone.'),

  ('spark_q15', 758910, 719060, 'mcq',  'leader',
   'How does the Spark Driver handle task scheduling if a specific Executor becomes a ''straggler'' due to aging hardware?',
   'The Driver uses ''Speculative Execution'' to launch a duplicate copy of the slow task on a different Executor. Spark then uses the result from whichever copy finishes first and kills the remaining one, preventing one bad node from stalling the job.',
   'Looks for architectural knowledge of ''Automated Resilience''. Focuses on distinguishing hardware issues from data skew.',
   'Speculation won''t help with data skew, as the duplicate task will also be slow. It is strictly a remedy for hardware-based slowness.'),

  ('spark_q16', 758910, 719060, 'mcq',  'junior',
   'What is the primary performance benefit of ''Lazy Evaluation'' in Apache Spark?',
   'Lazy evaluation allows Spark to wait until an action is called to see the entire chain of transformations. This ''global view'' enables the Catalyst Optimizer to perform optimizations like removing columns that are never used.',
   'Identifies the concept of ''Execution Plan Optimization''. Focuses on the idea that Spark ''plans the trip'' before ''driving the car''.',
   'Lazy evaluation is why complex code often runs faster than expected by allowing Spark to skip unnecessary data reads automatically.'),

  ('spark_q17', 758910, 719060, 'mcq',  'middle',
   'What was the primary architectural goal of introducing ''SparkSession'' in Spark 2.0?',
   'SparkSession provides a unified entry point for all Spark functionality, combining SQLContext, HiveContext, and SparkContext into one object. This simplifies development and provides a cleaner API for structured data and SQL.',
   'Checks awareness of Spark''s API evolution. Focuses on the term ''Unified Entry Point''.',
   'Start all modern Spark projects by creating a ''spark'' variable via ''SparkSession.builder''. It is the standard gateway to DataFrames and SQL.'),

  ('spark_q18', 758910, 719060, 'mcma', 'senior',
   'Which of the following operations are primary causes of a ''Shuffle'' in a Spark application? Select all that apply.',
   'Shuffling occurs during Wide Transformations where data must be redistributed by key. Common examples include ''groupByKey'', ''join'', ''repartition'', and ''distinct''. These require a global view of data that is not available within a single local partition.',
   'Looks for understanding of ''Data Redistribution''. Identifies that operations requiring a global view of a key trigger shuffles.',
   'Every shuffle is a performance hit. Use ''Broadcast Joins'' or ''Bucketing'' to eliminate shuffles whenever possible to keep network traffic low.'),

  ('spark_q19', 758910, 719060, 'mcq',  'leader',
   'How does Spark integrate with YARN to manage resources in a multi-tenant enterprise environment?',
   'Spark acts as a YARN application where the Driver requests resource ''containers'' from the YARN Resource Manager. YARN allocates these slots based on availability, ensuring Spark jobs share hardware fairly with other apps.',
   'Looks for high-level resource orchestration knowledge. Focuses on the role of the Cluster Manager in shared environments.',
   'Enable ''spark.dynamicAllocation'' in shared clusters. This allows Spark to release executors when idle, making your job a ''good citizen''.'),

  ('spark_q20', 758910, 719060, 'mcq',  'middle',
   'Why is ''Kryo Serialization'' often the preferred choice over standard Java Serialization for production Spark jobs?',
   'Kryo is significantly faster and produces more compact binary objects than Java serialization. This reduces the amount of data written to disk and sent over the network during shuffles, which speeds up execution.',
   'Evaluates performance tuning depth. Focuses on ''Network Throughput'' and ''CPU Overhead''.',
   'Switching to Kryo can cut shuffle time by 20-30%. Remember to register your custom classes to get the best performance.'),

  ('spark_q21', 758910, 719060, 'mcq',  'junior',
   'What happens to a Spark application running in ''Client Mode'' if the machine that submitted the job is shut down?',
   'In Client Mode, the Driver process runs on the local submitter machine. If that machine dies, the ''brain'' of the application is lost, and the entire job on the cluster will fail because no process is left to schedule tasks.',
   'Look for the ''local Driver'' constraint. Candidate should explain why this mode is risky for long production pipelines.',
   'Use Client Mode only for testing or interactive notebooks. For critical production pipelines, use Cluster Mode to ensure reliability.'),

  ('spark_q22', 758910, 719060, 'mcq',  'senior',
   'When should a Data Engineer choose the low-level RDD API instead of the modern DataFrame/Dataset API?',
   'RDDs are appropriate only when you need ''fine-grained control'' over physical data distribution (like custom partitioning) or when you are processing unstructured, non-tabular data that does not fit a schema.',
   'Checks understanding of the trade-off between control and optimization. Focuses on ''custom logic'' versus ''Catalyst'' balance.',
   'DataFrames are the default for performance. Reserve RDDs for highly specialized algorithms or writing custom data sources.'),

  ('spark_q23', 758910, 719060, 'mcq',  'junior',
   'Which Spark component is specifically responsible for converting user code into a Directed Acyclic Graph (DAG)?',
   'The Driver Program is the central coordinator. It parses the application code, builds the logical DAG of transformations, and then hands it off to the DAG Scheduler to be split into executable stages and tasks.',
   'Look for the Driver''s role as the ''Planner''. Junior candidates should separate the planning role from the executor''s execution role.',
   'Think of the Driver as the ''Architect''. If the Architect''s plan (DAG) is too complex, executors will struggle regardless of cluster size.'),

  ('spark_q24', 758910, 719060, 'mcma', 'junior',
   'Which of the following libraries are part of the unified Apache Spark Ecosystem? Select all that apply.',
   'Spark is a unified engine that includes Spark SQL for structured data, Spark Streaming/Structured Streaming for real-time data, MLlib for machine learning, and GraphX for graph-parallel processing.',
   'Checks for general platform awareness. Candidate should know Spark is a multi-tool for various types of data workloads.',
   'Spark''s unified nature allows you to join a real-time stream with a historical SQL table in a single script for complex logic.'),

  ('spark_q25', 758910, 719060, 'mcq',  'middle',
   'Why is Apache Spark generally 100x faster than Hadoop MapReduce for iterative machine learning algorithms?',
   'Spark keeps intermediate results in RAM (in-memory) between iterations. MapReduce forces a disk write and read after every step, which creates massive I/O overhead that slows down repetitive loops.',
   'Look for the ''In-Memory'' vs ''Disk-Based'' distinction. Candidate should mention the reduction in HDFS I/O.',
   'Spark''s memory-first approach is the gold standard for ML. If your data fits in RAM, the speedup over disk-based systems is massive.')
ON CONFLICT (question_id) DO NOTHING;

-- ── 4. Insert answer options into quiz-answer-legacy-2 ───────────────────────

INSERT INTO de_mobile_app."quiz-answer-legacy-2"
  (option_id, question_id, option_text, is_correct, "order")
VALUES
  -- spark_q6
  ('spark_q6_a', 'spark_q6', 'The Driver runs out of heap memory because .collect() moves all distributed data into its single RAM pool', true,  1),
  ('spark_q6_b', 'spark_q6', 'Executor nodes run out of memory because they must serialize data before sending it', false, 2),
  ('spark_q6_c', 'spark_q6', 'The network bandwidth is saturated, causing the JVM to crash', false, 3),
  ('spark_q6_d', 'spark_q6', 'Spark cannot collect more than 10GB of data due to a built-in limit', false, 4),

  -- spark_q7
  ('spark_q7_a', 'spark_q7', 'Fewer cores mean fewer concurrent tasks, so each task gets a larger share of the executor''s memory pool', true,  1),
  ('spark_q7_b', 'spark_q7', 'Reducing cores automatically increases the executor heap size proportionally', false, 2),
  ('spark_q7_c', 'spark_q7', 'Fewer cores reduce network I/O, which prevents OOM errors during shuffles', false, 3),
  ('spark_q7_d', 'spark_q7', 'Lower core count forces Spark to use disk spill instead of RAM', false, 4),

  -- spark_q8
  ('spark_q8_a', 'spark_q8', 'Lineage tracks transformations for logical recomputation; Checkpointing physically saves data and truncates the DAG to prevent unbounded growth', true,  1),
  ('spark_q8_b', 'spark_q8', 'Lineage saves data to HDFS; Checkpointing saves data to local disk', false, 2),
  ('spark_q8_c', 'spark_q8', 'They are identical mechanisms — checkpointing is just a faster form of lineage', false, 3),
  ('spark_q8_d', 'spark_q8', 'Checkpointing is only used in Spark Streaming, not in batch jobs', false, 4),

  -- spark_q9 (mcma — multiple correct)
  ('spark_q9_a', 'spark_q9', 'map',        true,  1),
  ('spark_q9_b', 'spark_q9', 'filter',     true,  2),
  ('spark_q9_c', 'spark_q9', 'union',      true,  3),
  ('spark_q9_d', 'spark_q9', 'groupByKey', false, 4),
  ('spark_q9_e', 'spark_q9', 'join',       false, 5),

  -- spark_q10
  ('spark_q10_a', 'spark_q10', 'Cluster Mode, because the Driver runs inside the cluster and the job survives if the submitter machine disconnects', true,  1),
  ('spark_q10_b', 'spark_q10', 'Client Mode, because it gives the developer direct access to Driver logs for debugging', false, 2),
  ('spark_q10_c', 'spark_q10', 'Client Mode, because it uses fewer cluster resources', false, 3),
  ('spark_q10_d', 'spark_q10', 'Both modes are equally safe for production deployments', false, 4),

  -- spark_q11
  ('spark_q11_a', 'spark_q11', 'Spark uses the Lineage Graph to recompute only the lost partition from the last available parent data source', true,  1),
  ('spark_q11_b', 'spark_q11', 'Spark restarts the entire job from the beginning automatically', false, 2),
  ('spark_q11_c', 'spark_q11', 'The job fails immediately and requires manual intervention to restart', false, 3),
  ('spark_q11_d', 'spark_q11', 'Spark copies the partition from another executor that cached it', false, 4),

  -- spark_q12
  ('spark_q12_a', 'spark_q12', 'Aggregating write-only counters or metrics from executors back to the Driver, such as counting bad records', true,  1),
  ('spark_q12_b', 'spark_q12', 'Sharing read-write variables between executors for distributed state management', false, 2),
  ('spark_q12_c', 'spark_q12', 'Broadcasting large lookup tables to all executors to avoid shuffles', false, 3),
  ('spark_q12_d', 'spark_q12', 'Caching intermediate RDD results in executor memory', false, 4),

  -- spark_q13
  ('spark_q13_a', 'spark_q13', 'A Wide Transformation (shuffle boundary) such as groupBy or join, which requires global data redistribution', true,  1),
  ('spark_q13_b', 'spark_q13', 'Any Narrow Transformation like map or filter that processes data locally', false, 2),
  ('spark_q13_c', 'spark_q13', 'Calling .cache() or .persist() on an RDD', false, 3),
  ('spark_q13_d', 'spark_q13', 'Adding a new executor to the cluster during job execution', false, 4),

  -- spark_q14
  ('spark_q14_a', 'spark_q14', 'Python and native C++ libraries allocate off-heap memory that exceeds the default memoryOverhead budget, causing YARN to kill the container', true,  1),
  ('spark_q14_b', 'spark_q14', 'The JVM heap is too small to hold the Python bytecode for ML libraries', false, 2),
  ('spark_q14_c', 'spark_q14', 'ML libraries require more network bandwidth, which is controlled by memoryOverhead', false, 3),
  ('spark_q14_d', 'spark_q14', 'memoryOverhead controls the number of Python worker processes per executor', false, 4),

  -- spark_q15
  ('spark_q15_a', 'spark_q15', 'Speculative Execution launches a duplicate task on a healthy node and uses whichever result arrives first', true,  1),
  ('spark_q15_b', 'spark_q15', 'The Driver kills the straggler executor and redistributes its partitions to other nodes', false, 2),
  ('spark_q15_c', 'spark_q15', 'The job pauses until the slow executor finishes, then resumes normally', false, 3),
  ('spark_q15_d', 'spark_q15', 'Spark automatically increases the memory allocation for the straggler executor', false, 4),

  -- spark_q16
  ('spark_q16_a', 'spark_q16', 'It gives the Catalyst Optimizer a global view of all transformations to eliminate redundant operations before execution', true,  1),
  ('spark_q16_b', 'spark_q16', 'It allows Spark to execute transformations in parallel across all executors immediately', false, 2),
  ('spark_q16_c', 'spark_q16', 'It reduces network I/O by caching transformation results automatically', false, 3),
  ('spark_q16_d', 'spark_q16', 'It prevents the Driver from running out of memory by deferring computation', false, 4),

  -- spark_q17
  ('spark_q17_a', 'spark_q17', 'To provide a single unified entry point combining SQLContext, HiveContext, and SparkContext into one object', true,  1),
  ('spark_q17_b', 'spark_q17', 'To replace the RDD API with a faster in-memory processing engine', false, 2),
  ('spark_q17_c', 'spark_q17', 'To add native support for Python and R languages in Spark', false, 3),
  ('spark_q17_d', 'spark_q17', 'To introduce real-time streaming capabilities into the Spark ecosystem', false, 4),

  -- spark_q18 (mcma — multiple correct)
  ('spark_q18_a', 'spark_q18', 'groupByKey', true,  1),
  ('spark_q18_b', 'spark_q18', 'join',        true,  2),
  ('spark_q18_c', 'spark_q18', 'repartition', true,  3),
  ('spark_q18_d', 'spark_q18', 'distinct',    true,  4),
  ('spark_q18_e', 'spark_q18', 'map',         false, 5),
  ('spark_q18_f', 'spark_q18', 'filter',      false, 6),

  -- spark_q19
  ('spark_q19_a', 'spark_q19', 'Spark requests resource containers from the YARN Resource Manager, which allocates slots based on availability for fair sharing', true,  1),
  ('spark_q19_b', 'spark_q19', 'Spark bypasses YARN and directly manages hardware resources on each worker node', false, 2),
  ('spark_q19_c', 'spark_q19', 'YARN controls the Spark Driver and assigns tasks directly to executors', false, 3),
  ('spark_q19_d', 'spark_q19', 'Spark and YARN run independently with no direct integration', false, 4),

  -- spark_q20
  ('spark_q20_a', 'spark_q20', 'Kryo is faster and produces smaller serialized objects, reducing disk writes and network I/O during shuffles', true,  1),
  ('spark_q20_b', 'spark_q20', 'Kryo provides built-in encryption for data in transit between executors', false, 2),
  ('spark_q20_c', 'spark_q20', 'Kryo automatically compresses data using gzip before serialization', false, 3),
  ('spark_q20_d', 'spark_q20', 'Kryo eliminates the need for shuffle operations entirely', false, 4),

  -- spark_q21
  ('spark_q21_a', 'spark_q21', 'The entire job fails because the Driver process running on the local machine is lost, leaving no process to schedule tasks', true,  1),
  ('spark_q21_b', 'spark_q21', 'The cluster automatically promotes an executor to become the new Driver', false, 2),
  ('spark_q21_c', 'spark_q21', 'The job pauses and resumes automatically when the machine comes back online', false, 3),
  ('spark_q21_d', 'spark_q21', 'Only the tasks running at the time of shutdown are lost; completed tasks are preserved', false, 4),

  -- spark_q22
  ('spark_q22_a', 'spark_q22', 'When you need fine-grained control over physical data distribution or are processing unstructured data that does not fit a schema', true,  1),
  ('spark_q22_b', 'spark_q22', 'When you need the Catalyst Optimizer to automatically tune query performance', false, 2),
  ('spark_q22_c', 'spark_q22', 'When working with structured tabular data from a database or CSV files', false, 3),
  ('spark_q22_d', 'spark_q22', 'When you want to use Spark SQL syntax for data transformations', false, 4),

  -- spark_q23
  ('spark_q23_a', 'spark_q23', 'The Driver Program, which parses application code and builds the logical DAG before handing it to the DAG Scheduler', true,  1),
  ('spark_q23_b', 'spark_q23', 'The Executor, which converts bytecode into a DAG during task execution', false, 2),
  ('spark_q23_c', 'spark_q23', 'The Cluster Manager, which creates the DAG based on available resources', false, 3),
  ('spark_q23_d', 'spark_q23', 'The DAG Scheduler itself, which reads the source code directly', false, 4),

  -- spark_q24 (mcma — multiple correct)
  ('spark_q24_a', 'spark_q24', 'Spark SQL',                true,  1),
  ('spark_q24_b', 'spark_q24', 'Spark Streaming / Structured Streaming', true, 2),
  ('spark_q24_c', 'spark_q24', 'MLlib',                    true,  3),
  ('spark_q24_d', 'spark_q24', 'GraphX',                   true,  4),
  ('spark_q24_e', 'spark_q24', 'Apache Kafka',             false, 5),
  ('spark_q24_f', 'spark_q24', 'Apache Hadoop MapReduce',  false, 6),

  -- spark_q25
  ('spark_q25_a', 'spark_q25', 'Spark keeps intermediate results in RAM between iterations, avoiding the disk I/O overhead that MapReduce incurs after every step', true,  1),
  ('spark_q25_b', 'spark_q25', 'Spark uses a more efficient programming language than MapReduce', false, 2),
  ('spark_q25_c', 'spark_q25', 'Spark automatically parallelizes code that MapReduce runs sequentially', false, 3),
  ('spark_q25_d', 'spark_q25', 'Spark compresses data more efficiently than MapReduce during processing', false, 4)
ON CONFLICT (option_id) DO NOTHING;
