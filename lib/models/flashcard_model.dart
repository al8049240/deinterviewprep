class FlashcardModel {
  final String id;
  final String front;
  final String back;
  final String category;
  final List<String> tags;
  bool isMastered;

  FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.category,
    this.tags = const [],
    this.isMastered = false,
  });

  /// Create a FlashcardModel from a Supabase row.
  /// The row is expected to have: flashcard_id, name, explanation,
  /// and optionally a joined topic name via topic_id.
  factory FlashcardModel.fromSupabase(
    Map<String, dynamic> row, {
    required String category,
  }) {
    return FlashcardModel(
      id: row['flashcard_id']?.toString() ?? '',
      front: row['name']?.toString() ?? '',
      back: row['explanation']?.toString() ?? '',
      category: category,
      tags:
          (row['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          [],
    );
  }
}

class InterviewQuestionModel {
  final String id;
  final String title;
  final String description;
  final String answer;
  final String category;
  final String difficulty;
  final bool isPro;
  final List<String> tags;
  final String topicId;
  final List<String> companies;

  const InterviewQuestionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.answer,
    required this.category,
    required this.difficulty,
    required this.isPro,
    required this.tags,
    this.topicId = '',
    this.companies = const [],
  });
}

final List<FlashcardModel> sampleFlashcards = [
  // ── SQL (20 cards) ──────────────────────────────────────────────────────
  FlashcardModel(
    id: 'fc1',
    front: 'What is the difference between Star Schema and Snowflake Schema?',
    back:
        'Star Schema: Denormalized, single fact table surrounded by dimension tables. Fast queries, simple joins.\n\nSnowflake Schema: Normalized dimensions split into sub-tables. Saves storage, more complex joins, slower queries.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc2',
    front: 'What is ETL vs ELT?',
    back:
        'ETL: Extract → Transform → Load. Transform happens before loading into warehouse. Traditional approach.\n\nELT: Extract → Load → Transform. Raw data loaded first, then transformed inside the warehouse. Modern cloud approach (Snowflake, BigQuery).',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc3',
    front: 'What are SQL Window Functions?',
    back:
        'Window functions perform calculations across a set of rows related to the current row without collapsing them.\n\nExamples: ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD(), SUM() OVER(), AVG() OVER(PARTITION BY ... ORDER BY ...)',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc4',
    front: 'What is the difference between RANK() and DENSE_RANK()?',
    back:
        'RANK(): Assigns the same rank to ties, then skips the next rank(s). E.g., 1, 2, 2, 4.\n\nDENSE_RANK(): Assigns the same rank to ties but does NOT skip ranks. E.g., 1, 2, 2, 3.\n\nUse DENSE_RANK() when you need consecutive ranking without gaps.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc5',
    front: 'What is a CTE (Common Table Expression)?',
    back:
        'A CTE is a named temporary result set defined with the WITH keyword, used to simplify complex queries.\n\nSyntax: WITH cte_name AS (SELECT ...) SELECT * FROM cte_name\n\nLimitation: CTEs are recomputed every time they are referenced in the same query.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc6',
    front: 'What is the difference between WHERE and HAVING?',
    back:
        'WHERE: Filters rows BEFORE aggregation. Cannot use aggregate functions.\n\nHAVING: Filters groups AFTER aggregation. Used with GROUP BY.\n\nExample: WHERE salary > 50000 vs HAVING AVG(salary) > 50000',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc7',
    front: 'What is a SQL fan-out problem?',
    back:
        'Fan-out occurs when a JOIN multiplies rows unexpectedly because one table has multiple matching rows per key.\n\nExample: A user in 16 segments × 500 events = 8,000 rows instead of 500.\n\nFix: Aggregate before joining, or use LATERAL FLATTEN after joining an array column.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc8',
    front: 'What is data partitioning in SQL databases?',
    back:
        'Splitting data across multiple nodes/files to improve query performance.\n\nTypes: Range (by date), Hash (by key), List (by category).\n\nBenefit: Partition pruning — queries only scan relevant partitions, skipping the rest.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc9',
    front: 'What is a Slowly Changing Dimension (SCD) Type 2?',
    back:
        'SCD Type 2 keeps full history by inserting a new row for every change instead of overwriting.\n\nRequired columns: effective_date, expiry_date (default 9999-12-31), is_current flag.\n\nUse case: "What was the customer\'s country at the time of purchase?"',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc10',
    front: 'What are the three SCD types and when to use each?',
    back:
        'Type 1 — Overwrite: No history kept. Use for correcting errors.\n\nType 2 — New row: Full history with effective/expiry dates. Most common for analytics.\n\nType 3 — New column: Stores only previous value. Use when only one level of history is needed.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc11',
    front:
        'What is the difference between INNER JOIN, LEFT JOIN, and FULL OUTER JOIN?',
    back:
        'INNER JOIN: Returns only rows with matching keys in both tables.\n\nLEFT JOIN: Returns all rows from the left table, NULLs for non-matching right rows.\n\nFULL OUTER JOIN: Returns all rows from both tables, NULLs where there is no match.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc12',
    front: 'What is a Broadcast Join in SQL/Spark?',
    back:
        'A broadcast join sends a full copy of a small table to every executor/node, eliminating the need for a shuffle.\n\nUse when: one table is small enough to fit in memory (typically < 200MB).\n\nBenefit: Removes network shuffle, dramatically speeds up joins.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc13',
    front: 'What is the purpose of EXPLAIN in SQL?',
    back:
        'EXPLAIN shows the query execution plan — how the database will retrieve data.\n\nKey things to look for:\n• Full table scans (bad)\n• Index usage (good)\n• Join types (hash join, nested loop)\n• Estimated row counts and costs\n\nUse EXPLAIN ANALYZE to see actual vs estimated rows.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc14',
    front: 'What is a recursive CTE?',
    back:
        'A recursive CTE references itself to process hierarchical data like org charts or category trees.\n\nStructure:\nWITH RECURSIVE cte AS (\n  -- Anchor: base case\n  SELECT id, parent_id FROM table WHERE parent_id IS NULL\n  UNION ALL\n  -- Recursive: join with itself\n  SELECT t.id, t.parent_id FROM table t JOIN cte ON t.parent_id = cte.id\n)',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc15',
    front: 'What is the difference between UNION and UNION ALL?',
    back:
        'UNION: Combines results from two queries and removes duplicates. Slower due to deduplication.\n\nUNION ALL: Combines results and keeps all duplicates. Faster.\n\nUse UNION ALL when you know there are no duplicates or performance matters more than deduplication.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc16',
    front: 'What is Snowflake Zero-Copy Cloning?',
    back:
        'Creates an independent copy of a table, schema, or database instantly with no data duplication.\n\nUses copy-on-write: the clone shares original storage until modified.\n\nUse cases: dev/test environments from production, snapshots before risky migrations.\n\nCost: Free to create. Pay only for rows changed after cloning.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc17',
    front: 'What are Snowflake Micro-Partitions and Clustering Keys?',
    back:
        'Micro-partitions: Snowflake automatically splits tables into 50-500MB chunks, storing min/max metadata per column for pruning.\n\nClustering Keys: Reorganize data so rows with the same key value are stored together, enabling partition pruning.\n\nResult: 95% partitions scanned → 3-5% scanned after clustering.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc18',
    front: 'What is a Transient Table in Snowflake?',
    back:
        'A Transient Table is a temporary table that persists across sessions but has no Fail-safe storage (no 7-day recovery).\n\nUse when: You need to share intermediate results across multiple queries or sessions.\n\nCost: Cheaper than permanent tables — no Fail-safe overhead.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc19',
    front: 'What is Redshift DISTKEY and SORTKEY?',
    back:
        'DISTKEY: Determines which node stores each row. Matching DISTKEY on joined tables eliminates network shuffle (DS_DIST_BOTH).\n\nSORTKEY: Sorts data on disk for fast range queries. Redshift skips entire blocks that don\'t match the filter.\n\nSmall tables: use DISTSTYLE ALL to copy to every node.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc20',
    front: 'What is the difference between a View and a Materialized View?',
    back:
        'View: A saved SQL query. Executes the query every time it is accessed. Always shows fresh data.\n\nMaterialized View: Stores the query result physically on disk. Must be refreshed to show new data.\n\nUse Materialized Views for expensive aggregations that are queried frequently.',
    category: 'SQL',
  ),

  // ── Architecture (20 cards) ──────────────────────────────────────────────
  FlashcardModel(
    id: 'fc21',
    front: 'Explain ACID vs BASE consistency models.',
    back:
        'ACID: Atomicity, Consistency, Isolation, Durability — used in relational DBs for strict transactions.\n\nBASE: Basically Available, Soft state, Eventually consistent — used in NoSQL for high availability and scalability.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc22',
    front: 'What is a Data Lakehouse?',
    back:
        'A hybrid architecture combining the low-cost storage of a Data Lake with the ACID transactions and schema enforcement of a Data Warehouse.\n\nExamples: Delta Lake, Apache Iceberg, Apache Hudi.\n\nKey feature: ACID transactions on top of object storage (S3, GCS).',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc23',
    front: 'What is the CAP Theorem?',
    back:
        'A distributed system can only guarantee 2 of 3 properties:\n• Consistency: All nodes see the same data\n• Availability: Every request gets a response\n• Partition Tolerance: System works despite network failures\n\nNoSQL DBs typically choose AP (Cassandra) or CP (HBase).',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc24',
    front: 'What is the difference between batch and stream processing?',
    back:
        'Batch: Processes large volumes of data at scheduled intervals (e.g., nightly ETL). Tools: Spark, Hive.\n\nStream: Processes data continuously as it arrives in real-time. Tools: Kafka Streams, Apache Flink, Spark Structured Streaming.\n\nLambda Architecture combines both.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc25',
    front: 'What is Lambda Architecture?',
    back:
        'A data architecture pattern with three layers:\n\n• Batch layer: Reprocesses all historical data for accuracy\n• Speed layer: Processes real-time data for low latency\n• Serving layer: Merges batch and speed results for queries\n\nDownside: Maintaining two codebases (batch + streaming) is complex.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc26',
    front: 'What is Kappa Architecture?',
    back:
        'A simplified alternative to Lambda Architecture that uses only a streaming layer.\n\nAll data (historical and real-time) is processed through a single streaming pipeline.\n\nAdvantage: One codebase to maintain.\nDisadvantage: Reprocessing historical data requires replaying the entire stream.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc27',
    front: 'What is Change Data Capture (CDC)?',
    back:
        'CDC reads a database\'s transaction log (WAL in PostgreSQL) and streams every INSERT, UPDATE, and DELETE as an event in real time.\n\nTool: Debezium → Kafka → downstream consumers.\n\nAdvantage over polling: No load on source DB, captures deletes, sub-second latency.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc28',
    front: 'What is a Dead Letter Queue (DLQ)?',
    back:
        'A DLQ is a separate queue/topic where failed messages are routed instead of blocking the main pipeline.\n\nContents: Original payload + error reason + timestamp + retry count.\n\nPurpose: Isolate bad records, keep the pipeline running, enable replay after fixing the root cause.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc29',
    front: 'What is idempotency in data pipelines?',
    back:
        'An idempotent operation produces the same result whether it runs once or multiple times.\n\nWhy it matters: Kafka delivers at-least-once, so consumers may process the same message twice.\n\nImplementation: Use deterministic event IDs (SHA256 of key fields) and upsert instead of insert.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc30',
    front: 'What is data lineage?',
    back:
        'Data lineage tracks the origin, movement, and transformation of data through a pipeline.\n\nWhy it matters: Debugging data quality issues, understanding impact of schema changes, regulatory compliance.\n\nTools: Apache Atlas, OpenLineage, dbt lineage graph.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc31',
    front: 'What is a Medallion Architecture (Bronze/Silver/Gold)?',
    back:
        'A layered data lake pattern:\n\n• Bronze: Raw ingested data, no transformations\n• Silver: Cleaned, deduplicated, validated data\n• Gold: Aggregated, business-ready data for analytics\n\nUsed in Delta Lake / Databricks. Each layer adds quality and reduces volume.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc32',
    front: 'What is event-driven architecture?',
    back:
        'A design pattern where services communicate by producing and consuming events asynchronously.\n\nComponents: Event producer → Event broker (Kafka) → Event consumer.\n\nAdvantages: Loose coupling, scalability, fault tolerance.\nDisadvantage: Harder to debug, eventual consistency.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc33',
    front: 'What is a data mesh?',
    back:
        'A decentralized data architecture where domain teams own their own data products.\n\nFour principles:\n1. Domain ownership\n2. Data as a product\n3. Self-serve data platform\n4. Federated computational governance\n\nContrast with centralized data lake owned by a single data team.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc34',
    front: 'What is schema evolution and how do you handle it?',
    back:
        'Schema evolution is the ability to change a table\'s schema over time without breaking existing consumers.\n\nSafe changes: Adding nullable columns, widening types.\nBreaking changes: Removing columns, renaming columns, changing types.\n\nTools: Schema Registry (Kafka), Delta Lake schema evolution, dbt migrations.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc35',
    front: 'What is the difference between horizontal and vertical scaling?',
    back:
        'Vertical scaling (scale up): Add more CPU/RAM to a single machine. Simple but has limits.\n\nHorizontal scaling (scale out): Add more machines to a cluster. More complex but nearly unlimited.\n\nDistributed systems like Kafka, Spark, and Cassandra are designed for horizontal scaling.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc36',
    front: 'What is a data contract?',
    back:
        'A formal agreement between a data producer and consumer that defines the schema, quality, and SLA of a dataset.\n\nIncludes: Field names, types, nullability, freshness SLA, owner.\n\nBenefit: Prevents breaking changes from propagating silently through the pipeline.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc37',
    front: 'What is the difference between OLTP and OLAP?',
    back:
        'OLTP (Online Transaction Processing): Optimized for fast reads/writes of individual rows. Used in operational databases (PostgreSQL, MySQL).\n\nOLAP (Online Analytical Processing): Optimized for aggregating large volumes of data. Used in data warehouses (Snowflake, BigQuery, Redshift).',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc38',
    front: 'What is a data catalog?',
    back:
        'A data catalog is an inventory of all data assets in an organization with metadata, lineage, and search capabilities.\n\nContents: Table descriptions, column definitions, owners, freshness, quality scores.\n\nTools: Apache Atlas, Alation, DataHub, Collibra.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc39',
    front: 'What is the difference between a Data Lake and a Data Warehouse?',
    back:
        'Data Lake: Stores raw, unstructured data in its native format (S3, GCS). Schema-on-read. Cheap storage.\n\nData Warehouse: Stores structured, processed data with enforced schema. Schema-on-write. Optimized for SQL queries.\n\nData Lakehouse: Combines both — raw storage with warehouse-quality query performance.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc40',
    front: 'What is eventual consistency?',
    back:
        'A consistency model where all replicas of data will eventually converge to the same value, but may temporarily differ.\n\nUsed in: Cassandra, DynamoDB, Kafka consumer groups.\n\nTrade-off: Higher availability and lower latency at the cost of temporary inconsistency.',
    category: 'Architecture',
  ),

  // ── Orchestration (15 cards) ─────────────────────────────────────────────
  FlashcardModel(
    id: 'fc41',
    front: 'What is Apache Kafka?',
    back:
        'A distributed event streaming platform used for high-throughput, fault-tolerant, real-time data pipelines.\n\nKey concepts: Topics, Partitions, Producers, Consumers, Consumer Groups, Offsets, Brokers.\n\nUse cases: Event streaming, CDC, log aggregation, real-time analytics.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc42',
    front: 'What is Apache Airflow?',
    back:
        'An open-source workflow orchestration platform for authoring, scheduling, and monitoring data pipelines as DAGs.\n\nKey components: DAG, Task, Operator, Scheduler, Executor, XCom.\n\nNote: "Success" in Airflow means the task ran without crashing — not that data was loaded correctly.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc43',
    front: 'What is a Kafka Consumer Group?',
    back:
        'A group of consumers that jointly consume a Kafka topic, with each partition assigned to exactly one consumer in the group.\n\nBenefit: Enables parallel processing — more consumers = higher throughput.\n\nRule: Number of active consumers ≤ number of partitions. Extra consumers sit idle.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc44',
    front: 'What is Kafka consumer lag?',
    back:
        'Consumer lag is the difference between the latest offset in a partition and the consumer\'s current offset.\n\nHigh lag means: consumers are falling behind producers.\n\nFix: Add more consumers (up to partition count), optimize consumer processing, or increase partition count.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc45',
    front: 'What is a Kafka offset?',
    back:
        'An offset is a unique sequential ID assigned to each message within a Kafka partition.\n\nConsumers track their position using offsets. Committing an offset means "I have processed up to this message."\n\nAt-least-once delivery: commit after processing. At-most-once: commit before processing.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc46',
    front: 'What is an Airflow DAG?',
    back:
        'A DAG (Directed Acyclic Graph) is a collection of tasks with defined dependencies and execution order.\n\nKey properties: No cycles (acyclic), tasks run in dependency order, supports parallel execution.\n\nBackfill: Re-run a DAG for historical dates using: airflow dags backfill -s START -e END dag_id',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc47',
    front: 'What is Kafka Schema Registry?',
    back:
        'A centralized service that stores and validates Avro/Protobuf/JSON schemas for Kafka messages.\n\nBenefit: Ensures producers and consumers agree on message format. Prevents schema mismatches.\n\nSupports: Backward compatibility (new schema reads old data), forward compatibility (old schema reads new data).',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc48',
    front: 'What is Flink\'s watermark?',
    back:
        'A watermark tells Flink "I am confident all events up to this timestamp have arrived."\n\nUsed for: Handling out-of-order events in event-time processing.\n\nExample: forBoundedOutOfOrderness(Duration.ofHours(4)) waits 4 hours before closing a window.\n\nTrade-off: Larger watermark = more accuracy but higher latency.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc49',
    front:
        'What is the difference between event time and processing time in streaming?',
    back:
        'Event time: When the event actually occurred (from the device/source). Use for accurate analytics.\n\nProcessing time: When Kafka/Flink received the event. Simpler but inaccurate for late-arriving data.\n\nRule: Always use event time for business metrics. Processing time is only for operational monitoring.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc50',
    front: 'What is Flink\'s session window?',
    back:
        'A session window groups events that occur within a specified gap of each other.\n\nExample: Gap = 10 minutes. If no events arrive for 10 minutes, the window closes.\n\nUse case: Grouping a user\'s activity into sessions, reconstructing trip timelines from GPS pings.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc51',
    front: 'What is Debezium?',
    back:
        'An open-source CDC (Change Data Capture) platform that reads database transaction logs and streams changes to Kafka.\n\nSupports: PostgreSQL (WAL), MySQL (binlog), MongoDB (oplog).\n\nOutput: Each message contains the operation type (c=create, u=update, d=delete) and the new/old values.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc52',
    front: 'What is Airflow XCom?',
    back:
        'XCom (Cross-Communication) allows Airflow tasks to share small pieces of data with each other.\n\nUsage: task_instance.xcom_push(key="result", value=data) and xcom_pull(task_ids="task_name", key="result").\n\nWarning: XCom is stored in the Airflow metadata DB — only use for small values, not large datasets.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc53',
    front: 'What is Kafka\'s replication factor?',
    back:
        'The replication factor determines how many copies of each partition are stored across brokers.\n\nReplication factor 3: One leader + two replicas. If the leader fails, a replica is promoted.\n\nRecommendation: Use replication factor ≥ 3 in production for fault tolerance.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc54',
    front: 'What is Flink\'s KeyedProcessFunction?',
    back:
        'A low-level Flink API that processes events keyed by a specific field, with access to per-key state and timers.\n\nUse cases: Deduplication (store seen event IDs in state), fraud detection (track per-user velocity), session management.\n\nState TTL: Set a time-to-live to automatically expire old state and bound memory usage.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc55',
    front:
        'What is the difference between Kafka and a traditional message queue?',
    back:
        'Traditional queue (RabbitMQ): Messages are deleted after consumption. One consumer per message.\n\nKafka: Messages are retained for a configurable period (days/weeks). Multiple consumer groups can independently read the same messages.\n\nKafka is a log, not a queue — it enables replay and multiple independent consumers.',
    category: 'Orchestration',
  ),

  // ── Cloud Data Lakes (15 cards) ──────────────────────────────────────────
  FlashcardModel(
    id: 'fc56',
    front: 'What is data partitioning in distributed systems?',
    back:
        'Splitting data across multiple nodes/files to improve query performance and manageability.\n\nTypes: Range partitioning (by date), Hash partitioning (by key), List partitioning (by category).\n\nBenefit: Partition pruning — queries only scan relevant partitions.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc57',
    front: 'What is Apache Iceberg?',
    back:
        'An open table format for huge analytic datasets on object storage (S3, GCS).\n\nKey features: ACID transactions, schema evolution, time travel, hidden partitioning.\n\nAdvantage over Hive: Atomic commits, no partition discovery overhead, supports row-level deletes.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc58',
    front: 'What is Delta Lake?',
    back:
        'An open-source storage layer that brings ACID transactions to Apache Spark and object storage.\n\nKey features: ACID transactions, time travel (RESTORE), schema enforcement, MERGE command for upserts.\n\nUsed in: Databricks Medallion Architecture (Bronze/Silver/Gold).',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc59',
    front: 'What is the difference between Parquet and CSV for data lakes?',
    back:
        'CSV: Row-based, human-readable, no compression, slow for analytics.\n\nParquet: Columnar, compressed (Snappy/GZIP), fast for analytical queries (reads only needed columns).\n\nSwitching from CSV to Parquet typically gives 3-5x query speedup and 70-80% storage reduction.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc60',
    front: 'What is the small files problem in data lakes?',
    back:
        'Having thousands of tiny files (< 1MB) in S3/HDFS causes:\n• High metadata overhead (too many file listings)\n• Slow query planning\n• Excessive S3 API calls\n\nFix: Compact small files into larger ones (128MB-1GB). Delta Lake OPTIMIZE command does this automatically.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc61',
    front: 'What is time travel in Delta Lake / Iceberg?',
    back:
        'Time travel allows querying a table as it existed at a previous point in time.\n\nDelta Lake: SELECT * FROM table TIMESTAMP AS OF "2024-01-01"\nOr: SELECT * FROM table VERSION AS OF 5\n\nUse cases: Auditing, debugging data quality issues, reproducing ML training datasets.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc62',
    front: 'What is the MERGE command in Delta Lake?',
    back:
        'MERGE performs an upsert — update existing rows and insert new ones in a single atomic operation.\n\nSyntax:\nMERGE INTO target USING source ON target.id = source.id\nWHEN MATCHED THEN UPDATE SET ...\nWHEN NOT MATCHED THEN INSERT ...\n\nUse case: SCD Type 2 updates, deduplication, CDC application.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc63',
    front: 'What is Apache Hudi?',
    back:
        'An open-source data lake storage format that supports ACID transactions and incremental data processing on object storage.\n\nTwo table types:\n• Copy-on-Write (COW): Rewrites files on update. Fast reads, slow writes.\n• Merge-on-Read (MOR): Appends delta logs. Fast writes, slower reads.\n\nUsed heavily at Uber.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc64',
    front: 'What is S3 Select?',
    back:
        'S3 Select allows querying a subset of data from an S3 object using SQL expressions, without downloading the entire file.\n\nSupports: CSV, JSON, Parquet.\n\nBenefit: Reduces data transfer and processing costs when you only need a few columns or rows from a large file.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc65',
    front: 'What is data skipping in cloud data lakes?',
    back:
        'Data skipping uses file-level statistics (min/max values per column) to skip files that cannot contain matching rows.\n\nRequires: Data sorted or clustered by the filter column.\n\nImplemented in: Delta Lake (Z-ordering), Iceberg (hidden partitioning), Snowflake (micro-partition pruning).',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc66',
    front: 'What is Z-ordering in Delta Lake?',
    back:
        'Z-ordering co-locates related data in the same set of files by sorting on multiple columns simultaneously.\n\nCommand: OPTIMIZE table ZORDER BY (column1, column2)\n\nBenefit: Queries filtering on either column can skip more files. More effective than single-column sorting for multi-dimensional filters.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc67',
    front:
        'What is the difference between a managed and external table in a data lake?',
    back:
        'Managed table: The catalog manages both metadata and data files. Dropping the table deletes the data.\n\nExternal table: The catalog manages only metadata. Data files live in a user-specified location. Dropping the table does NOT delete the data.\n\nUse external tables when data is shared across multiple tools.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc68',
    front: 'What is schema-on-read vs schema-on-write?',
    back:
        'Schema-on-write: Schema is enforced when data is written (Data Warehouses). Ensures data quality upfront.\n\nSchema-on-read: Schema is applied when data is read (Data Lakes). Flexible ingestion, but quality issues discovered late.\n\nData Lakehouse: Schema-on-write with the flexibility of a data lake.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc69',
    front: 'What is data compaction in Delta Lake?',
    back:
        'Compaction merges many small files into fewer large files to improve read performance.\n\nDelta Lake command: OPTIMIZE table_name\n\nWhen to run: After many small incremental writes (streaming ingestion, CDC).\n\nVACUUM: Removes old files no longer referenced by the Delta log (default 7-day retention).',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc70',
    front: 'What is the Open Table Format (OTF) ecosystem?',
    back:
        'Open Table Formats add warehouse-like capabilities to data lakes on object storage.\n\nThe three main OTFs:\n• Apache Iceberg: Best for multi-engine compatibility\n• Delta Lake: Best for Databricks/Spark ecosystem\n• Apache Hudi: Best for streaming upserts (Uber)\n\nAll support: ACID transactions, time travel, schema evolution.',
    category: 'Cloud Data Lakes',
  ),

  // ── PySpark (15 cards) ───────────────────────────────────────────────────
  FlashcardModel(
    id: 'fc71',
    front: 'What is data skew in PySpark and how do you fix it?',
    back:
        'Data skew: A few partition keys have far more data than others, causing some executors to be overloaded.\n\nDiagnose: df.groupBy("key").count().orderBy(desc("count")).show(10)\n\nFixes:\n1. Broadcast join (if one table is small)\n2. Salting: Add random suffix to skewed keys, replicate the other table\n3. Split: Process skewed keys separately with broadcast join',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc72',
    front: 'What causes OutOfMemoryError in PySpark?',
    back:
        'Common causes:\n1. Data skew — one executor gets too much data\n2. Too few partitions — large partitions don\'t fit in memory\n3. Collecting large DataFrames to the driver (df.collect())\n4. Insufficient executor memory overhead\n\nFix: Repartition, increase spark.executor.memoryOverhead, use broadcast joins, avoid collect() on large data.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc73',
    front:
        'What is the difference between repartition() and coalesce() in Spark?',
    back:
        'repartition(n): Shuffles data across the network to create exactly n equal partitions. Expensive but balanced.\n\ncoalesce(n): Reduces partitions by merging local partitions without a full shuffle. Cheap but may create uneven partitions.\n\nRule: Use coalesce() to reduce partitions. Use repartition() to increase or rebalance.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc74',
    front: 'What is lazy evaluation in Spark?',
    back:
        'Spark does not execute transformations immediately — it builds a logical plan and only executes when an action is called.\n\nTransformations (lazy): filter(), select(), join(), groupBy()\nActions (trigger execution): count(), collect(), write(), show()\n\nBenefit: Spark can optimize the entire plan before executing.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc75',
    front: 'What is the Spark Catalyst Optimizer?',
    back:
        'Catalyst is Spark\'s query optimizer that automatically rewrites and optimizes SQL/DataFrame operations.\n\nOptimizations: Predicate pushdown (filter early), column pruning (read only needed columns), join reordering.\n\nResult: Writing df.filter(...).select(...) is equivalent to the optimal SQL — Catalyst handles the rest.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc76',
    front:
        'What is the difference between a Spark transformation and an action?',
    back:
        'Transformation: Creates a new DataFrame from an existing one. Lazy — not executed immediately.\nExamples: filter(), select(), join(), withColumn(), groupBy()\n\nAction: Triggers execution of the entire DAG.\nExamples: count(), collect(), show(), write(), take()',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc77',
    front: 'What is spark.sql.shuffle.partitions?',
    back:
        'Controls the number of partitions created after a shuffle operation (groupBy, join, distinct).\n\nDefault: 200 (often too low for large datasets, too high for small ones).\n\nRecommendation: Set to 2-3x your total executor cores.\n\nExample: spark.conf.set("spark.sql.shuffle.partitions", "400")',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc78',
    front: 'What is caching in PySpark and when should you use it?',
    back:
        'df.cache() stores a DataFrame in memory so it is not recomputed on subsequent actions.\n\nUse when: The same DataFrame is used in multiple actions or joins.\n\nDo NOT use when: The DataFrame is only used once — caching wastes memory.\n\ndf.unpersist() releases the cached data when done.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc79',
    front: 'What is a Spark Stage and how does it relate to shuffles?',
    back:
        'A Stage is a set of tasks that can run in parallel without a shuffle.\n\nA new stage begins whenever a shuffle is required (groupBy, join, repartition).\n\nShuffle: Data is redistributed across partitions over the network — the most expensive operation in Spark.\n\nMinimize shuffles to improve performance.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc80',
    front: 'What is the difference between DataFrame and RDD in Spark?',
    back:
        'RDD (Resilient Distributed Dataset): Low-level API, no schema, no query optimization. Use for unstructured data or custom transformations.\n\nDataFrame: High-level API with schema, SQL support, and Catalyst optimization. Faster and easier to use.\n\nRecommendation: Always use DataFrames/Datasets unless you need RDD-level control.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc81',
    front: 'What is Spark Structured Streaming?',
    back:
        'A stream processing engine built on Spark SQL that treats a live data stream as an unbounded table.\n\nSupports: Exactly-once semantics, event-time processing, watermarks, windowed aggregations.\n\nSources: Kafka, S3, Delta Lake.\nSinks: Delta Lake, Kafka, JDBC, console.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc82',
    front: 'What is predicate pushdown in Spark?',
    back:
        'Predicate pushdown moves filter conditions as close to the data source as possible, reducing the amount of data read.\n\nExample: Reading a Parquet file with filter(col("date") == "2024-01-01") — Spark reads only the matching row groups.\n\nEnabled automatically by Catalyst. Works with Parquet, ORC, Delta Lake, JDBC.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc83',
    front: 'What is the Spark driver vs executor?',
    back:
        'Driver: The master process that runs the main() function, creates the SparkContext, builds the execution plan, and coordinates executors.\n\nExecutor: Worker processes that run tasks and store data in memory/disk.\n\nRule: Never collect large DataFrames to the driver — it has limited memory and is a single point of failure.',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc84',
    front: 'What is salting in PySpark for skew handling?',
    back:
        'Salting adds a random number (0 to N-1) to skewed join keys, distributing one key\'s data across N partitions.\n\nSteps:\n1. Add salt to the large table: key + "_" + random(0, N)\n2. Replicate the small table N times with matching salt values\n3. Join on the salted key\n4. Remove the salt column after joining',
    category: 'PySpark',
  ),
  FlashcardModel(
    id: 'fc85',
    front: 'What is Spark\'s Tungsten execution engine?',
    back:
        'Tungsten is Spark\'s physical execution engine that optimizes CPU and memory usage.\n\nKey optimizations:\n• Off-heap memory management (avoids JVM GC overhead)\n• Cache-friendly data structures\n• Code generation (generates bytecode at runtime for each query)\n\nResult: Near-native performance for Spark SQL queries.',
    category: 'PySpark',
  ),

  // ── System Design (15 cards) ─────────────────────────────────────────────
  FlashcardModel(
    id: 'fc86',
    front: 'How do you design a real-time fraud detection pipeline?',
    back:
        'Architecture: Kafka → Flink → ML Model → Decision Router\n\nFeatures computed in Flink: velocity (transactions/hour), amount anomaly (vs 30-day avg), location mismatch.\n\nDecision thresholds:\n• Score > 0.95: Auto-block\n• Score 0.85-0.95: Step-up auth (OTP)\n• Score < 0.85: Allow\n\nTarget latency: < 100ms end-to-end.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc87',
    front: 'How do you handle late-arriving data in streaming pipelines?',
    back:
        'Strategy:\n1. Set a watermark matching max observed latency (e.g., 4 hours)\n2. Route events arriving after the watermark to a side output (DLQ)\n3. Apply corrections nightly: read late events, recalculate, UPDATE published rows\n4. Label reports as "preliminary" until the correction window closes\n\nMonitor: Track correction percentage daily.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc88',
    front: 'How do you deduplicate events in a streaming pipeline at scale?',
    back:
        'Three-layer strategy:\n1. Deterministic event IDs: SHA256(user_id + event_type + client_timestamp + session_id)\n2. Streaming dedup: Flink KeyedProcessFunction stores seen IDs in state with 24-hour TTL\n3. Batch dedup: ROW_NUMBER() OVER (PARTITION BY user_id, event_type, DATE(ts) ORDER BY server_ts) — keep rn=1\n\nMonitor: Track dedup rate daily.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc89',
    front: 'How do you design a CDC pipeline with Debezium?',
    back:
        'Architecture: PostgreSQL → Debezium → Kafka → Flink → Redis\n\nSteps:\n1. Enable logical replication: ALTER SYSTEM SET wal_level = logical\n2. Deploy Debezium connector (reads WAL, publishes to Kafka)\n3. Flink consumer updates Redis cache\n4. Recommendation engine reads from Redis\n\nLatency: 15 minutes (batch) → < 1 second (CDC).',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc90',
    front: 'How do you handle corrupted JSON payloads in a pipeline?',
    back:
        'Principle: Never let one bad record block the rest.\n\nStrategy:\n1. Wrap every parse in try/except\n2. Validate required fields and types (not just JSON syntax)\n3. Route failures to a DLQ (S3 folder or Kafka topic) with original payload + error reason\n4. Emit valid_count and invalid_count metrics\n5. Alert if error rate > 5%\n6. Replay from DLQ after fixing the root cause.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc91',
    front:
        'How do you design a Kafka DLQ strategy for a high-throughput pipeline?',
    back:
        'Separate DLQ topics by failure type:\n• pipeline.dlq.schema_error\n• pipeline.dlq.validation_error\n• pipeline.dlq.processing_error\n\nEach DLQ record includes: original payload, error reason, timestamp, retry count, source consumer group.\n\nAlert: If DLQ lag > 10,000 messages, page on-call.\nReplay: After fix, republish to main topic. Archive after 3 failed retries.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc92',
    front: 'How do you fix Redshift query performance with DS_DIST_BOTH?',
    back:
        'DS_DIST_BOTH means Redshift is shuffling both tables over the network to complete the join.\n\nFix:\n1. Set DISTKEY on the largest join column (e.g., customer_id) on both tables\n2. Use DISTSTYLE ALL for small dimension tables (< 1GB)\n3. Add SORTKEY on the most common filter column (e.g., order_date)\n4. Run VACUUM + ANALYZE after changes\n\nExpected: 45 min → < 5 min.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc93',
    front: 'How do you handle out-of-order GPS events in a streaming pipeline?',
    back:
        'Strategy:\n1. Always use event time (device timestamp), not processing time\n2. Set watermark to max observed latency (e.g., 30 minutes)\n3. Use session windows to group events into trips (close on 10-min gap)\n4. Sort events by client timestamp inside each window\n5. Detect and adjust for clock skew (> 5 min from server time)\n6. Deduplicate retried events using device_id + sequence_number',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc94',
    front: 'How do you design a data pipeline for 100K events/sec?',
    back:
        'Architecture: Kafka (50 partitions, keyed by user_id) → Flink (dedup + enrich + aggregate) → Three storage tiers:\n\n• Hot (Redis): Real-time dashboard, updated every second\n• Warm (Iceberg on S3): Queryable analytics, updated every few minutes\n• Cold (S3 Parquet): Raw events for historical analysis\n\nFault tolerance: Kafka at-least-once + idempotent writes + Flink checkpoints every 30s.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc95',
    front: 'How do you optimize a PySpark job from 4 hours to 45 minutes?',
    back:
        'Step-by-step:\n1. Profile first: Open Spark UI, find the slowest stage\n2. Fix skew: repartition on high-cardinality column\n3. Switch to Parquet: 3-5x speedup over CSV\n4. Broadcast small tables: Eliminate shuffle for joins < 200MB\n5. Cache reused DataFrames\n6. Tune: shuffle.partitions = 2-3x executor cores\n\nExpected: 4 hours → 30-45 minutes.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc96',
    front: 'What is a data quality framework and how do you implement it?',
    back:
        'A data quality framework validates data at each pipeline stage.\n\nKey checks:\n• Completeness: No unexpected nulls in required fields\n• Uniqueness: No duplicate primary keys\n• Freshness: Data updated within SLA\n• Referential integrity: Foreign keys exist in dimension tables\n• Volume: Row count within expected range\n\nTools: Great Expectations, dbt tests, custom Airflow validation tasks.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc97',
    front: 'How do you design a backfill strategy for a data pipeline?',
    back:
        'Backfill: Re-processing historical data after a bug fix or new pipeline deployment.\n\nStrategy:\n1. Make the pipeline idempotent (safe to re-run)\n2. Use date-partitioned writes (overwrite only the affected partition)\n3. Run backfill in parallel with smaller date ranges\n4. Validate row counts after each partition\n5. Airflow: airflow dags backfill -s START -e END dag_id\n\nNever backfill by appending — always overwrite the partition.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc98',
    front: 'What is the difference between push and pull ingestion patterns?',
    back:
        'Pull ingestion: The pipeline queries the source on a schedule (polling). Simple but adds load to the source.\n\nPush ingestion: The source sends data to the pipeline when events occur (webhooks, CDC, Kafka producers). Lower latency, no polling overhead.\n\nRecommendation: Use push (CDC/Kafka) for real-time requirements. Use pull (batch) for systems that don\'t support push.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc99',
    front: 'How do you handle schema changes in a production pipeline?',
    back:
        'Safe changes (backward-compatible):\n• Adding nullable columns\n• Widening types (INT → BIGINT)\n\nBreaking changes (require coordination):\n• Removing columns\n• Renaming columns\n• Changing types\n\nProcess: Use Schema Registry for Kafka, Delta Lake schema evolution for storage, dbt migrations for warehouse. Always test in staging first.',
    category: 'System Design',
  ),
  FlashcardModel(
    id: 'fc100',
    front: 'What is the SCD Type 2 implementation pattern at scale?',
    back:
        'Pattern:\n1. Add columns: effective_date, expiry_date (default 9999-12-31), is_current\n2. On change: Close old row (expiry_date = yesterday, is_current = false), insert new row\n3. Point-in-time query: JOIN ON id = id AND event_date BETWEEN effective_date AND expiry_date\n4. At scale: Use Delta Lake MERGE for atomic close-and-insert\n5. Performance: Partition by is_current — most queries only need current rows',
    category: 'System Design',
  ),
];

final List<InterviewQuestionModel> sampleInterviewQuestions = [
  // ─── META ─────────────────────────────────────────────────────────────────
  const InterviewQuestionModel(
    id: 'meta_q1',
    title: 'SCD Type 2 for User Profile Changes at Meta Scale',
    description:
        'Meta\'s user dimension table receives ~2M profile updates daily (name, location, language). Your current pipeline overwrites records (SCD Type 1). The analytics team needs point-in-time historical queries — e.g., "What was the user\'s country at the time of their first ad click in Q3 2023?" Redesign the dimension table to support full history.',
    answer:
        '''The core problem here is that overwriting records destroys history. To fix this, I'd switch to SCD Type 2, which keeps every version of a record instead of replacing it.

Here's how I'd approach it:

1. Add three new columns to the user table:
   • effective_date — when this version became active
   • expiry_date — when it was replaced (default: 9999-12-31 for current rows)
   • is_current — a simple true/false flag

2. Every time a user changes their country or language, instead of updating the row, I'd close the old one (set expiry_date to yesterday, is_current = false) and insert a brand-new row with today's date.

3. For point-in-time queries, the join becomes:
   JOIN dim_user ON user_id = user_id
   AND click_date BETWEEN effective_date AND expiry_date

4. At Meta's scale, I'd use Delta Lake's MERGE command for this — it handles the close-and-insert logic atomically and gives ACID guarantees.

5. For performance, I'd partition the table by is_current so most queries only scan the small "current" slice, not the full history.

The key insight I'd share in an interview: SCD Type 2 is the industry standard for any dimension that needs historical accuracy. The trade-off is more storage and slightly more complex queries, but the analytical value is worth it.''',
    category: 'Data Modeling',
    difficulty: 'Senior',
    isPro: false,
    tags: ['Meta', 'SCD Type 2', 'Data Modeling', 'Delta Lake'],
  ),
  const InterviewQuestionModel(
    id: 'meta_q2',
    title: 'Preventing Fan-Out Row Explosion in Multi-Level SQL JOINs',
    description:
        'Your pipeline joins three tables: users (1M rows), user_events (500M rows), and user_segments (10M rows, one user can belong to multiple segments). After the JOIN, your fact table has 8B rows instead of the expected 500M. Diagnose and fix the fan-out problem.',
    answer:
        '''This is a classic fan-out problem — and it's one of the most common mistakes in data engineering. Here's how I'd explain it and fix it.

Why it happens:
If a user belongs to 16 segments, every one of their 500 events gets matched to all 16 segments. That's 500 × 16 = 8,000 rows per user instead of 500. Multiply that across millions of users and you get billions of rows.

How I'd diagnose it:
First, I'd check for duplicate join keys:
   SELECT user_id, COUNT(*) FROM user_segments
   GROUP BY user_id HAVING COUNT(*) > 1

If users average 16 segments, that explains the 16x explosion.

Three ways to fix it:

Option 1 — Aggregate before joining (my preferred approach):
   Collapse user_segments into one row per user first, storing all their segments as an array. Then join. This keeps the row count at 500M.

Option 2 — Use LATERAL FLATTEN (Snowflake/BigQuery):
   Join the aggregated array and then explode it only when needed for analysis, not during the base join.

Option 3 — Pick only the primary segment:
   Use a window function (FIRST_VALUE with a priority order) to select one segment per user before joining.

The golden rule I always apply: always validate row counts after every join. If the output has more rows than the largest input table, something is wrong.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Meta', 'SQL', 'Fan-out', 'JOIN Optimization'],
  ),
  const InterviewQuestionModel(
    id: 'meta_q3',
    title: 'User Activity Deduplication for Accurate DAU Metrics',
    description:
        'Meta\'s event ingestion pipeline receives duplicate click events due to client-side retry logic and network timeouts. Your DAU (Daily Active Users) metric is inflated by ~12%. Design a deduplication strategy that works at 500M events/day without reprocessing the entire dataset.',
    answer:
        '''Duplicate events are a very common problem in distributed systems — clients retry on network failures, and you end up counting the same action twice. Here's how I'd solve it at scale.

The root cause:
When a mobile client doesn't get a confirmation, it resends the event. The server receives it twice, and both copies look legitimate.

My deduplication strategy has three layers:

1. Deterministic event IDs (the foundation):
   Every event must have a unique ID generated from its content:
   event_id = SHA256(user_id + event_type + client_timestamp + session_id)
   Same event, same ID — every time. This is the key to idempotency.

2. Streaming dedup with Flink:
   I'd use a KeyedProcessFunction that stores seen event IDs in state with a 24-hour TTL. If the same ID arrives twice, the second one is silently dropped. The TTL bounds memory usage.

3. Batch dedup with Spark (daily reconciliation):
   ROW_NUMBER() OVER (PARTITION BY user_id, event_type, DATE(client_ts)
   ORDER BY server_received_ts ASC) AS rn
   Keep only rn = 1. This is the ground truth that corrects any streaming misses.

4. Monitoring:
   I'd track the dedup rate daily. If it suddenly jumps from 12% to 25%, that signals a new client bug or a retry storm — and I'd want to catch that early.

The key point I'd make in an interview: deduplication is not a one-time fix. It needs to be built into the pipeline architecture from day one, at both the streaming and batch layers.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Meta', 'Deduplication', 'Flink', 'DAU', 'Kafka'],
  ),

  // ─── AMAZON ───────────────────────────────────────────────────────────────
  const InterviewQuestionModel(
    id: 'amz_q1',
    title: 'Redshift Distribution & Sort Key Selection for Query Performance',
    description:
        'Your Redshift cluster runs a daily report joining fact_orders (2B rows) with dim_product (500K rows) and dim_customer (80M rows). The query takes 45 minutes. After profiling, you see massive data redistribution (DS_DIST_BOTH) in the query plan. Diagnose and apply clustering to fix partition pruning.',
    answer:
        '''The 45-minute query time is a distribution problem. Redshift is moving data between nodes to complete the join — that's what DS_DIST_BOTH means. Here's how I'd fix it.

Why it's slow:
Redshift stores data across multiple nodes. When you join two tables and their rows aren't on the same node, Redshift has to shuffle data over the network. That's expensive and slow.

My fix — three decisions:

1. fact_orders gets DISTKEY(customer_id):
   The largest join is between orders and customers, so I co-locate them by customer_id. Rows with the same customer_id land on the same node — no network shuffle needed.

2. dim_customer gets DISTKEY(customer_id) too:
   This matches the fact table, so the join is completely local.

3. dim_product gets DISTSTYLE ALL:
   It's only 500K rows — small enough to copy to every node. This eliminates the product join shuffle entirely.

For sort keys, I'd add SORTKEY(order_date) on the fact table since most queries filter by date. Redshift can skip entire blocks of data it doesn't need.

After the change, I'd run VACUUM and ANALYZE to apply the new layout, then re-run EXPLAIN to confirm DS_DIST_BOTH is gone.

Expected result: 45 minutes → under 5 minutes.

The interview takeaway: always look at the EXPLAIN plan first. DS_DIST_BOTH is the most expensive pattern in Redshift and it's almost always fixable with the right distribution key.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: [
      'Amazon',
      'Redshift',
      'Distribution Key',
      'Sort Key',
      'Query Optimization',
    ],
  ),
  const InterviewQuestionModel(
    id: 'amz_q2',
    title: 'Silent Data Pipeline Failure Triage: Airflow + S3',
    description:
        'At 2 AM, your Airflow DAG shows all tasks as "success" (green) but downstream Redshift tables have zero new rows. No alerts fired. S3 landing bucket shows files were written. Triage this silent failure scenario step by step.',
    answer:
        '''This is one of the scariest types of failures — everything looks green but the data isn't there. Here's exactly how I'd triage it.

Step 1 — Confirm the problem (2 minutes):
   SELECT MAX(load_timestamp), COUNT(*) FROM fact_orders WHERE order_date = TODAY
   If this returns 0 rows, the pipeline wrote to S3 but the Redshift COPY failed silently.

Step 2 — Check Redshift's error log:
   SELECT query, filename, err_reason FROM stl_load_errors
   WHERE starttime > NOW() - INTERVAL '6 hours'
   This is the most important query. Common errors: type mismatch, null constraint violation, encoding error.

Step 3 — Check the S3 files directly:
   Verify the files aren't empty and are actually readable. A common bug is a Spark job that filters all rows and writes an empty Parquet file — no error, just 0 rows.

Step 4 — The root cause I'd look for first:
   df_filtered = df.filter(col("status") == "COMPLETED")
   df_filtered.write.parquet(s3_path)  # Succeeds even if df_filtered is empty!
   
   The fix: always assert row count before writing:
   if df_filtered.count() == 0:
       raise ValueError("Empty DataFrame — aborting write")

Step 5 — Add permanent guardrails:
   Add a validation task at the end of every DAG that checks the row count in Redshift. If it's below a minimum threshold, the task fails and alerts fire.

The key lesson: "success" in Airflow only means the task ran without crashing. It doesn't mean data was loaded. Always validate the output, not just the process.''',
    category: 'Incident Response',
    difficulty: 'Senior',
    isPro: false,
    tags: [
      'Amazon',
      'Airflow',
      'S3',
      'Redshift',
      'Silent Failure',
      'Incident Response',
    ],
  ),
  const InterviewQuestionModel(
    id: 'amz_q3',
    title: 'Handling Late-Arriving Data in Streaming Pipelines',
    description:
        'Your Kinesis → Flink → Redshift pipeline processes order events. Business requires hourly revenue reports. You discover that 8% of mobile app events arrive 2-4 hours late due to offline mode. Your hourly aggregates are consistently understated. Design a late data handling strategy.',
    answer:
        '''Late data is a fundamental challenge in streaming — mobile apps go offline, buffer events, and send them in bulk when reconnected. Here's how I'd handle it properly.

The core concept — watermarks:
A watermark tells Flink "I'm confident all events up to this time have arrived." I'd set a 4-hour watermark to match the maximum observed latency. Flink waits 4 hours before closing a window.

My three-layer strategy:

1. Configure the watermark in Flink:
   WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofHours(4))
   This tells Flink to wait 4 hours before finalizing each hourly window.

2. Handle events that arrive even later (side outputs):
   For events arriving more than 4 hours late, I'd route them to a "late events" side output instead of dropping them. These get stored separately for correction.

3. Apply corrections to Redshift:
   A nightly job reads the late events, calculates the missing revenue, and runs an UPDATE on the already-published hourly rows. This way, reports are initially approximate but become accurate over time.

The business communication piece:
I'd clearly label reports as "preliminary" for the first 4 hours and "final" after the correction window closes. This sets the right expectations.

Monitoring:
Track the correction percentage daily. If corrections are consistently above 10%, the watermark needs to be extended.

The interview insight: there's no perfect solution for late data — it's always a trade-off between latency and accuracy. The right answer is to make that trade-off explicit and build a correction mechanism.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: [
      'Amazon',
      'Flink',
      'Kinesis',
      'Late Data',
      'Watermarks',
      'Streaming',
    ],
  ),
  const InterviewQuestionModel(
    id: 'amz_q4',
    title: 'Handling Corrupted JSON Payloads in S3 Ingestion Pipelines',
    description:
        'Your Lambda function ingests JSON events from an S3 bucket into DynamoDB. After a vendor API change, 3% of payloads contain malformed JSON (truncated strings, missing required fields, unexpected null types). Your pipeline crashes on these records, blocking all subsequent processing.',
    answer:
        '''The mistake here is treating bad data as a fatal error. A robust pipeline should isolate bad records and keep processing the good ones. Here's how I'd redesign it.

The core principle — never let one bad record block the rest:
Instead of crashing, the pipeline should route bad records to a Dead Letter Queue (DLQ) and continue.

My approach:

1. Wrap every parse in a try/except:
   For each record, I'd attempt to parse the JSON and validate it against a schema. If either step fails, I catch the error and send the record to the DLQ — I never let it crash the Lambda.

2. Schema validation (not just JSON parsing):
   Valid JSON doesn't mean valid data. I'd define required fields (order_id, user_id, amount, timestamp) and validate types. A missing order_id is just as bad as malformed JSON.

3. The DLQ is an S3 folder:
   Failed records go to s3://dlq-bucket/failed/ with the original payload, the error reason, and a timestamp. This gives engineers everything they need to investigate and replay.

4. Emit metrics to CloudWatch:
   After each batch, I'd publish valid_count and invalid_count. If the error rate exceeds 5%, an alarm fires and the on-call engineer is paged.

5. Reprocessing after the vendor fixes their API:
   Read from the DLQ, re-parse, validate, and re-ingest. Mark each record as "reprocessed" so it's not replayed twice.

The key interview point: a DLQ is not a failure — it's a feature. It means your pipeline is resilient. The real failure is a pipeline that crashes and blocks everything.''',
    category: 'Incident Response',
    difficulty: 'Mid',
    isPro: false,
    tags: ['Amazon', 'JSON', 'DLQ', 'Lambda', 'S3', 'Data Quality'],
  ),

  // ─── SNOWFLAKE / DATABRICKS ───────────────────────────────────────────────
  const InterviewQuestionModel(
    id: 'snow_q1',
    title: 'Snowflake Micro-Partition Tuning & Clustering Keys',
    description:
        'Your Snowflake query scanning a 500GB fact_transactions table takes 8 minutes despite having a WHERE clause on transaction_date. EXPLAIN output shows 95% of micro-partitions are being scanned. Diagnose and apply clustering to fix partition pruning.',
    answer:
        '''The problem is that Snowflake can't skip any data — it's scanning 95% of the table even though you're filtering by date. This means the data isn't organized in a way that helps Snowflake prune partitions.

How Snowflake stores data:
Snowflake automatically splits tables into micro-partitions (roughly 50-500MB each). Each partition stores metadata about the min/max values of every column. When you filter by date, Snowflake checks this metadata and skips partitions that can't contain matching rows. But if data was loaded in random order, every partition contains a mix of dates — so nothing can be skipped.

How to fix it — Clustering Keys:

1. Check the current clustering health:
   SELECT SYSTEM\$CLUSTERING_INFORMATION('fact_transactions', '(transaction_date)')
   Look at average_depth and average_overlaps. High values mean poor clustering.

2. Apply a clustering key:
   ALTER TABLE fact_transactions CLUSTER BY (TO_DATE(transaction_date), merchant_id)
   Snowflake will now reorganize data in the background so rows with the same date are stored together.

3. Test safely first:
   Use Zero-Copy Cloning to create a test copy and apply clustering there. Compare query performance before touching production.

4. Monitor the cost:
   Clustering uses compute credits. Check the automatic_clustering_history view to make sure the benefit outweighs the cost.

Expected result: 95% partitions scanned → 3-5% scanned. 8 minutes → under 30 seconds.

The interview insight: clustering keys are Snowflake's version of a sort key. They're most valuable on large tables with frequent range filters on date or region columns.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Snowflake', 'Micro-partitions', 'Clustering', 'Query Optimization'],
  ),
  const InterviewQuestionModel(
    id: 'dbx_q1',
    title: 'PySpark OOM Fix: Memory Optimization & Skewed Join Handling',
    description:
        'Your Databricks PySpark job fails with java.lang.OutOfMemoryError: GC overhead limit exceeded when joining a 2TB orders table with a 50GB customer table. The job uses 100 executors with 16GB RAM each. Some customer_ids appear in 40% of all orders (power users). Fix the OOM and skew.',
    answer:
        '''This is a data skew problem causing an OOM. A small number of "power user" customer IDs have so many orders that a single executor gets overwhelmed trying to process them all. Here's how I'd fix it.

First, confirm the skew:
   orders.groupBy("customer_id").count().orderBy(desc("count")).show(10)
   If the top 5 IDs have 40% of all rows, that's your problem.

Three fixes, in order of preference:

Fix 1 — Broadcast Join (simplest, if it fits):
   result = orders.join(broadcast(customers), "customer_id")
   This sends a full copy of the customers table to every executor, eliminating the shuffle entirely. Works if customers is under ~10GB.

Fix 2 — Salting (for severe skew):
   Add a random "salt" number (0-49) to the skewed keys in orders, then replicate each customer row 50 times with matching salt values. Now the 40% of orders for one customer_id gets spread across 50 partitions instead of one.
   
   This is the most powerful fix but adds complexity. I'd use it when broadcast isn't possible due to table size.

Fix 3 — Split and conquer:
   Separate the top 5 skewed IDs from the rest. Join the skewed subset with a broadcast join (it's a small subset). Join the normal subset with a regular join. Union the results.

Memory tuning alongside the fix:
   spark.executor.memoryOverhead = 4g  (extra buffer for JVM overhead)
   spark.sql.shuffle.partitions = 800  (more partitions = smaller each)

The interview insight: OOM errors in Spark are almost always caused by skew, not by the total data size. The fix is to redistribute the work, not just add more RAM.''',
    category: 'PySpark',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Databricks', 'PySpark', 'OOM', 'Skew', 'Memory Optimization'],
  ),
  const InterviewQuestionModel(
    id: 'snow_q2',
    title: 'Zero-Copy Cloning vs CTE Performance Trade-offs in Snowflake',
    description:
        'Your team debates whether to use Snowflake Zero-Copy Clones or CTEs for creating development/test environments and intermediate query results. When should you use each, and what are the performance implications?',
    answer:
        '''These two features solve completely different problems — the confusion usually comes from thinking they're alternatives when they're not.

Zero-Copy Clone — for environments and snapshots:
A clone creates an independent copy of a table or schema in seconds, with no data duplication. Snowflake uses copy-on-write: the clone shares the original's storage until you modify it.

When to use it:
• Creating a dev or test environment from production data (instant, free)
• Taking a snapshot before a risky migration
• Letting two teams experiment on the same dataset independently

Cost model: Free to create. You only pay for storage on rows that change after the clone.

CTE — for query readability:
A CTE is just a named subquery inside a single SQL statement. It makes complex queries easier to read by breaking them into named steps.

When to use it:
• Breaking a 200-line query into readable logical steps
• Referencing the same subquery multiple times in one query
• Writing recursive queries for hierarchical data

Important limitation: CTEs are recomputed every time they're referenced. If you use the same CTE 5 times, Snowflake runs it 5 times.

When CTEs aren't enough — use a Transient Table:
If you need to share intermediate results across multiple queries or sessions, materialize it:
   CREATE TRANSIENT TABLE tmp_daily_revenue AS SELECT ...
Transient tables have no Fail-safe cost and are perfect for temporary work.

The one-line summary for interviews: Use Zero-Copy Clone for environments and backups. Use CTEs for query readability. Use Transient Tables when you need to reuse intermediate results.''',
    category: 'System Design',
    difficulty: 'Mid',
    isPro: false,
    tags: [
      'Snowflake',
      'Zero-Copy Clone',
      'CTE',
      'Performance',
      'Cost Optimization',
    ],
  ),

  // ─── UBER / NETFLIX ───────────────────────────────────────────────────────
  const InterviewQuestionModel(
    id: 'uber_q1',
    title: 'Real-Time Kafka Event Stream Processing with Dead Letter Queues',
    description:
        'Uber\'s trip events pipeline processes 2M events/minute via Kafka. Your Flink consumer fails on ~0.1% of events due to schema mismatches, null GPS coordinates, and unexpected event types. These failures cause consumer lag to grow, eventually blocking all processing. Design a DLQ strategy.',
    answer:
        '''The problem is that one bad event is blocking the entire pipeline. The fix is to never let a single bad record stop the consumer — route it to a DLQ and keep moving.

My DLQ architecture:

1. Separate DLQ topics by failure type:
   • trips.events.dlq.schema_error — wrong field types or missing fields
   • trips.events.dlq.validation_error — null GPS, invalid trip ID
   • trips.events.dlq.processing_error — unexpected runtime exceptions
   
   Separating by type makes it much easier to fix and replay each category independently.

2. The Flink processor wraps everything in try/catch:
   For each event, I validate required fields and GPS coordinates first. If validation fails, I send it to the right DLQ topic with the original payload, the error reason, and a timestamp. If processing throws an unexpected exception, that goes to the processing_error DLQ. Valid events flow through normally.

3. The DLQ record includes everything needed for replay:
   Original event, error reason, timestamp, retry count, and source consumer group. This is critical — you need to be able to replay without losing context.

4. Monitoring and alerting:
   If DLQ lag exceeds 10,000 messages, PagerDuty fires. I'd also track DLQ rate as a percentage of total events. Target: under 0.05%.

5. Reprocessing after a fix:
   A separate job reads from the DLQ, applies the fix, and republishes to the main topic. After 3 failed retries, the record is archived to S3 for manual review.

The interview insight: a DLQ is what separates a production-grade pipeline from a fragile one. The goal is to isolate failures, not prevent them — failures will always happen at scale.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Uber', 'Kafka', 'DLQ', 'Flink', 'Streaming', 'Fault Tolerance'],
  ),
  const InterviewQuestionModel(
    id: 'netflix_q1',
    title: 'CDC via Debezium: Capturing Database Changes for Real-Time Sync',
    description:
        'Netflix needs to sync changes from a PostgreSQL user preferences database (10K writes/min) to their recommendation engine in near real-time. The current batch sync runs every 15 minutes causing stale recommendations. Design a CDC pipeline using Debezium.',
    answer:
        '''The 15-minute batch sync is too slow for a recommendation engine — user preferences need to be reflected in seconds, not minutes. Change Data Capture (CDC) is the right solution here.

What CDC does:
Instead of querying the database on a schedule, CDC reads the database's transaction log (WAL in PostgreSQL) and streams every INSERT, UPDATE, and DELETE as an event in real time. No polling, no delay.

My architecture:
PostgreSQL → Debezium → Kafka → Flink → Redis (recommendation cache)

Step 1 — Enable logical replication in PostgreSQL:
   ALTER SYSTEM SET wal_level = logical
   This tells PostgreSQL to write enough detail in its logs for CDC to work.

Step 2 — Deploy Debezium connector:
   Debezium connects to PostgreSQL, reads the WAL, and publishes every change to a Kafka topic. The topic name follows the pattern: server.schema.table. Each message contains the new values plus an operation type (c=create, u=update, d=delete).

Step 3 — Flink consumer updates the recommendation cache:
   The Flink job reads from Kafka, filters out deletes if needed, and writes updated preferences to Redis. The recommendation engine reads from Redis — latency drops from 15 minutes to under 1 second.

Step 4 — Handle schema changes safely:
   Debezium integrates with Schema Registry. When a new column is added to PostgreSQL, the schema is updated automatically. I'd only use backward-compatible changes (adding nullable columns) to avoid breaking consumers.

Monitoring:
Track replication lag — the time between a write in PostgreSQL and when it appears in Kafka. Target: under 500ms.

The interview insight: CDC is the gold standard for real-time database sync. It's more reliable than polling because it captures every change, including deletes, without any load on the source database.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Netflix', 'CDC', 'Debezium', 'PostgreSQL', 'Kafka', 'Real-time'],
  ),
  const InterviewQuestionModel(
    id: 'uber_q2',
    title: 'Handling Out-of-Order Log Timestamps in Distributed Systems',
    description:
        'Uber\'s driver location logs arrive out of order due to GPS buffering, network retries, and clock skew across devices. Your pipeline must reconstruct accurate trip timelines and compute precise trip duration. Events can arrive up to 30 minutes late. Design the ordering strategy.',
    answer:
        '''Out-of-order events are unavoidable in mobile systems. GPS devices buffer data when offline, clocks drift, and networks retry. The pipeline needs to handle this gracefully rather than assuming events arrive in order.

The fundamental rule: always use event time, not processing time.
Event time = when the GPS event actually happened (from the device).
Processing time = when Kafka received it.
These can differ by 30 minutes. Using processing time would give you completely wrong trip durations.

My strategy:

1. Set a 30-minute watermark in Flink:
   WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofMinutes(30))
   This tells Flink: "wait 30 minutes before closing a window, to give late events time to arrive."

2. Use session windows to group events into trips:
   A session window closes when there's a 10-minute gap in events. This naturally groups a driver's location pings into individual trips, even if some pings arrive late.

3. Sort events by client timestamp inside each window:
   Before computing trip duration, sort all events by their device timestamp. This reconstructs the correct timeline regardless of arrival order.

4. Handle clock skew:
   If a device's clock is more than 5 minutes off from server time, I'd use the server timestamp as an anchor and adjust. This prevents a device with a wrong clock from corrupting the timeline.

5. Deduplicate retried events:
   Use device_id + sequence_number as a unique event ID. Store seen IDs in Redis with a 24-hour TTL to drop duplicates.

Monitoring:
Track what percentage of events arrive after the watermark. If it's above 5%, extend the watermark window.

The interview insight: the hardest part of streaming is not the processing — it's correctly defining "when did this event happen?" Getting event time right is the foundation of accurate streaming analytics.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Uber', 'Flink', 'Out-of-Order', 'Watermarks', 'Event Time', 'GPS'],
  ),
  // ─── EXISTING QUESTIONS (preserved) ──────────────────────────────────────
  const InterviewQuestionModel(
    id: 'iq1',
    title: 'Design an Event-Driven Data Pipeline for E-Commerce Clickstream',
    description:
        'Design a scalable, fault-tolerant event-driven data pipeline to process e-commerce clickstream data (page views, add-to-cart, purchases) in real-time using Kafka and Flink. The system must handle 100K events/sec at peak.',
    answer:
        '''I'd design this as a three-layer pipeline: ingestion, processing, and storage.

Ingestion — Kafka:
Kafka is the backbone. I'd create topics partitioned by user_id so all events from the same user land on the same partition, preserving order. At 100K events/sec, I'd start with 50 partitions and scale up based on consumer lag.

Processing — Flink:
The Flink job does three things:
• Deduplication: use event_id + a 5-minute window to drop retries
• Enrichment: join with a Redis cache to add user profile data (country, segment) without hitting the database on every event
• Aggregation: compute real-time metrics like funnel conversion rates and session duration using sliding windows

Storage — three tiers:
• Hot (Redis): real-time dashboard metrics, updated every second
• Warm (Apache Iceberg on S3): queryable analytical data, updated every few minutes
• Cold (S3 Parquet): raw events for historical analysis and model training

Fault tolerance:
Kafka gives at-least-once delivery, so I'd use idempotent writes everywhere downstream. Flink checkpoints every 30 seconds so recovery from a failure means replaying at most 30 seconds of data.

The key design decision I'd highlight: keeping the hot, warm, and cold paths separate means a slow analytical query never affects the real-time dashboard. Each layer is independently scalable.''',
    category: 'System Design',
    difficulty: 'Senior',
    isPro: true,
    tags: ['Kafka', 'Flink', 'Streaming', 'Architecture'],
  ),
  const InterviewQuestionModel(
    id: 'iq2',
    title: 'Optimize a Slow PySpark Job Processing 10TB Daily',
    description:
        'Your PySpark job processing 10TB of daily transaction data takes 4 hours. Stakeholders need it under 45 minutes. Walk through your optimization strategy.',
    answer:
        '''A 4-hour job on 10TB is almost always fixable. I'd approach this systematically, starting with the biggest wins first.

Step 1 — Diagnose before optimizing:
Open the Spark UI and look at the stage timeline. The longest stage is where the bottleneck is. Check partition sizes — if one partition is 10x larger than the others, that's data skew and it's the most common cause of slow jobs.

Step 2 — Fix data skew (biggest win):
   df.rdd.glom().map(len).collect()  # Check partition sizes
   If skewed, repartition on a high-cardinality column:
   df.repartition(200, "transaction_date")

Step 3 — Switch to a better file format:
   If the input is CSV, switching to Parquet alone can give a 3-5x speedup. Parquet is columnar — Spark only reads the columns it needs, not the entire row. Add Snappy compression to reduce I/O further.

Step 4 — Use broadcast joins for small tables:
   Any lookup table under 200MB should be broadcast:
   spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 209715200)
   This eliminates the shuffle for those joins entirely.

Step 5 — Cache DataFrames that are used multiple times:
   df.cache()  # Keeps it in memory so it's not recomputed
   Only cache if the DataFrame is actually reused — caching unused data wastes memory.

Step 6 — Tune Spark config:
   spark.sql.shuffle.partitions = 400  (2-3x your total executor cores)
   spark.executor.memory = 8g
   spark.executor.cores = 4

Expected result: 4 hours → 30-45 minutes with these changes combined.

The interview insight: always profile before optimizing. The fix for skew is completely different from the fix for too many small files — you need to know which problem you have.''',
    category: 'PySpark',
    difficulty: 'Mid',
    isPro: true,
    tags: ['PySpark', 'Performance', 'Optimization'],
  ),
  const InterviewQuestionModel(
    id: 'iq3',
    title: 'Diagnose and Fix a Data Pipeline Incident',
    description:
        'At 2 AM, your Airflow DAG fails silently. Downstream dashboards show stale data from 6 hours ago. Walk through your incident response process.',
    answer:
        '''Silent failures are the hardest to deal with because there's no obvious alert. Here's how I'd handle this step by step.

First 5 minutes — triage and communicate:
Check the Airflow UI for the last successful run and any error logs. Immediately message stakeholders: "Investigating data freshness issue, ETA for update in 30 minutes." Setting expectations early is just as important as fixing the problem.

Next 10 minutes — find the root cause:
   SELECT MAX(updated_at) FROM fact_orders  -- How stale is the data?
   
   Then check the Airflow task logs for the word "ERROR". Common causes:
   • API rate limit from the source system
   • Database connection timeout
   • Disk space full on the worker
   • Schema change in the source that broke parsing

Fix and recover:
Once I find the root cause, I fix it and trigger a backfill:
   airflow dags backfill -s 2024-01-01 -e 2024-01-02 my_dag
   
   After the backfill, I validate the data:
   SELECT COUNT(*), MAX(updated_at) FROM fact_orders WHERE order_date = TODAY
   Only after this check do I tell stakeholders the data is fresh again.

Prevent it from happening again:
• Add a data freshness check as the last task in every DAG — if the row count is below a minimum, the task fails and alerts fire
• Add retry logic with exponential backoff for transient failures
• Set up Great Expectations for post-load data quality checks

The interview insight: incident response is 30% technical and 70% communication. The fastest fix means nothing if stakeholders don't know the data is stale. Always communicate first, then fix.''',
    category: 'Incident Response',
    difficulty: 'Senior',
    isPro: false,
    tags: ['Airflow', 'Incident', 'Data Quality'],
  ),
  const InterviewQuestionModel(
    id: 'iq4',
    title: 'Explain Slowly Changing Dimensions (SCD) Types',
    description:
        'What are Slowly Changing Dimensions? Explain Type 1, Type 2, and Type 3 with use cases.',
    answer:
        '''SCDs are about how you handle changes to dimension data over time. The question is: when a customer moves to a new city, do you keep the old city or replace it?

Type 1 — Overwrite (no history):
Simply update the record. The old value is gone forever.
   UPDATE dim_customer SET city = 'New York' WHERE customer_id = 123

Use when: the old value doesn't matter. Correcting a typo, updating an email address, fixing a data entry error.

Type 2 — Add a new row (full history):
This is the most important one. Instead of updating, you close the old record and insert a new one.
   • Add effective_date, expiry_date, and is_current columns
   • Set the old row's expiry_date to yesterday and is_current = false
   • Insert a new row with today's effective_date and is_current = true

Use when: you need to answer "what was the customer's city at the time of purchase?" This is the standard for most analytical use cases.

Type 3 — Add a column (limited history):
Add a "previous_value" column alongside the current one.
   • current_city = 'New York'
   • previous_city = 'Boston'

Use when: you only need one level of history and want simpler queries. Rarely used in practice because it only tracks one change.

My recommendation for interviews:
Lead with Type 2. It's what most companies use, and knowing how to implement it with effective/expiry dates and is_current flags shows real-world experience. Mention that at scale, you'd use Delta Lake's MERGE command to handle the close-and-insert atomically.''',
    category: 'Data Modeling',
    difficulty: 'Junior',
    isPro: false,
    tags: ['Data Modeling', 'Warehouse', 'SCD'],
  ),
  const InterviewQuestionModel(
    id: 'iq5',
    title: 'Design a Real-Time Fraud Detection Pipeline',
    description:
        'Design a data pipeline to detect fraudulent transactions in real-time for a payment processor handling 50K transactions/minute.',
    answer:
        '''Fraud detection needs to be fast (under 100ms) and accurate. I'd design this as a streaming pipeline with three stages: feature engineering, ML scoring, and decision routing.

Ingestion — Kafka:
Every transaction goes into a Kafka topic with 50 partitions, keyed by user_id. This ensures all transactions for the same user are processed in order, which is critical for velocity checks.

Feature Engineering — Flink:
For each transaction, I'd compute real-time features:
• Velocity: how many transactions has this user made in the last hour?
• Amount anomaly: is this amount more than 3 standard deviations above their 30-day average?
• Location mismatch: is this transaction happening 500 miles from their last one?

These features are computed in Flink using sliding windows and enriched with user history from a Redis cache.

ML Scoring:
A pre-trained XGBoost model (loaded into the Flink operator) scores each transaction in under 10ms. The model outputs a fraud probability between 0 and 1.

Decision Routing:
• Score > 0.95: Auto-block the transaction and send a push notification to the user
• Score 0.85-0.95: Allow but require step-up authentication (OTP)
• Score < 0.85: Allow and log for model retraining

Storage:
All transactions go to an Iceberg table for model retraining. Flagged transactions go to PostgreSQL for the fraud analyst team to review.

End-to-end latency target: under 100ms from transaction to decision.

The interview insight: the key to fraud detection is feature freshness. A model trained on yesterday's data is only as good as the real-time features you feed it. The Flink feature engineering layer is what makes the model effective.''',
    category: 'System Design',
    difficulty: 'Lead',
    isPro: true,
    tags: ['Kafka', 'Flink', 'ML', 'Real-time'],
  ),
];
