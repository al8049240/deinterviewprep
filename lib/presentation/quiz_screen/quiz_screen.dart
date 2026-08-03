import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/bookmark_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/performance_service.dart';
import '../../theme/app_theme.dart';
import './widgets/quiz_explanation_widget.dart';
import './widgets/quiz_navigation_buttons_widget.dart';
import './widgets/quiz_option_widget.dart';
import './widgets/quiz_progress_bar_widget.dart';
import './widgets/quiz_question_widget.dart';
import './widgets/quiz_stats_row_widget.dart';
import './widgets/quiz_timer_row_widget.dart';

class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String difficulty;
  final String proTip;
  final String category;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.proTip,
    required this.category,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String,
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List),
      correctIndex: map['correctIndex'] as int,
      explanation: map['explanation'] as String,
      difficulty: map['difficulty'] as String,
      proTip: map['proTip'] as String,
      category: map['category'] as String,
    );
  }
}

/// Master question bank — every question is tagged with a `category` that
/// matches the topic `id` values defined in TopicsListScreen.
/// Topic IDs: sql, python, etl, spark, kafka, airflow, cloud, dbt,
///            datamodeling, docker, nosql, dataops
const List<Map<String, dynamic>> masterQuestionBank = [
  // ─── SQL & Query Optimization (category: 'sql') ───────────────────────────
  {
    'id': 'sql_q1',
    'category': 'sql',
    'text':
        'Which SQL clause is used to filter aggregated results in a GROUP BY query?',
    'options': ['HAVING', 'WHERE', 'FILTER', 'ON'],
    'correctIndex': 0,
    'explanation':
        'HAVING filters groups after aggregation, while WHERE filters rows before aggregation. Use HAVING with aggregate functions like COUNT(), SUM(), AVG().',
    'difficulty': 'easy',
    'proTip':
        'Remember: WHERE → rows, HAVING → groups. This distinction is frequently tested in interviews.',
  },
  {
    'id': 'sql_q2',
    'category': 'sql',
    'text':
        'What does the SQL window function RANK() do differently from ROW_NUMBER()?',
    'options': [
      'RANK() assigns unique sequential integers; ROW_NUMBER() allows ties',
      'RANK() operates across partitions; ROW_NUMBER() operates on the full table',
      'RANK() requires ORDER BY; ROW_NUMBER() does not require it',
      'RANK() leaves gaps after ties; ROW_NUMBER() never leaves gaps',
    ],
    'correctIndex': 3,
    'explanation':
        'RANK() assigns the same rank to tied rows and skips the next rank (e.g., 1,1,3). ROW_NUMBER() always assigns a unique number regardless of ties.',
    'difficulty': 'hard',
    'proTip':
        'RANK() = gaps after ties, DENSE_RANK() = no gaps after ties, ROW_NUMBER() = always unique.',
  },
  {
    'id': 'sql_q3',
    'category': 'sql',
    'text': 'What does "partitioning" a table in a data warehouse achieve?',
    'options': [
      'It encrypts specific columns for security compliance',
      'It divides the table into smaller physical segments to speed up query performance',
      'It creates a read-only replica of the table for analytics',
      'It removes duplicate records before loading into the warehouse',
    ],
    'correctIndex': 1,
    'explanation':
        'Partitioning divides a large table into smaller segments (e.g., by date). Queries that filter on the partition key only scan relevant partitions, dramatically reducing I/O.',
    'difficulty': 'medium',
    'proTip':
        'Partition on high-cardinality columns used in WHERE clauses. Common choices: date, region, event_type.',
  },
  {
    'id': 'sql_q4',
    'category': 'sql',
    'text':
        'Which type of SQL JOIN returns only rows that have matching values in both tables?',
    'options': ['LEFT JOIN', 'FULL OUTER JOIN', 'INNER JOIN', 'CROSS JOIN'],
    'correctIndex': 2,
    'explanation':
        'INNER JOIN returns only the rows where there is a match in both tables. LEFT JOIN returns all rows from the left table plus matched rows from the right.',
    'difficulty': 'easy',
    'proTip':
        'INNER JOIN = intersection, LEFT JOIN = all left + matched right, FULL OUTER JOIN = union of both tables.',
  },
  {
    'id': 'sql_q5',
    'category': 'sql',
    'text': 'What is the purpose of a database INDEX?',
    'options': [
      'To enforce referential integrity between tables',
      'To compress table data for storage efficiency',
      'To speed up data retrieval by creating a lookup structure',
      'To automatically partition large tables by date',
    ],
    'correctIndex': 2,
    'explanation':
        'An index creates a separate data structure (e.g., B-tree) that allows the database engine to find rows faster without scanning the entire table.',
    'difficulty': 'easy',
    'proTip':
        'Indexes speed up reads but slow down writes. Over-indexing is a common performance anti-pattern.',
  },
  {
    'id': 'sql_q6',
    'category': 'sql',
    'text': 'What does the COALESCE() function do in SQL?',
    'options': [
      'Concatenates multiple string columns into one',
      'Returns the first non-NULL value from a list of expressions',
      'Rounds a numeric value to a specified number of decimal places',
      'Converts a NULL value to zero for arithmetic operations only',
    ],
    'correctIndex': 1,
    'explanation':
        'COALESCE() evaluates its arguments in order and returns the first non-NULL value. It is commonly used to provide default values when a column may be NULL.',
    'difficulty': 'medium',
    'proTip':
        'COALESCE(col, 0) is a clean way to replace NULLs with a default. It works across all major SQL dialects.',
  },
  {
    'id': 'sql_q7',
    'category': 'sql',
    'text':
        'Which SQL command is used to remove all rows from a table without logging individual row deletions?',
    'options': [
      'DELETE FROM table',
      'DROP TABLE',
      'TRUNCATE TABLE',
      'REMOVE FROM table',
    ],
    'correctIndex': 2,
    'explanation':
        'TRUNCATE TABLE removes all rows quickly by deallocating data pages rather than logging each row deletion. It cannot be rolled back in most databases.',
    'difficulty': 'medium',
    'proTip':
        'TRUNCATE is faster than DELETE for clearing a table, but DELETE allows WHERE filtering and is fully logged.',
  },
  {
    'id': 'sql_q8',
    'category': 'sql',
    'text': 'What is a CTE (Common Table Expression) in SQL?',
    'options': [
      'A permanent table stored in the database schema',
      'A temporary named result set defined within a WITH clause',
      'A stored procedure that returns a table-valued result',
      'A materialized view refreshed on a schedule',
    ],
    'correctIndex': 1,
    'explanation':
        'A CTE is a temporary named result set defined using the WITH keyword. It improves query readability and can be referenced multiple times within the same query.',
    'difficulty': 'medium',
    'proTip':
        'Recursive CTEs are powerful for hierarchical data (org charts, bill of materials). Use WITH RECURSIVE in PostgreSQL.',
  },

  // ─── Python for Data Engineering (category: 'python') ────────────────────
  {
    'id': 'py_q1',
    'category': 'python',
    'text': 'In Python, what does the pandas function `df.merge()` perform?',
    'options': [
      'Concatenates two DataFrames vertically along rows',
      'Removes duplicate rows from a single DataFrame',
      'Joins two DataFrames on a common column or index',
      'Reshapes a DataFrame from wide to long format',
    ],
    'correctIndex': 2,
    'explanation':
        'df.merge() performs SQL-style joins on DataFrames. It supports inner, left, right, and outer joins using the `how` parameter.',
    'difficulty': 'easy',
    'proTip':
        'Know the difference between merge() (SQL-join), join() (index-based), and concat() (axis stacking).',
  },
  {
    'id': 'py_q2',
    'category': 'python',
    'text': 'What will be the output of print(bool("")) in Python?',
    'options': ['True', 'None', 'Error', 'False'],
    'correctIndex': 3,
    'explanation':
        'An empty string "" is falsy in Python. bool("") evaluates to False. Non-empty strings evaluate to True.',
    'difficulty': 'easy',
    'proTip':
        'Falsy values in Python: 0, 0.0, "", [], {}, None, False. Everything else is truthy.',
  },
  {
    'id': 'py_q3',
    'category': 'python',
    'text':
        'Which Python data structure provides O(1) average-case lookup time?',
    'options': ['list', 'tuple', 'dict', 'deque'],
    'correctIndex': 2,
    'explanation':
        'Python dictionaries use hash tables internally, providing O(1) average-case time complexity for get, set, and delete operations.',
    'difficulty': 'easy',
    'proTip':
        'Use dict for fast lookups, set for membership tests, list for ordered sequences. All three are fundamental to data engineering scripts.',
  },
  {
    'id': 'py_q4',
    'category': 'python',
    'text': 'What does the `@staticmethod` decorator do in a Python class?',
    'options': [
      'Marks a method that can only be called on the class, not instances',
      'Defines a method that does not receive the class or instance as the first argument',
      'Prevents the method from being overridden in subclasses',
      'Caches the method result for repeated calls with the same arguments',
    ],
    'correctIndex': 1,
    'explanation':
        '@staticmethod defines a method that belongs to the class namespace but does not receive `self` or `cls`. It behaves like a regular function scoped inside a class.',
    'difficulty': 'medium',
    'proTip':
        '@staticmethod = no self/cls, @classmethod = receives cls, regular method = receives self.',
  },
  {
    'id': 'py_q5',
    'category': 'python',
    'text':
        'In PySpark, what is the difference between a transformation and an action?',
    'options': [
      'Transformations write data to disk; actions keep data in memory',
      'Transformations are lazy and build a DAG; actions trigger execution',
      'Transformations run on the driver; actions run on executors',
      'Transformations require a schema; actions work on unstructured data',
    ],
    'correctIndex': 1,
    'explanation':
        'PySpark transformations (filter, select, map) are lazy — they build an execution plan (DAG) without running. Actions (collect, count, show) trigger the actual computation.',
    'difficulty': 'medium',
    'proTip':
        'Transformations = lazy (filter, map, select). Actions = trigger execution (collect, count, show, write).',
  },
  {
    'id': 'py_q6',
    'category': 'python',
    'text':
        'Which pandas method is used to apply a function element-wise to a DataFrame column?',
    'options': ['df.apply()', 'df.map()', 'df.transform()', 'df.applymap()'],
    'correctIndex': 0,
    'explanation':
        'df[col].apply() applies a function to each element of a Series. df.apply() can apply a function along rows or columns of a DataFrame.',
    'difficulty': 'easy',
    'proTip':
        'For Series: use .map() or .apply(). For DataFrame row/column-wise: use .apply(). For element-wise on DataFrame: use .applymap() (deprecated in newer pandas, use .map()).',
  },
  {
    'id': 'py_q7',
    'category': 'python',
    'text':
        'What is a Python generator and why is it useful for large data processing?',
    'options': [
      'A class that automatically generates test data for unit tests',
      'A function that uses `yield` to produce values lazily, one at a time',
      'A built-in that creates a list from a range of integers',
      'A decorator that converts a function into a parallel process',
    ],
    'correctIndex': 1,
    'explanation':
        'Generators use `yield` to produce values one at a time without loading the entire dataset into memory. This is ideal for processing large files or streams in data pipelines.',
    'difficulty': 'medium',
    'proTip':
        'Use generators when processing files line-by-line or streaming API responses. They are memory-efficient alternatives to loading full lists.',
  },
  {
    'id': 'py_q8',
    'category': 'python',
    'text':
        'In PySpark, which function is used to read a CSV file into a DataFrame?',
    'options': [
      'spark.read.csv()',
      'spark.load.csv()',
      'SparkContext.textFile()',
      'spark.import.csv()',
    ],
    'correctIndex': 0,
    'explanation':
        'spark.read.csv() reads a CSV file into a Spark DataFrame. You can pass options like header=True and inferSchema=True for automatic schema detection.',
    'difficulty': 'easy',
    'proTip':
        'Always set inferSchema=True or define a schema explicitly. Avoid inferSchema on large files in production — it requires a full scan.',
  },

  // ─── ETL Pipelines & Workflows (category: 'etl') ─────────────────────────
  {
    'id': 'etl_q1',
    'category': 'etl',
    'text': 'In an ETL pipeline, what does "idempotency" mean?',
    'options': [
      'Running the pipeline multiple times produces the same result',
      'The pipeline executes in parallel across multiple nodes',
      'The pipeline handles schema changes automatically',
      'Data is loaded incrementally rather than in full batches',
    ],
    'correctIndex': 0,
    'explanation':
        'An idempotent pipeline produces the same output regardless of how many times it runs. Critical for fault-tolerant systems where retries are common.',
    'difficulty': 'medium',
    'proTip':
        'Design ETL jobs with idempotency by using UPSERT operations and tracking watermarks.',
  },
  {
    'id': 'etl_q2',
    'category': 'etl',
    'text': 'What is "data lineage" in a data engineering context?',
    'options': [
      'The ability to track the origin, movement, and transformation of data through a pipeline',
      'The process of compressing historical data to reduce storage costs',
      'A method for encrypting PII data before it is stored',
      'The schema versioning system used in a data warehouse',
    ],
    'correctIndex': 0,
    'explanation':
        'Data lineage tracks where data comes from, how it has been transformed, and where it goes. It is essential for debugging, compliance (GDPR), and impact analysis.',
    'difficulty': 'medium',
    'proTip':
        'Tools: Apache Atlas, OpenLineage, dbt lineage graph, DataHub. Always ask about lineage in system design interviews.',
  },
  {
    'id': 'etl_q3',
    'category': 'etl',
    'text':
        'What is the difference between ETL and ELT in modern data pipelines?',
    'options': [
      'ETL transforms data before loading; ELT loads raw data first then transforms in the warehouse',
      'ETL is batch-only; ELT supports real-time streaming',
      'ETL uses cloud storage; ELT uses on-premise databases',
      'ETL is for structured data; ELT is for unstructured data only',
    ],
    'correctIndex': 0,
    'explanation':
        'ETL transforms data before loading it into the target. ELT loads raw data into the warehouse first, then uses the warehouse compute power to transform it. ELT is preferred with modern cloud warehouses.',
    'difficulty': 'easy',
    'proTip':
        'ELT is favored with Snowflake, BigQuery, Redshift because warehouse compute is cheap and scalable.',
  },
  {
    'id': 'etl_q4',
    'category': 'etl',
    'text': 'What is a "watermark" in the context of incremental data loading?',
    'options': [
      'A digital signature applied to data files for security auditing',
      'A timestamp or sequence value used to track the last successfully processed record',
      'A checksum that validates data integrity after each pipeline run',
      'A schema version tag appended to each record during transformation',
    ],
    'correctIndex': 1,
    'explanation':
        'A watermark is a high-water mark (typically a timestamp or ID) that tracks the last record processed. Incremental loads use it to fetch only new or changed records since the last run.',
    'difficulty': 'medium',
    'proTip':
        'Store watermarks in a metadata table. Always use UTC timestamps to avoid timezone issues in incremental loads.',
  },
  {
    'id': 'etl_q5',
    'category': 'etl',
    'text':
        'Which strategy is best for handling schema evolution in an ETL pipeline?',
    'options': [
      'Fail the pipeline immediately on any schema change',
      'Ignore new columns and only process known fields',
      'Use schema registries and backward-compatible schema evolution policies',
      'Reload the entire dataset from scratch on every schema change',
    ],
    'correctIndex': 2,
    'explanation':
        'Schema registries (like Confluent Schema Registry) enforce compatibility rules (backward, forward, full) so pipelines can evolve without breaking downstream consumers.',
    'difficulty': 'hard',
    'proTip':
        'Backward compatibility = new schema can read old data. Forward compatibility = old schema can read new data. Full = both.',
  },

  // ─── Apache Spark & Big Data (category: 'spark') ─────────────────────────
  {
    'id': 'spark_q1',
    'category': 'spark',
    'text':
        'Which Spark transformation is "lazy" — meaning it does not execute immediately?',
    'options': ['collect()', 'filter()', 'count()', 'show()'],
    'correctIndex': 1,
    'explanation':
        'filter() is a transformation in Spark and is lazy — it builds the execution plan but does not run until an action (like collect() or count()) is called.',
    'difficulty': 'medium',
    'proTip':
        'Transformations (map, filter, select) = lazy. Actions (collect, count, show) = trigger execution.',
  },
  {
    'id': 'spark_q2',
    'category': 'spark',
    'text': 'What is the purpose of `cache()` in PySpark?',
    'options': [
      'Writes the DataFrame to disk as a Parquet file',
      'Stores the DataFrame in memory to avoid recomputation on repeated access',
      'Compresses the DataFrame to reduce shuffle data size',
      'Broadcasts the DataFrame to all worker nodes for join optimization',
    ],
    'correctIndex': 1,
    'explanation':
        'cache() persists a DataFrame in memory (default storage level: MEMORY_AND_DISK). It avoids recomputing the same transformation DAG on repeated actions.',
    'difficulty': 'medium',
    'proTip':
        'Use cache() when a DataFrame is used multiple times. Call unpersist() when done to free memory.',
  },
  {
    'id': 'spark_q3',
    'category': 'spark',
    'text': 'What is a Spark "shuffle" and why is it expensive?',
    'options': [
      'A shuffle reorders partitions alphabetically to improve sort performance',
      'A shuffle moves data across the network between executors to redistribute it by key',
      'A shuffle compresses data before writing to HDFS',
      'A shuffle merges small files into larger ones to reduce metadata overhead',
    ],
    'correctIndex': 1,
    'explanation':
        'A shuffle occurs when Spark needs to redistribute data across partitions (e.g., during groupBy, join, distinct). It involves network I/O and disk writes, making it the most expensive operation.',
    'difficulty': 'hard',
    'proTip':
        'Minimize shuffles by using broadcast joins for small tables, partitioning data on join keys, and avoiding wide transformations when possible.',
  },
  {
    'id': 'spark_q4',
    'category': 'spark',
    'text': 'What does `repartition()` do in PySpark?',
    'options': [
      'Reduces the number of partitions by merging adjacent ones without a shuffle',
      'Increases or decreases partitions by performing a full shuffle of the data',
      'Splits a single large partition into two equal halves',
      'Reorders rows within each partition by a specified column',
    ],
    'correctIndex': 1,
    'explanation':
        'repartition() performs a full shuffle to redistribute data into the specified number of partitions. Use coalesce() instead when only reducing partitions to avoid the shuffle.',
    'difficulty': 'medium',
    'proTip':
        'repartition(n) = full shuffle (use to increase or evenly redistribute). coalesce(n) = no shuffle (use to reduce partitions efficiently).',
  },
  {
    'id': 'spark_q5',
    'category': 'spark',
    'text': 'What is a broadcast join in Spark?',
    'options': [
      'A join that sends query results to all connected BI tools simultaneously',
      'A join where a small DataFrame is copied to every executor to avoid shuffling the large DataFrame',
      'A join that runs across multiple Spark clusters in parallel',
      'A join that caches both DataFrames in memory before execution',
    ],
    'correctIndex': 1,
    'explanation':
        'A broadcast join copies the smaller DataFrame to every executor node. This eliminates the shuffle of the large DataFrame, making it much faster for small-large table joins.',
    'difficulty': 'hard',
    'proTip':
        'Use broadcast() hint when joining a large table with a small lookup table (< 10 MB by default). Set spark.sql.autoBroadcastJoinThreshold to tune the threshold.',
  },

  // ─── Kafka & Streaming Data (category: 'kafka') ──────────────────────────
  {
    'id': 'kafka_q1',
    'category': 'kafka',
    'text': 'In Kafka, what is a "consumer group"?',
    'options': [
      'A set of producers writing to the same topic partition',
      'A cluster of Kafka brokers sharing the same configuration',
      'A group of consumers that collectively read from a topic, each partition assigned to one consumer',
      'A schema registry group for managing Avro message schemas',
    ],
    'correctIndex': 2,
    'explanation':
        'A consumer group allows parallel consumption: each partition is consumed by exactly one consumer in the group. This enables horizontal scaling of message processing.',
    'difficulty': 'hard',
    'proTip':
        'If consumers > partitions, some consumers will be idle. Scale partitions to match your consumer parallelism needs.',
  },
  {
    'id': 'kafka_q2',
    'category': 'kafka',
    'text': 'What is the role of a Kafka "offset"?',
    'options': [
      'The byte position of a message within a compressed batch',
      'A unique sequential ID that tracks a consumer\'s position within a partition',
      'The replication factor assigned to a topic partition',
      'The time-to-live setting for messages before they are deleted',
    ],
    'correctIndex': 1,
    'explanation':
        'An offset is a sequential ID assigned to each message within a partition. Consumers track their offset to know which messages have been processed and where to resume after a restart.',
    'difficulty': 'medium',
    'proTip':
        'Committing offsets too early risks message loss; too late risks reprocessing. Use at-least-once delivery with idempotent consumers.',
  },
  {
    'id': 'kafka_q3',
    'category': 'kafka',
    'text': 'What does Kafka\'s "retention period" control?',
    'options': [
      'How long a consumer group can remain inactive before being removed',
      'The maximum size of a single Kafka message in bytes',
      'How long messages are kept in a topic before being deleted',
      'The number of replicas maintained for each partition',
    ],
    'correctIndex': 2,
    'explanation':
        'The retention period (log.retention.hours or log.retention.bytes) controls how long Kafka keeps messages. After the period expires, old messages are deleted to free disk space.',
    'difficulty': 'easy',
    'proTip':
        'Default retention is 7 days. For event sourcing or audit logs, increase retention or use log compaction to keep only the latest value per key.',
  },
  {
    'id': 'kafka_q4',
    'category': 'kafka',
    'text': 'What is Kafka log compaction?',
    'options': [
      'Compresses message payloads using gzip to reduce storage',
      'Merges multiple small log segments into a single large file',
      'Retains only the most recent message per key, removing older duplicates',
      'Deletes all messages older than the configured retention period',
    ],
    'correctIndex': 2,
    'explanation':
        'Log compaction ensures that Kafka retains at least the last known value for each message key. It is useful for changelog topics where only the latest state matters.',
    'difficulty': 'hard',
    'proTip':
        'Use log compaction for CDC (Change Data Capture) topics and state store changelogs in Kafka Streams.',
  },
  {
    'id': 'kafka_q5',
    'category': 'kafka',
    'text': 'What is the purpose of a Kafka Schema Registry?',
    'options': [
      'To store Kafka broker configuration and topic metadata',
      'To manage and enforce Avro/Protobuf/JSON schemas for Kafka messages',
      'To monitor consumer lag and alert on processing delays',
      'To replicate topics across multiple Kafka clusters',
    ],
    'correctIndex': 1,
    'explanation':
        'The Schema Registry stores and validates message schemas. Producers and consumers use it to serialize/deserialize messages consistently, preventing schema incompatibilities.',
    'difficulty': 'medium',
    'proTip':
        'Always use a Schema Registry in production Kafka deployments. It prevents breaking changes from propagating silently through your pipeline.',
  },

  // ─── Apache Airflow & Orchestration (category: 'airflow') ────────────────
  {
    'id': 'airflow_q1',
    'category': 'airflow',
    'text': 'In Apache Airflow, what is a DAG?',
    'options': [
      'A database configuration file for Airflow metadata',
      'A Docker container running an Airflow worker node',
      'A Directed Acyclic Graph that defines task dependencies and execution order',
      'A data validation rule applied to incoming datasets',
    ],
    'correctIndex': 2,
    'explanation':
        'A DAG (Directed Acyclic Graph) in Airflow defines a workflow: tasks as nodes, dependencies as directed edges. "Acyclic" means no circular dependencies.',
    'difficulty': 'easy',
    'proTip':
        'Key DAG parameters: schedule_interval, start_date, catchup, max_active_runs.',
  },
  {
    'id': 'airflow_q2',
    'category': 'airflow',
    'text': 'What does the `catchup` parameter do in an Airflow DAG?',
    'options': [
      'Retries failed tasks automatically up to a configured limit',
      'Runs all missed DAG executions between start_date and today when enabled',
      'Sends email alerts when a DAG run exceeds its SLA',
      'Pauses the DAG if upstream dependencies are not met',
    ],
    'correctIndex': 1,
    'explanation':
        'When catchup=True, Airflow backfills all missed DAG runs from start_date to the current date. Set catchup=False to only run the most recent interval.',
    'difficulty': 'medium',
    'proTip':
        'Always set catchup=False for new DAGs unless you explicitly need backfilling. Unexpected catchup runs can overwhelm your infrastructure.',
  },
  {
    'id': 'airflow_q3',
    'category': 'airflow',
    'text': 'What is an Airflow "sensor"?',
    'options': [
      'A monitoring agent that tracks DAG execution metrics',
      'A task that waits for an external condition to be met before proceeding',
      'A plugin that connects Airflow to external data sources',
      'A scheduler component that triggers DAG runs on a cron schedule',
    ],
    'correctIndex': 1,
    'explanation':
        'Sensors are special operators that poll for a condition (e.g., file arrival, API response, database record) and block the DAG until the condition is satisfied.',
    'difficulty': 'medium',
    'proTip':
        'Use poke_interval and timeout on sensors. For long waits, use mode="reschedule" to free the worker slot while waiting.',
  },
  {
    'id': 'airflow_q4',
    'category': 'airflow',
    'text':
        'What is the difference between `PythonOperator` and `BashOperator` in Airflow?',
    'options': [
      'PythonOperator runs Python functions; BashOperator executes shell commands',
      'PythonOperator runs on the scheduler; BashOperator runs on workers',
      'PythonOperator supports retries; BashOperator does not',
      'PythonOperator is for ETL tasks; BashOperator is for monitoring tasks',
    ],
    'correctIndex': 0,
    'explanation':
        'PythonOperator executes a Python callable within the Airflow worker. BashOperator runs a bash command or script in a subprocess on the worker node.',
    'difficulty': 'easy',
    'proTip':
        'Prefer PythonOperator for complex logic. Use BashOperator for simple shell scripts. For production, consider KubernetesPodOperator for isolation.',
  },
  {
    'id': 'airflow_q5',
    'category': 'airflow',
    'text': 'What does `task_id` uniqueness requirement mean in Airflow DAGs?',
    'options': [
      'Each task must have a globally unique ID across all DAGs in the system',
      'Each task_id must be unique within its own DAG',
      'task_id must match the Python function name exactly',
      'task_id must be a UUID to prevent naming conflicts',
    ],
    'correctIndex': 1,
    'explanation':
        'task_id must be unique within a single DAG. The same task_id can exist in different DAGs. Duplicate task_ids within a DAG will raise an error.',
    'difficulty': 'easy',
    'proTip':
        'Use descriptive task_ids like "extract_orders_from_postgres" rather than generic names like "task1". They appear in the UI and logs.',
  },

  // ─── dbt & Data Transformation (category: 'dbt') ─────────────────────────
  {
    'id': 'dbt_q1',
    'category': 'dbt',
    'text': 'Which dbt command runs and tests your models in one step?',
    'options': ['dbt compile', 'dbt run --test', 'dbt execute', 'dbt build'],
    'correctIndex': 3,
    'explanation':
        'dbt build runs models, seeds, snapshots, and tests in dependency order. It is the recommended command for full pipeline execution.',
    'difficulty': 'medium',
    'proTip':
        'dbt run = execute models only. dbt test = run tests only. dbt build = run + test + seed + snapshot.',
  },
  {
    'id': 'dbt_q2',
    'category': 'dbt',
    'text': 'What is a dbt "ref()" function used for?',
    'options': [
      'To reference an external API endpoint for data enrichment',
      'To create a reference to another dbt model, enabling dependency tracking',
      'To define a foreign key relationship in the warehouse schema',
      'To import a Python function into a dbt macro',
    ],
    'correctIndex': 1,
    'explanation':
        'ref() is how dbt models reference each other. It resolves the correct schema/table name and builds the dependency graph for ordered execution.',
    'difficulty': 'easy',
    'proTip':
        'Always use ref() instead of hardcoding table names. It enables environment-aware compilation (dev vs. prod schemas).',
  },
  {
    'id': 'dbt_q3',
    'category': 'dbt',
    'text': 'What is the purpose of dbt "sources"?',
    'options': [
      'To define raw data tables loaded by external tools that dbt does not manage',
      'To store dbt model output in a separate source schema',
      'To configure the data warehouse connection credentials',
      'To define reusable SQL snippets shared across multiple models',
    ],
    'correctIndex': 0,
    'explanation':
        'dbt sources define raw tables that are loaded by external tools (e.g., Fivetran, Airbyte). They enable freshness checks and allow models to reference raw tables using source().',
    'difficulty': 'medium',
    'proTip':
        'Use source() for raw tables and ref() for dbt-managed models. Add freshness checks to sources to alert on stale data.',
  },
  {
    'id': 'dbt_q4',
    'category': 'dbt',
    'text': 'What does the dbt materialization type "incremental" do?',
    'options': [
      'Drops and recreates the table on every dbt run',
      'Creates a view that is recomputed on every query',
      'Appends or upserts only new/changed rows since the last run',
      'Stores the model as a temporary table that expires after the session',
    ],
    'correctIndex': 2,
    'explanation':
        'Incremental models process only new or changed rows using a filter (is_incremental() macro). This dramatically reduces compute costs for large tables.',
    'difficulty': 'hard',
    'proTip':
        'Use unique_key with incremental models to enable upserts. Always test your incremental logic with --full-refresh periodically.',
  },
  {
    'id': 'dbt_q5',
    'category': 'dbt',
    'text': 'What are dbt "tests" and what do they validate?',
    'options': [
      'Unit tests that validate Python transformation logic in dbt models',
      'SQL assertions that validate data quality constraints like uniqueness and not-null',
      'Performance benchmarks that measure query execution time',
      'Schema migration scripts that validate column type changes',
    ],
    'correctIndex': 1,
    'explanation':
        'dbt tests are SQL assertions run against model outputs. Built-in tests include unique, not_null, accepted_values, and relationships. Custom tests can be written as SQL.',
    'difficulty': 'easy',
    'proTip':
        'Run dbt test after every dbt run in CI/CD. Add not_null and unique tests to all primary key columns as a baseline.',
  },

  // ─── Data Modeling & Warehousing (category: 'datamodeling') ──────────────
  {
    'id': 'dm_q1',
    'category': 'datamodeling',
    'text':
        'What is a "slowly changing dimension" (SCD Type 2) in data warehousing?',
    'options': [
      'A dimension that never changes after the initial load',
      'A dimension that overwrites the old value with the new value',
      'A dimension that adds a new column to track the previous value',
      'A dimension that stores historical records by adding new rows for each change',
    ],
    'correctIndex': 3,
    'explanation':
        'SCD Type 2 maintains full history by inserting a new row with updated values and marking the old row as inactive with an end date.',
    'difficulty': 'hard',
    'proTip':
        'SCD Type 1 = overwrite, Type 2 = new row + history, Type 3 = add column for previous value.',
  },
  {
    'id': 'dm_q2',
    'category': 'datamodeling',
    'text': 'In a star schema, what is the role of a "fact table"?',
    'options': [
      'It stores descriptive attributes about business entities',
      'It defines the primary keys for all dimension tables',
      'It stores measurable, quantitative data about business events',
      'It contains the ETL audit log for each data load cycle',
    ],
    'correctIndex': 2,
    'explanation':
        'Fact tables store business events (sales, clicks, transactions) with numeric measures (revenue, quantity) and foreign keys to dimension tables.',
    'difficulty': 'easy',
    'proTip':
        'Fact table = numbers + foreign keys. Dimension table = descriptive attributes. Remember: facts are measured, dimensions are described.',
  },
  {
    'id': 'dm_q3',
    'category': 'datamodeling',
    'text':
        'What is the main difference between a Star Schema and a Snowflake Schema?',
    'options': [
      'Star Schema uses columnar storage; Snowflake Schema uses row-based storage',
      'Star Schema has denormalized dimensions; Snowflake Schema normalizes dimensions into sub-tables',
      'Star Schema supports only OLTP; Snowflake Schema supports only OLAP',
      'Star Schema requires a cloud warehouse; Snowflake Schema works on-premise only',
    ],
    'correctIndex': 1,
    'explanation':
        'In a Star Schema, dimension tables are denormalized (flat). In a Snowflake Schema, dimensions are normalized into multiple related tables, reducing redundancy but increasing join complexity.',
    'difficulty': 'medium',
    'proTip':
        'Star Schema = simpler queries, more storage. Snowflake Schema = less storage, more complex joins. Most BI tools prefer Star Schema for performance.',
  },
  {
    'id': 'dm_q4',
    'category': 'datamodeling',
    'text': 'What is "schema-on-read" as used in data lakes?',
    'options': [
      'The schema is defined and enforced when data is written to storage',
      'The schema is applied when data is read, allowing raw storage without upfront structure',
      'The schema is automatically inferred from column names at write time',
      'The schema is validated against a central registry before each query',
    ],
    'correctIndex': 1,
    'explanation':
        'Schema-on-read stores raw data without enforcing structure at write time. The schema is applied only when the data is queried, providing flexibility for diverse data sources.',
    'difficulty': 'medium',
    'proTip':
        'Data lakes use schema-on-read (flexible). Data warehouses use schema-on-write (enforced). Lakehouses aim to combine both.',
  },
  {
    'id': 'dm_q5',
    'category': 'datamodeling',
    'text': 'What is the primary difference between OLTP and OLAP systems?',
    'options': [
      'OLTP handles real-time transactional writes; OLAP is optimized for analytical read queries',
      'OLTP is cloud-based only; OLAP runs exclusively on-premise',
      'OLTP uses columnar storage; OLAP uses row-based storage',
      'OLTP supports only SQL; OLAP supports NoSQL queries',
    ],
    'correctIndex': 0,
    'explanation':
        'OLTP (Online Transaction Processing) is optimized for high-frequency writes and reads of individual records. OLAP (Online Analytical Processing) is optimized for complex aggregation queries over large datasets.',
    'difficulty': 'medium',
    'proTip':
        'Interview shortcut: OLTP = many small transactions (banking), OLAP = few large analytical queries (BI dashboards).',
  },

  // ─── Cloud Data Platforms (category: 'cloud') ────────────────────────────
  {
    'id': 'cloud_q1',
    'category': 'cloud',
    'text':
        'What is Amazon S3 primarily used for in a data engineering context?',
    'options': [
      'Running distributed SQL queries on structured data',
      'Storing raw and processed data files as a scalable object store',
      'Orchestrating ETL workflows with a visual pipeline editor',
      'Providing a managed Kafka service for event streaming',
    ],
    'correctIndex': 1,
    'explanation':
        'Amazon S3 is an object storage service used as the foundation of data lakes. It stores raw files (CSV, Parquet, JSON) cheaply and integrates with virtually every AWS analytics service.',
    'difficulty': 'easy',
    'proTip':
        'Use S3 as your data lake landing zone. Organize with prefixes like s3://bucket/raw/year=2024/month=01/ for efficient partition pruning.',
  },
  {
    'id': 'cloud_q2',
    'category': 'cloud',
    'text':
        'What is Google BigQuery\'s key architectural advantage over traditional databases?',
    'options': [
      'It stores data in row-based format for fast transactional writes',
      'It separates compute and storage, enabling serverless columnar analytics at scale',
      'It provides built-in machine learning without any SQL knowledge',
      'It replicates data across all global regions automatically at no cost',
    ],
    'correctIndex': 1,
    'explanation':
        'BigQuery separates storage (Colossus) from compute (Dremel). This serverless architecture allows it to scale query compute independently and charge only for bytes scanned.',
    'difficulty': 'medium',
    'proTip':
        'Use partitioned and clustered tables in BigQuery to reduce bytes scanned and lower query costs.',
  },
  {
    'id': 'cloud_q3',
    'category': 'cloud',
    'text': 'What is AWS Glue primarily used for?',
    'options': [
      'Hosting containerized microservices on managed Kubernetes',
      'A serverless ETL service for discovering, cataloging, and transforming data',
      'A managed Spark cluster service for real-time stream processing',
      'A NoSQL database optimized for high-throughput key-value operations',
    ],
    'correctIndex': 1,
    'explanation':
        'AWS Glue is a serverless ETL service. It includes a Data Catalog for metadata management, crawlers for schema discovery, and a managed Spark environment for data transformation.',
    'difficulty': 'medium',
    'proTip':
        'Use Glue Crawlers to auto-discover schemas in S3. The Glue Data Catalog integrates with Athena, Redshift Spectrum, and EMR.',
  },
  {
    'id': 'cloud_q4',
    'category': 'cloud',
    'text': 'What is the purpose of Snowflake\'s "virtual warehouse"?',
    'options': [
      'A logical namespace for organizing database objects like tables and views',
      'An independent compute cluster that processes queries without affecting storage',
      'A backup storage tier for archiving historical data at lower cost',
      'A shared cache layer that speeds up repeated queries across all users',
    ],
    'correctIndex': 1,
    'explanation':
        'A Snowflake virtual warehouse is an independent compute cluster (MPP engine). Multiple warehouses can run simultaneously against the same data without contention.',
    'difficulty': 'hard',
    'proTip':
        'Use separate virtual warehouses for ETL loads and BI queries to prevent resource contention. Auto-suspend idle warehouses to control costs.',
  },
  {
    'id': 'cloud_q5',
    'category': 'cloud',
    'text': 'What does "data lakehouse" architecture combine?',
    'options': [
      'The low cost of tape storage with the speed of in-memory databases',
      'The flexibility of a data lake with the ACID transactions and governance of a data warehouse',
      'The scalability of NoSQL with the query language of SQL databases',
      'The batch processing of Hadoop with the real-time processing of Flink',
    ],
    'correctIndex': 1,
    'explanation':
        'A data lakehouse (e.g., Delta Lake, Apache Iceberg, Apache Hudi) adds ACID transactions, schema enforcement, and BI-quality performance on top of cheap object storage.',
    'difficulty': 'hard',
    'proTip':
        'Delta Lake (Databricks), Apache Iceberg (Netflix/Apple), and Apache Hudi (Uber) are the three major open table formats enabling lakehouse architecture.',
  },

  // ─── NoSQL Databases (category: 'nosql') ─────────────────────────────────
  {
    'id': 'nosql_q1',
    'category': 'nosql',
    'text': 'What does the CAP theorem state about distributed databases?',
    'options': [
      'A distributed system can guarantee Consistency, Availability, and Partition tolerance simultaneously',
      'A distributed system can guarantee at most two of: Consistency, Availability, Partition tolerance',
      'A distributed system must sacrifice Availability to achieve Consistency',
      'A distributed system can achieve all three guarantees with eventual consistency',
    ],
    'correctIndex': 1,
    'explanation':
        'CAP theorem states that a distributed system can only guarantee two of three properties: Consistency (all nodes see the same data), Availability (every request gets a response), and Partition tolerance (system works despite network splits).',
    'difficulty': 'hard',
    'proTip':
        'CP systems (HBase, Zookeeper) sacrifice availability. AP systems (Cassandra, DynamoDB) sacrifice consistency. CA is only possible without network partitions.',
  },
  {
    'id': 'nosql_q2',
    'category': 'nosql',
    'text': 'What type of NoSQL database is MongoDB?',
    'options': [
      'Key-value store',
      'Column-family store',
      'Document store',
      'Graph database',
    ],
    'correctIndex': 2,
    'explanation':
        'MongoDB is a document store that stores data as JSON-like BSON documents. Each document can have a different structure, providing schema flexibility.',
    'difficulty': 'easy',
    'proTip':
        'Document stores (MongoDB, CouchDB) = flexible schema. Key-value (Redis, DynamoDB) = fast lookups. Column-family (Cassandra, HBase) = wide rows. Graph (Neo4j) = relationships.',
  },
  {
    'id': 'nosql_q3',
    'category': 'nosql',
    'text': 'What is "eventual consistency" in distributed databases?',
    'options': [
      'Data is immediately consistent across all nodes after every write',
      'The system guarantees that all nodes will eventually converge to the same value given no new updates',
      'Consistency is enforced only during business hours to reduce latency',
      'The database rolls back inconsistent writes automatically after a timeout',
    ],
    'correctIndex': 1,
    'explanation':
        'Eventual consistency means that if no new updates are made, all replicas will eventually converge to the same value. It trades strong consistency for higher availability and lower latency.',
    'difficulty': 'medium',
    'proTip':
        'Cassandra and DynamoDB use eventual consistency by default. Use quorum reads/writes when stronger consistency is needed.',
  },
  {
    'id': 'nosql_q4',
    'category': 'nosql',
    'text': 'What is Redis primarily used for in data engineering pipelines?',
    'options': [
      'Long-term archival of large datasets in compressed format',
      'In-memory caching, session storage, and real-time pub/sub messaging',
      'Running complex analytical SQL queries on structured data',
      'Storing graph relationships between entities for recommendation engines',
    ],
    'correctIndex': 1,
    'explanation':
        'Redis is an in-memory data structure store used for caching (reduce database load), session management, rate limiting, and pub/sub messaging between pipeline components.',
    'difficulty': 'easy',
    'proTip':
        'Redis TTL (time-to-live) is essential for cache invalidation. Use Redis Streams for lightweight event streaming in smaller-scale pipelines.',
  },
  {
    'id': 'nosql_q5',
    'category': 'nosql',
    'text': 'What is the primary data model of Apache Cassandra?',
    'options': [
      'Document model with nested JSON objects',
      'Wide-column model with rows identified by partition keys',
      'Graph model with nodes and edges',
      'Relational model with normalized tables and foreign keys',
    ],
    'correctIndex': 1,
    'explanation':
        'Cassandra uses a wide-column model where data is organized by partition key (determines node placement) and clustering columns (determines row ordering within a partition).',
    'difficulty': 'medium',
    'proTip':
        'Design Cassandra tables around your query patterns, not your data model. Denormalization is expected and encouraged.',
  },

  // ─── Docker & Containerization (category: 'docker') ──────────────────────
  {
    'id': 'docker_q1',
    'category': 'docker',
    'text':
        'What is the difference between a Docker image and a Docker container?',
    'options': [
      'An image is a running process; a container is a static snapshot',
      'An image is a read-only template; a container is a running instance of that image',
      'An image is stored in a registry; a container is stored on the host filesystem',
      'An image contains only the application code; a container includes the OS kernel',
    ],
    'correctIndex': 1,
    'explanation':
        'A Docker image is a read-only blueprint (layers of filesystem changes). A container is a running instance of an image with a writable layer on top.',
    'difficulty': 'easy',
    'proTip':
        'Images are immutable and shareable. Containers are ephemeral. Use volumes to persist data beyond container lifecycle.',
  },
  {
    'id': 'docker_q2',
    'category': 'docker',
    'text': 'What does the `ENTRYPOINT` instruction do in a Dockerfile?',
    'options': [
      'Sets the working directory for all subsequent RUN commands',
      'Defines the default executable that runs when the container starts',
      'Copies files from the host into the container image',
      'Exposes a network port for the container to listen on',
    ],
    'correctIndex': 1,
    'explanation':
        'ENTRYPOINT defines the main command that runs when a container starts. Unlike CMD, ENTRYPOINT is not easily overridden at runtime, making it suitable for defining the container\'s primary purpose.',
    'difficulty': 'medium',
    'proTip':
        'Use ENTRYPOINT for the main process and CMD for default arguments. CMD arguments can be overridden at docker run time.',
  },
  {
    'id': 'docker_q3',
    'category': 'docker',
    'text': 'What is the purpose of Docker Compose?',
    'options': [
      'To build optimized multi-stage Docker images for production',
      'To define and run multi-container applications with a single YAML configuration',
      'To push Docker images to a remote container registry',
      'To monitor resource usage of running containers in real time',
    ],
    'correctIndex': 1,
    'explanation':
        'Docker Compose uses a docker-compose.yml file to define multi-container applications (e.g., app + database + cache). A single `docker-compose up` starts all services.',
    'difficulty': 'easy',
    'proTip':
        'Docker Compose is ideal for local development. For production orchestration, use Kubernetes or Docker Swarm.',
  },
  {
    'id': 'docker_q4',
    'category': 'docker',
    'text': 'What is a Docker volume used for?',
    'options': [
      'To limit the CPU and memory resources available to a container',
      'To persist data generated by containers beyond their lifecycle',
      'To expose container ports to the host network',
      'To share environment variables between multiple containers',
    ],
    'correctIndex': 1,
    'explanation':
        'Docker volumes persist data outside the container\'s writable layer. When a container is removed, volume data remains. Volumes are the recommended way to handle stateful data.',
    'difficulty': 'easy',
    'proTip':
        'Use named volumes for databases and bind mounts for development code. Never store important data only in a container\'s writable layer.',
  },
  {
    'id': 'docker_q5',
    'category': 'docker',
    'text': 'What is a multi-stage Docker build?',
    'options': [
      'A build that runs on multiple machines in parallel to speed up compilation',
      'A Dockerfile technique that uses multiple FROM instructions to produce a smaller final image',
      'A CI/CD pipeline that builds images for multiple target platforms simultaneously',
      'A build process that creates separate images for development and testing environments',
    ],
    'correctIndex': 1,
    'explanation':
        'Multi-stage builds use multiple FROM instructions. Earlier stages compile/build the application; the final stage copies only the necessary artifacts, producing a lean production image.',
    'difficulty': 'medium',
    'proTip':
        'Multi-stage builds can reduce image size from GBs to MBs by excluding build tools, compilers, and test dependencies from the final image.',
  },

  // ─── DataOps & CI/CD for Data (category: 'dataops') ──────────────────────
  {
    'id': 'dataops_q1',
    'category': 'dataops',
    'text': 'What is the primary goal of DataOps?',
    'options': [
      'To replace manual data engineering work with automated machine learning',
      'To apply DevOps principles (automation, collaboration, monitoring) to data pipelines',
      'To centralize all data processing in a single cloud provider',
      'To eliminate the need for data quality testing in production pipelines',
    ],
    'correctIndex': 1,
    'explanation':
        'DataOps applies DevOps practices — CI/CD, automated testing, monitoring, and collaboration — to data pipelines to improve speed, quality, and reliability of data delivery.',
    'difficulty': 'easy',
    'proTip':
        'DataOps = DevOps for data. Key practices: automated data quality tests, pipeline CI/CD, observability, and cross-team collaboration.',
  },
  {
    'id': 'dataops_q2',
    'category': 'dataops',
    'text': 'What does "data observability" mean in a DataOps context?',
    'options': [
      'The ability to visually monitor data flowing through a pipeline in real time',
      'The ability to understand the health, freshness, and quality of data across the pipeline',
      'A compliance framework for auditing data access and usage',
      'A monitoring tool that tracks query performance in a data warehouse',
    ],
    'correctIndex': 1,
    'explanation':
        'Data observability covers five pillars: freshness (is data up to date?), volume (is data complete?), distribution (are values in expected ranges?), schema (did structure change?), and lineage (where did data come from?).',
    'difficulty': 'medium',
    'proTip':
        'Tools: Monte Carlo, Bigeye, Great Expectations, dbt tests. Implement observability before incidents happen, not after.',
  },
  {
    'id': 'dataops_q3',
    'category': 'dataops',
    'text':
        'What is the purpose of data quality testing in a CI/CD pipeline for data?',
    'options': [
      'To measure the performance of SQL queries before deployment',
      'To automatically validate data correctness and catch regressions before they reach production',
      'To enforce access control policies on sensitive data columns',
      'To generate synthetic test data for development environments',
    ],
    'correctIndex': 1,
    'explanation':
        'Data quality tests in CI/CD catch issues (null values, schema drift, unexpected distributions) before bad data reaches downstream consumers or production dashboards.',
    'difficulty': 'medium',
    'proTip':
        'Use Great Expectations or dbt tests in your CI pipeline. Block merges if critical data quality checks fail.',
  },
  {
    'id': 'dataops_q4',
    'category': 'dataops',
    'text':
        'What is "infrastructure as code" (IaC) and why is it important for DataOps?',
    'options': [
      'Writing Python scripts to automate data transformation logic',
      'Defining and provisioning infrastructure using configuration files instead of manual processes',
      'Using SQL to define database schemas and table structures',
      'Storing pipeline configuration in environment variables for portability',
    ],
    'correctIndex': 1,
    'explanation':
        'IaC (Terraform, Pulumi, CloudFormation) defines infrastructure in version-controlled files. This enables reproducible environments, automated provisioning, and rollback capabilities.',
    'difficulty': 'hard',
    'proTip':
        'Store Terraform state remotely (S3 + DynamoDB lock). Use workspaces or separate state files for dev/staging/prod environments.',
  },
  {
    'id': 'dataops_q5',
    'category': 'dataops',
    'text': 'What is a "data contract" in modern data engineering?',
    'options': [
      'A legal agreement between data vendors and data consumers',
      'A formal agreement between data producers and consumers defining schema, SLAs, and quality expectations',
      'A configuration file that maps source columns to target columns in an ETL pipeline',
      'A database constraint that enforces referential integrity between tables',
    ],
    'correctIndex': 1,
    'explanation':
        'A data contract is a formal specification (schema, semantics, SLAs, quality rules) agreed upon between data producers and consumers. It prevents breaking changes and sets clear expectations.',
    'difficulty': 'hard',
    'proTip':
        'Data contracts are becoming standard practice. Tools like Soda, Great Expectations, and custom OpenAPI specs are used to define and enforce them.',
  },

  // ─── Company-Specific: Meta (category: 'datamodeling') ───────────────────
  {
    'id': 'meta_quiz_q1',
    'category': 'datamodeling',
    'text':
        '[Meta] In SCD Type 2, a user changes their country from "US" to "UK". Which SQL operation correctly implements this change?',
    'options': [
      'UPDATE dim_user SET country = "UK" WHERE user_id = 123',
      'DELETE the old row and INSERT a new row with country = "UK"',
      'UPDATE old row to set is_current = FALSE and expiry_date = yesterday; INSERT new row with country = "UK", is_current = TRUE',
      'INSERT a new column "previous_country" with value "US" and update country to "UK"',
    ],
    'correctIndex': 2,
    'explanation':
        'SCD Type 2 preserves history by closing the old record (is_current=FALSE, expiry_date=yesterday) and inserting a new active record. This enables point-in-time historical queries.',
    'difficulty': 'hard',
    'proTip':
        'SCD Type 1 = overwrite (no history). Type 2 = new row (full history). Type 3 = new column (one previous value). Meta uses Type 2 for user dimension tables.',
  },
  {
    'id': 'meta_quiz_q2',
    'category': 'sql',
    'text':
        '[Meta] A JOIN between user_events (500M rows) and user_segments (10M rows, avg 16 segments/user) produces 8B output rows instead of 500M. What is the root cause?',
    'options': [
      'Missing WHERE clause causing a full table scan',
      'Many-to-many relationship causing row multiplication (fan-out)',
      'Incorrect JOIN type — should use LEFT JOIN instead of INNER JOIN',
      'Missing index on the join key causing a hash collision',
    ],
    'correctIndex': 1,
    'explanation':
        'Fan-out occurs when a many-to-many relationship causes row multiplication. 500M events × 16 segments/user = 8B rows. Fix by aggregating user_segments before joining (ARRAY_AGG or GROUP BY).',
    'difficulty': 'hard',
    'proTip':
        'Always verify expected vs actual row counts after JOINs. Use COUNT(*) and COUNT(DISTINCT key) to detect fan-out early.',
  },
  {
    'id': 'meta_quiz_q3',
    'category': 'sql',
    'text':
        '[Meta] Which SQL approach best deduplicates 500M daily user events where duplicates share the same user_id, event_type, and event_date?',
    'options': [
      'SELECT DISTINCT * FROM raw_events',
      'DELETE FROM raw_events WHERE event_id IN (SELECT MAX(event_id) FROM raw_events GROUP BY user_id, event_type, event_date)',
      'SELECT * FROM raw_events WHERE ROW_NUMBER() OVER (PARTITION BY user_id, event_type, event_date ORDER BY server_received_ts) = 1',
      'SELECT user_id, event_type, event_date, COUNT(*) FROM raw_events GROUP BY 1,2,3',
    ],
    'correctIndex': 2,
    'explanation':
        'ROW_NUMBER() OVER (PARTITION BY dedup_key ORDER BY server_received_ts) = 1 keeps the first occurrence per unique key combination. It is efficient, handles ties, and works in all major SQL engines.',
    'difficulty': 'medium',
    'proTip':
        'ROW_NUMBER() dedup is the industry standard. Partition on the natural key, order by ingestion timestamp to keep the earliest record.',
  },

  // ─── Company-Specific: Amazon (category: 'systemdesign') ─────────────────
  {
    'id': 'amz_quiz_q1',
    'category': 'cloud',
    'text':
        '[Amazon Redshift] Which distribution style should you use for a 500K-row dimension table that is joined frequently with multiple large fact tables?',
    'options': [
      'DISTKEY on the primary key column',
      'DISTSTYLE EVEN for balanced distribution',
      'DISTSTYLE ALL to replicate the table on every node',
      'DISTSTYLE AUTO and let Redshift decide',
    ],
    'correctIndex': 2,
    'explanation':
        'DISTSTYLE ALL copies the small dimension table to every compute node, eliminating network shuffles during joins. This is optimal for small tables (< 1M rows) joined frequently.',
    'difficulty': 'hard',
    'proTip':
        'Rule of thumb: Large fact tables → DISTKEY on join column. Small dimension tables → DISTSTYLE ALL. Medium tables → DISTKEY matching the fact table.',
  },
  {
    'id': 'amz_quiz_q2',
    'category': 'airflow',
    'text':
        '[Amazon] Your Airflow DAG shows all tasks as "success" but Redshift has zero new rows. What is the FIRST diagnostic step?',
    'options': [
      'Restart the Airflow scheduler and re-run the DAG',
      'Check stl_load_errors in Redshift for COPY command failures',
      'Increase executor memory and retry the failed tasks',
      'Roll back to the previous DAG version and redeploy',
    ],
    'correctIndex': 1,
    'explanation':
        'Silent failures often occur when the Redshift COPY command fails but the Airflow task succeeds (e.g., empty file written to S3). stl_load_errors reveals the actual COPY failure reason.',
    'difficulty': 'hard',
    'proTip':
        'Always add a post-load row count validation task in your DAG. A task that writes 0 rows should fail, not succeed silently.',
  },
  {
    'id': 'amz_quiz_q3',
    'category': 'kafka',
    'text':
        '[Amazon] Mobile app events arrive 2-4 hours late in your Kinesis → Flink pipeline. Which Flink feature handles this correctly?',
    'options': [
      'Processing time windows that use server ingestion time',
      'Event time windows with watermarks set to 4-hour bounded out-of-orderness',
      'Session windows with a 10-minute gap threshold',
      'Tumbling windows with a 1-hour size and no lateness allowance',
    ],
    'correctIndex': 1,
    'explanation':
        'Event time windows with WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofHours(4)) allow Flink to wait up to 4 hours for late events before closing a window, using the actual event timestamp.',
    'difficulty': 'hard',
    'proTip':
        'Always use event time (client timestamp) for business metrics. Processing time is only acceptable for operational metrics where latency matters more than accuracy.',
  },
  {
    'id': 'amz_quiz_q4',
    'category': 'etl',
    'text':
        '[Amazon] A Lambda function ingesting JSON from S3 crashes on 3% of payloads with malformed JSON. What is the correct fault-tolerant pattern?',
    'options': [
      'Wrap the entire Lambda in a try-except and silently ignore all errors',
      'Validate each record with a JSON schema, route invalid records to a Dead Letter Queue (DLQ) S3 bucket, and continue processing valid records',
      'Increase Lambda timeout and memory to handle larger payloads',
      'Pre-validate all files in S3 before triggering the Lambda function',
    ],
    'correctIndex': 1,
    'explanation':
        'The DLQ pattern isolates bad records without blocking valid ones. Invalid records are written to a separate S3 path with error metadata for later inspection and reprocessing.',
    'difficulty': 'medium',
    'proTip':
        'Never let one bad record block an entire batch. Always implement per-record error isolation with DLQ routing and CloudWatch metrics for error rate monitoring.',
  },

  // ─── Company-Specific: Snowflake / Databricks (category: 'spark') ─────────
  {
    'id': 'snow_quiz_q1',
    'category': 'cloud',
    'text':
        '[Snowflake] A query scanning a 500GB table ignores the WHERE clause on transaction_date and scans 95% of micro-partitions. What is the fix?',
    'options': [
      'Add a B-tree index on transaction_date',
      'Apply a clustering key on transaction_date to improve micro-partition pruning',
      'Increase the virtual warehouse size to XL',
      'Partition the table by transaction_date using CREATE TABLE AS SELECT',
    ],
    'correctIndex': 1,
    'explanation':
        'Snowflake uses micro-partition pruning instead of traditional indexes. Applying a clustering key on transaction_date reorganizes micro-partitions so queries with date filters scan only relevant partitions.',
    'difficulty': 'hard',
    'proTip':
        'Check SYSTEM\$CLUSTERING_INFORMATION() to measure clustering depth. Ideal average_depth < 2. High depth = poor pruning = full scans.',
  },
  {
    'id': 'snow_quiz_q2',
    'category': 'cloud',
    'text':
        '[Snowflake] What is the primary benefit of Zero-Copy Cloning a production table for development?',
    'options': [
      'It creates a compressed backup that reduces storage costs by 50%',
      'It instantly creates an independent copy sharing underlying storage with no data duplication cost until writes occur',
      'It automatically syncs changes from production to the dev clone in real time',
      'It encrypts the cloned data with a separate key for security isolation',
    ],
    'correctIndex': 1,
    'explanation':
        'Zero-Copy Cloning uses copy-on-write: the clone shares micro-partitions with the source at creation time. Storage cost only accrues for rows modified after cloning, making it nearly free for dev environments.',
    'difficulty': 'medium',
    'proTip':
        'Use Zero-Copy Clones for: dev/test environments, pre-migration snapshots, A/B testing pipeline logic. Clone creation is instant regardless of table size.',
  },
  {
    'id': 'dbx_quiz_q1',
    'category': 'spark',
    'text':
        '[Databricks] Your PySpark job fails with OutOfMemoryError when joining a 2TB orders table with a 50GB customer table. What is the MOST effective first fix?',
    'options': [
      'Increase spark.executor.memory from 8g to 64g',
      'Use broadcast() hint on the customer table to eliminate the shuffle',
      'Repartition the orders table to 2000 partitions before the join',
      'Switch from DataFrame API to RDD API for lower memory overhead',
    ],
    'correctIndex': 1,
    'explanation':
        'Broadcasting the smaller table (50GB, if within threshold) copies it to every executor, eliminating the shuffle of the 2TB table. Set spark.sql.autoBroadcastJoinThreshold to 50GB or use the broadcast() hint explicitly.',
    'difficulty': 'hard',
    'proTip':
        'Broadcast join threshold default is 10MB. For larger tables, use broadcast() hint explicitly. If the table is truly too large to broadcast, use salting to fix data skew.',
  },
  {
    'id': 'dbx_quiz_q2',
    'category': 'spark',
    'text':
        '[Databricks] Your PySpark groupBy on customer_id is extremely slow because 40% of all rows belong to 5 "power user" IDs. What technique fixes this skew?',
    'options': [
      'Increase spark.sql.shuffle.partitions to 2000',
      'Use salting: append a random integer (0-49) to the skewed key before groupBy, then aggregate twice',
      'Filter out the top 5 customer IDs before running the groupBy',
      'Use coalesce() to reduce partitions before the groupBy operation',
    ],
    'correctIndex': 1,
    'explanation':
        'Salting distributes skewed keys across multiple partitions. Append a random salt (0-N) to the key, perform the first aggregation, then strip the salt and aggregate again. This spreads the 40% load across N partitions.',
    'difficulty': 'hard',
    'proTip':
        'Salt factor should be 2-5x the number of executors. After salting aggregation, do a second aggregation on the original key to get final results.',
  },

  // ─── Company-Specific: Uber / Netflix (category: 'kafka') ─────────────────
  {
    'id': 'uber_quiz_q1',
    'category': 'kafka',
    'text':
        '[Uber] Your Flink consumer fails on 0.1% of Kafka events due to schema mismatches, causing consumer lag to grow. What is the correct architectural pattern?',
    'options': [
      'Increase Kafka partition count to distribute the load more evenly',
      'Route failed events to a Dead Letter Queue (DLQ) topic and continue processing valid events',
      'Set max.poll.records=1 to process events one at a time and avoid batch failures',
      'Add a try-catch block and log errors without routing to any secondary topic',
    ],
    'correctIndex': 1,
    'explanation':
        'DLQ (Dead Letter Queue) topics isolate failed events without blocking the main consumer. Failed events are written to a separate Kafka topic with error metadata for later inspection and reprocessing.',
    'difficulty': 'hard',
    'proTip':
        'Create separate DLQ topics per error type (schema_error, validation_error, processing_error). Monitor DLQ lag with PagerDuty alerts. Implement a reprocessing job for DLQ records.',
  },
  {
    'id': 'netflix_quiz_q1',
    'category': 'kafka',
    'text':
        '[Netflix] You are implementing CDC (Change Data Capture) from PostgreSQL to Kafka using Debezium. Which PostgreSQL setting MUST be enabled first?',
    'options': [
      'max_connections = 1000 to support Debezium connection pooling',
      'wal_level = logical to enable logical replication for Debezium',
      'shared_buffers = 4GB to cache WAL segments in memory',
      'synchronous_commit = off to reduce write latency for CDC',
    ],
    'correctIndex': 1,
    'explanation':
        'Debezium reads PostgreSQL\'s Write-Ahead Log (WAL) to capture row-level changes. wal_level must be set to "logical" (not "replica" or "minimal") to expose the full change data needed by Debezium.',
    'difficulty': 'hard',
    'proTip':
        'After enabling wal_level=logical, also create a replication slot and publication. Grant REPLICATION privilege to the Debezium user. Monitor WAL disk usage to prevent replication slot bloat.',
  },
  {
    'id': 'uber_quiz_q2',
    'category': 'kafka',
    'text':
        '[Uber] GPS location events arrive out of order due to device offline buffering. Which Flink watermark strategy correctly handles events arriving up to 30 minutes late?',
    'options': [
      'WatermarkStrategy.forMonotonousTimestamps() with event time processing',
      'WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofMinutes(30)) with client timestamp assignment',
      'WatermarkStrategy.noWatermarks() and use processing time windows instead',
      'WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofSeconds(5)) with server ingestion time',
    ],
    'correctIndex': 1,
    'explanation':
        'forBoundedOutOfOrderness(Duration.ofMinutes(30)) tells Flink to wait up to 30 minutes for late events before advancing the watermark. The timestamp assigner must use the client (device) timestamp, not server ingestion time.',
    'difficulty': 'hard',
    'proTip':
        'Always use client_timestamp for event time in mobile pipelines. Server ingestion time is unreliable for ordering. Add withIdleness() to handle partitions with no events.',
  },
  {
    'id': 'netflix_quiz_q2',
    'category': 'datamodeling',
    'text':
        '[Netflix] Apache Iceberg is used as the open table format for Netflix\'s data lakehouse. What key capability does Iceberg add over raw Parquet files on S3?',
    'options': [
      'Columnar compression that reduces storage costs by 80%',
      'ACID transactions, schema evolution, time travel queries, and partition pruning on object storage',
      'Real-time streaming ingestion directly into S3 without a message queue',
      'Automatic data quality checks and anomaly detection on ingested data',
    ],
    'correctIndex': 1,
    'explanation':
        'Apache Iceberg adds ACID transactions (concurrent reads/writes), schema evolution (add/rename/drop columns), time travel (query historical snapshots), and hidden partitioning on top of raw object storage like S3.',
    'difficulty': 'hard',
    'proTip':
        'The three major open table formats: Delta Lake (Databricks), Apache Iceberg (Netflix/Apple), Apache Hudi (Uber). All enable lakehouse architecture with ACID on object storage.',
  },
];

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int questionCount;
  final List<Map<String, dynamic>>? overrideQuestions;

  const QuizScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.questionCount,
    this.overrideQuestions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  late Timer _timer;
  int _totalSeconds = 0;
  late AnimationController _optionAnimController;
  late AnimationController _explanationAnimController;
  late Animation<double> _explanationAnim;
  int _currentStreak = 0;
  int _maxStreak = 0;

  late List<QuestionModel> _questions;
  late List<Map<String, dynamic>> _filteredMaps;

  /// Returns questions strictly matching the selected topicId.
  List<Map<String, dynamic>> _getFilteredMaps() {
    if (widget.overrideQuestions != null) {
      return widget.overrideQuestions!;
    }
    return masterQuestionBank
        .where((q) => q['category'] == widget.topicId)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    _filteredMaps = _getFilteredMaps();

    // Guardrail: if fewer than 5 matching questions, show warning after build
    // (skip guardrail when overrideQuestions is provided — single-question mode)
    if (widget.overrideQuestions == null && _filteredMaps.length < 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showInsufficientQuestionsDialog(_filteredMaps.length);
      });
    }

    final count = widget.questionCount.clamp(0, _filteredMaps.length);
    _questions = _filteredMaps.take(count).map(QuestionModel.fromMap).toList();

    _optionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _explanationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _explanationAnim = CurvedAnimation(
      parent: _explanationAnimController,
      curve: Curves.easeOutCubic,
    );

    _startTimer();
  }

  void _showInsufficientQuestionsDialog(int count) {
    if (count == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'No Questions Found',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'There are no questions available for "${widget.topicName}" yet. Please choose a different topic.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF555555),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Limited Questions',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Only $count question${count == 1 ? '' : 's'} found for "${widget.topicName}". A minimum of 5 is recommended for a full quiz session.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF555555),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: Text(
                'Choose Another Topic',
                style: GoogleFonts.dmSans(color: const Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue Anyway',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _totalSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _optionAnimController.dispose();
    _explanationAnimController.dispose();
    super.dispose();
  }

  QuestionModel get _currentQuestion => _questions[_currentIndex];
  bool get _hasAnswered => _selectedAnswers.containsKey(_currentIndex);
  int get _answeredCount => _selectedAnswers.length;

  void _selectAnswer(int optionIndex) {
    if (_hasAnswered) return;
    final isCorrect = optionIndex == _currentQuestion.correctIndex;
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
      if (isCorrect) {
        _currentStreak++;
        if (_currentStreak > _maxStreak) _maxStreak = _currentStreak;
      } else {
        _currentStreak = 0;
      }
    });
    _explanationAnimController.forward();
  }

  void _toggleBookmark() {
    final questionId = _currentQuestion.id;
    context.read<BookmarkProvider>().toggleQuiz(questionId);
  }

  void _goNext() {
    if (_questions.isEmpty) return;
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _explanationAnimController.reset();
        if (_hasAnswered) _explanationAnimController.forward();
      });
    } else {
      _finishQuiz();
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _explanationAnimController.reset();
        if (_hasAnswered) _explanationAnimController.forward();
      });
    }
  }

  void _finishQuiz() {
    _timer.cancel();
    int correct = 0;
    _selectedAnswers.forEach((qIdx, ansIdx) {
      if (ansIdx == _questions[qIdx].correctIndex) correct++;
    });

    // Save session to PerformanceService
    PerformanceService().saveSession(
      topicId: widget.topicId,
      topicName: widget.topicName,
      totalQuestions: _questions.length,
      correctAnswers: correct,
      durationSeconds: _totalSeconds,
    );

    context.pushReplacement(
      AppRoutes.resultsScreen,
      extra: {
        'topicName': widget.topicName,
        'score': correct * 10,
        'totalQuestions': _questions.length,
        'correctAnswers': correct,
        'timeTakenSeconds': _totalSeconds,
        'topicId': widget.topicId,
        'maxStreak': _maxStreak,
        'questions': _filteredMaps.take(widget.questionCount).toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final bookmarkProvider = context.watch<BookmarkProvider>();

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          title: Text(
            widget.topicName,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No questions available for this topic yet.',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: const Color(0xFF555555),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: isTablet
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildBody(theme),
                ),
              )
            : _buildBody(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        onPressed: () => _showExitDialog(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      title: Text(
        widget.topicName,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (_currentStreak > 0)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 3),
                Text(
                  '$_currentStreak',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          onPressed: _finishQuiz,
          icon: const Icon(Icons.flag_rounded, color: Colors.white),
          tooltip: 'Finish Quiz',
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Column(
      children: [
        QuizTimerRowWidget(totalSeconds: _totalSeconds),
        QuizStatsRowWidget(
          totalQuestions: _questions.length,
          totalAnswered: _answeredCount,
        ),
        QuizProgressBarWidget(
          current: _currentIndex + 1,
          total: _questions.length,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuizQuestionWidget(
                  questionNumber: _currentIndex + 1,
                  totalQuestions: _questions.length,
                  questionText: _currentQuestion.text,
                  difficulty: _currentQuestion.difficulty,
                  isBookmarked: context
                      .watch<BookmarkProvider>()
                      .isQuizBookmarked(_currentQuestion.id),
                  onBookmark: _toggleBookmark,
                ),
                const SizedBox(height: 16),
                _buildOptionsLabel(theme),
                const SizedBox(height: 10),
                ..._currentQuestion.options.asMap().entries.map((entry) {
                  return QuizOptionWidget(
                    index: entry.key,
                    text: entry.value,
                    isSelected: _selectedAnswers[_currentIndex] == entry.key,
                    isCorrect:
                        _hasAnswered &&
                        entry.key == _currentQuestion.correctIndex,
                    isWrong:
                        _hasAnswered &&
                        _selectedAnswers[_currentIndex] == entry.key &&
                        entry.key != _currentQuestion.correctIndex,
                    hasAnswered: _hasAnswered,
                    onTap: () => _selectAnswer(entry.key),
                  );
                }),
                if (_hasAnswered) ...[
                  const SizedBox(height: 16),
                  QuizExplanationWidget(
                    explanation: _currentQuestion.explanation,
                    proTip: _currentQuestion.proTip,
                    animation: _explanationAnim,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        QuizNavigationButtonsWidget(
          onPrevious: _currentIndex > 0 ? _goPrevious : null,
          onNext: _goNext,
          isLastQuestion: _currentIndex == _questions.length - 1,
          hasAnswered: _hasAnswered,
        ),
      ],
    );
  }

  Widget _buildOptionsLabel(ThemeData theme) {
    return Center(
      child: Text(
        'SELECT YOUR ANSWER',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit Quiz?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Stay',
              style: GoogleFonts.dmSans(color: AppTheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _timer.cancel();
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Exit',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
