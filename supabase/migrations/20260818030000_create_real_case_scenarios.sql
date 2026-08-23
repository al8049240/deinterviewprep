-- Migration: Create real_case_scenarios table in de_mobile_app schema
-- Timestamp: 20260818030000

CREATE TABLE IF NOT EXISTS de_mobile_app.real_case_scenarios (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    category text NOT NULL,
    tags text[] DEFAULT '{}',
    problem_statement text NOT NULL,
    solution_breakdown text NOT NULL,
    is_active boolean DEFAULT true,
    published_date date DEFAULT current_date,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_real_case_scenarios_category ON de_mobile_app.real_case_scenarios(category);
CREATE INDEX IF NOT EXISTS idx_real_case_scenarios_is_active ON de_mobile_app.real_case_scenarios(is_active);
CREATE INDEX IF NOT EXISTS idx_real_case_scenarios_published_date ON de_mobile_app.real_case_scenarios(published_date DESC);

-- Enable RLS
ALTER TABLE de_mobile_app.real_case_scenarios ENABLE ROW LEVEL SECURITY;

-- Public read policy (anyone can read active scenarios)
DROP POLICY IF EXISTS "public_read_real_case_scenarios" ON de_mobile_app.real_case_scenarios;
CREATE POLICY "public_read_real_case_scenarios"
ON de_mobile_app.real_case_scenarios
FOR SELECT
TO public
USING (is_active = true);

-- Seed sample data
DO $$
BEGIN
    INSERT INTO de_mobile_app.real_case_scenarios (title, category, tags, problem_statement, solution_breakdown, is_active, published_date)
    VALUES
    (
        'Redshift Distribution & Sort Key Selection for Query Performance',
        'System Design',
        ARRAY['Amazon', 'Redshift', 'Distribution Key', 'Sort Key', 'Query Optimization'],
        'Your team is running a 10TB Redshift data warehouse for an e-commerce platform. Analysts report that queries joining the orders table (500M rows) with the customers table (10M rows) are taking 8-12 minutes. The orders table uses EVEN distribution and no sort key. How would you redesign the distribution and sort key strategy to reduce query time to under 30 seconds?',
        'Step 1 - Analyze query patterns: Identify the most frequent join columns (customer_id) and filter columns (order_date, status). Step 2 - Choose distribution style: Change orders to KEY distribution on customer_id to co-locate rows with the customers table. Step 3 - Set sort keys: Use compound sort key (order_date, status) on orders for range-restricted scans. Step 4 - Rebuild tables: Use CREATE TABLE AS SELECT (CTAS) to rebuild with new distribution, then VACUUM ANALYZE. Step 5 - Validate: Run EXPLAIN to confirm DS_DIST_NONE (no redistribution) on the join.',
        true,
        '2024-01-15'
    ),
    (
        'Silent Data Pipeline Failure Triage: Airflow + S3',
        'Incident Response',
        ARRAY['Amazon', 'Airflow', 'S3', 'Redshift', 'Silent Failure', 'Incident Response'],
        'A critical daily DAG that loads S3 data into Redshift has been marking tasks as SUCCESS for 3 days, but downstream BI dashboards show stale data. No alerts fired. How do you triage this silent failure, identify the root cause, and implement safeguards to prevent recurrence?',
        'Step 1 - Immediate triage: Check Airflow task logs for the last 3 runs — look for zero-row inserts or S3 ListObjects returning empty. Step 2 - Validate data freshness: Query Redshift for MAX(loaded_at) and compare with S3 object last-modified timestamps. Step 3 - Root cause: Likely an S3 prefix change or empty file being silently accepted. Step 4 - Fix: Add row count validation sensor after load task; fail the DAG if inserted_rows == 0. Step 5 - Alerting: Configure Airflow SLA miss callbacks and add a dbt test or Great Expectations check on row count thresholds.',
        true,
        '2024-01-18'
    ),
    (
        'Handling Late-Arriving Data in Streaming Pipelines',
        'System Design',
        ARRAY['Amazon', 'Flink', 'Kinesis', 'Late Data', 'Watermarks', 'Streaming'],
        'You are building a real-time revenue aggregation pipeline using Apache Flink consuming from Kinesis. Business requires 5-minute tumbling window aggregates. Mobile app events can arrive up to 15 minutes late due to offline usage. How do you handle late data without reprocessing the entire stream or missing revenue figures?',
        'Step 1 - Configure watermarks: Set Flink watermark strategy with 15-minute out-of-orderness tolerance using WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofMinutes(15)). Step 2 - Allowed lateness: Set window allowed lateness to 15 minutes so late elements update existing windows. Step 3 - Side outputs: Route elements arriving after allowed lateness to a side output stream for manual reconciliation. Step 4 - Late data correction: Write late-arriving aggregates to a corrections table in the data warehouse with a flag for downstream restatement. Step 5 - Monitoring: Track late_records_count metric and alert if it exceeds 5% of total volume.',
        true,
        '2024-01-20'
    ),
    (
        'Handling Corrupted JSON Payloads in S3 Ingestion Pipelines',
        'Incident Response',
        ARRAY['Amazon', 'JSON', 'DLQ', 'Lambda', 'S3', 'Data Quality'],
        'Your Lambda-based ingestion pipeline reads JSON events from S3 and writes to DynamoDB. After a mobile app update, 12% of records are failing with JSON parse errors, causing the Lambda to crash and retry indefinitely. The S3 bucket is accumulating 50K+ failed files. How do you stop the bleeding, recover the data, and prevent this in the future?',
        'Step 1 - Stop the bleeding: Add try/except around JSON parsing; on failure, move the file to an s3://bucket/dlq/ prefix instead of retrying. Step 2 - Inspect failures: Sample 100 files from DLQ — identify the schema change (new nested field, encoding issue, null values). Step 3 - Schema validation: Implement JSON Schema validation using jsonschema library before processing. Step 4 - Recovery: Write a backfill Lambda that reads from DLQ, applies schema migration logic, and reprocesses valid records. Step 5 - Prevention: Add schema registry (AWS Glue Schema Registry) and enforce schema evolution rules on the producer side.',
        true,
        '2024-01-22'
    ),
    (
        'Optimizing Spark Job for Large-Scale Data Skew',
        'PySpark',
        ARRAY['Databricks', 'Spark', 'Data Skew', 'Salting', 'Performance'],
        'A PySpark job joining a 2TB transactions table with a 500MB merchants table is taking 4 hours. Spark UI shows 3 tasks taking 90% of the time while 200 others finish in minutes. The transactions table has 60% of records for merchant_id = 1001 (a major retailer). How do you fix the skew?',
        'Step 1 - Confirm skew: Use df.groupBy("merchant_id").count().orderBy(desc("count")).show(10) to verify distribution. Step 2 - Broadcast join: Since merchants is 500MB (under 10GB), use broadcast(merchants_df) to eliminate shuffle entirely. Step 3 - If broadcast not viable: Apply salting — add a random salt (0-9) to merchant_id in transactions, explode merchants with 10 copies each, join on salted key, then aggregate. Step 4 - Partition tuning: Set spark.sql.shuffle.partitions=400 and use repartition("merchant_id") before the join. Step 5 - Validate: Check Spark UI Stage details — all tasks should complete within 2x of each other.',
        true,
        '2024-01-25'
    ),
    (
        'Designing a Fault-Tolerant ETL Pipeline for Financial Data',
        'Data Modeling',
        ARRAY['Snowflake', 'dbt', 'Airflow', 'Financial', 'Idempotency'],
        'You need to build an ETL pipeline that processes daily stock trade data from 5 exchanges into Snowflake. Each exchange sends files at different times (some up to 6 hours late). The pipeline must be idempotent, handle partial failures, and produce a consolidated daily trades table by 8 AM EST for trading desk reports. How do you architect this?',
        'Step 1 - Ingestion layer: Use Airflow with ExternalTaskSensor to wait for each exchange file, with a 6-hour timeout and fallback to previous day data if missing. Step 2 - Staging: Load raw files into Snowflake stage tables with COPY INTO using FORCE=FALSE for idempotency (skip already-loaded files). Step 3 - Transformation: Use dbt incremental models with unique_key on (trade_date, exchange_id, trade_id) and merge strategy. Step 4 - Orchestration: Implement a fan-in pattern — 5 parallel exchange DAGs feeding a downstream consolidation DAG triggered only when all exchanges complete or timeout. Step 5 - SLA monitoring: Set Airflow SLA on the consolidation task to alert at 7:30 AM if not complete.',
        true,
        '2024-01-28'
    )
    ON CONFLICT (id) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
