-- Migration: Add options and correct_answer columns to de_mobile_app."quiz-question"
-- and insert all existing hardcoded quiz questions

-- Step 1: Add missing columns to de_mobile_app."quiz-question"
ALTER TABLE de_mobile_app."quiz-question"
ADD COLUMN IF NOT EXISTS options JSONB,
ADD COLUMN IF NOT EXISTS correct_answer INTEGER;

-- Step 2: Enable RLS and add public read policy
ALTER TABLE de_mobile_app."quiz-question" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_quiz_questions" ON de_mobile_app."quiz-question";
CREATE POLICY "public_read_quiz_questions"
ON de_mobile_app."quiz-question"
FOR SELECT
TO public
USING (true);

-- Step 3: Insert all quiz questions (idempotent via ON CONFLICT on question_id)
-- Note: de_mobile_app."quiz-question" has question_id as text (nullable), use unique index approach
-- We use ON CONFLICT DO NOTHING with a DO block for safety

DO $$
BEGIN

-- ─── SQL & Query Optimization ─────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q1','sql','multiple_choice','easy',
 'Which SQL clause is used to filter aggregated results in a GROUP BY query?',
 '["HAVING","WHERE","FILTER","ON"]'::jsonb, 0,
 'HAVING filters groups after aggregation, while WHERE filters rows before aggregation. Use HAVING with aggregate functions like COUNT(), SUM(), AVG().',
 'Know the difference between WHERE and HAVING — this is a classic interview question.',
 'Remember: WHERE → rows, HAVING → groups. This distinction is frequently tested in interviews.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q2','sql','multiple_choice','hard',
 'What does the SQL window function RANK() do differently from ROW_NUMBER()?',
 '["RANK() assigns unique sequential integers; ROW_NUMBER() allows ties","RANK() operates across partitions; ROW_NUMBER() operates on the full table","RANK() requires ORDER BY; ROW_NUMBER() does not require it","RANK() leaves gaps after ties; ROW_NUMBER() never leaves gaps"]'::jsonb, 3,
 'RANK() assigns the same rank to tied rows and skips the next rank (e.g., 1,1,3). ROW_NUMBER() always assigns a unique number regardless of ties.',
 'Window functions are heavily tested at FAANG. Know RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD.',
 'RANK() = gaps after ties, DENSE_RANK() = no gaps after ties, ROW_NUMBER() = always unique.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q3','sql','multiple_choice','medium',
 'What does "partitioning" a table in a data warehouse achieve?',
 '["It encrypts specific columns for security compliance","It divides the table into smaller physical segments to speed up query performance","It creates a read-only replica of the table for analytics","It removes duplicate records before loading into the warehouse"]'::jsonb, 1,
 'Partitioning divides a large table into smaller segments (e.g., by date). Queries that filter on the partition key only scan relevant partitions, dramatically reducing I/O.',
 'Partitioning strategy is a common system design question for data engineering roles.',
 'Partition on high-cardinality columns used in WHERE clauses. Common choices: date, region, event_type.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q4','sql','multiple_choice','easy',
 'Which type of SQL JOIN returns only rows that have matching values in both tables?',
 '["LEFT JOIN","FULL OUTER JOIN","INNER JOIN","CROSS JOIN"]'::jsonb, 2,
 'INNER JOIN returns only the rows where there is a match in both tables. LEFT JOIN returns all rows from the left table plus matched rows from the right.',
 'Be ready to draw Venn diagrams for JOIN types in whiteboard interviews.',
 'INNER JOIN = intersection, LEFT JOIN = all left + matched right, FULL OUTER JOIN = union of both tables.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q5','sql','multiple_choice','easy',
 'What is the purpose of a database INDEX?',
 '["To enforce referential integrity between tables","To compress table data for storage efficiency","To speed up data retrieval by creating a lookup structure","To automatically partition large tables by date"]'::jsonb, 2,
 'An index creates a separate data structure (e.g., B-tree) that allows the database engine to find rows faster without scanning the entire table.',
 'Interviewers often ask when NOT to use an index. Know the trade-offs.',
 'Indexes speed up reads but slow down writes. Over-indexing is a common performance anti-pattern.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q6','sql','multiple_choice','medium',
 'What does the COALESCE() function do in SQL?',
 '["Concatenates multiple string columns into one","Returns the first non-NULL value from a list of expressions","Rounds a numeric value to a specified number of decimal places","Converts a NULL value to zero for arithmetic operations only"]'::jsonb, 1,
 'COALESCE() evaluates its arguments in order and returns the first non-NULL value. It is commonly used to provide default values when a column may be NULL.',
 'NULL handling is a common source of bugs. Know COALESCE, NULLIF, and IS NULL.',
 'COALESCE(col, 0) is a clean way to replace NULLs with a default. It works across all major SQL dialects.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q7','sql','multiple_choice','medium',
 'Which SQL command is used to remove all rows from a table without logging individual row deletions?',
 '["DELETE FROM table","DROP TABLE","TRUNCATE TABLE","REMOVE FROM table"]'::jsonb, 2,
 'TRUNCATE TABLE removes all rows quickly by deallocating data pages rather than logging each row deletion. It cannot be rolled back in most databases.',
 'Know the difference between DELETE, TRUNCATE, and DROP for interviews.',
 'TRUNCATE is faster than DELETE for clearing a table, but DELETE allows WHERE filtering and is fully logged.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('sql_q8','sql','multiple_choice','medium',
 'What is a CTE (Common Table Expression) in SQL?',
 '["A permanent table stored in the database schema","A temporary named result set defined within a WITH clause","A stored procedure that returns a table-valued result","A materialized view refreshed on a schedule"]'::jsonb, 1,
 'A CTE is a temporary named result set defined using the WITH keyword. It improves query readability and can be referenced multiple times within the same query.',
 'Recursive CTEs are a common advanced SQL interview topic.',
 'Recursive CTEs are powerful for hierarchical data (org charts, bill of materials). Use WITH RECURSIVE in PostgreSQL.')
ON CONFLICT DO NOTHING;

-- ─── Python for Data Engineering ──────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q1','python','multiple_choice','easy',
 'In Python, what does the pandas function df.merge() perform?',
 '["Concatenates two DataFrames vertically along rows","Removes duplicate rows from a single DataFrame","Joins two DataFrames on a common column or index","Reshapes a DataFrame from wide to long format"]'::jsonb, 2,
 'df.merge() performs SQL-style joins on DataFrames. It supports inner, left, right, and outer joins using the how parameter.',
 'pandas merge vs join vs concat is a classic Python data engineering interview question.',
 'Know the difference between merge() (SQL-join), join() (index-based), and concat() (axis stacking).')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q2','python','multiple_choice','easy',
 'What will be the output of print(bool("")) in Python?',
 '["True","None","Error","False"]'::jsonb, 3,
 'An empty string "" is falsy in Python. bool("") evaluates to False. Non-empty strings evaluate to True.',
 'Python truthiness rules are tested in coding screens. Know all falsy values.',
 'Falsy values in Python: 0, 0.0, "", [], {}, None, False. Everything else is truthy.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q3','python','multiple_choice','easy',
 'Which Python data structure provides O(1) average-case lookup time?',
 '["list","tuple","dict","deque"]'::jsonb, 2,
 'Python dictionaries use hash tables internally, providing O(1) average-case time complexity for get, set, and delete operations.',
 'Time complexity of Python data structures is a common interview topic.',
 'Use dict for fast lookups, set for membership tests, list for ordered sequences.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q4','python','multiple_choice','medium',
 'What does the @staticmethod decorator do in a Python class?',
 '["Marks a method that can only be called on the class, not instances","Defines a method that does not receive the class or instance as the first argument","Prevents the method from being overridden in subclasses","Caches the method result for repeated calls with the same arguments"]'::jsonb, 1,
 '@staticmethod defines a method that belongs to the class namespace but does not receive self or cls. It behaves like a regular function scoped inside a class.',
 'Know the difference between @staticmethod, @classmethod, and instance methods.',
 '@staticmethod = no self/cls, @classmethod = receives cls, regular method = receives self.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q5','python','multiple_choice','medium',
 'In PySpark, what is the difference between a transformation and an action?',
 '["Transformations write data to disk; actions keep data in memory","Transformations are lazy and build a DAG; actions trigger execution","Transformations run on the driver; actions run on executors","Transformations require a schema; actions work on unstructured data"]'::jsonb, 1,
 'PySpark transformations (filter, select, map) are lazy — they build an execution plan (DAG) without running. Actions (collect, count, show) trigger the actual computation.',
 'Lazy evaluation is a core Spark concept tested in every data engineering interview.',
 'Transformations = lazy (filter, map, select). Actions = trigger execution (collect, count, show, write).')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q6','python','multiple_choice','easy',
 'Which pandas method is used to apply a function element-wise to a DataFrame column?',
 '["df.apply()","df.map()","df.transform()","df.applymap()"]'::jsonb, 0,
 'df[col].apply() applies a function to each element of a Series. df.apply() can apply a function along rows or columns of a DataFrame.',
 'Know when to use apply vs map vs applymap for pandas operations.',
 'For Series: use .map() or .apply(). For DataFrame row/column-wise: use .apply().')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q7','python','multiple_choice','medium',
 'What is a Python generator and why is it useful for large data processing?',
 '["A class that automatically generates test data for unit tests","A function that uses yield to produce values lazily, one at a time","A built-in that creates a list from a range of integers","A decorator that converts a function into a parallel process"]'::jsonb, 1,
 'Generators use yield to produce values one at a time without loading the entire dataset into memory. This is ideal for processing large files or streams in data pipelines.',
 'Generators are a memory-efficiency pattern commonly asked about in data engineering interviews.',
 'Use generators when processing files line-by-line or streaming API responses.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('py_q8','python','multiple_choice','easy',
 'In PySpark, which function is used to read a CSV file into a DataFrame?',
 '["spark.read.csv()","spark.load.csv()","SparkContext.textFile()","spark.import.csv()"]'::jsonb, 0,
 'spark.read.csv() reads a CSV file into a Spark DataFrame. You can pass options like header=True and inferSchema=True for automatic schema detection.',
 'Know the Spark DataFrameReader API for reading various file formats.',
 'Always set inferSchema=True or define a schema explicitly. Avoid inferSchema on large files in production.')
ON CONFLICT DO NOTHING;

-- ─── ETL Pipelines & Workflows ────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('etl_q1','etl','multiple_choice','medium',
 'In an ETL pipeline, what does "idempotency" mean?',
 '["Running the pipeline multiple times produces the same result","The pipeline executes in parallel across multiple nodes","The pipeline handles schema changes automatically","Data is loaded incrementally rather than in full batches"]'::jsonb, 0,
 'An idempotent pipeline produces the same output regardless of how many times it runs. Critical for fault-tolerant systems where retries are common.',
 'Idempotency is a must-know concept for data engineering system design interviews.',
 'Design ETL jobs with idempotency by using UPSERT operations and tracking watermarks.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('etl_q2','etl','multiple_choice','medium',
 'What is "data lineage" in a data engineering context?',
 '["The ability to track the origin, movement, and transformation of data through a pipeline","The process of compressing historical data to reduce storage costs","A method for encrypting PII data before it is stored","The schema versioning system used in a data warehouse"]'::jsonb, 0,
 'Data lineage tracks where data comes from, how it has been transformed, and where it goes. It is essential for debugging, compliance (GDPR), and impact analysis.',
 'Data lineage tools and concepts are frequently asked in senior data engineering interviews.',
 'Tools: Apache Atlas, OpenLineage, dbt lineage graph, DataHub.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('etl_q3','etl','multiple_choice','easy',
 'What is the difference between ETL and ELT in modern data pipelines?',
 '["ETL transforms data before loading; ELT loads raw data first then transforms in the warehouse","ETL is batch-only; ELT supports real-time streaming","ETL uses cloud storage; ELT uses on-premise databases","ETL is for structured data; ELT is for unstructured data only"]'::jsonb, 0,
 'ETL transforms data before loading it into the target. ELT loads raw data into the warehouse first, then uses the warehouse compute power to transform it. ELT is preferred with modern cloud warehouses.',
 'ETL vs ELT is a foundational question in every data engineering interview.',
 'ELT is favored with Snowflake, BigQuery, Redshift because warehouse compute is cheap and scalable.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('etl_q4','etl','multiple_choice','medium',
 'What is a "watermark" in the context of incremental data loading?',
 '["A digital signature applied to data files for security auditing","A timestamp or sequence value used to track the last successfully processed record","A checksum that validates data integrity after each pipeline run","A schema version tag appended to each record during transformation"]'::jsonb, 1,
 'A watermark is a high-water mark (typically a timestamp or ID) that tracks the last record processed. Incremental loads use it to fetch only new or changed records since the last run.',
 'Watermark-based incremental loading is a core ETL pattern asked in system design rounds.',
 'Store watermarks in a metadata table. Always use UTC timestamps to avoid timezone issues.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('etl_q5','etl','multiple_choice','hard',
 'Which strategy is best for handling schema evolution in an ETL pipeline?',
 '["Fail the pipeline immediately on any schema change","Ignore new columns and only process known fields","Use schema registries and backward-compatible schema evolution policies","Reload the entire dataset from scratch on every schema change"]'::jsonb, 2,
 'Schema registries (like Confluent Schema Registry) enforce compatibility rules (backward, forward, full) so pipelines can evolve without breaking downstream consumers.',
 'Schema evolution handling is a senior-level question that tests real-world pipeline experience.',
 'Backward compatibility = new schema can read old data. Forward compatibility = old schema can read new data.')
ON CONFLICT DO NOTHING;

-- ─── Apache Spark & Big Data ──────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('spark_q1','spark','multiple_choice','medium',
 'Which Spark transformation is "lazy" — meaning it does not execute immediately?',
 '["collect()","filter()","count()","show()"]'::jsonb, 1,
 'filter() is a transformation in Spark and is lazy — it builds the execution plan but does not run until an action (like collect() or count()) is called.',
 'Lazy evaluation and the DAG execution model are core Spark interview topics.',
 'Transformations (map, filter, select) = lazy. Actions (collect, count, show) = trigger execution.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('spark_q2','spark','multiple_choice','medium',
 'What is the purpose of cache() in PySpark?',
 '["Writes the DataFrame to disk as a Parquet file","Stores the DataFrame in memory to avoid recomputation on repeated access","Compresses the DataFrame to reduce shuffle data size","Broadcasts the DataFrame to all worker nodes for join optimization"]'::jsonb, 1,
 'cache() persists a DataFrame in memory (default storage level: MEMORY_AND_DISK). It avoids recomputing the same transformation DAG on repeated actions.',
 'Know when to use cache() vs persist() and the different storage levels.',
 'Use cache() when a DataFrame is used multiple times. Call unpersist() when done to free memory.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('spark_q3','spark','multiple_choice','hard',
 'What is a Spark "shuffle" and why is it expensive?',
 '["A shuffle reorders partitions alphabetically to improve sort performance","A shuffle moves data across the network between executors to redistribute it by key","A shuffle compresses data before writing to HDFS","A shuffle merges small files into larger ones to reduce metadata overhead"]'::jsonb, 1,
 'A shuffle occurs when Spark needs to redistribute data across partitions (e.g., during groupBy, join, distinct). It involves network I/O and disk writes, making it the most expensive operation.',
 'Shuffle optimization is a key performance tuning topic in Spark interviews.',
 'Minimize shuffles by using broadcast joins for small tables, partitioning data on join keys.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('spark_q4','spark','multiple_choice','medium',
 'What does repartition() do in PySpark?',
 '["Reduces the number of partitions by merging adjacent ones without a shuffle","Increases or decreases partitions by performing a full shuffle of the data","Splits a single large partition into two equal halves","Reorders rows within each partition by a specified column"]'::jsonb, 1,
 'repartition() performs a full shuffle to redistribute data into the specified number of partitions. Use coalesce() instead when only reducing partitions to avoid the shuffle.',
 'repartition vs coalesce is a classic Spark performance question.',
 'repartition(n) = full shuffle. coalesce(n) = no shuffle (use to reduce partitions efficiently).')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('spark_q5','spark','multiple_choice','hard',
 'What is a broadcast join in Spark?',
 '["A join that sends query results to all connected BI tools simultaneously","A join where a small DataFrame is copied to every executor to avoid shuffling the large DataFrame","A join that runs across multiple Spark clusters in parallel","A join that caches both DataFrames in memory before execution"]'::jsonb, 1,
 'A broadcast join copies the smaller DataFrame to every executor node. This eliminates the shuffle of the large DataFrame, making it much faster for small-large table joins.',
 'Broadcast join optimization is a must-know for Spark performance interviews.',
 'Use broadcast() hint when joining a large table with a small lookup table (< 10 MB by default).')
ON CONFLICT DO NOTHING;

-- ─── Kafka & Streaming Data ───────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('kafka_q1','kafka','multiple_choice','hard',
 'In Kafka, what is a "consumer group"?',
 '["A set of producers writing to the same topic partition","A cluster of Kafka brokers sharing the same configuration","A group of consumers that collectively read from a topic, each partition assigned to one consumer","A schema registry group for managing Avro message schemas"]'::jsonb, 2,
 'A consumer group allows parallel consumption: each partition is consumed by exactly one consumer in the group. This enables horizontal scaling of message processing.',
 'Consumer groups and partition assignment are core Kafka interview topics.',
 'If consumers > partitions, some consumers will be idle. Scale partitions to match your consumer parallelism needs.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('kafka_q2','kafka','multiple_choice','medium',
 'What is the role of a Kafka "offset"?',
 '["The byte position of a message within a compressed batch","A unique sequential ID that tracks a consumer position within a partition","The replication factor assigned to a topic partition","The time-to-live setting for messages before they are deleted"]'::jsonb, 1,
 'An offset is a sequential ID assigned to each message within a partition. Consumers track their offset to know which messages have been processed and where to resume after a restart.',
 'Offset management and delivery guarantees are key Kafka interview topics.',
 'Committing offsets too early risks message loss; too late risks reprocessing.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('kafka_q3','kafka','multiple_choice','easy',
 'What does Kafka retention period control?',
 '["How long a consumer group can remain inactive before being removed","The maximum size of a single Kafka message in bytes","How long messages are kept in a topic before being deleted","The number of replicas maintained for each partition"]'::jsonb, 2,
 'The retention period (log.retention.hours or log.retention.bytes) controls how long Kafka keeps messages. After the period expires, old messages are deleted to free disk space.',
 'Know the difference between time-based and size-based retention in Kafka.',
 'Default retention is 7 days. For event sourcing or audit logs, increase retention or use log compaction.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('kafka_q4','kafka','multiple_choice','hard',
 'What is Kafka log compaction?',
 '["Compresses message payloads using gzip to reduce storage","Merges multiple small log segments into a single large file","Retains only the most recent message per key, removing older duplicates","Deletes all messages older than the configured retention period"]'::jsonb, 2,
 'Log compaction ensures that Kafka retains at least the last known value for each message key. It is useful for changelog topics where only the latest state matters.',
 'Log compaction vs retention is a common advanced Kafka interview question.',
 'Use log compaction for CDC (Change Data Capture) topics and state store changelogs in Kafka Streams.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('kafka_q5','kafka','multiple_choice','medium',
 'What is the purpose of a Kafka Schema Registry?',
 '["To store Kafka broker configuration and topic metadata","To manage and enforce Avro/Protobuf/JSON schemas for Kafka messages","To monitor consumer lag and alert on processing delays","To replicate topics across multiple Kafka clusters"]'::jsonb, 1,
 'The Schema Registry stores and validates message schemas. Producers and consumers use it to serialize/deserialize messages consistently, preventing schema incompatibilities.',
 'Schema Registry is a must-know for production Kafka deployments.',
 'Always use a Schema Registry in production Kafka deployments.')
ON CONFLICT DO NOTHING;

-- ─── Apache Airflow & Orchestration ──────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('airflow_q1','airflow','multiple_choice','easy',
 'In Apache Airflow, what is a DAG?',
 '["A database configuration file for Airflow metadata","A Docker container running an Airflow worker node","A Directed Acyclic Graph that defines task dependencies and execution order","A data validation rule applied to incoming datasets"]'::jsonb, 2,
 'A DAG (Directed Acyclic Graph) in Airflow defines a workflow: tasks as nodes, dependencies as directed edges. "Acyclic" means no circular dependencies.',
 'DAG concepts and Airflow architecture are foundational interview topics.',
 'Key DAG parameters: schedule_interval, start_date, catchup, max_active_runs.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('airflow_q2','airflow','multiple_choice','medium',
 'What does the catchup parameter do in an Airflow DAG?',
 '["Retries failed tasks automatically up to a configured limit","Runs all missed DAG executions between start_date and today when enabled","Sends email alerts when a DAG run exceeds its SLA","Pauses the DAG if upstream dependencies are not met"]'::jsonb, 1,
 'When catchup=True, Airflow backfills all missed DAG runs from start_date to the current date. Set catchup=False to only run the most recent interval.',
 'catchup=True causing unexpected backfill runs is a common production incident topic.',
 'Always set catchup=False for new DAGs unless you explicitly need backfilling.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('airflow_q3','airflow','multiple_choice','medium',
 'What is an Airflow "sensor"?',
 '["A monitoring agent that tracks DAG execution metrics","A task that waits for an external condition to be met before proceeding","A plugin that connects Airflow to external data sources","A scheduler component that triggers DAG runs on a cron schedule"]'::jsonb, 1,
 'Sensors are special operators that poll for a condition (e.g., file arrival, API response, database record) and block the DAG until the condition is satisfied.',
 'Sensors and their modes (poke vs reschedule) are commonly asked in Airflow interviews.',
 'Use poke_interval and timeout on sensors. For long waits, use mode="reschedule" to free the worker slot.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('airflow_q4','airflow','multiple_choice','easy',
 'What is the difference between PythonOperator and BashOperator in Airflow?',
 '["PythonOperator runs Python functions; BashOperator executes shell commands","PythonOperator runs on the scheduler; BashOperator runs on workers","PythonOperator supports retries; BashOperator does not","PythonOperator is for ETL tasks; BashOperator is for monitoring tasks"]'::jsonb, 0,
 'PythonOperator executes a Python callable within the Airflow worker. BashOperator runs a bash command or script in a subprocess on the worker node.',
 'Know the common Airflow operators and when to use each.',
 'Prefer PythonOperator for complex logic. Use BashOperator for simple shell scripts.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('airflow_q5','airflow','multiple_choice','easy',
 'What does task_id uniqueness requirement mean in Airflow DAGs?',
 '["Each task must have a globally unique ID across all DAGs in the system","Each task_id must be unique within its own DAG","task_id must match the Python function name exactly","task_id must be a UUID to prevent naming conflicts"]'::jsonb, 1,
 'task_id must be unique within a single DAG. The same task_id can exist in different DAGs. Duplicate task_ids within a DAG will raise an error.',
 'DAG structure and task naming conventions are tested in Airflow interviews.',
 'Use descriptive task_ids like "extract_orders_from_postgres" rather than generic names like "task1".')
ON CONFLICT DO NOTHING;

-- ─── dbt & Data Transformation ────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dbt_q1','dbt','multiple_choice','medium',
 'Which dbt command runs and tests your models in one step?',
 '["dbt compile","dbt run --test","dbt execute","dbt build"]'::jsonb, 3,
 'dbt build runs models, seeds, snapshots, and tests in dependency order. It is the recommended command for full pipeline execution.',
 'Know the dbt CLI commands and what each does.',
 'dbt run = execute models only. dbt test = run tests only. dbt build = run + test + seed + snapshot.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dbt_q2','dbt','multiple_choice','easy',
 'What is a dbt ref() function used for?',
 '["To reference an external API endpoint for data enrichment","To create a reference to another dbt model, enabling dependency tracking","To define a foreign key relationship in the warehouse schema","To import a Python function into a dbt macro"]'::jsonb, 1,
 'ref() is how dbt models reference each other. It resolves the correct schema/table name and builds the dependency graph for ordered execution.',
 'ref() vs source() is a common dbt interview question.',
 'Always use ref() instead of hardcoding table names. It enables environment-aware compilation.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dbt_q3','dbt','multiple_choice','medium',
 'What is the purpose of dbt "sources"?',
 '["To define raw data tables loaded by external tools that dbt does not manage","To store dbt model output in a separate source schema","To configure the data warehouse connection credentials","To define reusable SQL snippets shared across multiple models"]'::jsonb, 0,
 'dbt sources define raw tables that are loaded by external tools (e.g., Fivetran, Airbyte). They enable freshness checks and allow models to reference raw tables using source().',
 'Understanding dbt sources and freshness checks is important for production dbt deployments.',
 'Use source() for raw tables and ref() for dbt-managed models. Add freshness checks to sources.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dbt_q4','dbt','multiple_choice','hard',
 'What does the dbt materialization type "incremental" do?',
 '["Drops and recreates the table on every dbt run","Creates a view that is recomputed on every query","Appends or upserts only new/changed rows since the last run","Stores the model as a temporary table that expires after the session"]'::jsonb, 2,
 'Incremental models process only new or changed rows using a filter (is_incremental() macro). This dramatically reduces compute costs for large tables.',
 'Incremental materialization strategy is a key dbt interview topic.',
 'Use unique_key with incremental models to enable upserts. Always test your incremental logic with --full-refresh periodically.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dbt_q5','dbt','multiple_choice','easy',
 'What are dbt "tests" and what do they validate?',
 '["Unit tests that validate Python transformation logic in dbt models","SQL assertions that validate data quality constraints like uniqueness and not-null","Performance benchmarks that measure query execution time","Schema migration scripts that validate column type changes"]'::jsonb, 1,
 'dbt tests are SQL assertions run against model outputs. Built-in tests include unique, not_null, accepted_values, and relationships. Custom tests can be written as SQL.',
 'dbt testing strategy is a common interview topic for data quality discussions.',
 'Run dbt test after every dbt run in CI/CD. Add not_null and unique tests to all primary key columns.')
ON CONFLICT DO NOTHING;

-- ─── Data Modeling & Warehousing ──────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dm_q1','datamodeling','multiple_choice','hard',
 'What is a "slowly changing dimension" (SCD Type 2) in data warehousing?',
 '["A dimension that never changes after the initial load","A dimension that overwrites the old value with the new value","A dimension that adds a new column to track the previous value","A dimension that stores historical records by adding new rows for each change"]'::jsonb, 3,
 'SCD Type 2 maintains full history by inserting a new row with updated values and marking the old row as inactive with an end date.',
 'SCD types are a classic data warehousing interview question.',
 'SCD Type 1 = overwrite, Type 2 = new row + history, Type 3 = add column for previous value.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dm_q2','datamodeling','multiple_choice','easy',
 'In a star schema, what is the role of a "fact table"?',
 '["It stores descriptive attributes about business entities","It defines the primary keys for all dimension tables","It stores measurable, quantitative data about business events","It contains the ETL audit log for each data load cycle"]'::jsonb, 2,
 'Fact tables store business events (sales, clicks, transactions) with numeric measures (revenue, quantity) and foreign keys to dimension tables.',
 'Star schema design is a foundational data warehousing interview topic.',
 'Fact table = numbers + foreign keys. Dimension table = descriptive attributes.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dm_q3','datamodeling','multiple_choice','medium',
 'What is the main difference between a Star Schema and a Snowflake Schema?',
 '["Star Schema uses columnar storage; Snowflake Schema uses row-based storage","Star Schema has denormalized dimensions; Snowflake Schema normalizes dimensions into sub-tables","Star Schema supports only OLTP; Snowflake Schema supports only OLAP","Star Schema requires a cloud warehouse; Snowflake Schema works on-premise only"]'::jsonb, 1,
 'In a Star Schema, dimension tables are denormalized (flat). In a Snowflake Schema, dimensions are normalized into multiple related tables, reducing redundancy but increasing join complexity.',
 'Star vs Snowflake schema trade-offs are commonly discussed in data warehouse design interviews.',
 'Star Schema = simpler queries, more storage. Snowflake Schema = less storage, more complex joins.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dm_q4','datamodeling','multiple_choice','medium',
 'What is "schema-on-read" as used in data lakes?',
 '["The schema is defined and enforced when data is written to storage","The schema is applied when data is read, allowing raw storage without upfront structure","The schema is automatically inferred from column names at write time","The schema is validated against a central registry before each query"]'::jsonb, 1,
 'Schema-on-read stores raw data without enforcing structure at write time. The schema is applied only when the data is queried, providing flexibility for diverse data sources.',
 'Schema-on-read vs schema-on-write is a key data lake vs data warehouse distinction.',
 'Data lakes use schema-on-read (flexible). Data warehouses use schema-on-write (enforced).')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dm_q5','datamodeling','multiple_choice','medium',
 'What is the primary difference between OLTP and OLAP systems?',
 '["OLTP handles real-time transactional writes; OLAP is optimized for analytical read queries","OLTP is cloud-based only; OLAP runs exclusively on-premise","OLTP uses columnar storage; OLAP uses row-based storage","OLTP supports only SQL; OLAP supports NoSQL queries"]'::jsonb, 0,
 'OLTP (Online Transaction Processing) is optimized for high-frequency writes and reads of individual records. OLAP (Online Analytical Processing) is optimized for complex aggregation queries over large datasets.',
 'OLTP vs OLAP is a foundational question in every data engineering interview.',
 'OLTP = many small transactions (banking), OLAP = few large analytical queries (BI dashboards).')
ON CONFLICT DO NOTHING;

-- ─── Cloud Data Platforms ─────────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('cloud_q1','cloud','multiple_choice','easy',
 'What is Amazon S3 primarily used for in a data engineering context?',
 '["Running distributed SQL queries on structured data","Storing raw and processed data files as a scalable object store","Orchestrating ETL workflows with a visual pipeline editor","Providing a managed Kafka service for event streaming"]'::jsonb, 1,
 'Amazon S3 is an object storage service used as the foundation of data lakes. It stores raw files (CSV, Parquet, JSON) cheaply and integrates with virtually every AWS analytics service.',
 'S3 as a data lake foundation is a core AWS data engineering concept.',
 'Use S3 as your data lake landing zone. Organize with prefixes like s3://bucket/raw/year=2024/month=01/.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('cloud_q2','cloud','multiple_choice','medium',
 'What is Google BigQuery key architectural advantage over traditional databases?',
 '["It stores data in row-based format for fast transactional writes","It separates compute and storage, enabling serverless columnar analytics at scale","It provides built-in machine learning without any SQL knowledge","It replicates data across all global regions automatically at no cost"]'::jsonb, 1,
 'BigQuery separates storage (Colossus) from compute (Dremel). This serverless architecture allows it to scale query compute independently and charge only for bytes scanned.',
 'BigQuery architecture is commonly asked in GCP data engineering interviews.',
 'Use partitioned and clustered tables in BigQuery to reduce bytes scanned and lower query costs.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('cloud_q3','cloud','multiple_choice','medium',
 'What is AWS Glue primarily used for?',
 '["Hosting containerized microservices on managed Kubernetes","A serverless ETL service for discovering, cataloging, and transforming data","A managed Spark cluster service for real-time stream processing","A NoSQL database optimized for high-throughput key-value operations"]'::jsonb, 1,
 'AWS Glue is a serverless ETL service. It includes a Data Catalog for metadata management, crawlers for schema discovery, and a managed Spark environment for data transformation.',
 'AWS Glue vs EMR vs Lambda for ETL is a common AWS interview question.',
 'Use Glue Crawlers to auto-discover schemas in S3. The Glue Data Catalog integrates with Athena, Redshift Spectrum, and EMR.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('cloud_q4','cloud','multiple_choice','hard',
 'What is the purpose of Snowflake virtual warehouse?',
 '["A logical namespace for organizing database objects like tables and views","An independent compute cluster that processes queries without affecting storage","A backup storage tier for archiving historical data at lower cost","A shared cache layer that speeds up repeated queries across all users"]'::jsonb, 1,
 'A Snowflake virtual warehouse is an independent compute cluster (MPP engine). Multiple warehouses can run simultaneously against the same data without contention.',
 'Snowflake virtual warehouse sizing and cost optimization are common interview topics.',
 'Use separate virtual warehouses for ETL loads and BI queries to prevent resource contention.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('cloud_q5','cloud','multiple_choice','hard',
 'What does "data lakehouse" architecture combine?',
 '["The low cost of tape storage with the speed of in-memory databases","The flexibility of a data lake with the ACID transactions and governance of a data warehouse","The scalability of NoSQL with the query language of SQL databases","The batch processing of Hadoop with the real-time processing of Flink"]'::jsonb, 1,
 'A data lakehouse (e.g., Delta Lake, Apache Iceberg, Apache Hudi) adds ACID transactions, schema enforcement, and BI-quality performance on top of cheap object storage.',
 'Lakehouse architecture is a hot topic in modern data engineering interviews.',
 'Delta Lake (Databricks), Apache Iceberg (Netflix/Apple), and Apache Hudi (Uber) are the three major open table formats.')
ON CONFLICT DO NOTHING;

-- ─── NoSQL Databases ──────────────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('nosql_q1','nosql','multiple_choice','hard',
 'What does the CAP theorem state about distributed databases?',
 '["A distributed system can guarantee Consistency, Availability, and Partition tolerance simultaneously","A distributed system can guarantee at most two of: Consistency, Availability, Partition tolerance","A distributed system must sacrifice Availability to achieve Consistency","A distributed system can achieve all three guarantees with eventual consistency"]'::jsonb, 1,
 'CAP theorem states that a distributed system can only guarantee two of three properties: Consistency, Availability, and Partition tolerance.',
 'CAP theorem is a foundational distributed systems interview question.',
 'CP systems (HBase, Zookeeper) sacrifice availability. AP systems (Cassandra, DynamoDB) sacrifice consistency.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('nosql_q2','nosql','multiple_choice','easy',
 'What type of NoSQL database is MongoDB?',
 '["Key-value store","Column-family store","Document store","Graph database"]'::jsonb, 2,
 'MongoDB is a document store that stores data as JSON-like BSON documents. Each document can have a different structure, providing schema flexibility.',
 'Know the four main NoSQL database types and their use cases.',
 'Document stores (MongoDB, CouchDB) = flexible schema. Key-value (Redis, DynamoDB) = fast lookups.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('nosql_q3','nosql','multiple_choice','medium',
 'What is "eventual consistency" in distributed databases?',
 '["Data is immediately consistent across all nodes after every write","The system guarantees that all nodes will eventually converge to the same value given no new updates","Consistency is enforced only during business hours to reduce latency","The database rolls back inconsistent writes automatically after a timeout"]'::jsonb, 1,
 'Eventual consistency means that if no new updates are made, all replicas will eventually converge to the same value. It trades strong consistency for higher availability and lower latency.',
 'Consistency models are a key distributed systems interview topic.',
 'Cassandra and DynamoDB use eventual consistency by default. Use quorum reads/writes when stronger consistency is needed.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('nosql_q4','nosql','multiple_choice','easy',
 'What is Redis primarily used for in data engineering pipelines?',
 '["Long-term archival of large datasets in compressed format","In-memory caching, session storage, and real-time pub/sub messaging","Running complex analytical SQL queries on structured data","Storing graph relationships between entities for recommendation engines"]'::jsonb, 1,
 'Redis is an in-memory data structure store used for caching (reduce database load), session management, rate limiting, and pub/sub messaging between pipeline components.',
 'Redis use cases in data pipelines are commonly asked in system design interviews.',
 'Redis TTL (time-to-live) is essential for cache invalidation. Use Redis Streams for lightweight event streaming.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('nosql_q5','nosql','multiple_choice','medium',
 'What is the primary data model of Apache Cassandra?',
 '["Document model with nested JSON objects","Wide-column model with rows identified by partition keys","Graph model with nodes and edges","Relational model with normalized tables and foreign keys"]'::jsonb, 1,
 'Cassandra uses a wide-column model where data is organized by partition key (determines node placement) and clustering columns (determines row ordering within a partition).',
 'Cassandra data modeling and partition key design are key interview topics.',
 'Design Cassandra tables around your query patterns, not your data model. Denormalization is expected.')
ON CONFLICT DO NOTHING;

-- ─── Docker & Containerization ────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('docker_q1','docker','multiple_choice','easy',
 'What is the difference between a Docker image and a Docker container?',
 '["An image is a running process; a container is a static snapshot","An image is a read-only template; a container is a running instance of that image","An image is stored in a registry; a container is stored on the host filesystem","An image contains only the application code; a container includes the OS kernel"]'::jsonb, 1,
 'A Docker image is a read-only blueprint (layers of filesystem changes). A container is a running instance of an image with a writable layer on top.',
 'Image vs container distinction is a foundational Docker interview question.',
 'Images are immutable and shareable. Containers are ephemeral. Use volumes to persist data.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('docker_q2','docker','multiple_choice','medium',
 'What does the ENTRYPOINT instruction do in a Dockerfile?',
 '["Sets the working directory for all subsequent RUN commands","Defines the default executable that runs when the container starts","Copies files from the host into the container image","Exposes a network port for the container to listen on"]'::jsonb, 1,
 'ENTRYPOINT defines the main command that runs when a container starts. Unlike CMD, ENTRYPOINT is not easily overridden at runtime, making it suitable for defining the container primary purpose.',
 'ENTRYPOINT vs CMD is a common Docker interview question.',
 'Use ENTRYPOINT for the main process and CMD for default arguments.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('docker_q3','docker','multiple_choice','easy',
 'What is the purpose of Docker Compose?',
 '["To build optimized multi-stage Docker images for production","To define and run multi-container applications with a single YAML configuration","To push Docker images to a remote container registry","To monitor resource usage of running containers in real time"]'::jsonb, 1,
 'Docker Compose uses a docker-compose.yml file to define multi-container applications (e.g., app + database + cache). A single docker-compose up starts all services.',
 'Docker Compose is commonly used in local development and is asked about in DevOps interviews.',
 'Docker Compose is ideal for local development. For production orchestration, use Kubernetes or Docker Swarm.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('docker_q4','docker','multiple_choice','easy',
 'What is a Docker volume used for?',
 '["To limit the CPU and memory resources available to a container","To persist data generated by containers beyond their lifecycle","To expose container ports to the host network","To share environment variables between multiple containers"]'::jsonb, 1,
 'Docker volumes persist data outside the container writable layer. When a container is removed, volume data remains. Volumes are the recommended way to handle stateful data.',
 'Docker volume types and use cases are commonly asked in containerization interviews.',
 'Use named volumes for databases and bind mounts for development code.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('docker_q5','docker','multiple_choice','medium',
 'What is a multi-stage Docker build?',
 '["A build that runs on multiple machines in parallel to speed up compilation","A Dockerfile technique that uses multiple FROM instructions to produce a smaller final image","A CI/CD pipeline that builds images for multiple target platforms simultaneously","A build process that creates separate images for development and testing environments"]'::jsonb, 1,
 'Multi-stage builds use multiple FROM instructions. Earlier stages compile/build the application; the final stage copies only the necessary artifacts, producing a lean production image.',
 'Multi-stage builds are a Docker best practice asked in DevOps and data engineering interviews.',
 'Multi-stage builds can reduce image size from GBs to MBs by excluding build tools and compilers.')
ON CONFLICT DO NOTHING;

-- ─── DataOps & CI/CD for Data ─────────────────────────────────────────────
INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dataops_q1','dataops','multiple_choice','easy',
 'What is the primary goal of DataOps?',
 '["To replace manual data engineering work with automated machine learning","To apply DevOps principles (automation, collaboration, monitoring) to data pipelines","To centralize all data processing in a single cloud provider","To eliminate the need for data quality testing in production pipelines"]'::jsonb, 1,
 'DataOps applies DevOps practices — CI/CD, automated testing, monitoring, and collaboration — to data pipelines to improve speed, quality, and reliability of data delivery.',
 'DataOps principles are increasingly asked in senior data engineering interviews.',
 'DataOps = DevOps for data. Key practices: automated data quality tests, pipeline CI/CD, observability.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dataops_q2','dataops','multiple_choice','medium',
 'What does "data observability" mean in a DataOps context?',
 '["The ability to visually monitor data flowing through a pipeline in real time","The ability to understand the health, freshness, and quality of data across the pipeline","A compliance framework for auditing data access and usage","A monitoring tool that tracks query performance in a data warehouse"]'::jsonb, 1,
 'Data observability covers five pillars: freshness, volume, distribution, schema, and lineage.',
 'Data observability is a hot topic in modern data engineering interviews.',
 'Tools: Monte Carlo, Bigeye, Great Expectations, dbt tests. Implement observability before incidents happen.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dataops_q3','dataops','multiple_choice','medium',
 'What is the purpose of data quality testing in a CI/CD pipeline for data?',
 '["To measure the performance of SQL queries before deployment","To automatically validate data correctness and catch regressions before they reach production","To enforce access control policies on sensitive data columns","To generate synthetic test data for development environments"]'::jsonb, 1,
 'Data quality tests in CI/CD catch issues (null values, schema drift, unexpected distributions) before bad data reaches downstream consumers or production dashboards.',
 'Data quality in CI/CD is a key DataOps interview topic.',
 'Use Great Expectations or dbt tests in your CI pipeline. Block merges if critical data quality checks fail.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dataops_q4','dataops','multiple_choice','hard',
 'What is "infrastructure as code" (IaC) and why is it important for DataOps?',
 '["Writing Python scripts to automate data transformation logic","Defining and provisioning infrastructure using configuration files instead of manual processes","Using SQL to define database schemas and table structures","Storing pipeline configuration in environment variables for portability"]'::jsonb, 1,
 'IaC (Terraform, Pulumi, CloudFormation) defines infrastructure in version-controlled files. This enables reproducible environments, automated provisioning, and rollback capabilities.',
 'IaC tools and concepts are commonly asked in senior data engineering and DevOps interviews.',
 'Store Terraform state remotely (S3 + DynamoDB lock). Use workspaces for dev/staging/prod environments.')
ON CONFLICT DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, options, correct_answer, explanation, interview_tips, pro_tips)
VALUES
('dataops_q5','dataops','multiple_choice','hard',
 'What is a "data contract" in modern data engineering?',
 '["A legal agreement between data vendors and data consumers","A formal agreement between data producers and consumers defining schema, SLAs, and quality expectations","A configuration file that maps source columns to target columns in an ETL pipeline","A database constraint that enforces referential integrity between tables"]'::jsonb, 1,
 'A data contract is a formal specification (schema, semantics, SLAs, quality rules) agreed upon between data producers and consumers. It prevents breaking changes and sets clear expectations.',
 'Data contracts are an emerging best practice increasingly asked in senior data engineering interviews.',
 'Tools like Soda, Great Expectations, and custom OpenAPI specs are used to define and enforce data contracts.')
ON CONFLICT DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Quiz question insertion failed: %', SQLERRM;
END $$;
