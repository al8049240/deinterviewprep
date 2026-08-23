-- Migration: Seed 100 flashcards into de_mobile_app.flashcards
-- Timestamp: 20260818010000
-- Maps flashcard categories to topics/subtopics in de_mobile_app schema

DO $$
DECLARE
    v_sql_topic_id BIGINT;
    v_arch_topic_id BIGINT;
    v_orch_topic_id BIGINT;
    v_cloud_topic_id BIGINT;
    v_spark_topic_id BIGINT;
    v_sysdesign_topic_id BIGINT;

    v_sql_sub_id BIGINT;
    v_arch_sub_id BIGINT;
    v_orch_sub_id BIGINT;
    v_cloud_sub_id BIGINT;
    v_spark_sub_id BIGINT;
    v_sysdesign_sub_id BIGINT;
BEGIN
    -- Fetch topic IDs by name
    SELECT id INTO v_sql_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%sql%' LIMIT 1;

    SELECT id INTO v_arch_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%architect%' OR LOWER(name) LIKE '%data engineer%' LIMIT 1;

    SELECT id INTO v_orch_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%orchestrat%' OR LOWER(name) LIKE '%kafka%' OR LOWER(name) LIKE '%airflow%' LIMIT 1;

    SELECT id INTO v_cloud_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%cloud%' OR LOWER(name) LIKE '%lake%' LIMIT 1;

    SELECT id INTO v_spark_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%spark%' OR LOWER(name) LIKE '%pyspark%' LIMIT 1;

    SELECT id INTO v_sysdesign_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%system%' OR LOWER(name) LIKE '%design%' LIMIT 1;

    -- Fallback: use first available topic if specific ones not found
    IF v_sql_topic_id IS NULL THEN
        SELECT id INTO v_sql_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    END IF;
    IF v_arch_topic_id IS NULL THEN
        SELECT id INTO v_arch_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    END IF;
    IF v_orch_topic_id IS NULL THEN
        SELECT id INTO v_orch_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    END IF;
    IF v_cloud_topic_id IS NULL THEN
        SELECT id INTO v_cloud_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    END IF;
    IF v_spark_topic_id IS NULL THEN
        SELECT id INTO v_spark_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    END IF;
    IF v_sysdesign_topic_id IS NULL THEN
        SELECT id INTO v_sysdesign_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    END IF;

    -- Fetch subtopic IDs
    SELECT id INTO v_sql_sub_id
        FROM "de_mobile_app"."subtopics-legacy"
        WHERE topic_id = v_sql_topic_id LIMIT 1;

    SELECT id INTO v_arch_sub_id
        FROM "de_mobile_app"."subtopics-legacy"
        WHERE topic_id = v_arch_topic_id LIMIT 1;

    SELECT id INTO v_orch_sub_id
        FROM "de_mobile_app"."subtopics-legacy"
        WHERE topic_id = v_orch_topic_id LIMIT 1;

    SELECT id INTO v_cloud_sub_id
        FROM "de_mobile_app"."subtopics-legacy"
        WHERE topic_id = v_cloud_topic_id LIMIT 1;

    SELECT id INTO v_spark_sub_id
        FROM "de_mobile_app"."subtopics-legacy"
        WHERE topic_id = v_spark_topic_id LIMIT 1;

    SELECT id INTO v_sysdesign_sub_id
        FROM "de_mobile_app"."subtopics-legacy"
        WHERE topic_id = v_sysdesign_topic_id LIMIT 1;

    -- Fallback subtopics
    IF v_sql_sub_id IS NULL THEN
        SELECT id INTO v_sql_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;
    END IF;
    IF v_arch_sub_id IS NULL THEN
        SELECT id INTO v_arch_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;
    END IF;
    IF v_orch_sub_id IS NULL THEN
        SELECT id INTO v_orch_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;
    END IF;
    IF v_cloud_sub_id IS NULL THEN
        SELECT id INTO v_cloud_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;
    END IF;
    IF v_spark_sub_id IS NULL THEN
        SELECT id INTO v_spark_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;
    END IF;
    IF v_sysdesign_sub_id IS NULL THEN
        SELECT id INTO v_sysdesign_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;
    END IF;

    -- ── SQL Flashcards (fc1–fc20) ──────────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the difference between Star Schema and Snowflake Schema?',
     'Star Schema: Denormalized, single fact table surrounded by dimension tables. Fast queries, simple joins.' || chr(10) || chr(10) || 'Snowflake Schema: Normalized dimensions split into sub-tables. Saves storage, more complex joins, slower queries.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is ETL vs ELT?',
     'ETL: Extract -> Transform -> Load. Transform happens before loading into warehouse. Traditional approach.' || chr(10) || chr(10) || 'ELT: Extract -> Load -> Transform. Raw data loaded first, then transformed inside the warehouse. Modern cloud approach (Snowflake, BigQuery).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What are SQL Window Functions?',
     'Window functions perform calculations across a set of rows related to the current row without collapsing them.' || chr(10) || chr(10) || 'Examples: ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD(), SUM() OVER(), AVG() OVER(PARTITION BY ... ORDER BY ...)')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the difference between RANK() and DENSE_RANK()?',
     'RANK(): Assigns the same rank to ties, then skips the next rank(s). E.g., 1, 2, 2, 4.' || chr(10) || chr(10) || 'DENSE_RANK(): Assigns the same rank to ties but does NOT skip ranks. E.g., 1, 2, 2, 3.' || chr(10) || chr(10) || 'Use DENSE_RANK() when you need consecutive ranking without gaps.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is a CTE (Common Table Expression)?',
     'A CTE is a named temporary result set defined with the WITH keyword, used to simplify complex queries.' || chr(10) || chr(10) || 'Syntax: WITH cte_name AS (SELECT ...) SELECT * FROM cte_name' || chr(10) || chr(10) || 'Limitation: CTEs are recomputed every time they are referenced in the same query.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the difference between WHERE and HAVING?',
     'WHERE: Filters rows BEFORE aggregation. Cannot use aggregate functions.' || chr(10) || chr(10) || 'HAVING: Filters groups AFTER aggregation. Used with GROUP BY.' || chr(10) || chr(10) || 'Example: WHERE salary > 50000 vs HAVING AVG(salary) > 50000')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is a SQL fan-out problem?',
     'Fan-out occurs when a JOIN multiplies rows unexpectedly because one table has multiple matching rows per key.' || chr(10) || chr(10) || 'Example: A user in 16 segments x 500 events = 8,000 rows instead of 500.' || chr(10) || chr(10) || 'Fix: Aggregate before joining, or use LATERAL FLATTEN after joining an array column.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is data partitioning in SQL databases?',
     'Splitting data across multiple nodes/files to improve query performance.' || chr(10) || chr(10) || 'Types: Range (by date), Hash (by key), List (by category).' || chr(10) || chr(10) || 'Benefit: Partition pruning - queries only scan relevant partitions, skipping the rest.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is a Slowly Changing Dimension (SCD) Type 2?',
     'SCD Type 2 keeps full history by inserting a new row for every change instead of overwriting.' || chr(10) || chr(10) || 'Required columns: effective_date, expiry_date (default 9999-12-31), is_current flag.' || chr(10) || chr(10) || 'Use case: "What was the customer''s country at the time of purchase?"')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What are the three SCD types and when to use each?',
     'Type 1 - Overwrite: No history kept. Use for correcting errors.' || chr(10) || chr(10) || 'Type 2 - New row: Full history with effective/expiry dates. Most common for analytics.' || chr(10) || chr(10) || 'Type 3 - New column: Stores only previous value. Use when only one level of history is needed.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the difference between INNER JOIN, LEFT JOIN, and FULL OUTER JOIN?',
     'INNER JOIN: Returns only rows with matching keys in both tables.' || chr(10) || chr(10) || 'LEFT JOIN: Returns all rows from the left table, NULLs for non-matching right rows.' || chr(10) || chr(10) || 'FULL OUTER JOIN: Returns all rows from both tables, NULLs where there is no match.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is a Broadcast Join in SQL/Spark?',
     'A broadcast join sends a full copy of a small table to every executor/node, eliminating the need for a shuffle.' || chr(10) || chr(10) || 'Use when: one table is small enough to fit in memory (typically < 200MB).' || chr(10) || chr(10) || 'Benefit: Removes network shuffle, dramatically speeds up joins.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the purpose of EXPLAIN in SQL?',
     'EXPLAIN shows the query execution plan - how the database will retrieve data.' || chr(10) || chr(10) || 'Key things to look for: Full table scans (bad), Index usage (good), Join types, Estimated row counts.' || chr(10) || chr(10) || 'Use EXPLAIN ANALYZE to see actual vs estimated rows.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is a recursive CTE?',
     'A recursive CTE references itself to process hierarchical data like org charts or category trees.' || chr(10) || chr(10) || 'Structure: WITH RECURSIVE cte AS (anchor SELECT UNION ALL recursive SELECT joining cte with itself)')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the difference between UNION and UNION ALL?',
     'UNION: Combines results from two queries and removes duplicates. Slower due to deduplication.' || chr(10) || chr(10) || 'UNION ALL: Combines results and keeps all duplicates. Faster.' || chr(10) || chr(10) || 'Use UNION ALL when you know there are no duplicates or performance matters more.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is Snowflake Zero-Copy Cloning?',
     'Creates an independent copy of a table, schema, or database instantly with no data duplication.' || chr(10) || chr(10) || 'Uses copy-on-write: the clone shares original storage until modified.' || chr(10) || chr(10) || 'Use cases: dev/test environments from production, snapshots before risky migrations. Cost: Free to create.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What are Snowflake Micro-Partitions and Clustering Keys?',
     'Micro-partitions: Snowflake automatically splits tables into 50-500MB chunks, storing min/max metadata per column for pruning.' || chr(10) || chr(10) || 'Clustering Keys: Reorganize data so rows with the same key value are stored together, enabling partition pruning.' || chr(10) || chr(10) || 'Result: 95% partitions scanned -> 3-5% scanned after clustering.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is a Transient Table in Snowflake?',
     'A Transient Table is a temporary table that persists across sessions but has no Fail-safe storage (no 7-day recovery).' || chr(10) || chr(10) || 'Use when: You need to share intermediate results across multiple queries or sessions.' || chr(10) || chr(10) || 'Cost: Cheaper than permanent tables - no Fail-safe overhead.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is Redshift DISTKEY and SORTKEY?',
     'DISTKEY: Determines which node stores each row. Matching DISTKEY on joined tables eliminates network shuffle.' || chr(10) || chr(10) || 'SORTKEY: Sorts data on disk for fast range queries. Redshift skips entire blocks that do not match the filter.' || chr(10) || chr(10) || 'Small tables: use DISTSTYLE ALL to copy to every node.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
     'What is the difference between a View and a Materialized View?',
     'View: A saved SQL query. Executes the query every time it is accessed. Always shows fresh data.' || chr(10) || chr(10) || 'Materialized View: Stores the query result physically on disk. Must be refreshed to show new data.' || chr(10) || chr(10) || 'Use Materialized Views for expensive aggregations that are queried frequently.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    -- ── Architecture Flashcards (fc21–fc40) ──────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'Explain ACID vs BASE consistency models.',
     'ACID: Atomicity, Consistency, Isolation, Durability - used in relational DBs for strict transactions.' || chr(10) || chr(10) || 'BASE: Basically Available, Soft state, Eventually consistent - used in NoSQL for high availability and scalability.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is a Data Lakehouse?',
     'A hybrid architecture combining the low-cost storage of a Data Lake with the ACID transactions and schema enforcement of a Data Warehouse.' || chr(10) || chr(10) || 'Examples: Delta Lake, Apache Iceberg, Apache Hudi.' || chr(10) || chr(10) || 'Key feature: ACID transactions on top of object storage (S3, GCS).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is the CAP Theorem?',
     'A distributed system can only guarantee 2 of 3 properties: Consistency (all nodes see same data), Availability (every request gets a response), Partition Tolerance (system works despite network failures).' || chr(10) || chr(10) || 'NoSQL DBs typically choose AP (Cassandra) or CP (HBase).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is the difference between batch and stream processing?',
     'Batch: Processes large volumes of data at scheduled intervals (e.g., nightly ETL). Tools: Spark, Hive.' || chr(10) || chr(10) || 'Stream: Processes data continuously as it arrives in real-time. Tools: Kafka Streams, Apache Flink, Spark Structured Streaming.' || chr(10) || chr(10) || 'Lambda Architecture combines both.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is Lambda Architecture?',
     'A data architecture pattern with three layers: Batch layer (reprocesses all historical data), Speed layer (processes real-time data), Serving layer (merges batch and speed results).' || chr(10) || chr(10) || 'Downside: Maintaining two codebases (batch + streaming) is complex.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is Kappa Architecture?',
     'A simplified alternative to Lambda Architecture that uses only a streaming layer.' || chr(10) || chr(10) || 'All data (historical and real-time) is processed through a single streaming pipeline.' || chr(10) || chr(10) || 'Advantage: One codebase. Disadvantage: Reprocessing historical data requires replaying the entire stream.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is Change Data Capture (CDC)?',
     'CDC reads a database''s transaction log (WAL in PostgreSQL) and streams every INSERT, UPDATE, and DELETE as an event in real time.' || chr(10) || chr(10) || 'Tool: Debezium -> Kafka -> downstream consumers.' || chr(10) || chr(10) || 'Advantage over polling: No load on source DB, captures deletes, sub-second latency.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is a Dead Letter Queue (DLQ)?',
     'A DLQ is a separate queue/topic where failed messages are routed instead of blocking the main pipeline.' || chr(10) || chr(10) || 'Contents: Original payload + error reason + timestamp + retry count.' || chr(10) || chr(10) || 'Purpose: Isolate bad records, keep the pipeline running, enable replay after fixing the root cause.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is idempotency in data pipelines?',
     'An idempotent operation produces the same result whether it runs once or multiple times.' || chr(10) || chr(10) || 'Why it matters: Kafka delivers at-least-once, so consumers may process the same message twice.' || chr(10) || chr(10) || 'Implementation: Use deterministic event IDs (SHA256 of key fields) and upsert instead of insert.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is data lineage?',
     'Data lineage tracks the origin, movement, and transformation of data through a pipeline.' || chr(10) || chr(10) || 'Why it matters: Debugging data quality issues, understanding impact of schema changes, regulatory compliance.' || chr(10) || chr(10) || 'Tools: Apache Atlas, OpenLineage, dbt lineage graph.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is a Medallion Architecture (Bronze/Silver/Gold)?',
     'A layered data lake pattern: Bronze (raw ingested data), Silver (cleaned, deduplicated, validated), Gold (aggregated, business-ready data for analytics).' || chr(10) || chr(10) || 'Used in Delta Lake / Databricks. Each layer adds quality and reduces volume.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is event-driven architecture?',
     'A design pattern where services communicate by producing and consuming events asynchronously.' || chr(10) || chr(10) || 'Components: Event producer -> Event broker (Kafka) -> Event consumer.' || chr(10) || chr(10) || 'Advantages: Loose coupling, scalability, fault tolerance. Disadvantage: Harder to debug, eventual consistency.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is a data mesh?',
     'A decentralized data architecture where domain teams own their own data products.' || chr(10) || chr(10) || 'Four principles: Domain ownership, Data as a product, Self-serve data platform, Federated computational governance.' || chr(10) || chr(10) || 'Contrast with centralized data lake owned by a single data team.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is schema evolution and how do you handle it?',
     'Schema evolution is the ability to change a table''s schema over time without breaking existing consumers.' || chr(10) || chr(10) || 'Safe changes: Adding nullable columns, widening types. Breaking changes: Removing/renaming columns, changing types.' || chr(10) || chr(10) || 'Tools: Schema Registry (Kafka), Delta Lake schema evolution, dbt migrations.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is the difference between horizontal and vertical scaling?',
     'Vertical scaling (scale up): Add more CPU/RAM to a single machine. Simple but has limits.' || chr(10) || chr(10) || 'Horizontal scaling (scale out): Add more machines to a cluster. More complex but nearly unlimited.' || chr(10) || chr(10) || 'Distributed systems like Kafka, Spark, and Cassandra are designed for horizontal scaling.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is a data contract?',
     'A formal agreement between a data producer and consumer that defines the schema, quality, and SLA of a dataset.' || chr(10) || chr(10) || 'Includes: Field names, types, nullability, freshness SLA, owner.' || chr(10) || chr(10) || 'Benefit: Prevents breaking changes from propagating silently through the pipeline.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is the difference between OLTP and OLAP?',
     'OLTP (Online Transaction Processing): Optimized for fast reads/writes of individual rows. Used in operational databases (PostgreSQL, MySQL).' || chr(10) || chr(10) || 'OLAP (Online Analytical Processing): Optimized for aggregating large volumes of data. Used in data warehouses (Snowflake, BigQuery, Redshift).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is a data catalog?',
     'A data catalog is an inventory of all data assets in an organization with metadata, lineage, and search capabilities.' || chr(10) || chr(10) || 'Contents: Table descriptions, column definitions, owners, freshness, quality scores.' || chr(10) || chr(10) || 'Tools: Apache Atlas, Alation, DataHub, Collibra.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is the difference between a Data Lake and a Data Warehouse?',
     'Data Lake: Stores raw, unstructured data in its native format (S3, GCS). Schema-on-read. Cheap storage.' || chr(10) || chr(10) || 'Data Warehouse: Stores structured, processed data with enforced schema. Schema-on-write. Optimized for SQL queries.' || chr(10) || chr(10) || 'Data Lakehouse: Combines both.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
     'What is eventual consistency?',
     'A consistency model where all replicas of data will eventually converge to the same value, but may temporarily differ.' || chr(10) || chr(10) || 'Used in: Cassandra, DynamoDB, Kafka consumer groups.' || chr(10) || chr(10) || 'Trade-off: Higher availability and lower latency at the cost of temporary inconsistency.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    -- ── Orchestration Flashcards (fc41–fc55) ─────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Apache Kafka?',
     'A distributed event streaming platform used for high-throughput, fault-tolerant, real-time data pipelines.' || chr(10) || chr(10) || 'Key concepts: Topics, Partitions, Producers, Consumers, Consumer Groups, Offsets, Brokers.' || chr(10) || chr(10) || 'Use cases: Event streaming, CDC, log aggregation, real-time analytics.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Apache Airflow?',
     'An open-source workflow orchestration platform for authoring, scheduling, and monitoring data pipelines as DAGs.' || chr(10) || chr(10) || 'Key components: DAG, Task, Operator, Scheduler, Executor, XCom.' || chr(10) || chr(10) || 'Note: "Success" in Airflow means the task ran without crashing - not that data was loaded correctly.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is a Kafka Consumer Group?',
     'A group of consumers that jointly consume a Kafka topic, with each partition assigned to exactly one consumer in the group.' || chr(10) || chr(10) || 'Benefit: Enables parallel processing - more consumers = higher throughput.' || chr(10) || chr(10) || 'Rule: Number of active consumers <= number of partitions. Extra consumers sit idle.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Kafka consumer lag?',
     'Consumer lag is the difference between the latest offset in a partition and the consumer''s current offset.' || chr(10) || chr(10) || 'High lag means: consumers are falling behind producers.' || chr(10) || chr(10) || 'Fix: Add more consumers (up to partition count), optimize consumer processing, or increase partition count.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is a Kafka offset?',
     'An offset is a unique sequential ID assigned to each message within a Kafka partition.' || chr(10) || chr(10) || 'Consumers track their position using offsets. Committing an offset means "I have processed up to this message."' || chr(10) || chr(10) || 'At-least-once delivery: commit after processing. At-most-once: commit before processing.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is an Airflow DAG?',
     'A DAG (Directed Acyclic Graph) is a collection of tasks with defined dependencies and execution order.' || chr(10) || chr(10) || 'Key properties: No cycles (acyclic), tasks run in dependency order, supports parallel execution.' || chr(10) || chr(10) || 'Backfill: Re-run a DAG for historical dates using: airflow dags backfill -s START -e END dag_id')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Kafka Schema Registry?',
     'A centralized service that stores and validates Avro/Protobuf/JSON schemas for Kafka messages.' || chr(10) || chr(10) || 'Benefit: Ensures producers and consumers agree on message format. Prevents schema mismatches.' || chr(10) || chr(10) || 'Supports: Backward compatibility (new schema reads old data), forward compatibility (old schema reads new data).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Flink''s watermark?',
     'A watermark tells Flink "I am confident all events up to this timestamp have arrived."' || chr(10) || chr(10) || 'Used for: Handling out-of-order events in event-time processing.' || chr(10) || chr(10) || 'Example: forBoundedOutOfOrderness(Duration.ofHours(4)) waits 4 hours before closing a window. Trade-off: Larger watermark = more accuracy but higher latency.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is the difference between event time and processing time in streaming?',
     'Event time: When the event actually occurred (from the device/source). Use for accurate analytics.' || chr(10) || chr(10) || 'Processing time: When Kafka/Flink received the event. Simpler but inaccurate for late-arriving data.' || chr(10) || chr(10) || 'Rule: Always use event time for business metrics. Processing time is only for operational monitoring.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Flink''s session window?',
     'A session window groups events that occur within a specified gap of each other.' || chr(10) || chr(10) || 'Example: Gap = 10 minutes. If no events arrive for 10 minutes, the window closes.' || chr(10) || chr(10) || 'Use case: Grouping a user''s activity into sessions, reconstructing trip timelines from GPS pings.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Debezium?',
     'An open-source CDC (Change Data Capture) platform that reads database transaction logs and streams changes to Kafka.' || chr(10) || chr(10) || 'Supports: PostgreSQL (WAL), MySQL (binlog), MongoDB (oplog).' || chr(10) || chr(10) || 'Output: Each message contains the operation type (c=create, u=update, d=delete) and the new/old values.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Airflow XCom?',
     'XCom (Cross-Communication) allows Airflow tasks to share small pieces of data with each other.' || chr(10) || chr(10) || 'Usage: task_instance.xcom_push(key="result", value=data) and xcom_pull(task_ids="task_name", key="result").' || chr(10) || chr(10) || 'Warning: XCom is stored in the Airflow metadata DB - only use for small values, not large datasets.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Kafka''s replication factor?',
     'The replication factor determines how many copies of each partition are stored across brokers.' || chr(10) || chr(10) || 'Replication factor 3: One leader + two replicas. If the leader fails, a replica is promoted.' || chr(10) || chr(10) || 'Recommendation: Use replication factor >= 3 in production for fault tolerance.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is Flink''s KeyedProcessFunction?',
     'A low-level Flink API that processes events keyed by a specific field, with access to per-key state and timers.' || chr(10) || chr(10) || 'Use cases: Deduplication (store seen event IDs in state), fraud detection (track per-user velocity), session management.' || chr(10) || chr(10) || 'State TTL: Set a time-to-live to automatically expire old state and bound memory usage.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
     'What is the difference between Kafka and a traditional message queue?',
     'Traditional queue (RabbitMQ): Messages are deleted after consumption. One consumer per message.' || chr(10) || chr(10) || 'Kafka: Messages are retained for a configurable period (days/weeks). Multiple consumer groups can independently read the same messages.' || chr(10) || chr(10) || 'Kafka is a log, not a queue - it enables replay and multiple independent consumers.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    -- ── Cloud Data Lakes Flashcards (fc56–fc70) ───────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is data partitioning in distributed systems?',
     'Splitting data across multiple nodes/files to improve query performance and manageability.' || chr(10) || chr(10) || 'Types: Range partitioning (by date), Hash partitioning (by key), List partitioning (by category).' || chr(10) || chr(10) || 'Benefit: Partition pruning - queries only scan relevant partitions.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is Apache Iceberg?',
     'An open table format for huge analytic datasets on object storage (S3, GCS).' || chr(10) || chr(10) || 'Key features: ACID transactions, schema evolution, time travel, hidden partitioning.' || chr(10) || chr(10) || 'Advantage over Hive: Atomic commits, no partition discovery overhead, supports row-level deletes.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is Delta Lake?',
     'An open-source storage layer that brings ACID transactions to Apache Spark and object storage.' || chr(10) || chr(10) || 'Key features: ACID transactions, time travel (RESTORE), schema enforcement, MERGE command for upserts.' || chr(10) || chr(10) || 'Used in: Databricks Medallion Architecture (Bronze/Silver/Gold).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is the difference between Parquet and CSV for data lakes?',
     'CSV: Row-based, human-readable, no compression, slow for analytics.' || chr(10) || chr(10) || 'Parquet: Columnar, compressed (Snappy/GZIP), fast for analytical queries (reads only needed columns).' || chr(10) || chr(10) || 'Switching from CSV to Parquet typically gives 3-5x query speedup and 70-80% storage reduction.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is the small files problem in data lakes?',
     'Having thousands of tiny files (< 1MB) in S3/HDFS causes high metadata overhead, slow query planning, and excessive S3 API calls.' || chr(10) || chr(10) || 'Fix: Compact small files into larger ones (128MB-1GB). Delta Lake OPTIMIZE command does this automatically.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is time travel in Delta Lake / Iceberg?',
     'Time travel allows querying a table as it existed at a previous point in time.' || chr(10) || chr(10) || 'Delta Lake: SELECT * FROM table TIMESTAMP AS OF "2024-01-01" or VERSION AS OF 5.' || chr(10) || chr(10) || 'Use cases: Auditing, debugging data quality issues, reproducing ML training datasets.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is the MERGE command in Delta Lake?',
     'MERGE performs an upsert - update existing rows and insert new ones in a single atomic operation.' || chr(10) || chr(10) || 'Syntax: MERGE INTO target USING source ON target.id = source.id WHEN MATCHED THEN UPDATE ... WHEN NOT MATCHED THEN INSERT ...' || chr(10) || chr(10) || 'Use case: SCD Type 2 updates, deduplication, CDC application.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is Apache Hudi?',
     'An open-source data lake storage format that supports ACID transactions and incremental data processing on object storage.' || chr(10) || chr(10) || 'Two table types: Copy-on-Write (COW) - fast reads, slow writes. Merge-on-Read (MOR) - fast writes, slower reads.' || chr(10) || chr(10) || 'Used heavily at Uber.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is S3 Select?',
     'S3 Select allows querying a subset of data from an S3 object using SQL expressions, without downloading the entire file.' || chr(10) || chr(10) || 'Supports: CSV, JSON, Parquet.' || chr(10) || chr(10) || 'Benefit: Reduces data transfer and processing costs when you only need a few columns or rows from a large file.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is data skipping in cloud data lakes?',
     'Data skipping uses file-level statistics (min/max values per column) to skip files that cannot contain matching rows.' || chr(10) || chr(10) || 'Requires: Data sorted or clustered by the filter column.' || chr(10) || chr(10) || 'Implemented in: Delta Lake (Z-ordering), Iceberg (hidden partitioning), Snowflake (micro-partition pruning).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is Z-ordering in Delta Lake?',
     'Z-ordering co-locates related data in the same set of files by sorting on multiple columns simultaneously.' || chr(10) || chr(10) || 'Command: OPTIMIZE table ZORDER BY (column1, column2)' || chr(10) || chr(10) || 'Benefit: Queries filtering on either column can skip more files. More effective than single-column sorting for multi-dimensional filters.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is the difference between a managed and external table in a data lake?',
     'Managed table: The catalog manages both metadata and data files. Dropping the table deletes the data.' || chr(10) || chr(10) || 'External table: The catalog manages only metadata. Data files live in a user-specified location. Dropping the table does NOT delete the data.' || chr(10) || chr(10) || 'Use external tables when data is shared across multiple tools.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is schema-on-read vs schema-on-write?',
     'Schema-on-write: Schema is enforced when data is written (Data Warehouses). Ensures data quality upfront.' || chr(10) || chr(10) || 'Schema-on-read: Schema is applied when data is read (Data Lakes). Flexible ingestion, but quality issues discovered late.' || chr(10) || chr(10) || 'Data Lakehouse: Schema-on-write with the flexibility of a data lake.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is data compaction in Delta Lake?',
     'Compaction merges many small files into fewer large files to improve read performance.' || chr(10) || chr(10) || 'Delta Lake command: OPTIMIZE table_name' || chr(10) || chr(10) || 'When to run: After many small incremental writes (streaming ingestion, CDC). VACUUM removes old files no longer referenced by the Delta log (default 7-day retention).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
     'What is the Open Table Format (OTF) ecosystem?',
     'Open Table Formats add warehouse-like capabilities to data lakes on object storage.' || chr(10) || chr(10) || 'The three main OTFs: Apache Iceberg (best for multi-engine compatibility), Delta Lake (best for Databricks/Spark), Apache Hudi (best for streaming upserts).' || chr(10) || chr(10) || 'All support: ACID transactions, time travel, schema evolution.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    -- ── PySpark Flashcards (fc71–fc85) ────────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is data skew in PySpark and how do you fix it?',
     'Data skew: A few partition keys have far more data than others, causing some executors to be overloaded.' || chr(10) || chr(10) || 'Diagnose: df.groupBy("key").count().orderBy(desc("count")).show(10)' || chr(10) || chr(10) || 'Fixes: 1. Broadcast join (if one table is small). 2. Salting: Add random suffix to skewed keys. 3. Split: Process skewed keys separately.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What causes OutOfMemoryError in PySpark?',
     'Common causes: Data skew (one executor gets too much data), too few partitions, collecting large DataFrames to the driver (df.collect()), insufficient executor memory overhead.' || chr(10) || chr(10) || 'Fix: Repartition, increase spark.executor.memoryOverhead, use broadcast joins, avoid collect() on large data.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is the difference between repartition() and coalesce() in Spark?',
     'repartition(n): Shuffles data across the network to create exactly n equal partitions. Expensive but balanced.' || chr(10) || chr(10) || 'coalesce(n): Reduces partitions by merging local partitions without a full shuffle. Cheap but may create uneven partitions.' || chr(10) || chr(10) || 'Rule: Use coalesce() to reduce partitions. Use repartition() to increase or rebalance.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is lazy evaluation in Spark?',
     'Spark does not execute transformations immediately - it builds a logical plan and only executes when an action is called.' || chr(10) || chr(10) || 'Transformations (lazy): filter(), select(), join(), groupBy()' || chr(10) || chr(10) || 'Actions (trigger execution): count(), collect(), write(), show()' || chr(10) || chr(10) || 'Benefit: Spark can optimize the entire plan before executing.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is the Spark Catalyst Optimizer?',
     'Catalyst is Spark''s query optimizer that automatically rewrites and optimizes SQL/DataFrame operations.' || chr(10) || chr(10) || 'Optimizations: Predicate pushdown (filter early), column pruning (read only needed columns), join reordering.' || chr(10) || chr(10) || 'Result: Writing df.filter(...).select(...) is equivalent to the optimal SQL - Catalyst handles the rest.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is the difference between a Spark transformation and an action?',
     'Transformation: Creates a new DataFrame from an existing one. Lazy - not executed immediately. Examples: filter(), select(), join(), withColumn(), groupBy()' || chr(10) || chr(10) || 'Action: Triggers execution of the entire DAG. Examples: count(), collect(), show(), write(), take()')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is spark.sql.shuffle.partitions?',
     'Controls the number of partitions created after a shuffle operation (groupBy, join, distinct).' || chr(10) || chr(10) || 'Default: 200 (often too low for large datasets, too high for small ones).' || chr(10) || chr(10) || 'Recommendation: Set to 2-3x your total executor cores. Example: spark.conf.set("spark.sql.shuffle.partitions", "400")')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is caching in PySpark and when should you use it?',
     'df.cache() stores a DataFrame in memory so it is not recomputed on subsequent actions.' || chr(10) || chr(10) || 'Use when: The same DataFrame is used in multiple actions or joins.' || chr(10) || chr(10) || 'Do NOT use when: The DataFrame is only used once - caching wastes memory. df.unpersist() releases the cached data when done.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is a Spark Stage and how does it relate to shuffles?',
     'A Stage is a set of tasks that can run in parallel without a shuffle.' || chr(10) || chr(10) || 'A new stage begins whenever a shuffle is required (groupBy, join, repartition).' || chr(10) || chr(10) || 'Shuffle: Data is redistributed across partitions over the network - the most expensive operation in Spark. Minimize shuffles to improve performance.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is the difference between DataFrame and RDD in Spark?',
     'RDD (Resilient Distributed Dataset): Low-level API, no schema, no query optimization. Use for unstructured data or custom transformations.' || chr(10) || chr(10) || 'DataFrame: High-level API with schema, SQL support, and Catalyst optimization. Faster and easier to use.' || chr(10) || chr(10) || 'Recommendation: Always use DataFrames/Datasets unless you need RDD-level control.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is Spark Structured Streaming?',
     'A stream processing engine built on Spark SQL that treats a live data stream as an unbounded table.' || chr(10) || chr(10) || 'Supports: Exactly-once semantics, event-time processing, watermarks, windowed aggregations.' || chr(10) || chr(10) || 'Sources: Kafka, S3, Delta Lake. Sinks: Delta Lake, Kafka, JDBC, console.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is predicate pushdown in Spark?',
     'Predicate pushdown moves filter conditions as close to the data source as possible, reducing the amount of data read.' || chr(10) || chr(10) || 'Example: Reading a Parquet file with filter(col("date") == "2024-01-01") - Spark reads only the matching row groups.' || chr(10) || chr(10) || 'Enabled automatically by Catalyst. Works with Parquet, ORC, Delta Lake, JDBC.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is the Spark driver vs executor?',
     'Driver: The master process that runs the main() function, creates the SparkContext, builds the execution plan, and coordinates executors.' || chr(10) || chr(10) || 'Executor: Worker processes that run tasks and store data in memory/disk.' || chr(10) || chr(10) || 'Rule: Never collect large DataFrames to the driver - it has limited memory and is a single point of failure.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is salting in PySpark for skew handling?',
     'Salting adds a random number (0 to N-1) to skewed join keys, distributing one key''s data across N partitions.' || chr(10) || chr(10) || 'Steps: 1. Add salt to the large table: key + "_" + random(0, N). 2. Replicate the small table N times with matching salt values. 3. Join on the salted key. 4. Remove the salt column after joining.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
     'What is Spark''s Tungsten execution engine?',
     'Tungsten is Spark''s physical execution engine that optimizes CPU and memory usage.' || chr(10) || chr(10) || 'Key optimizations: Off-heap memory management (avoids JVM GC overhead), cache-friendly data structures, code generation (generates bytecode at runtime for each query).' || chr(10) || chr(10) || 'Result: Near-native performance for Spark SQL queries.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    -- ── System Design Flashcards (fc86–fc100) ─────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you design a real-time fraud detection pipeline?',
     'Architecture: Kafka -> Flink -> ML Model -> Decision Router' || chr(10) || chr(10) || 'Features computed in Flink: velocity (transactions/hour), amount anomaly (vs 30-day avg), location mismatch.' || chr(10) || chr(10) || 'Decision thresholds: Score > 0.95: Auto-block. Score 0.85-0.95: Step-up auth (OTP). Score < 0.85: Allow. Target latency: < 100ms end-to-end.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you handle late-arriving data in streaming pipelines?',
     'Strategy: 1. Set a watermark matching max observed latency (e.g., 4 hours). 2. Route events arriving after the watermark to a side output (DLQ). 3. Apply corrections nightly: read late events, recalculate, UPDATE published rows. 4. Label reports as "preliminary" until the correction window closes.' || chr(10) || chr(10) || 'Monitor: Track correction percentage daily.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you deduplicate events in a streaming pipeline at scale?',
     'Three-layer strategy: 1. Deterministic event IDs: SHA256(user_id + event_type + client_timestamp + session_id). 2. Streaming dedup: Flink KeyedProcessFunction stores seen IDs in state with 24-hour TTL. 3. Batch dedup: ROW_NUMBER() OVER (PARTITION BY user_id, event_type, DATE(ts) ORDER BY server_ts) - keep rn=1.' || chr(10) || chr(10) || 'Monitor: Track dedup rate daily.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you design a CDC pipeline with Debezium?',
     'Architecture: PostgreSQL -> Debezium -> Kafka -> Flink -> Redis' || chr(10) || chr(10) || 'Steps: 1. Enable logical replication: ALTER SYSTEM SET wal_level = logical. 2. Deploy Debezium connector (reads WAL, publishes to Kafka). 3. Flink consumer updates Redis cache. 4. Recommendation engine reads from Redis.' || chr(10) || chr(10) || 'Latency: 15 minutes (batch) -> < 1 second (CDC).')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you handle corrupted JSON payloads in a pipeline?',
     'Principle: Never let one bad record block the rest.' || chr(10) || chr(10) || 'Strategy: 1. Wrap every parse in try/except. 2. Validate required fields and types. 3. Route failures to a DLQ with original payload + error reason. 4. Emit valid_count and invalid_count metrics. 5. Alert if error rate > 5%. 6. Replay from DLQ after fixing the root cause.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you design a Kafka DLQ strategy for a high-throughput pipeline?',
     'Separate DLQ topics by failure type: pipeline.dlq.schema_error, pipeline.dlq.validation_error, pipeline.dlq.processing_error.' || chr(10) || chr(10) || 'Each DLQ record includes: original payload, error reason, timestamp, retry count, source consumer group.' || chr(10) || chr(10) || 'Alert: If DLQ lag > 10,000 messages, page on-call. Replay: After fix, republish to main topic. Archive after 3 failed retries.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you fix Redshift query performance with DS_DIST_BOTH?',
     'DS_DIST_BOTH means Redshift is shuffling both tables over the network to complete the join.' || chr(10) || chr(10) || 'Fix: 1. Set DISTKEY on the largest join column on both tables. 2. Use DISTSTYLE ALL for small dimension tables (< 1GB). 3. Add SORTKEY on the most common filter column. 4. Run VACUUM + ANALYZE after changes.' || chr(10) || chr(10) || 'Expected: 45 min -> < 5 min.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you handle out-of-order GPS events in a streaming pipeline?',
     'Strategy: 1. Always use event time (device timestamp), not processing time. 2. Set watermark to max observed latency (e.g., 30 minutes). 3. Use session windows to group events into trips (close on 10-min gap). 4. Sort events by client timestamp inside each window. 5. Detect and adjust for clock skew (> 5 min from server time). 6. Deduplicate retried events using device_id + sequence_number.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you design a data pipeline for 100K events/sec?',
     'Architecture: Kafka (50 partitions, keyed by user_id) -> Flink (dedup + enrich + aggregate) -> Three storage tiers: Hot (Redis), Warm (Iceberg on S3), Cold (S3 Parquet).' || chr(10) || chr(10) || 'Fault tolerance: Kafka at-least-once + idempotent writes + Flink checkpoints every 30s.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you optimize a PySpark job from 4 hours to 45 minutes?',
     'Step-by-step: 1. Profile first: Open Spark UI, find the slowest stage. 2. Fix skew: repartition on high-cardinality column. 3. Switch to Parquet: 3-5x speedup over CSV. 4. Broadcast small tables: Eliminate shuffle for joins < 200MB. 5. Cache reused DataFrames. 6. Tune: shuffle.partitions = 2-3x executor cores.' || chr(10) || chr(10) || 'Expected: 4 hours -> 30-45 minutes.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'What is a data quality framework and how do you implement it?',
     'A data quality framework validates data at each pipeline stage.' || chr(10) || chr(10) || 'Key checks: Completeness (no unexpected nulls), Uniqueness (no duplicate PKs), Freshness (data updated within SLA), Referential integrity, Volume (row count within expected range).' || chr(10) || chr(10) || 'Tools: Great Expectations, dbt tests, custom Airflow validation tasks.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you design a backfill strategy for a data pipeline?',
     'Backfill: Re-processing historical data after a bug fix or new pipeline deployment.' || chr(10) || chr(10) || 'Strategy: 1. Make the pipeline idempotent (safe to re-run). 2. Use date-partitioned writes (overwrite only the affected partition). 3. Run backfill in parallel with smaller date ranges. 4. Validate row counts after each partition.' || chr(10) || chr(10) || 'Never backfill by appending - always overwrite the partition.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'What is the difference between push and pull ingestion patterns?',
     'Pull ingestion: The pipeline queries the source on a schedule (polling). Simple but adds load to the source.' || chr(10) || chr(10) || 'Push ingestion: The source sends data to the pipeline when events occur (webhooks, CDC, Kafka producers). Lower latency, no polling overhead.' || chr(10) || chr(10) || 'Recommendation: Use push (CDC/Kafka) for real-time requirements. Use pull (batch) for systems that do not support push.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'How do you handle schema changes in a production pipeline?',
     'Safe changes (backward-compatible): Adding nullable columns, widening types (INT -> BIGINT).' || chr(10) || chr(10) || 'Breaking changes (require coordination): Removing columns, renaming columns, changing types.' || chr(10) || chr(10) || 'Process: Use Schema Registry for Kafka, Delta Lake schema evolution for storage, dbt migrations for warehouse. Always test in staging first.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation) VALUES
    (gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
     'What is the SCD Type 2 implementation pattern at scale?',
     'Pattern: 1. Add columns: effective_date, expiry_date (default 9999-12-31), is_current. 2. On change: Close old row (expiry_date = yesterday, is_current = false), insert new row. 3. Point-in-time query: JOIN ON id = id AND event_date BETWEEN effective_date AND expiry_date.' || chr(10) || chr(10) || 'At scale: Use Delta Lake MERGE for atomic close-and-insert. Performance: Partition by is_current.')
    ON CONFLICT (flashcard_id) DO NOTHING;

    RAISE NOTICE 'Flashcard seed completed successfully.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Flashcard seed failed: %', SQLERRM;
END $$;
