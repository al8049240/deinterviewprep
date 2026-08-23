-- Migration: Insert all quiz questions (with remapped difficulty) and answers
-- into de_mobile_app."quiz-question" and de_mobile_app."quiz-answer"
-- Difficulty mapping: easy → junior, medium → middle, hard → senior, (very hard → leader)
-- No columns are added or altered — strictly working within the defined schema.

-- Step 1: Ensure RLS is enabled and public read policy exists on quiz-answer
ALTER TABLE de_mobile_app."quiz-answer" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_quiz_answers" ON de_mobile_app."quiz-answer";
CREATE POLICY "public_read_quiz_answers"
ON de_mobile_app."quiz-answer"
FOR SELECT
TO public
USING (true);

-- Step 2: Ensure public read policy exists on quiz-question (idempotent)
ALTER TABLE de_mobile_app."quiz-question" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_quiz_questions" ON de_mobile_app."quiz-question";
CREATE POLICY "public_read_quiz_questions"
ON de_mobile_app."quiz-question"
FOR SELECT
TO public
USING (true);

-- Step 3: Insert all quiz questions with remapped difficulty, then insert answers
-- Difficulty mapping: easy → junior, medium → middle, hard → senior

DO $$
BEGIN

-- ─── SQL & Query Optimization ─────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q1','sql','multiple_choice','junior',
 'Which SQL clause is used to filter aggregated results in a GROUP BY query?',
 'HAVING filters groups after aggregation, while WHERE filters rows before aggregation. Use HAVING with aggregate functions like COUNT(), SUM(), AVG().',
 'Know the difference between WHERE and HAVING — this is a classic interview question.',
 'Remember: WHERE → rows, HAVING → groups. This distinction is frequently tested in interviews.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q1_o1','sql_q1','HAVING',true,1),
('sql_q1_o2','sql_q1','WHERE',false,2),
('sql_q1_o3','sql_q1','FILTER',false,3),
('sql_q1_o4','sql_q1','ON',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q2','sql','multiple_choice','senior',
 'What does the SQL window function RANK() do differently from ROW_NUMBER()?',
 'RANK() assigns the same rank to tied rows and skips the next rank (e.g., 1,1,3). ROW_NUMBER() always assigns a unique number regardless of ties.',
 'Window functions are heavily tested at FAANG. Know RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD.',
 'RANK() = gaps after ties, DENSE_RANK() = no gaps after ties, ROW_NUMBER() = always unique.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q2_o1','sql_q2','RANK() assigns unique sequential integers; ROW_NUMBER() allows ties',false,1),
('sql_q2_o2','sql_q2','RANK() operates across partitions; ROW_NUMBER() operates on the full table',false,2),
('sql_q2_o3','sql_q2','RANK() requires ORDER BY; ROW_NUMBER() does not require it',false,3),
('sql_q2_o4','sql_q2','RANK() leaves gaps after ties; ROW_NUMBER() never leaves gaps',true,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q3','sql','multiple_choice','middle',
 'What does "partitioning" a table in a data warehouse achieve?',
 'Partitioning divides a large table into smaller segments (e.g., by date). Queries that filter on the partition key only scan relevant partitions, dramatically reducing I/O.',
 'Partitioning strategy is a common system design question for data engineering roles.',
 'Partition on high-cardinality columns used in WHERE clauses. Common choices: date, region, event_type.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q3_o1','sql_q3','It encrypts specific columns for security compliance',false,1),
('sql_q3_o2','sql_q3','It divides the table into smaller physical segments to speed up query performance',true,2),
('sql_q3_o3','sql_q3','It creates a read-only replica of the table for analytics',false,3),
('sql_q3_o4','sql_q3','It removes duplicate records before loading into the warehouse',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q4','sql','multiple_choice','junior',
 'Which type of SQL JOIN returns only rows that have matching values in both tables?',
 'INNER JOIN returns only the rows where there is a match in both tables. LEFT JOIN returns all rows from the left table plus matched rows from the right.',
 'Be ready to draw Venn diagrams for JOIN types in whiteboard interviews.',
 'INNER JOIN = intersection, LEFT JOIN = all left + matched right, FULL OUTER JOIN = union of both tables.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q4_o1','sql_q4','LEFT JOIN',false,1),
('sql_q4_o2','sql_q4','FULL OUTER JOIN',false,2),
('sql_q4_o3','sql_q4','INNER JOIN',true,3),
('sql_q4_o4','sql_q4','CROSS JOIN',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q5','sql','multiple_choice','junior',
 'What is the purpose of a database INDEX?',
 'An index creates a separate data structure (e.g., B-tree) that allows the database engine to find rows faster without scanning the entire table.',
 'Interviewers often ask when NOT to use an index. Know the trade-offs.',
 'Indexes speed up reads but slow down writes. Over-indexing is a common performance anti-pattern.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q5_o1','sql_q5','To enforce referential integrity between tables',false,1),
('sql_q5_o2','sql_q5','To compress table data for storage efficiency',false,2),
('sql_q5_o3','sql_q5','To speed up data retrieval by creating a lookup structure',true,3),
('sql_q5_o4','sql_q5','To automatically partition large tables by date',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q6','sql','multiple_choice','middle',
 'What does the COALESCE() function do in SQL?',
 'COALESCE() evaluates its arguments in order and returns the first non-NULL value. It is commonly used to provide default values when a column may be NULL.',
 'NULL handling is a common source of bugs. Know COALESCE, NULLIF, and IS NULL.',
 'COALESCE(col, 0) is a clean way to replace NULLs with a default. It works across all major SQL dialects.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q6_o1','sql_q6','Concatenates multiple string columns into one',false,1),
('sql_q6_o2','sql_q6','Returns the first non-NULL value from a list of expressions',true,2),
('sql_q6_o3','sql_q6','Rounds a numeric value to a specified number of decimal places',false,3),
('sql_q6_o4','sql_q6','Converts a NULL value to zero for arithmetic operations only',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q7','sql','multiple_choice','middle',
 'Which SQL command is used to remove all rows from a table without logging individual row deletions?',
 'TRUNCATE TABLE removes all rows quickly by deallocating data pages rather than logging each row deletion. It cannot be rolled back in most databases.',
 'Know the difference between DELETE, TRUNCATE, and DROP for interviews.',
 'TRUNCATE is faster than DELETE for clearing a table, but DELETE allows WHERE filtering and is fully logged.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q7_o1','sql_q7','DELETE FROM table',false,1),
('sql_q7_o2','sql_q7','DROP TABLE',false,2),
('sql_q7_o3','sql_q7','TRUNCATE TABLE',true,3),
('sql_q7_o4','sql_q7','REMOVE FROM table',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('sql_q8','sql','multiple_choice','middle',
 'What is a CTE (Common Table Expression) in SQL?',
 'A CTE is a temporary named result set defined using the WITH keyword. It improves query readability and can be referenced multiple times within the same query.',
 'Recursive CTEs are a common advanced SQL interview topic.',
 'Recursive CTEs are powerful for hierarchical data (org charts, bill of materials). Use WITH RECURSIVE in PostgreSQL.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('sql_q8_o1','sql_q8','A permanent table stored in the database schema',false,1),
('sql_q8_o2','sql_q8','A temporary named result set defined within a WITH clause',true,2),
('sql_q8_o3','sql_q8','A stored procedure that returns a table-valued result',false,3),
('sql_q8_o4','sql_q8','A materialized view refreshed on a schedule',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Python for Data Engineering ──────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q1','python','multiple_choice','junior',
 'In Python, what does the pandas function df.merge() perform?',
 'df.merge() performs SQL-style joins on DataFrames. It supports inner, left, right, and outer joins using the how parameter.',
 'pandas merge vs join vs concat is a classic Python data engineering interview question.',
 'Know the difference between merge() (SQL-join), join() (index-based), and concat() (axis stacking).')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q1_o1','py_q1','Concatenates two DataFrames vertically along rows',false,1),
('py_q1_o2','py_q1','Removes duplicate rows from a single DataFrame',false,2),
('py_q1_o3','py_q1','Joins two DataFrames on a common column or index',true,3),
('py_q1_o4','py_q1','Reshapes a DataFrame from wide to long format',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q2','python','multiple_choice','junior',
 'What will be the output of print(bool("")) in Python?',
 'An empty string "" is falsy in Python. bool("") evaluates to False. Non-empty strings evaluate to True.',
 'Python truthiness rules are tested in coding screens. Know all falsy values.',
 'Falsy values in Python: 0, 0.0, "", [], {}, None, False. Everything else is truthy.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q2_o1','py_q2','True',false,1),
('py_q2_o2','py_q2','None',false,2),
('py_q2_o3','py_q2','Error',false,3),
('py_q2_o4','py_q2','False',true,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q3','python','multiple_choice','junior',
 'Which Python data structure provides O(1) average-case lookup time?',
 'Python dictionaries use hash tables internally, providing O(1) average-case time complexity for get, set, and delete operations.',
 'Time complexity of Python data structures is a common interview topic.',
 'Use dict for fast lookups, set for membership tests, list for ordered sequences.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q3_o1','py_q3','list',false,1),
('py_q3_o2','py_q3','tuple',false,2),
('py_q3_o3','py_q3','dict',true,3),
('py_q3_o4','py_q3','deque',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q4','python','multiple_choice','middle',
 'What does the @staticmethod decorator do in a Python class?',
 '@staticmethod defines a method that belongs to the class namespace but does not receive self or cls. It behaves like a regular function scoped inside a class.',
 'Know the difference between @staticmethod, @classmethod, and instance methods.',
 '@staticmethod = no self/cls, @classmethod = receives cls, regular method = receives self.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q4_o1','py_q4','Marks a method that can only be called on the class, not instances',false,1),
('py_q4_o2','py_q4','Defines a method that does not receive the class or instance as the first argument',true,2),
('py_q4_o3','py_q4','Prevents the method from being overridden in subclasses',false,3),
('py_q4_o4','py_q4','Caches the method result for repeated calls with the same arguments',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q5','python','multiple_choice','middle',
 'In PySpark, what is the difference between a transformation and an action?',
 'PySpark transformations (filter, select, map) are lazy — they build an execution plan (DAG) without running. Actions (collect, count, show) trigger the actual computation.',
 'Lazy evaluation is a core Spark concept tested in every data engineering interview.',
 'Transformations = lazy (filter, map, select). Actions = trigger execution (collect, count, show, write).')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q5_o1','py_q5','Transformations write data to disk; actions keep data in memory',false,1),
('py_q5_o2','py_q5','Transformations are lazy and build a DAG; actions trigger execution',true,2),
('py_q5_o3','py_q5','Transformations run on the driver; actions run on executors',false,3),
('py_q5_o4','py_q5','Transformations require a schema; actions work on unstructured data',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q6','python','multiple_choice','junior',
 'Which pandas method is used to apply a function element-wise to a DataFrame column?',
 'df[col].apply() applies a function to each element of a Series. df.apply() can apply a function along rows or columns of a DataFrame.',
 'Know when to use apply vs map vs applymap for pandas operations.',
 'For Series: use .map() or .apply(). For DataFrame row/column-wise: use .apply().')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q6_o1','py_q6','df.apply()',true,1),
('py_q6_o2','py_q6','df.map()',false,2),
('py_q6_o3','py_q6','df.transform()',false,3),
('py_q6_o4','py_q6','df.applymap()',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q7','python','multiple_choice','middle',
 'What is a Python generator and why is it useful for large data processing?',
 'Generators use yield to produce values one at a time without loading the entire dataset into memory. This is ideal for processing large files or streams in data pipelines.',
 'Generators are a memory-efficiency pattern commonly asked about in data engineering interviews.',
 'Use generators when processing files line-by-line or streaming API responses.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q7_o1','py_q7','A class that automatically generates test data for unit tests',false,1),
('py_q7_o2','py_q7','A function that uses yield to produce values lazily, one at a time',true,2),
('py_q7_o3','py_q7','A built-in that creates a list from a range of integers',false,3),
('py_q7_o4','py_q7','A decorator that converts a function into a parallel process',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('py_q8','python','multiple_choice','junior',
 'In PySpark, which function is used to read a CSV file into a DataFrame?',
 'spark.read.csv() reads a CSV file into a Spark DataFrame. You can pass options like header=True and inferSchema=True for automatic schema detection.',
 'Know the Spark DataFrameReader API for reading various file formats.',
 'Always set inferSchema=True or define a schema explicitly. Avoid inferSchema on large files in production.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('py_q8_o1','py_q8','spark.read.csv()',true,1),
('py_q8_o2','py_q8','spark.load.csv()',false,2),
('py_q8_o3','py_q8','SparkContext.textFile()',false,3),
('py_q8_o4','py_q8','spark.import.csv()',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── ETL Pipelines & Workflows ────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('etl_q1','etl','multiple_choice','middle',
 'In an ETL pipeline, what does "idempotency" mean?',
 'An idempotent pipeline produces the same output regardless of how many times it runs. Critical for fault-tolerant systems where retries are common.',
 'Idempotency is a must-know concept for data engineering system design interviews.',
 'Design ETL jobs with idempotency by using UPSERT operations and tracking watermarks.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('etl_q1_o1','etl_q1','Running the pipeline multiple times produces the same result',true,1),
('etl_q1_o2','etl_q1','The pipeline executes in parallel across multiple nodes',false,2),
('etl_q1_o3','etl_q1','The pipeline handles schema changes automatically',false,3),
('etl_q1_o4','etl_q1','Data is loaded incrementally rather than in full batches',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('etl_q2','etl','multiple_choice','middle',
 'What is "data lineage" in a data engineering context?',
 'Data lineage tracks where data comes from, how it has been transformed, and where it goes. It is essential for debugging, compliance (GDPR), and impact analysis.',
 'Data lineage tools and concepts are frequently asked in senior data engineering interviews.',
 'Tools: Apache Atlas, OpenLineage, dbt lineage graph, DataHub.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('etl_q2_o1','etl_q2','The ability to track the origin, movement, and transformation of data through a pipeline',true,1),
('etl_q2_o2','etl_q2','The process of compressing historical data to reduce storage costs',false,2),
('etl_q2_o3','etl_q2','A method for encrypting PII data before it is stored',false,3),
('etl_q2_o4','etl_q2','The schema versioning system used in a data warehouse',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('etl_q3','etl','multiple_choice','junior',
 'What is the difference between ETL and ELT in modern data pipelines?',
 'ETL transforms data before loading it into the target. ELT loads raw data into the warehouse first, then uses the warehouse compute power to transform it. ELT is preferred with modern cloud warehouses.',
 'ETL vs ELT is a foundational question in every data engineering interview.',
 'ELT is favored with Snowflake, BigQuery, Redshift because warehouse compute is cheap and scalable.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('etl_q3_o1','etl_q3','ETL transforms data before loading; ELT loads raw data first then transforms in the warehouse',true,1),
('etl_q3_o2','etl_q3','ETL is batch-only; ELT supports real-time streaming',false,2),
('etl_q3_o3','etl_q3','ETL uses cloud storage; ELT uses on-premise databases',false,3),
('etl_q3_o4','etl_q3','ETL is for structured data; ELT is for unstructured data only',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('etl_q4','etl','multiple_choice','middle',
 'What is a "watermark" in the context of incremental data loading?',
 'A watermark is a high-water mark (typically a timestamp or ID) that tracks the last record processed. Incremental loads use it to fetch only new or changed records since the last run.',
 'Watermark-based incremental loading is a core ETL pattern asked in system design rounds.',
 'Store watermarks in a metadata table. Always use UTC timestamps to avoid timezone issues.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('etl_q4_o1','etl_q4','A digital signature applied to data files for security auditing',false,1),
('etl_q4_o2','etl_q4','A timestamp or sequence value used to track the last successfully processed record',true,2),
('etl_q4_o3','etl_q4','A checksum that validates data integrity after each pipeline run',false,3),
('etl_q4_o4','etl_q4','A schema version tag appended to each record during transformation',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('etl_q5','etl','multiple_choice','senior',
 'Which strategy is best for handling schema evolution in an ETL pipeline?',
 'Schema registries (like Confluent Schema Registry) enforce compatibility rules (backward, forward, full) so pipelines can evolve without breaking downstream consumers.',
 'Schema evolution handling is a senior-level question that tests real-world pipeline experience.',
 'Backward compatibility = new schema can read old data. Forward compatibility = old schema can read new data.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('etl_q5_o1','etl_q5','Fail the pipeline immediately on any schema change',false,1),
('etl_q5_o2','etl_q5','Ignore new columns and only process known fields',false,2),
('etl_q5_o3','etl_q5','Use schema registries and backward-compatible schema evolution policies',true,3),
('etl_q5_o4','etl_q5','Reload the entire dataset from scratch on every schema change',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Apache Spark & Big Data ──────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('spark_q1','spark','multiple_choice','middle',
 'Which Spark transformation is "lazy" — meaning it does not execute immediately?',
 'filter() is a transformation in Spark and is lazy — it builds the execution plan but does not run until an action (like collect() or count()) is called.',
 'Lazy evaluation and the DAG execution model are core Spark interview topics.',
 'Transformations (map, filter, select) = lazy. Actions (collect, count, show) = trigger execution.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q1_o1','spark_q1','collect()',false,1),
('spark_q1_o2','spark_q1','filter()',true,2),
('spark_q1_o3','spark_q1','count()',false,3),
('spark_q1_o4','spark_q1','show()',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('spark_q2','spark','multiple_choice','middle',
 'What is the purpose of cache() in PySpark?',
 'cache() persists a DataFrame in memory (default storage level: MEMORY_AND_DISK). It avoids recomputing the same transformation DAG on repeated actions.',
 'Know when to use cache() vs persist() and the different storage levels.',
 'Use cache() when a DataFrame is used multiple times. Call unpersist() when done to free memory.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q2_o1','spark_q2','Writes the DataFrame to disk as a Parquet file',false,1),
('spark_q2_o2','spark_q2','Stores the DataFrame in memory to avoid recomputation on repeated access',true,2),
('spark_q2_o3','spark_q2','Compresses the DataFrame to reduce shuffle data size',false,3),
('spark_q2_o4','spark_q2','Broadcasts the DataFrame to all worker nodes for join optimization',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('spark_q3','spark','multiple_choice','senior',
 'What is a Spark "shuffle" and why is it expensive?',
 'A shuffle occurs when Spark needs to redistribute data across partitions (e.g., during groupBy, join, distinct). It involves network I/O and disk writes, making it the most expensive operation.',
 'Shuffle optimization is a key performance tuning topic in Spark interviews.',
 'Minimize shuffles by using broadcast joins for small tables, partitioning data on join keys.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q3_o1','spark_q3','A shuffle reorders partitions alphabetically to improve sort performance',false,1),
('spark_q3_o2','spark_q3','A shuffle moves data across the network between executors to redistribute it by key',true,2),
('spark_q3_o3','spark_q3','A shuffle compresses data before writing to HDFS',false,3),
('spark_q3_o4','spark_q3','A shuffle merges small files into larger ones to reduce metadata overhead',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('spark_q4','spark','multiple_choice','middle',
 'What does repartition() do in PySpark?',
 'repartition() performs a full shuffle to redistribute data into the specified number of partitions. Use coalesce() instead when only reducing partitions to avoid the shuffle.',
 'repartition vs coalesce is a classic Spark performance question.',
 'repartition(n) = full shuffle. coalesce(n) = no shuffle (use to reduce partitions efficiently).')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q4_o1','spark_q4','Reduces the number of partitions by merging adjacent ones without a shuffle',false,1),
('spark_q4_o2','spark_q4','Increases or decreases partitions by performing a full shuffle of the data',true,2),
('spark_q4_o3','spark_q4','Splits a single large partition into two equal halves',false,3),
('spark_q4_o4','spark_q4','Reorders rows within each partition by a specified column',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('spark_q5','spark','multiple_choice','senior',
 'What is a broadcast join in Spark?',
 'A broadcast join copies the smaller DataFrame to every executor node. This eliminates the shuffle of the large DataFrame, making it much faster for small-large table joins.',
 'Broadcast join optimization is a must-know for Spark performance interviews.',
 'Use broadcast() hint when joining a large table with a small lookup table (< 10 MB by default).')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('spark_q5_o1','spark_q5','A join that sends query results to all connected BI tools simultaneously',false,1),
('spark_q5_o2','spark_q5','A join where a small DataFrame is copied to every executor to avoid shuffling the large DataFrame',true,2),
('spark_q5_o3','spark_q5','A join that runs across multiple Spark clusters in parallel',false,3),
('spark_q5_o4','spark_q5','A join that caches both DataFrames in memory before execution',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Kafka & Streaming Data ───────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('kafka_q1','kafka','multiple_choice','senior',
 'In Kafka, what is a "consumer group"?',
 'A consumer group allows parallel consumption: each partition is consumed by exactly one consumer in the group. This enables horizontal scaling of message processing.',
 'Consumer groups and partition assignment are core Kafka interview topics.',
 'If consumers > partitions, some consumers will be idle. Scale partitions to match your consumer parallelism needs.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('kafka_q1_o1','kafka_q1','A set of producers writing to the same topic partition',false,1),
('kafka_q1_o2','kafka_q1','A cluster of Kafka brokers sharing the same configuration',false,2),
('kafka_q1_o3','kafka_q1','A group of consumers that collectively read from a topic, each partition assigned to one consumer',true,3),
('kafka_q1_o4','kafka_q1','A schema registry group for managing Avro message schemas',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('kafka_q2','kafka','multiple_choice','middle',
 'What is the role of a Kafka "offset"?',
 'An offset is a sequential ID assigned to each message within a partition. Consumers track their offset to know which messages have been processed and where to resume after a restart.',
 'Offset management and delivery guarantees are key Kafka interview topics.',
 'Committing offsets too early risks message loss; too late risks reprocessing.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('kafka_q2_o1','kafka_q2','The byte position of a message within a compressed batch',false,1),
('kafka_q2_o2','kafka_q2','A unique sequential ID that tracks a consumer position within a partition',true,2),
('kafka_q2_o3','kafka_q2','The replication factor assigned to a topic partition',false,3),
('kafka_q2_o4','kafka_q2','The time-to-live setting for messages before they are deleted',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('kafka_q3','kafka','multiple_choice','junior',
 'What does Kafka retention period control?',
 'The retention period (log.retention.hours or log.retention.bytes) controls how long Kafka keeps messages. After the period expires, old messages are deleted to free disk space.',
 'Know the difference between time-based and size-based retention in Kafka.',
 'Default retention is 7 days. For event sourcing or audit logs, increase retention or use log compaction.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('kafka_q3_o1','kafka_q3','How long a consumer group can remain inactive before being removed',false,1),
('kafka_q3_o2','kafka_q3','The maximum size of a single Kafka message in bytes',false,2),
('kafka_q3_o3','kafka_q3','How long messages are kept in a topic before being deleted',true,3),
('kafka_q3_o4','kafka_q3','The number of replicas maintained for each partition',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('kafka_q4','kafka','multiple_choice','senior',
 'What is Kafka log compaction?',
 'Log compaction ensures that Kafka retains at least the last known value for each message key. It is useful for changelog topics where only the latest state matters.',
 'Log compaction vs retention is a common advanced Kafka interview question.',
 'Use log compaction for CDC (Change Data Capture) topics and state store changelogs in Kafka Streams.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('kafka_q4_o1','kafka_q4','Compresses message payloads using gzip to reduce storage',false,1),
('kafka_q4_o2','kafka_q4','Merges multiple small log segments into a single large file',false,2),
('kafka_q4_o3','kafka_q4','Retains only the most recent message per key, removing older duplicates',true,3),
('kafka_q4_o4','kafka_q4','Deletes all messages older than the configured retention period',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('kafka_q5','kafka','multiple_choice','middle',
 'What is the purpose of a Kafka Schema Registry?',
 'The Schema Registry stores and validates message schemas. Producers and consumers use it to serialize/deserialize messages consistently, preventing schema incompatibilities.',
 'Schema Registry is a must-know for production Kafka deployments.',
 'Always use a Schema Registry in production Kafka deployments.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('kafka_q5_o1','kafka_q5','To store Kafka broker configuration and topic metadata',false,1),
('kafka_q5_o2','kafka_q5','To manage and enforce Avro/Protobuf/JSON schemas for Kafka messages',true,2),
('kafka_q5_o3','kafka_q5','To monitor consumer lag and alert on processing delays',false,3),
('kafka_q5_o4','kafka_q5','To replicate topics across multiple Kafka clusters',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Apache Airflow & Orchestration ──────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('airflow_q1','airflow','multiple_choice','junior',
 'In Apache Airflow, what is a DAG?',
 'A DAG (Directed Acyclic Graph) in Airflow defines a workflow: tasks as nodes, dependencies as directed edges. "Acyclic" means no circular dependencies.',
 'DAG concepts and Airflow architecture are foundational interview topics.',
 'Key DAG parameters: schedule_interval, start_date, catchup, max_active_runs.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('airflow_q1_o1','airflow_q1','A database configuration file for Airflow metadata',false,1),
('airflow_q1_o2','airflow_q1','A Docker container running an Airflow worker node',false,2),
('airflow_q1_o3','airflow_q1','A Directed Acyclic Graph that defines task dependencies and execution order',true,3),
('airflow_q1_o4','airflow_q1','A data validation rule applied to incoming datasets',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('airflow_q2','airflow','multiple_choice','middle',
 'What does the catchup parameter do in an Airflow DAG?',
 'When catchup=True, Airflow backfills all missed DAG runs from start_date to the current date. Set catchup=False to only run the most recent interval.',
 'catchup=True causing unexpected backfill runs is a common production incident topic.',
 'Always set catchup=False for new DAGs unless you explicitly need backfilling.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('airflow_q2_o1','airflow_q2','Retries failed tasks automatically up to a configured limit',false,1),
('airflow_q2_o2','airflow_q2','Runs all missed DAG executions between start_date and today when enabled',true,2),
('airflow_q2_o3','airflow_q2','Sends email alerts when a DAG run exceeds its SLA',false,3),
('airflow_q2_o4','airflow_q2','Pauses the DAG if upstream dependencies are not met',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('airflow_q3','airflow','multiple_choice','middle',
 'What is an Airflow "sensor"?',
 'Sensors are special operators that poll for a condition (e.g., file arrival, API response, database record) and block the DAG until the condition is satisfied.',
 'Sensors and their modes (poke vs reschedule) are commonly asked in Airflow interviews.',
 'Use poke_interval and timeout on sensors. For long waits, use mode="reschedule" to free the worker slot.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('airflow_q3_o1','airflow_q3','A monitoring agent that tracks DAG execution metrics',false,1),
('airflow_q3_o2','airflow_q3','A task that waits for an external condition to be met before proceeding',true,2),
('airflow_q3_o3','airflow_q3','A plugin that connects Airflow to external data sources',false,3),
('airflow_q3_o4','airflow_q3','A scheduler component that triggers DAG runs on a cron schedule',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('airflow_q4','airflow','multiple_choice','junior',
 'What is the difference between PythonOperator and BashOperator in Airflow?',
 'PythonOperator executes a Python callable within the Airflow worker. BashOperator runs a bash command or script in a subprocess on the worker node.',
 'Know the common Airflow operators and when to use each.',
 'Prefer PythonOperator for complex logic. Use BashOperator for simple shell scripts.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('airflow_q4_o1','airflow_q4','PythonOperator runs Python functions; BashOperator executes shell commands',true,1),
('airflow_q4_o2','airflow_q4','PythonOperator runs on the scheduler; BashOperator runs on workers',false,2),
('airflow_q4_o3','airflow_q4','PythonOperator supports retries; BashOperator does not',false,3),
('airflow_q4_o4','airflow_q4','PythonOperator is for ETL tasks; BashOperator is for monitoring tasks',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('airflow_q5','airflow','multiple_choice','junior',
 'What does task_id uniqueness requirement mean in Airflow DAGs?',
 'task_id must be unique within a single DAG. The same task_id can exist in different DAGs. Duplicate task_ids within a DAG will raise an error.',
 'DAG structure and task naming conventions are tested in Airflow interviews.',
 'Use descriptive task_ids like "extract_orders_from_postgres" rather than generic names like "task1".')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('airflow_q5_o1','airflow_q5','Each task must have a globally unique ID across all DAGs in the system',false,1),
('airflow_q5_o2','airflow_q5','Each task_id must be unique within its own DAG',true,2),
('airflow_q5_o3','airflow_q5','task_id must match the Python function name exactly',false,3),
('airflow_q5_o4','airflow_q5','task_id must be a UUID to prevent naming conflicts',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── dbt & Data Transformation ────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dbt_q1','dbt','multiple_choice','middle',
 'Which dbt command runs and tests your models in one step?',
 'dbt build runs models, seeds, snapshots, and tests in dependency order. It is the recommended command for full pipeline execution.',
 'Know the dbt CLI commands and what each does.',
 'dbt run = execute models only. dbt test = run tests only. dbt build = run + test + seed + snapshot.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dbt_q1_o1','dbt_q1','dbt compile',false,1),
('dbt_q1_o2','dbt_q1','dbt run --test',false,2),
('dbt_q1_o3','dbt_q1','dbt execute',false,3),
('dbt_q1_o4','dbt_q1','dbt build',true,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dbt_q2','dbt','multiple_choice','junior',
 'What is a dbt ref() function used for?',
 'ref() is how dbt models reference each other. It resolves the correct schema/table name and builds the dependency graph for ordered execution.',
 'ref() vs source() is a common dbt interview question.',
 'Always use ref() instead of hardcoding table names. It enables environment-aware compilation.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dbt_q2_o1','dbt_q2','To reference an external API endpoint for data enrichment',false,1),
('dbt_q2_o2','dbt_q2','To create a reference to another dbt model, enabling dependency tracking',true,2),
('dbt_q2_o3','dbt_q2','To define a foreign key relationship in the warehouse schema',false,3),
('dbt_q2_o4','dbt_q2','To import a Python function into a dbt macro',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dbt_q3','dbt','multiple_choice','middle',
 'What is the purpose of dbt "sources"?',
 'dbt sources define raw tables that are loaded by external tools (e.g., Fivetran, Airbyte). They enable freshness checks and allow models to reference raw tables using source().',
 'Understanding dbt sources and freshness checks is important for production dbt deployments.',
 'Use source() for raw tables and ref() for dbt-managed models. Add freshness checks to sources.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dbt_q3_o1','dbt_q3','To define raw data tables loaded by external tools that dbt does not manage',true,1),
('dbt_q3_o2','dbt_q3','To store dbt model output in a separate source schema',false,2),
('dbt_q3_o3','dbt_q3','To configure the data warehouse connection credentials',false,3),
('dbt_q3_o4','dbt_q3','To define reusable SQL snippets shared across multiple models',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dbt_q4','dbt','multiple_choice','senior',
 'What does the dbt materialization type "incremental" do?',
 'Incremental models process only new or changed rows using a filter (is_incremental() macro). This dramatically reduces compute costs for large tables.',
 'Incremental materialization strategy is a key dbt interview topic.',
 'Use unique_key with incremental models to enable upserts. Always test your incremental logic with --full-refresh periodically.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dbt_q4_o1','dbt_q4','Drops and recreates the table on every dbt run',false,1),
('dbt_q4_o2','dbt_q4','Creates a view that is recomputed on every query',false,2),
('dbt_q4_o3','dbt_q4','Appends or upserts only new/changed rows since the last run',true,3),
('dbt_q4_o4','dbt_q4','Stores the model as a temporary table that expires after the session',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dbt_q5','dbt','multiple_choice','junior',
 'What are dbt "tests" and what do they validate?',
 'dbt tests are SQL assertions run against model outputs. Built-in tests include unique, not_null, accepted_values, and relationships. Custom tests can be written as SQL.',
 'dbt testing strategy is a common interview topic for data quality discussions.',
 'Run dbt test after every dbt run in CI/CD. Add not_null and unique tests to all primary key columns.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dbt_q5_o1','dbt_q5','Unit tests that validate Python transformation logic in dbt models',false,1),
('dbt_q5_o2','dbt_q5','SQL assertions that validate data quality constraints like uniqueness and not-null',true,2),
('dbt_q5_o3','dbt_q5','Performance benchmarks that measure query execution time',false,3),
('dbt_q5_o4','dbt_q5','Schema migration scripts that validate column type changes',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Data Modeling & Warehousing ──────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dm_q1','datamodeling','multiple_choice','senior',
 'What is a "slowly changing dimension" (SCD Type 2) in data warehousing?',
 'SCD Type 2 maintains full history by inserting a new row with updated values and marking the old row as inactive with an end date.',
 'SCD types are a classic data warehousing interview question.',
 'SCD Type 1 = overwrite, Type 2 = new row + history, Type 3 = add column for previous value.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dm_q1_o1','dm_q1','A dimension that never changes after the initial load',false,1),
('dm_q1_o2','dm_q1','A dimension that overwrites the old value with the new value',false,2),
('dm_q1_o3','dm_q1','A dimension that adds a new column to track the previous value',false,3),
('dm_q1_o4','dm_q1','A dimension that stores historical records by adding new rows for each change',true,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dm_q2','datamodeling','multiple_choice','junior',
 'In a star schema, what is the role of a "fact table"?',
 'Fact tables store business events (sales, clicks, transactions) with numeric measures (revenue, quantity) and foreign keys to dimension tables.',
 'Star schema design is a foundational data warehousing interview topic.',
 'Fact table = numbers + foreign keys. Dimension table = descriptive attributes.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dm_q2_o1','dm_q2','It stores descriptive attributes about business entities',false,1),
('dm_q2_o2','dm_q2','It defines the primary keys for all dimension tables',false,2),
('dm_q2_o3','dm_q2','It stores measurable, quantitative data about business events',true,3),
('dm_q2_o4','dm_q2','It contains the ETL audit log for each data load cycle',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dm_q3','datamodeling','multiple_choice','middle',
 'What is the main difference between a Star Schema and a Snowflake Schema?',
 'In a Star Schema, dimension tables are denormalized (flat). In a Snowflake Schema, dimensions are normalized into multiple related tables, reducing redundancy but increasing join complexity.',
 'Star vs Snowflake schema trade-offs are commonly discussed in data warehouse design interviews.',
 'Star Schema = simpler queries, more storage. Snowflake Schema = less storage, more complex joins.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dm_q3_o1','dm_q3','Star Schema uses columnar storage; Snowflake Schema uses row-based storage',false,1),
('dm_q3_o2','dm_q3','Star Schema has denormalized dimensions; Snowflake Schema normalizes dimensions into sub-tables',true,2),
('dm_q3_o3','dm_q3','Star Schema supports only OLTP; Snowflake Schema supports only OLAP',false,3),
('dm_q3_o4','dm_q3','Star Schema requires a cloud warehouse; Snowflake Schema works on-premise only',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dm_q4','datamodeling','multiple_choice','middle',
 'What is "schema-on-read" as used in data lakes?',
 'Schema-on-read stores raw data without enforcing structure at write time. The schema is applied only when the data is queried, providing flexibility for diverse data sources.',
 'Schema-on-read vs schema-on-write is a key data lake vs data warehouse distinction.',
 'Data lakes use schema-on-read (flexible). Data warehouses use schema-on-write (enforced).')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dm_q4_o1','dm_q4','The schema is defined and enforced when data is written to storage',false,1),
('dm_q4_o2','dm_q4','The schema is applied when data is read, allowing raw storage without upfront structure',true,2),
('dm_q4_o3','dm_q4','The schema is automatically inferred from column names at write time',false,3),
('dm_q4_o4','dm_q4','The schema is validated against a central registry before each query',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dm_q5','datamodeling','multiple_choice','middle',
 'What is the primary difference between OLTP and OLAP systems?',
 'OLTP (Online Transaction Processing) is optimized for high-frequency writes and reads of individual records. OLAP (Online Analytical Processing) is optimized for complex aggregation queries over large datasets.',
 'OLTP vs OLAP is a foundational question in every data engineering interview.',
 'OLTP = many small transactions (banking), OLAP = few large analytical queries (BI dashboards).')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dm_q5_o1','dm_q5','OLTP handles real-time transactional writes; OLAP is optimized for analytical read queries',true,1),
('dm_q5_o2','dm_q5','OLTP is cloud-based only; OLAP runs exclusively on-premise',false,2),
('dm_q5_o3','dm_q5','OLTP uses columnar storage; OLAP uses row-based storage',false,3),
('dm_q5_o4','dm_q5','OLTP supports only SQL; OLAP supports NoSQL queries',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Cloud Data Platforms ─────────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('cloud_q1','cloud','multiple_choice','junior',
 'What is Amazon S3 primarily used for in a data engineering context?',
 'Amazon S3 is an object storage service used as the foundation of data lakes. It stores raw files (CSV, Parquet, JSON) cheaply and integrates with virtually every AWS analytics service.',
 'S3 as a data lake foundation is a core AWS data engineering concept.',
 'Use S3 as your data lake landing zone. Organize with prefixes like s3://bucket/raw/year=2024/month=01/.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('cloud_q1_o1','cloud_q1','Running distributed SQL queries on structured data',false,1),
('cloud_q1_o2','cloud_q1','Storing raw and processed data files as a scalable object store',true,2),
('cloud_q1_o3','cloud_q1','Orchestrating ETL workflows with a visual pipeline editor',false,3),
('cloud_q1_o4','cloud_q1','Providing a managed Kafka service for event streaming',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('cloud_q2','cloud','multiple_choice','middle',
 'What is Google BigQuery key architectural advantage over traditional databases?',
 'BigQuery separates storage (Colossus) from compute (Dremel). This serverless architecture allows it to scale query compute independently and charge only for bytes scanned.',
 'BigQuery architecture is commonly asked in GCP data engineering interviews.',
 'Use partitioned and clustered tables in BigQuery to reduce bytes scanned and lower query costs.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('cloud_q2_o1','cloud_q2','It stores data in row-based format for fast transactional writes',false,1),
('cloud_q2_o2','cloud_q2','It separates compute and storage, enabling serverless columnar analytics at scale',true,2),
('cloud_q2_o3','cloud_q2','It provides built-in machine learning without any SQL knowledge',false,3),
('cloud_q2_o4','cloud_q2','It replicates data across all global regions automatically at no cost',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('cloud_q3','cloud','multiple_choice','middle',
 'What is AWS Glue primarily used for?',
 'AWS Glue is a serverless ETL service. It includes a Data Catalog for metadata management, crawlers for schema discovery, and a managed Spark environment for data transformation.',
 'AWS Glue vs EMR vs Lambda for ETL is a common AWS interview question.',
 'Use Glue Crawlers to auto-discover schemas in S3. The Glue Data Catalog integrates with Athena, Redshift Spectrum, and EMR.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('cloud_q3_o1','cloud_q3','Hosting containerized microservices on managed Kubernetes',false,1),
('cloud_q3_o2','cloud_q3','A serverless ETL service for discovering, cataloging, and transforming data',true,2),
('cloud_q3_o3','cloud_q3','A managed Spark cluster service for real-time stream processing',false,3),
('cloud_q3_o4','cloud_q3','A NoSQL database optimized for high-throughput key-value operations',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('cloud_q4','cloud','multiple_choice','senior',
 'What is the purpose of Snowflake virtual warehouse?',
 'A Snowflake virtual warehouse is an independent compute cluster (MPP engine). Multiple warehouses can run simultaneously against the same data without contention.',
 'Snowflake virtual warehouse sizing and cost optimization are common interview topics.',
 'Use separate virtual warehouses for ETL loads and BI queries to prevent resource contention.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('cloud_q4_o1','cloud_q4','A logical namespace for organizing database objects like tables and views',false,1),
('cloud_q4_o2','cloud_q4','An independent compute cluster that processes queries without affecting storage',true,2),
('cloud_q4_o3','cloud_q4','A backup storage tier for archiving historical data at lower cost',false,3),
('cloud_q4_o4','cloud_q4','A shared cache layer that speeds up repeated queries across all users',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('cloud_q5','cloud','multiple_choice','senior',
 'What does "data lakehouse" architecture combine?',
 'A data lakehouse (e.g., Delta Lake, Apache Iceberg, Apache Hudi) adds ACID transactions, schema enforcement, and BI-quality performance on top of cheap object storage.',
 'Lakehouse architecture is a hot topic in modern data engineering interviews.',
 'Delta Lake (Databricks), Apache Iceberg (Netflix/Apple), and Apache Hudi (Uber) are the three major open table formats.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('cloud_q5_o1','cloud_q5','The low cost of tape storage with the speed of in-memory databases',false,1),
('cloud_q5_o2','cloud_q5','The flexibility of a data lake with the ACID transactions and governance of a data warehouse',true,2),
('cloud_q5_o3','cloud_q5','The scalability of NoSQL with the query language of SQL databases',false,3),
('cloud_q5_o4','cloud_q5','The batch processing of Hadoop with the real-time processing of Flink',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── NoSQL Databases ──────────────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('nosql_q1','nosql','multiple_choice','senior',
 'What does the CAP theorem state about distributed databases?',
 'CAP theorem states that a distributed system can only guarantee two of three properties: Consistency, Availability, and Partition tolerance.',
 'CAP theorem is a foundational distributed systems interview question.',
 'CP systems (HBase, Zookeeper) sacrifice availability. AP systems (Cassandra, DynamoDB) sacrifice consistency.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('nosql_q1_o1','nosql_q1','A distributed system can guarantee Consistency, Availability, and Partition tolerance simultaneously',false,1),
('nosql_q1_o2','nosql_q1','A distributed system can guarantee at most two of: Consistency, Availability, Partition tolerance',true,2),
('nosql_q1_o3','nosql_q1','A distributed system must sacrifice Availability to achieve Consistency',false,3),
('nosql_q1_o4','nosql_q1','A distributed system can achieve all three guarantees with eventual consistency',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('nosql_q2','nosql','multiple_choice','junior',
 'What type of NoSQL database is MongoDB?',
 'MongoDB is a document store that stores data as JSON-like BSON documents. Each document can have a different structure, providing schema flexibility.',
 'Know the four main NoSQL database types and their use cases.',
 'Document stores (MongoDB, CouchDB) = flexible schema. Key-value (Redis, DynamoDB) = fast lookups.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('nosql_q2_o1','nosql_q2','Key-value store',false,1),
('nosql_q2_o2','nosql_q2','Column-family store',false,2),
('nosql_q2_o3','nosql_q2','Document store',true,3),
('nosql_q2_o4','nosql_q2','Graph database',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('nosql_q3','nosql','multiple_choice','middle',
 'What is "eventual consistency" in distributed databases?',
 'Eventual consistency means that if no new updates are made, all replicas will eventually converge to the same value. It trades strong consistency for higher availability and lower latency.',
 'Consistency models are a key distributed systems interview topic.',
 'Cassandra and DynamoDB use eventual consistency by default. Use quorum reads/writes when stronger consistency is needed.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('nosql_q3_o1','nosql_q3','Data is immediately consistent across all nodes after every write',false,1),
('nosql_q3_o2','nosql_q3','The system guarantees that all nodes will eventually converge to the same value given no new updates',true,2),
('nosql_q3_o3','nosql_q3','Consistency is enforced only during business hours to reduce latency',false,3),
('nosql_q3_o4','nosql_q3','The database rolls back inconsistent writes automatically after a timeout',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('nosql_q4','nosql','multiple_choice','junior',
 'What is Redis primarily used for in data engineering pipelines?',
 'Redis is an in-memory data structure store used for caching (reduce database load), session management, rate limiting, and pub/sub messaging between pipeline components.',
 'Redis use cases in data pipelines are commonly asked in system design interviews.',
 'Redis TTL (time-to-live) is essential for cache invalidation. Use Redis Streams for lightweight event streaming.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('nosql_q4_o1','nosql_q4','Long-term archival of large datasets in compressed format',false,1),
('nosql_q4_o2','nosql_q4','In-memory caching, session storage, and real-time pub/sub messaging',true,2),
('nosql_q4_o3','nosql_q4','Running complex analytical SQL queries on structured data',false,3),
('nosql_q4_o4','nosql_q4','Storing graph relationships between entities for recommendation engines',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('nosql_q5','nosql','multiple_choice','middle',
 'What is the primary data model of Apache Cassandra?',
 'Cassandra uses a wide-column model where data is organized by partition key (determines node placement) and clustering columns (determines row ordering within a partition).',
 'Cassandra data modeling and partition key design are key interview topics.',
 'Design Cassandra tables around your query patterns, not your data model. Denormalization is expected.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('nosql_q5_o1','nosql_q5','Document model with nested JSON objects',false,1),
('nosql_q5_o2','nosql_q5','Wide-column model with rows identified by partition keys',true,2),
('nosql_q5_o3','nosql_q5','Graph model with nodes and edges',false,3),
('nosql_q5_o4','nosql_q5','Relational model with normalized tables and foreign keys',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── Docker & Containerization ────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('docker_q1','docker','multiple_choice','junior',
 'What is the difference between a Docker image and a Docker container?',
 'A Docker image is a read-only blueprint (layers of filesystem changes). A container is a running instance of an image with a writable layer on top.',
 'Image vs container distinction is a foundational Docker interview question.',
 'Images are immutable and shareable. Containers are ephemeral. Use volumes to persist data.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('docker_q1_o1','docker_q1','An image is a running process; a container is a static snapshot',false,1),
('docker_q1_o2','docker_q1','An image is a read-only template; a container is a running instance of that image',true,2),
('docker_q1_o3','docker_q1','An image is stored in a registry; a container is stored on the host filesystem',false,3),
('docker_q1_o4','docker_q1','An image contains only the application code; a container includes the OS kernel',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('docker_q2','docker','multiple_choice','middle',
 'What does the ENTRYPOINT instruction do in a Dockerfile?',
 'ENTRYPOINT defines the main command that runs when a container starts. Unlike CMD, ENTRYPOINT is not easily overridden at runtime, making it suitable for defining the container primary purpose.',
 'ENTRYPOINT vs CMD is a common Docker interview question.',
 'Use ENTRYPOINT for the main process and CMD for default arguments.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('docker_q2_o1','docker_q2','Sets the working directory for all subsequent RUN commands',false,1),
('docker_q2_o2','docker_q2','Defines the default executable that runs when the container starts',true,2),
('docker_q2_o3','docker_q2','Copies files from the host into the container image',false,3),
('docker_q2_o4','docker_q2','Exposes a network port for the container to listen on',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('docker_q3','docker','multiple_choice','junior',
 'What is the purpose of Docker Compose?',
 'Docker Compose uses a docker-compose.yml file to define multi-container applications (e.g., app + database + cache). A single docker-compose up starts all services.',
 'Docker Compose is commonly used in local development and is asked about in DevOps interviews.',
 'Docker Compose is ideal for local development. For production orchestration, use Kubernetes or Docker Swarm.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('docker_q3_o1','docker_q3','To build optimized multi-stage Docker images for production',false,1),
('docker_q3_o2','docker_q3','To define and run multi-container applications with a single YAML configuration',true,2),
('docker_q3_o3','docker_q3','To push Docker images to a remote container registry',false,3),
('docker_q3_o4','docker_q3','To monitor resource usage of running containers in real time',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('docker_q4','docker','multiple_choice','junior',
 'What is a Docker volume used for?',
 'Docker volumes persist data outside the container writable layer. When a container is removed, volume data remains. Volumes are the recommended way to handle stateful data.',
 'Docker volume types and use cases are commonly asked in containerization interviews.',
 'Use named volumes for databases and bind mounts for development code.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('docker_q4_o1','docker_q4','To limit the CPU and memory resources available to a container',false,1),
('docker_q4_o2','docker_q4','To persist data generated by containers beyond their lifecycle',true,2),
('docker_q4_o3','docker_q4','To expose container ports to the host network',false,3),
('docker_q4_o4','docker_q4','To share environment variables between multiple containers',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('docker_q5','docker','multiple_choice','middle',
 'What is a multi-stage Docker build?',
 'Multi-stage builds use multiple FROM instructions. Earlier stages compile/build the application; the final stage copies only the necessary artifacts, producing a lean production image.',
 'Multi-stage builds are a Docker best practice asked in DevOps and data engineering interviews.',
 'Multi-stage builds can reduce image size from GBs to MBs by excluding build tools and compilers.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('docker_q5_o1','docker_q5','A build that runs on multiple machines in parallel to speed up compilation',false,1),
('docker_q5_o2','docker_q5','A Dockerfile technique that uses multiple FROM instructions to produce a smaller final image',true,2),
('docker_q5_o3','docker_q5','A CI/CD pipeline that builds images for multiple target platforms simultaneously',false,3),
('docker_q5_o4','docker_q5','A build process that creates separate images for development and testing environments',false,4)
ON CONFLICT (option_id) DO NOTHING;

-- ─── DataOps & CI/CD for Data ─────────────────────────────────────────────

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dataops_q1','dataops','multiple_choice','junior',
 'What is the primary goal of DataOps?',
 'DataOps applies DevOps practices — CI/CD, automated testing, monitoring, and collaboration — to data pipelines to improve speed, quality, and reliability of data delivery.',
 'DataOps principles are increasingly asked in senior data engineering interviews.',
 'DataOps = DevOps for data. Key practices: automated data quality tests, pipeline CI/CD, observability.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'junior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dataops_q1_o1','dataops_q1','To replace manual data engineering work with automated machine learning',false,1),
('dataops_q1_o2','dataops_q1','To apply DevOps principles (automation, collaboration, monitoring) to data pipelines',true,2),
('dataops_q1_o3','dataops_q1','To centralize all data processing in a single cloud provider',false,3),
('dataops_q1_o4','dataops_q1','To eliminate the need for data quality testing in production pipelines',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dataops_q2','dataops','multiple_choice','middle',
 'What does "data observability" mean in a DataOps context?',
 'Data observability covers five pillars: freshness, volume, distribution, schema, and lineage.',
 'Data observability is a hot topic in modern data engineering interviews.',
 'Tools: Monte Carlo, Bigeye, Great Expectations, dbt tests. Implement observability before incidents happen.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dataops_q2_o1','dataops_q2','The ability to visually monitor data flowing through a pipeline in real time',false,1),
('dataops_q2_o2','dataops_q2','The ability to understand the health, freshness, and quality of data across the pipeline',true,2),
('dataops_q2_o3','dataops_q2','A compliance framework for auditing data access and usage',false,3),
('dataops_q2_o4','dataops_q2','A monitoring tool that tracks query performance in a data warehouse',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dataops_q3','dataops','multiple_choice','middle',
 'What is the purpose of data quality testing in a CI/CD pipeline for data?',
 'Data quality tests in CI/CD catch issues (null values, schema drift, unexpected distributions) before bad data reaches downstream consumers or production dashboards.',
 'Data quality in CI/CD is a key DataOps interview topic.',
 'Use Great Expectations or dbt tests in your CI pipeline. Block merges if critical data quality checks fail.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'middle';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dataops_q3_o1','dataops_q3','To measure the performance of SQL queries before deployment',false,1),
('dataops_q3_o2','dataops_q3','To automatically validate data correctness and catch regressions before they reach production',true,2),
('dataops_q3_o3','dataops_q3','To enforce access control policies on sensitive data columns',false,3),
('dataops_q3_o4','dataops_q3','To generate synthetic test data for development environments',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dataops_q4','dataops','multiple_choice','senior',
 'What is "infrastructure as code" (IaC) and why is it important for DataOps?',
 'IaC (Terraform, Pulumi, CloudFormation) defines infrastructure in version-controlled files. This enables reproducible environments, automated provisioning, and rollback capabilities.',
 'IaC tools and concepts are commonly asked in senior data engineering and DevOps interviews.',
 'Store Terraform state remotely (S3 + DynamoDB lock). Use workspaces for dev/staging/prod environments.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dataops_q4_o1','dataops_q4','Writing Python scripts to automate data transformation logic',false,1),
('dataops_q4_o2','dataops_q4','Defining and provisioning infrastructure using configuration files instead of manual processes',true,2),
('dataops_q4_o3','dataops_q4','Using SQL to define database schemas and table structures',false,3),
('dataops_q4_o4','dataops_q4','Storing pipeline configuration in environment variables for portability',false,4)
ON CONFLICT (option_id) DO NOTHING;

INSERT INTO de_mobile_app."quiz-question" (question_id, topic, type, difficulty, question, explanation, interview_tips, pro_tips)
VALUES ('dataops_q5','dataops','multiple_choice','senior',
 'What is a "data contract" in modern data engineering?',
 'A data contract is a formal specification (schema, semantics, SLAs, quality rules) agreed upon between data producers and consumers. It prevents breaking changes and sets clear expectations.',
 'Data contracts are an emerging best practice increasingly asked in senior data engineering interviews.',
 'Tools like Soda, Great Expectations, and custom OpenAPI specs are used to define and enforce data contracts.')
ON CONFLICT (question_id) DO UPDATE SET difficulty = 'senior';

INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order") VALUES
('dataops_q5_o1','dataops_q5','A legal agreement between data vendors and data consumers',false,1),
('dataops_q5_o2','dataops_q5','A formal agreement between data producers and consumers defining schema, SLAs, and quality expectations',true,2),
('dataops_q5_o3','dataops_q5','A configuration file that maps source columns to target columns in an ETL pipeline',false,3),
('dataops_q5_o4','dataops_q5','A database constraint that enforces referential integrity between tables',false,4)
ON CONFLICT (option_id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Quiz data migration failed: %', SQLERRM;
END $$;
