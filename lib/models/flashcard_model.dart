class FlashcardModel {
  final String id;
  final String front;
  final String back;
  final String category;
  bool isMastered;

  FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.category,
    this.isMastered = false,
  });
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
  FlashcardModel(
    id: 'fc1',
    front: 'What is the difference between Star Schema and Snowflake Schema?',
    back:
        'Star Schema: Denormalized, single fact table surrounded by dimension tables. Fast queries, simple joins.\n\nSnowflake Schema: Normalized dimensions split into sub-tables. Saves storage, more complex joins, slower queries.',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc2',
    front: 'Explain ACID vs BASE consistency models.',
    back:
        'ACID: Atomicity, Consistency, Isolation, Durability — used in relational DBs for strict transactions.\n\nBASE: Basically Available, Soft state, Eventually consistent — used in NoSQL for high availability and scalability.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc3',
    front: 'What is ETL vs ELT?',
    back:
        'ETL: Extract → Transform → Load. Transform happens before loading into warehouse. Traditional approach.\n\nELT: Extract → Load → Transform. Raw data loaded first, then transformed inside the warehouse. Modern cloud approach (Snowflake, BigQuery).',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc4',
    front: 'What is a Data Lakehouse?',
    back:
        'A hybrid architecture combining the low-cost storage of a Data Lake with the ACID transactions and schema enforcement of a Data Warehouse. Examples: Delta Lake, Apache Iceberg, Apache Hudi.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc5',
    front: 'What are SQL Window Functions?',
    back:
        'Window functions perform calculations across a set of rows related to the current row without collapsing them.\n\nExamples: ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD(), SUM() OVER(), AVG() OVER(PARTITION BY ... ORDER BY ...)',
    category: 'SQL',
  ),
  FlashcardModel(
    id: 'fc6',
    front: 'What is Apache Kafka?',
    back:
        'A distributed event streaming platform used for high-throughput, fault-tolerant, real-time data pipelines.\n\nKey concepts: Topics, Partitions, Producers, Consumers, Consumer Groups, Offsets, Brokers.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc7',
    front: 'What is the CAP Theorem?',
    back:
        'A distributed system can only guarantee 2 of 3 properties:\n• Consistency: All nodes see the same data\n• Availability: Every request gets a response\n• Partition Tolerance: System works despite network failures\n\nNoSQL DBs typically choose AP or CP.',
    category: 'Architecture',
  ),
  FlashcardModel(
    id: 'fc8',
    front: 'What is Apache Airflow?',
    back:
        'An open-source workflow orchestration platform for authoring, scheduling, and monitoring data pipelines as DAGs (Directed Acyclic Graphs).\n\nKey components: DAG, Task, Operator, Scheduler, Executor, XCom.',
    category: 'Orchestration',
  ),
  FlashcardModel(
    id: 'fc9',
    front: 'What is data partitioning in distributed systems?',
    back:
        'Splitting data across multiple nodes/files to improve query performance and manageability.\n\nTypes: Range partitioning, Hash partitioning, List partitioning.\n\nBenefit: Partition pruning — queries only scan relevant partitions.',
    category: 'Cloud Data Lakes',
  ),
  FlashcardModel(
    id: 'fc10',
    front: 'What is the difference between batch and stream processing?',
    back:
        'Batch: Processes large volumes of data at scheduled intervals (e.g., nightly ETL). Tools: Spark, Hive.\n\nStream: Processes data continuously as it arrives in real-time. Tools: Kafka Streams, Apache Flink, Spark Structured Streaming.',
    category: 'Architecture',
  ),
];

final List<InterviewQuestionModel> sampleInterviewQuestions = [
  // ─── META ─────────────────────────────────────────────────────────────────
  const InterviewQuestionModel(
    id: 'meta_q1',
    title: 'SCD Type 2 for User Profile Changes at Meta Scale',
    description:
        'Meta\'s user dimension table receives ~2M profile updates daily (name, location, language). Your current pipeline overwrites records (SCD Type 1). The analytics team needs point-in-time historical queries — e.g., "What was the user\'s country at the time of their first ad click in Q3 2023?" Redesign the dimension table to support full history.',
    answer: '''SCD Type 2 Implementation Playbook:

1. Schema Design:
   ALTER TABLE dim_user ADD COLUMN (
     surrogate_key    BIGINT GENERATED ALWAYS AS IDENTITY,
     effective_date   DATE    NOT NULL,
     expiry_date      DATE    DEFAULT '9999-12-31',
     is_current       BOOLEAN DEFAULT TRUE
   );

2. Daily Merge Logic (Spark SQL / dbt):
   MERGE INTO dim_user AS target
   USING (SELECT * FROM stg_user_updates) AS source
   ON target.user_id = source.user_id
      AND target.is_current = TRUE
   WHEN MATCHED AND (
     target.country != source.country OR
     target.language != source.language
   ) THEN UPDATE SET
     target.expiry_date = CURRENT_DATE - 1,
     target.is_current  = FALSE
   WHEN NOT MATCHED THEN INSERT (
     user_id, country, language,
     effective_date, expiry_date, is_current
   ) VALUES (
     source.user_id, source.country, source.language,
     CURRENT_DATE, '9999-12-31', TRUE
   );

   -- Insert new version for changed records
   INSERT INTO dim_user (user_id, country, language, effective_date, expiry_date, is_current)
   SELECT source.user_id, source.country, source.language,
          CURRENT_DATE, '9999-12-31', TRUE
   FROM stg_user_updates source
   JOIN dim_user target ON target.user_id = source.user_id
     AND target.is_current = FALSE
     AND target.expiry_date = CURRENT_DATE - 1;

3. Point-in-Time Join:
   SELECT f.ad_click_id, d.country
   FROM fact_ad_clicks f
   JOIN dim_user d
     ON f.user_id = d.user_id
    AND f.click_date BETWEEN d.effective_date AND d.expiry_date;

4. Performance Tip:
   - Partition dim_user by is_current to avoid scanning historical rows
   - Add composite index on (user_id, is_current)
   - At Meta scale, use Delta Lake MERGE for ACID guarantees''',
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
    answer: '''Fan-Out Diagnosis & Fix:

1. Diagnose the Explosion:
   -- Check for duplicate join keys
   SELECT user_id, COUNT(*) as cnt
   FROM user_segments
   GROUP BY user_id
   HAVING COUNT(*) > 1
   ORDER BY cnt DESC LIMIT 10;
   -- If users have avg 16 segments, 500M * 16 = 8B rows ✓

2. Root Cause:
   Many-to-many relationship between user_events and user_segments
   causes Cartesian-like multiplication.

3. Fix Option A — Aggregate Before Join:
   WITH user_segment_agg AS (
     SELECT user_id,
            ARRAY_AGG(segment_name) AS segments,
            COUNT(*)                AS segment_count
     FROM user_segments
     GROUP BY user_id
   )
   SELECT e.*, s.segments, s.segment_count
   FROM user_events e
   LEFT JOIN user_segment_agg s USING (user_id);

4. Fix Option B — Lateral Flatten (Snowflake/BigQuery):
   SELECT e.event_id, e.user_id, seg.value::STRING AS segment
   FROM user_events e,
   LATERAL FLATTEN(input => s.segments) seg
   JOIN user_segment_agg s ON e.user_id = s.user_id;

5. Fix Option C — Pre-aggregate in Staging:
   CREATE TABLE stg_user_primary_segment AS
   SELECT user_id,
          FIRST_VALUE(segment_name) OVER (
            PARTITION BY user_id ORDER BY priority DESC
          ) AS primary_segment
   FROM user_segments;

6. Validation Check:
   -- Always verify row counts match expectations
   SELECT COUNT(*) FROM fact_table;  -- Should equal source event count
   SELECT COUNT(DISTINCT event_id) FROM fact_table;  -- Should match above''',
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
    answer: '''Deduplication Strategy at Scale:

1. Event Schema Requirements:
   -- Every event MUST have a deterministic event_id
   event_id = SHA256(user_id || event_type || client_timestamp || session_id)

2. Streaming Dedup (Kafka + Flink):
   // Flink KeyedProcessFunction
   public class DeduplicationFunction
       extends KeyedProcessFunction<String, Event, Event> {
     private ValueState<Boolean> seenState;

     @Override
     public void processElement(Event event, Context ctx, Collector<Event> out) {
       if (seenState.value() == null) {
         seenState.update(true);
         out.collect(event);
         // TTL: clear state after 24h to bound memory
         ctx.timerService().registerEventTimeTimer(
           event.timestamp + TimeUnit.HOURS.toMillis(24)
         );
       }
       // Duplicate silently dropped
     }
   }

3. Batch Dedup (Spark SQL):
   WITH ranked AS (
     SELECT *,
            ROW_NUMBER() OVER (
              PARTITION BY user_id, event_type, DATE(client_ts)
              ORDER BY server_received_ts ASC
            ) AS rn
     FROM raw_events
   )
   SELECT * FROM ranked WHERE rn = 1;

4. Idempotent Load Pattern:
   -- Use INSERT OVERWRITE on date partitions
   -- Re-running the job on the same partition is safe
   INSERT OVERWRITE TABLE clean_events
   PARTITION (event_date = '2024-01-15')
   SELECT * FROM ranked WHERE rn = 1 AND event_date = '2024-01-15';

5. Monitoring:
   -- Track dedup rate daily
   SELECT event_date,
          COUNT(*) AS raw_count,
          COUNT(DISTINCT event_id) AS deduped_count,
          ROUND(100.0 * (COUNT(*) - COUNT(DISTINCT event_id)) / COUNT(*), 2) AS dup_rate_pct
   FROM raw_events GROUP BY event_date;''',
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
        'Your Redshift cluster runs a daily report joining fact_orders (2B rows) with dim_product (500K rows) and dim_customer (80M rows). The query takes 45 minutes. After profiling, you see massive data redistribution (DS_DIST_BOTH) in the query plan. Redesign the distribution strategy.',
    answer: '''Redshift Distribution Strategy:

1. Analyze Current Plan:
   EXPLAIN SELECT f.order_id, p.product_name, c.customer_segment, SUM(f.revenue)
   FROM fact_orders f
   JOIN dim_product p ON f.product_id = p.product_id
   JOIN dim_customer c ON f.customer_id = c.customer_id
   GROUP BY 1, 2, 3;
   -- Look for DS_DIST_BOTH = both tables redistributed (worst case)

2. Distribution Key Rules:
   -- fact_orders: DISTKEY on most frequent join column
   CREATE TABLE fact_orders (
     order_id    BIGINT,
     customer_id BIGINT,
     product_id  INT,
     revenue     DECIMAL(12,2),
     order_date  DATE
   )
   DISTKEY(customer_id)  -- joins to largest dim table
   SORTKEY(order_date);  -- most common WHERE filter

   -- dim_customer: Match fact table distkey
   CREATE TABLE dim_customer (
     customer_id      BIGINT,
     customer_segment VARCHAR(50),
     country          VARCHAR(50)
   )
   DISTKEY(customer_id);  -- co-located with fact_orders

   -- dim_product: Small table → ALL distribution
   CREATE TABLE dim_product (
     product_id   INT,
     product_name VARCHAR(200),
     category     VARCHAR(100)
   )
   DISTSTYLE ALL;  -- Full copy on every node, eliminates shuffle

3. Sort Key Strategy:
   -- Compound sort key for range queries
   SORTKEY(order_date, customer_segment)
   -- Interleaved sort key when multiple columns equally filtered
   INTERLEAVED SORTKEY(order_date, product_id)

4. Vacuum & Analyze:
   VACUUM SORT ONLY fact_orders;
   ANALYZE fact_orders;

5. Expected Result:
   DS_DIST_BOTH → DS_DIST_NONE (co-located join)
   45 min → ~4 min query time''',
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
    answer: '''Silent Failure Triage Playbook:

1. Immediate Checks (0-5 min):
   -- Verify data actually landed in Redshift
   SELECT MAX(load_timestamp), COUNT(*) FROM fact_orders
   WHERE order_date = CURRENT_DATE;
   -- Result: 0 rows → pipeline wrote to S3 but COPY failed silently

2. Check Redshift COPY Errors:
   SELECT query, filename, line_number, colname, err_reason
   FROM stl_load_errors
   WHERE starttime > CURRENT_TIMESTAMP - INTERVAL '6 hours'
   ORDER BY starttime DESC;
   -- Common: type mismatch, null constraint, encoding error

3. Check S3 File Integrity:
   -- Verify files are non-empty and parseable
   aws s3 ls s3://bucket/orders/2024-01-15/ --recursive
   aws s3 cp s3://bucket/orders/2024-01-15/part-00000.parquet /tmp/
   python3 -c "import pandas as pd; print(pd.read_parquet('/tmp/part-00000.parquet').head())"

4. Root Cause Pattern — Empty DataFrame Written:
   # Bug: filter returns empty df, write succeeds with 0 rows
   df_filtered = df.filter(col("status") == "COMPLETED")
   df_filtered.write.parquet(s3_path)  # No error if empty!

   # Fix: Add row count assertion
   row_count = df_filtered.count()
   if row_count == 0:
       raise ValueError(f"Empty DataFrame after filter — aborting write")

5. Add Guardrails to Airflow DAG:
   from airflow.operators.python import PythonOperator

   def validate_row_count(**context):
       count = get_redshift_count(table="fact_orders", date=context["ds"])
       if count < 1000:  # Minimum expected rows
           raise AirflowException(f"Row count {count} below threshold 1000")

   validate_task = PythonOperator(
       task_id="validate_row_count",
       python_callable=validate_row_count,
   )
   load_task >> validate_task  # Always run after load

6. Prevention:
   - Add data freshness check as final DAG task
   - Set up CloudWatch alarm on Redshift table row count
   - Use Great Expectations for post-load validation''',
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
    answer: '''Late Data Handling Strategy:

1. Watermark Configuration (Flink):
   // Allow events up to 4 hours late
   DataStream<OrderEvent> stream = env
     .addSource(kinesisSource)
     .assignTimestampsAndWatermarks(
       WatermarkStrategy
         .<OrderEvent>forBoundedOutOfOrderness(Duration.ofHours(4))
         .withTimestampAssigner((event, ts) -> event.clientTimestamp)
     );

2. Window with Side Output for Very Late Events:
   OutputTag<OrderEvent> lateTag = new OutputTag<>("late-events"){};

   SingleOutputStreamOperator<HourlyRevenue> mainStream = stream
     .keyBy(OrderEvent::getMerchantId)
     .window(TumblingEventTimeWindows.of(Time.hours(1)))
     .allowedLateness(Time.hours(4))
     .sideOutputLateData(lateTag)
     .aggregate(new RevenueAggregator());

   // Capture events arriving > 4h late for manual reconciliation
   DataStream<OrderEvent> veryLateEvents = mainStream.getSideOutput(lateTag);
   veryLateEvents.addSink(s3LateEventsSink);

3. Correction Pattern — Upsert Aggregates:
   -- Redshift: Use staging table + MERGE for corrections
   CREATE TABLE stg_hourly_revenue_correction AS
   SELECT merchant_id,
          DATE_TRUNC('hour', event_time) AS revenue_hour,
          SUM(amount) AS late_revenue
   FROM late_events_table
   GROUP BY 1, 2;

   UPDATE fact_hourly_revenue f
   SET revenue = f.revenue + c.late_revenue,
       last_corrected_at = CURRENT_TIMESTAMP
   FROM stg_hourly_revenue_correction c
   WHERE f.merchant_id = c.merchant_id
     AND f.revenue_hour = c.revenue_hour;

4. Lambda Architecture Fallback:
   -- Batch job reconciles streaming results daily
   -- Compares streaming aggregates vs batch ground truth
   -- Applies corrections to finalized hourly partitions

5. Monitoring:
   -- Track late event rate and correction magnitude
   SELECT revenue_hour,
          streaming_revenue,
          final_revenue,
          ROUND(100.0 * (final_revenue - streaming_revenue) / streaming_revenue, 2) AS correction_pct
   FROM revenue_reconciliation_log
   ORDER BY revenue_hour DESC;''',
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
    answer: '''Corrupted JSON Handling Strategy:

1. Defensive Parsing with Schema Validation:
   import json
   from jsonschema import validate, ValidationError
   from datetime import datetime

   ORDER_SCHEMA = {
     "type": "object",
     "required": ["order_id", "user_id", "amount", "timestamp"],
     "properties": {
       "order_id": {"type": "string"},
       "user_id":  {"type": "string"},
       "amount":   {"type": "number", "minimum": 0},
       "timestamp": {"type": "string", "format": "date-time"}
     }
   }

   def safe_parse_event(raw_str: str) -> dict | None:
       try:
           data = json.loads(raw_str)
           validate(instance=data, schema=ORDER_SCHEMA)
           return data
       except json.JSONDecodeError as e:
           log_to_dlq(raw_str, error=f"JSONDecodeError: {e}")
           return None
       except ValidationError as e:
           log_to_dlq(raw_str, error=f"SchemaError: {e.message}")
           return None

2. Dead Letter Queue (DLQ) Pattern:
   def log_to_dlq(raw_payload: str, error: str):
       s3_client.put_object(
           Bucket="dlq-bucket",
           Key=f"failed/{datetime.utcnow().isoformat()}/{uuid4()}.json",
           Body=json.dumps({
               "raw_payload": raw_payload,
               "error": error,
               "ingested_at": datetime.utcnow().isoformat(),
               "source": "order-ingestion-lambda"
           })
       )

3. Partial Recovery — Field Coercion:
   def coerce_amount(raw_amount) -> float:
       try:
           return float(str(raw_amount).replace(",", "").strip())
       except (ValueError, TypeError):
           return 0.0  # Default with audit flag

4. Batch Processing with Fault Isolation:
   def process_s3_file(bucket: str, key: str):
       records = read_s3_jsonl(bucket, key)
       valid, invalid = [], []
       for record in records:
           parsed = safe_parse_event(record)
           (valid if parsed else invalid).append(parsed or record)

       # Process valid records
       batch_write_to_dynamodb(valid)
       # Route invalid to DLQ
       write_to_dlq_bucket(invalid)

       # Emit metrics
       cloudwatch.put_metric_data(
           Namespace="DataPipeline",
           MetricData=[
               {"MetricName": "ValidRecords",   "Value": len(valid)},
               {"MetricName": "InvalidRecords", "Value": len(invalid)},
               {"MetricName": "ErrorRate",      "Value": len(invalid)/len(records)*100}
           ]
       )

5. DLQ Reprocessing:
   -- After vendor fix, replay DLQ records
   -- Parse, validate, and re-ingest to DynamoDB
   -- Mark DLQ records as "reprocessed" after success''',
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
    answer: '''Snowflake Micro-Partition Optimization:

1. Diagnose with EXPLAIN:
   EXPLAIN USING TABULAR
   SELECT merchant_id, SUM(amount)
   FROM fact_transactions
   WHERE transaction_date = '2024-01-15'
   GROUP BY merchant_id;
   -- Look for: partitionsTotal vs partitionsAssigned
   -- Bad: partitionsAssigned = 95% of partitionsTotal

2. Check Current Clustering:
   SELECT SYSTEM\$CLUSTERING_INFORMATION('fact_transactions', '(transaction_date)');
   -- Returns: average_depth (ideal < 2), average_overlaps (ideal < 1)
   -- High values = poor clustering = full scans

3. Apply Clustering Key:
   -- For time-series queries filtered by date
   ALTER TABLE fact_transactions
   CLUSTER BY (TO_DATE(transaction_date), merchant_id);

   -- Monitor clustering progress (async background service)
   SELECT SYSTEM\$CLUSTERING_INFORMATION('fact_transactions');

4. Clustering Key Selection Rules:
   -- Good candidates: columns in WHERE, JOIN, GROUP BY
   -- Cardinality: 10K-1M distinct values (not too low, not too high)
   -- Avoid: high-cardinality columns like transaction_id
   -- Compound key: most selective column first

5. Zero-Copy Clone for Testing:
   -- Test clustering without affecting production
   CREATE TABLE fact_transactions_test
   CLONE fact_transactions;

   ALTER TABLE fact_transactions_test
   CLUSTER BY (TO_DATE(transaction_date));

   -- Compare query performance before promoting to prod

6. Automatic Clustering Cost:
   -- Monitor credit consumption
   SELECT table_name, credits_used, num_bytes_reclustered
   FROM snowflake.account_usage.automatic_clustering_history
   WHERE start_time > DATEADD(day, -7, CURRENT_TIMESTAMP)
   ORDER BY credits_used DESC;

7. Result:
   Before: 95% partitions scanned, 8 min
   After:  3-5% partitions scanned, <30 sec''',
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
    answer: '''PySpark OOM & Skew Fix Playbook:

1. Diagnose the Skew:
   from pyspark.sql.functions import col, count

   # Find skewed keys
   skew_df = orders.groupBy("customer_id") \\
       .agg(count("*").alias("order_count")) \\
       .orderBy(col("order_count").desc()) \\
       .limit(20)
   skew_df.show()
   # Result: top 5 customer_ids have 40% of all rows

2. Fix A — Salting for Skewed Join:
   from pyspark.sql.functions import concat, lit, floor, rand

   SALT_FACTOR = 50  # Number of salt buckets

   # Salt the large table
   orders_salted = orders.withColumn(
       "salted_customer_id",
       concat(col("customer_id"), lit("_"), (rand() * SALT_FACTOR).cast("int"))
   )

   # Explode the small table to match all salt values
   from pyspark.sql.functions import explode, array
   customers_exploded = customers.withColumn(
       "salt", explode(array([lit(i) for i in range(SALT_FACTOR)]))
   ).withColumn(
       "salted_customer_id",
       concat(col("customer_id"), lit("_"), col("salt"))
   )

   # Join on salted key
   result = orders_salted.join(
       customers_exploded,
       on="salted_customer_id",
       how="left"
   ).drop("salted_customer_id", "salt")

3. Fix B — Broadcast Join for Small Table:
   from pyspark.sql.functions import broadcast

   # customers (50GB) may be too large for default broadcast (10MB)
   # Increase threshold or use hint
   spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 10 * 1024 * 1024 * 1024)  # 10GB

   result = orders.join(broadcast(customers), on="customer_id", how="left")

4. Fix C — Separate Skewed Keys:
   SKEWED_IDS = ['user_123', 'user_456']  # Top power users

   orders_normal = orders.filter(~col("customer_id").isin(SKEWED_IDS))
   orders_skewed = orders.filter(col("customer_id").isin(SKEWED_IDS))

   # Broadcast join for skewed subset (small result set)
   result_skewed = orders_skewed.join(broadcast(customers), "customer_id")
   result_normal = orders_normal.join(customers, "customer_id")
   result = result_normal.union(result_skewed)

5. Memory Tuning:
   spark.conf.set("spark.executor.memory", "20g")
   spark.conf.set("spark.executor.memoryOverhead", "4g")  # Off-heap for JVM
   spark.conf.set("spark.sql.shuffle.partitions", "800")  # 2x executor cores
   spark.conf.set("spark.memory.fraction", "0.8")
   spark.conf.set("spark.memory.storageFraction", "0.3")

6. Monitoring:
   # Check partition sizes in Spark UI
   # Target: all partitions < 200MB
   # Red flag: any partition > 2GB''',
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
    answer: '''Zero-Copy Clone vs CTE — Decision Framework:

1. Zero-Copy Clone:
   -- Creates an independent copy sharing underlying micro-partitions
   -- No data duplication until writes occur (copy-on-write)
   CREATE TABLE orders_dev CLONE orders_prod;
   CREATE SCHEMA analytics_dev CLONE analytics_prod;

   Use Cases:
   ✅ Dev/test environments (full table copy in seconds)
   ✅ Pre-migration snapshots before schema changes
   ✅ A/B testing pipeline logic on production-scale data
   ✅ Disaster recovery point-in-time snapshots

   Cost Model:
   - Clone creation: FREE (no data copied)
   - Storage cost: Only for rows modified after clone
   - Query cost: Same as original table (full micro-partition access)

2. CTE (Common Table Expression):
   WITH daily_revenue AS (
     SELECT merchant_id, DATE(txn_time) AS txn_date, SUM(amount) AS revenue
     FROM transactions
     WHERE txn_date >= DATEADD(day, -30, CURRENT_DATE)
     GROUP BY 1, 2
   ),
   ranked_merchants AS (
     SELECT *, RANK() OVER (PARTITION BY txn_date ORDER BY revenue DESC) AS rank
     FROM daily_revenue
   )
   SELECT * FROM ranked_merchants WHERE rank <= 10;

   Use Cases:
   ✅ Breaking complex queries into readable steps
   ✅ Referencing intermediate results within a single query
   ✅ Recursive queries (hierarchical data)
   ❌ NOT for sharing results across multiple queries (recomputed each time)

3. Materialized CTE Alternative — Transient Table:
   -- When CTE is referenced many times in a session
   CREATE TRANSIENT TABLE tmp_daily_revenue AS
   SELECT merchant_id, DATE(txn_time) AS txn_date, SUM(amount) AS revenue
   FROM transactions GROUP BY 1, 2;
   -- Transient = no Fail-safe storage cost, auto-dropped after session

4. Decision Matrix:
   | Scenario                        | Use                    |
   |---------------------------------|------------------------|
   | Dev environment from prod       | Zero-Copy Clone        |
   | Pre-deploy backup               | Zero-Copy Clone        |
   | Complex multi-step query        | CTE                    |
   | Intermediate result reused 5x+  | Transient Table        |
   | Sharing data across teams       | Zero-Copy Clone        |
   | Single-query readability        | CTE                    |''',
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
    answer: '''Kafka DLQ Architecture for Uber-Scale Pipelines:

1. DLQ Topic Design:
   # Main topic
   trips.events (partitions=200, replication=3)

   # DLQ topics by failure category
   trips.events.dlq.schema_error    (partitions=20)
   trips.events.dlq.validation_error (partitions=20)
   trips.events.dlq.processing_error (partitions=20)

2. Flink Consumer with DLQ Routing:
   public class TripEventProcessor extends ProcessFunction<TripEvent, ProcessedTrip> {

     private final KafkaProducer<String, String> dlqProducer;

     @Override
     public void processElement(TripEvent event, Context ctx, Collector<ProcessedTrip> out) {
       try {
         // Schema validation
         if (event.getDriverId() == null || event.getTripId() == null) {
           sendToDLQ("trips.events.dlq.validation_error", event,
                     "Missing required fields: driver_id or trip_id");
           return;
         }

         // GPS validation
         if (!isValidGPS(event.getLatitude(), event.getLongitude())) {
           sendToDLQ("trips.events.dlq.validation_error", event,
                     "Invalid GPS coordinates: " + event.getLatitude());
           return;
         }

         // Process valid event
         out.collect(transformEvent(event));

       } catch (SchemaException e) {
         sendToDLQ("trips.events.dlq.schema_error", event, e.getMessage());
       } catch (Exception e) {
         sendToDLQ("trips.events.dlq.processing_error", event, e.getMessage());
       }
     }

     private void sendToDLQ(String topic, TripEvent event, String errorReason) {
       DLQRecord dlqRecord = DLQRecord.builder()
           .originalEvent(event)
           .errorReason(errorReason)
           .failedAt(Instant.now())
           .retryCount(0)
           .sourceConsumerGroup("trip-processor-v2")
           .build();
       dlqProducer.send(new ProducerRecord<>(topic, event.getTripId(), dlqRecord.toJson()));
     }
   }

3. DLQ Monitoring & Alerting:
   -- PagerDuty alert if DLQ lag > 10K messages
   -- Dashboard: DLQ rate per error type per hour
   -- SLA: DLQ records must be reviewed within 4 hours

4. DLQ Reprocessing Job:
   def reprocess_dlq(dlq_topic: str, fix_fn: Callable):
       consumer = KafkaConsumer(dlq_topic, group_id="dlq-reprocessor")
       for msg in consumer:
           dlq_record = json.loads(msg.value)
           if dlq_record["retry_count"] >= 3:
               archive_to_s3(dlq_record)  # Give up after 3 retries
               continue
           try:
               fixed_event = fix_fn(dlq_record["original_event"])
               republish_to_main_topic(fixed_event)
               dlq_record["retry_count"] += 1
           except Exception as e:
               update_retry_count(dlq_record, e)

5. Key Metrics to Track:
   - DLQ rate: target < 0.05% of total events
   - DLQ lag: alert if > 10K unprocessed records
   - Reprocessing success rate: target > 95%
   - Time-to-resolution: SLA < 4 hours''',
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
    answer: '''Debezium CDC Pipeline Design:

1. Architecture Overview:
   PostgreSQL → Debezium Connector → Kafka → Flink/Spark Streaming → Recommendation Engine

2. PostgreSQL Configuration:
   -- Enable logical replication (required for Debezium)
   ALTER SYSTEM SET wal_level = logical;
   ALTER SYSTEM SET max_replication_slots = 10;
   ALTER SYSTEM SET max_wal_senders = 10;
   SELECT pg_reload_conf();

   -- Create replication slot
   SELECT pg_create_logical_replication_slot('debezium_slot', 'pgoutput');

   -- Grant replication permissions
   CREATE ROLE debezium_user REPLICATION LOGIN PASSWORD 'secure_password';
   GRANT SELECT ON TABLE user_preferences TO debezium_user;

3. Debezium Connector Configuration:
   {
     "name": "postgres-user-preferences-connector",
     "config": {
       "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
       "database.hostname": "postgres-primary.netflix.internal",
       "database.port": "5432",
       "database.user": "debezium_user",
       "database.password": "\${secrets:postgres-password}",
       "database.dbname": "user_preferences_db",
       "database.server.name": "netflix-postgres",
       "table.include.list": "public.user_preferences,public.watch_history",
       "plugin.name": "pgoutput",
       "slot.name": "debezium_slot",
       "publication.name": "debezium_publication",
       "transforms": "unwrap",
       "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
       "transforms.unwrap.delete.handling.mode": "rewrite",
       "key.converter": "io.confluent.kafka.serializers.KafkaAvroSerializer",
       "value.converter": "io.confluent.kafka.serializers.KafkaAvroSerializer"
     }
   }

4. Kafka Topic Structure:
   # Debezium creates topics automatically
   netflix-postgres.public.user_preferences
   # Message format (after ExtractNewRecordState transform):
   {
     "user_id": "u_12345",
     "genre_preferences": ["thriller", "documentary"],
     "language": "en",
     "updated_at": "2024-01-15T10:30:00Z",
     "__op": "u",  # u=update, c=create, d=delete
     "__deleted": false
   }

5. Flink Consumer for Recommendation Engine:
   DataStream<UserPreference> prefStream = env
     .addSource(new FlinkKafkaConsumer<>(
       "netflix-postgres.public.user_preferences",
       new AvroDeserializationSchema<>(),
       kafkaProps
     ))
     .filter(pref -> !pref.isDeleted())
     .keyBy(UserPreference::getUserId);

   // Update recommendation model in real-time
   prefStream.process(new RecommendationUpdateFunction())
             .addSink(new RedisSink<>());  // Hot cache for serving

6. Handling Schema Evolution:
   -- Debezium + Schema Registry handles column additions automatically
   -- Use BACKWARD compatible schema changes only
   -- Test with: ALTER TABLE user_preferences ADD COLUMN new_col VARCHAR(50) DEFAULT NULL;

7. Monitoring:
   -- Replication lag: target < 500ms
   -- Connector status: curl /connectors/postgres-connector/status
   -- WAL disk usage: SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) FROM pg_replication_slots;''',
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
    answer: '''Out-of-Order Event Handling Strategy:

1. Root Causes of Out-of-Order Events:
   - GPS buffering: Device stores events offline, sends in bulk on reconnect
   - Network retries: Same event sent multiple times with original timestamp
   - Clock skew: Device clock drifts from server time (up to ±5 min)
   - Distributed producers: Multiple services emit events with different latencies

2. Event Time vs Processing Time:
   // Always use EVENT TIME (client_timestamp), not PROCESSING TIME (server_received_at)
   // client_timestamp = when event actually occurred
   // server_received_at = when Kafka received it (unreliable for ordering)

3. Flink Watermark Strategy:
   DataStream<LocationEvent> locationStream = env
     .addSource(kafkaSource)
     .assignTimestampsAndWatermarks(
       WatermarkStrategy
         .<LocationEvent>forBoundedOutOfOrderness(Duration.ofMinutes(30))
         .withTimestampAssigner((event, ts) -> event.getClientTimestampMs())
         .withIdleness(Duration.ofMinutes(5))  // Handle idle partitions
     );

4. Trip Timeline Reconstruction:
   // Session window: group events into trips with 10-min gap threshold
   DataStream<TripTimeline> trips = locationStream
     .keyBy(LocationEvent::getDriverId)
     .window(EventTimeSessionWindows.withGap(Time.minutes(10)))
     .allowedLateness(Time.minutes(30))
     .aggregate(new TripTimelineAggregator());

   class TripTimelineAggregator implements AggregateFunction<LocationEvent, TripState, TripTimeline> {
     public TripState add(LocationEvent event, TripState state) {
       state.addEvent(event);
       state.updateStartTime(Math.min(state.startTime, event.clientTimestamp));
       state.updateEndTime(Math.max(state.endTime, event.clientTimestamp));
       return state;
     }
     public TripTimeline getResult(TripState state) {
       // Sort events by client_timestamp before computing duration
       List<LocationEvent> sorted = state.events.stream()
           .sorted(Comparator.comparing(LocationEvent::getClientTimestamp))
           .collect(Collectors.toList());
       return new TripTimeline(sorted, state.endTime - state.startTime);
     }
   }

5. Clock Skew Correction:
   def correct_clock_skew(client_ts: datetime, server_ts: datetime) -> datetime:
       skew = server_ts - client_ts
       # If skew > 5 min, likely clock drift — use server time as anchor
       if abs(skew.total_seconds()) > 300:
           return server_ts - timedelta(seconds=30)  # Estimated true time
       return client_ts

6. Deduplication for Retried Events:
   -- Use event_id (device_id + sequence_number) as idempotency key
   -- Redis SET NX with 24h TTL for streaming dedup
   -- Spark DISTINCT on event_id for batch reconciliation

7. Monitoring:
   -- Track out-of-order rate: events where client_ts < watermark
   -- Alert if > 5% of events arrive after window closes
   -- Dashboard: P50/P95/P99 event latency (server_received_at - client_ts)''',
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
    answer: '''Architecture Overview:
1. Ingestion Layer: Kafka topics partitioned by user_id for ordering guarantees. Use Kafka Connect for source connectors.

2. Stream Processing (Flink):
   - Deduplicate events using event_id + 5-min window
   - Enrich with user profile data from Redis cache
   - Compute real-time metrics: funnel conversion, session duration
   - Write to Kafka sink topics

3. Storage Layer:
   - Hot path: Redis for real-time dashboards
   - Warm path: Apache Iceberg on S3 for analytical queries
   - Cold path: S3 Parquet for historical analysis

4. Serving Layer: Trino/Presto for ad-hoc queries, Grafana for dashboards

Trade-offs: Kafka guarantees at-least-once delivery; use idempotent writes to handle duplicates.''',
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
    answer: '''Optimization Strategy:

1. Data Skew Detection:
   - Check partition sizes: df.rdd.glom().map(len).collect()
   - Identify skewed keys causing data imbalance

2. Partitioning:
   - Repartition on high-cardinality column: df.repartition(200, "date")
   - Use coalesce() before writes to reduce small files

3. Caching & Persistence:
   - Cache frequently reused DataFrames: df.cache() or df.persist(StorageLevel.MEMORY_AND_DISK)

4. Broadcast Joins:
   - For small lookup tables (<200MB): spark.sql.autoBroadcastJoinThreshold=209715200

5. File Format:
   - Switch from CSV to Parquet/ORC with Snappy compression
   - Enable predicate pushdown and column pruning

6. Spark Config Tuning:
   - spark.executor.memory=8g, spark.executor.cores=4
   - spark.sql.shuffle.partitions=400 (2-3x cluster cores)

Result: Expected 5-8x speedup.''',
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
    answer: '''Incident Response Playbook:

1. Immediate Triage (0-5 min):
   - Check Airflow UI: Task logs, last successful run timestamp
   - Check data freshness: SELECT MAX(updated_at) FROM fact_orders
   - Alert stakeholders with ETA

2. Root Cause Analysis:
   - Check upstream source: API rate limit? DB connection timeout?
   - Review Airflow logs: grep "ERROR" in task logs
   - Check infrastructure: Disk space, memory, network

3. Common Causes & Fixes:
   - Schema change in source: Add schema validation step
   - Memory OOM: Increase executor memory or add chunking
   - Dependency failure: Add retry logic with exponential backoff

4. Recovery:
   - Backfill missing data: airflow dags backfill -s 2024-01-01 -e 2024-01-02 my_dag
   - Validate data quality post-recovery

5. Prevention:
   - Add data freshness SLA alerts
   - Implement Great Expectations for data quality checks
   - Set up dead letter queues for failed records''',
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
    answer: '''SCD Types:

Type 1 - Overwrite:
- Simply update the record, no history kept
- Use case: Correcting typos, non-critical attributes
- Example: UPDATE dim_customer SET email = new_email WHERE id = 123

Type 2 - Add New Row (most common):
- Insert new row with new surrogate key, mark old row inactive
- Columns: effective_date, expiry_date, is_current flag
- Use case: Customer address changes, price history
- Preserves full history for point-in-time analysis

Type 3 - Add New Column:
- Add "previous_value" column alongside current
- Use case: When only one previous value matters
- Limited history, simpler queries

Best Practice: Use Type 2 for most analytical use cases.''',
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
    answer: '''Fraud Detection Architecture:

1. Ingestion: Kafka topic "transactions" with 50 partitions
   - Schema: transaction_id, user_id, amount, merchant, timestamp, location

2. Feature Engineering (Flink):
   - Velocity checks: COUNT(txn) OVER last 1 hour per user
   - Amount anomaly: z-score vs user's 30-day average
   - Location mismatch: distance from last transaction

3. ML Scoring:
   - Load pre-trained model (XGBoost) in Flink operator
   - Score each transaction in <50ms
   - Threshold: score > 0.85 → flag as suspicious

4. Decision Engine:
   - High confidence fraud (>0.95): Auto-block, notify user
   - Medium (0.85-0.95): Step-up authentication
   - Low (<0.85): Allow, log for model retraining

5. Storage:
   - All transactions → Iceberg table for model retraining
   - Flagged transactions → PostgreSQL for analyst review

Latency target: <100ms end-to-end''',
    category: 'System Design',
    difficulty: 'Lead',
    isPro: true,
    tags: ['Kafka', 'Flink', 'ML', 'Real-time'],
  ),
];
