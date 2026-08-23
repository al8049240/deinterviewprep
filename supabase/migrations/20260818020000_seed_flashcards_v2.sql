-- Migration: Seed 100 flashcards into de_mobile_app.flashcards (v2 - idempotent by name)
-- Timestamp: 20260818020000
-- Uses INSERT ... WHERE NOT EXISTS to avoid duplicates on re-run

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

    v_fallback_topic_id BIGINT;
    v_fallback_sub_id BIGINT;
BEGIN
    -- Fetch fallback topic/subtopic first
    SELECT id INTO v_fallback_topic_id FROM "de_mobile_app"."topics-legacy" LIMIT 1;
    SELECT id INTO v_fallback_sub_id FROM "de_mobile_app"."subtopics-legacy" LIMIT 1;

    -- Fetch topic IDs by name
    SELECT id INTO v_sql_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%sql%' OR LOWER(name) LIKE '%snowflake%' OR LOWER(name) LIKE '%redshift%' LIMIT 1;

    SELECT id INTO v_arch_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%architect%' OR LOWER(name) LIKE '%data engineer%' LIMIT 1;

    SELECT id INTO v_orch_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%orchestrat%' OR LOWER(name) LIKE '%kafka%' OR LOWER(name) LIKE '%airflow%' OR LOWER(name) LIKE '%pipeline%' LIMIT 1;

    SELECT id INTO v_cloud_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%cloud%' OR LOWER(name) LIKE '%lake%' OR LOWER(name) LIKE '%delta%' LIMIT 1;

    SELECT id INTO v_spark_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%spark%' OR LOWER(name) LIKE '%pyspark%' OR LOWER(name) LIKE '%databricks%' LIMIT 1;

    SELECT id INTO v_sysdesign_topic_id
        FROM "de_mobile_app"."topics-legacy"
        WHERE LOWER(name) LIKE '%system%' OR LOWER(name) LIKE '%design%' LIMIT 1;

    -- Apply fallbacks
    v_sql_topic_id      := COALESCE(v_sql_topic_id, v_fallback_topic_id);
    v_arch_topic_id     := COALESCE(v_arch_topic_id, v_fallback_topic_id);
    v_orch_topic_id     := COALESCE(v_orch_topic_id, v_fallback_topic_id);
    v_cloud_topic_id    := COALESCE(v_cloud_topic_id, v_fallback_topic_id);
    v_spark_topic_id    := COALESCE(v_spark_topic_id, v_fallback_topic_id);
    v_sysdesign_topic_id := COALESCE(v_sysdesign_topic_id, v_fallback_topic_id);

    -- Fetch subtopic IDs
    SELECT id INTO v_sql_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_sql_topic_id LIMIT 1;
    SELECT id INTO v_arch_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_arch_topic_id LIMIT 1;
    SELECT id INTO v_orch_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_orch_topic_id LIMIT 1;
    SELECT id INTO v_cloud_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_cloud_topic_id LIMIT 1;
    SELECT id INTO v_spark_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_spark_topic_id LIMIT 1;
    SELECT id INTO v_sysdesign_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_sysdesign_topic_id LIMIT 1;

    -- Apply subtopic fallbacks
    v_sql_sub_id      := COALESCE(v_sql_sub_id, v_fallback_sub_id);
    v_arch_sub_id     := COALESCE(v_arch_sub_id, v_fallback_sub_id);
    v_orch_sub_id     := COALESCE(v_orch_sub_id, v_fallback_sub_id);
    v_cloud_sub_id    := COALESCE(v_cloud_sub_id, v_fallback_sub_id);
    v_spark_sub_id    := COALESCE(v_spark_sub_id, v_fallback_sub_id);
    v_sysdesign_sub_id := COALESCE(v_sysdesign_sub_id, v_fallback_sub_id);

    -- ── SQL Flashcards (1–20) ──────────────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between Star Schema and Snowflake Schema?',
        'Star Schema: Denormalized, single fact table surrounded by dimension tables. Fast queries, simple joins.' || chr(10) || chr(10) || 'Snowflake Schema: Normalized dimensions split into sub-tables. Saves storage, more complex joins, slower queries.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between Star Schema and Snowflake Schema?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is ETL vs ELT?',
        'ETL: Extract -> Transform -> Load. Transform happens before loading into warehouse. Traditional approach.' || chr(10) || chr(10) || 'ELT: Extract -> Load -> Transform. Raw data loaded first, then transformed inside the warehouse. Modern cloud approach (Snowflake, BigQuery).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is ETL vs ELT?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What are SQL Window Functions?',
        'Window functions perform calculations across a set of rows related to the current row without collapsing them.' || chr(10) || chr(10) || 'Examples: ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD(), SUM() OVER(), AVG() OVER(PARTITION BY ... ORDER BY ...)'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What are SQL Window Functions?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between RANK() and DENSE_RANK()?',
        'RANK(): Assigns the same rank to ties, then skips the next rank(s). E.g., 1, 2, 2, 4.' || chr(10) || chr(10) || 'DENSE_RANK(): Assigns the same rank to ties but does NOT skip ranks. E.g., 1, 2, 2, 3.' || chr(10) || chr(10) || 'Use DENSE_RANK() when you need consecutive ranking without gaps.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between RANK() and DENSE_RANK()?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a CTE (Common Table Expression)?',
        'A CTE is a named temporary result set defined with the WITH keyword, used to simplify complex queries.' || chr(10) || chr(10) || 'Syntax: WITH cte_name AS (SELECT ...) SELECT * FROM cte_name' || chr(10) || chr(10) || 'Limitation: CTEs are recomputed every time they are referenced in the same query.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a CTE (Common Table Expression)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between WHERE and HAVING?',
        'WHERE: Filters rows BEFORE aggregation. Cannot use aggregate functions.' || chr(10) || chr(10) || 'HAVING: Filters groups AFTER aggregation. Used with GROUP BY.' || chr(10) || chr(10) || 'Example: WHERE salary > 50000 vs HAVING AVG(salary) > 50000'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between WHERE and HAVING?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a SQL fan-out problem?',
        'Fan-out occurs when a JOIN multiplies rows unexpectedly because one table has multiple matching rows per key.' || chr(10) || chr(10) || 'Example: A user in 16 segments x 500 events = 8,000 rows instead of 500.' || chr(10) || chr(10) || 'Fix: Aggregate before joining, or use LATERAL FLATTEN after joining an array column.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a SQL fan-out problem?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is data partitioning in SQL databases?',
        'Splitting data across multiple nodes/files to improve query performance.' || chr(10) || chr(10) || 'Types: Range (by date), Hash (by key), List (by category).' || chr(10) || chr(10) || 'Benefit: Partition pruning - queries only scan relevant partitions, skipping the rest.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data partitioning in SQL databases?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a Slowly Changing Dimension (SCD) Type 2?',
        'SCD Type 2 keeps full history by inserting a new row for every change instead of overwriting.' || chr(10) || chr(10) || 'Required columns: effective_date, expiry_date (default 9999-12-31), is_current flag.' || chr(10) || chr(10) || 'Use case: What was the customer''s country at the time of purchase?'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Slowly Changing Dimension (SCD) Type 2?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What are the three SCD types and when to use each?',
        'Type 1 - Overwrite: No history kept. Use for correcting errors.' || chr(10) || chr(10) || 'Type 2 - New row: Full history with effective/expiry dates. Most common for analytics.' || chr(10) || chr(10) || 'Type 3 - New column: Stores only previous value. Use when only one level of history is needed.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What are the three SCD types and when to use each?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between INNER JOIN, LEFT JOIN, and FULL OUTER JOIN?',
        'INNER JOIN: Returns only rows with matching keys in both tables.' || chr(10) || chr(10) || 'LEFT JOIN: Returns all rows from the left table, NULLs for non-matching right rows.' || chr(10) || chr(10) || 'FULL OUTER JOIN: Returns all rows from both tables, NULLs where there is no match.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between INNER JOIN, LEFT JOIN, and FULL OUTER JOIN?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a Broadcast Join in SQL/Spark?',
        'A broadcast join sends a full copy of a small table to every executor/node, eliminating the need for a shuffle.' || chr(10) || chr(10) || 'Use when: one table is small enough to fit in memory (typically < 200MB).' || chr(10) || chr(10) || 'Benefit: Removes network shuffle, dramatically speeds up joins.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Broadcast Join in SQL/Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the purpose of EXPLAIN in SQL?',
        'EXPLAIN shows the query execution plan - how the database will retrieve data.' || chr(10) || chr(10) || 'Key things to look for: Full table scans (bad), Index usage (good), Join types (hash join, nested loop), Estimated row counts and costs.' || chr(10) || chr(10) || 'Use EXPLAIN ANALYZE to see actual vs estimated rows.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the purpose of EXPLAIN in SQL?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a recursive CTE?',
        'A recursive CTE references itself to process hierarchical data like org charts or category trees.' || chr(10) || chr(10) || 'Structure: WITH RECURSIVE cte AS (anchor SELECT UNION ALL recursive SELECT joining cte with itself).' || chr(10) || chr(10) || 'Use cases: org hierarchies, category trees, bill of materials.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a recursive CTE?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between UNION and UNION ALL?',
        'UNION: Combines results from two queries and removes duplicates. Slower due to deduplication.' || chr(10) || chr(10) || 'UNION ALL: Combines results and keeps all duplicates. Faster.' || chr(10) || chr(10) || 'Use UNION ALL when you know there are no duplicates or performance matters more than deduplication.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between UNION and UNION ALL?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is Snowflake Zero-Copy Cloning?',
        'Creates an independent copy of a table, schema, or database instantly with no data duplication.' || chr(10) || chr(10) || 'Uses copy-on-write: the clone shares original storage until modified.' || chr(10) || chr(10) || 'Use cases: dev/test environments from production, snapshots before risky migrations. Cost: Free to create, pay only for rows changed after cloning.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Snowflake Zero-Copy Cloning?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What are Snowflake Micro-Partitions and Clustering Keys?',
        'Micro-partitions: Snowflake automatically splits tables into 50-500MB chunks, storing min/max metadata per column for pruning.' || chr(10) || chr(10) || 'Clustering Keys: Reorganize data so rows with the same key value are stored together, enabling partition pruning.' || chr(10) || chr(10) || 'Result: 95% partitions scanned -> 3-5% scanned after clustering.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What are Snowflake Micro-Partitions and Clustering Keys?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a Transient Table in Snowflake?',
        'A Transient Table is a temporary table that persists across sessions but has no Fail-safe storage (no 7-day recovery).' || chr(10) || chr(10) || 'Use when: You need to share intermediate results across multiple queries or sessions.' || chr(10) || chr(10) || 'Cost: Cheaper than permanent tables - no Fail-safe overhead.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Transient Table in Snowflake?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is Redshift DISTKEY and SORTKEY?',
        'DISTKEY: Determines which node stores each row. Matching DISTKEY on joined tables eliminates network shuffle (DS_DIST_BOTH).' || chr(10) || chr(10) || 'SORTKEY: Sorts data on disk for fast range queries. Redshift skips entire blocks that do not match the filter.' || chr(10) || chr(10) || 'Small tables: use DISTSTYLE ALL to copy to every node.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Redshift DISTKEY and SORTKEY?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between a View and a Materialized View?',
        'View: A saved SQL query. Executes the query every time it is accessed. Always shows fresh data.' || chr(10) || chr(10) || 'Materialized View: Stores the query result physically on disk. Must be refreshed to show new data.' || chr(10) || chr(10) || 'Use Materialized Views for expensive aggregations that are queried frequently.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between a View and a Materialized View?');

    -- ── Architecture Flashcards (21–40) ──────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'Explain ACID vs BASE consistency models.',
        'ACID: Atomicity, Consistency, Isolation, Durability - used in relational DBs for strict transactions.' || chr(10) || chr(10) || 'BASE: Basically Available, Soft state, Eventually consistent - used in NoSQL for high availability and scalability.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'Explain ACID vs BASE consistency models.');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is a Data Lakehouse?',
        'A hybrid architecture combining the low-cost storage of a Data Lake with the ACID transactions and schema enforcement of a Data Warehouse.' || chr(10) || chr(10) || 'Examples: Delta Lake, Apache Iceberg, Apache Hudi.' || chr(10) || chr(10) || 'Key feature: ACID transactions on top of object storage (S3, GCS).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Data Lakehouse?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is the CAP Theorem?',
        'A distributed system can only guarantee 2 of 3 properties: Consistency (all nodes see same data), Availability (every request gets a response), Partition Tolerance (system works despite network failures).' || chr(10) || chr(10) || 'NoSQL DBs typically choose AP (Cassandra) or CP (HBase).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the CAP Theorem?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is the difference between batch and stream processing?',
        'Batch: Processes large volumes of data at scheduled intervals (e.g., nightly ETL). Tools: Spark, Hive.' || chr(10) || chr(10) || 'Stream: Processes data continuously as it arrives in real-time. Tools: Kafka Streams, Apache Flink, Spark Structured Streaming.' || chr(10) || chr(10) || 'Lambda Architecture combines both.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between batch and stream processing?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is Lambda Architecture?',
        'A data architecture pattern with three layers: Batch layer (reprocesses all historical data for accuracy), Speed layer (processes real-time data for low latency), Serving layer (merges batch and speed results for queries).' || chr(10) || chr(10) || 'Downside: Maintaining two codebases (batch + streaming) is complex.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Lambda Architecture?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is Kappa Architecture?',
        'A simplified alternative to Lambda Architecture that uses only a streaming layer.' || chr(10) || chr(10) || 'All data (historical and real-time) is processed through a single streaming pipeline.' || chr(10) || chr(10) || 'Advantage: One codebase to maintain. Disadvantage: Reprocessing historical data requires replaying the entire stream.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Kappa Architecture?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is Change Data Capture (CDC)?',
        'CDC reads a database''s transaction log (WAL in PostgreSQL) and streams every INSERT, UPDATE, and DELETE as an event in real time.' || chr(10) || chr(10) || 'Tool: Debezium -> Kafka -> downstream consumers.' || chr(10) || chr(10) || 'Advantage over polling: No load on source DB, captures deletes, sub-second latency.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Change Data Capture (CDC)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is a Data Mesh?',
        'A decentralized data architecture where domain teams own and serve their own data as a product.' || chr(10) || chr(10) || 'Four principles: Domain ownership, Data as a product, Self-serve data platform, Federated computational governance.' || chr(10) || chr(10) || 'Contrast: Centralized data lake/warehouse owned by a single data team.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Data Mesh?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is the difference between a Data Lake and a Data Warehouse?',
        'Data Lake: Stores raw, unstructured/semi-structured data at low cost (S3, GCS). Schema-on-read.' || chr(10) || chr(10) || 'Data Warehouse: Stores structured, processed data optimized for analytics (Snowflake, BigQuery, Redshift). Schema-on-write.' || chr(10) || chr(10) || 'Data Lake is cheaper but harder to query; Warehouse is faster but more expensive.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between a Data Lake and a Data Warehouse?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is an Event-Driven Architecture?',
        'A design pattern where services communicate by producing and consuming events asynchronously.' || chr(10) || chr(10) || 'Components: Event producers, Event broker (Kafka), Event consumers.' || chr(10) || chr(10) || 'Benefits: Loose coupling, scalability, fault tolerance. Use case: Real-time data pipelines, microservices.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is an Event-Driven Architecture?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is schema evolution and how do you handle it?',
        'Schema evolution is the process of changing a data schema over time without breaking existing consumers.' || chr(10) || chr(10) || 'Strategies: Backward compatibility (new schema reads old data), Forward compatibility (old schema reads new data).' || chr(10) || chr(10) || 'Tools: Apache Avro with Schema Registry, Delta Lake schema evolution, dbt migrations.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is schema evolution and how do you handle it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is data lineage?',
        'Data lineage tracks the origin, movement, and transformation of data throughout its lifecycle.' || chr(10) || chr(10) || 'Why it matters: Debugging data quality issues, compliance/auditing, impact analysis before schema changes.' || chr(10) || chr(10) || 'Tools: Apache Atlas, OpenLineage, dbt lineage graph, Marquez.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data lineage?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is the Medallion Architecture (Bronze/Silver/Gold)?',
        'A layered data lake pattern: Bronze (raw ingested data, no transformation), Silver (cleaned, validated, deduplicated data), Gold (aggregated, business-ready data for analytics).' || chr(10) || chr(10) || 'Used in Delta Lake / Databricks. Each layer progressively improves data quality.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the Medallion Architecture (Bronze/Silver/Gold)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is idempotency in data pipelines?',
        'An idempotent pipeline produces the same result regardless of how many times it runs with the same input.' || chr(10) || chr(10) || 'Why it matters: Pipelines fail and need to be retried. Without idempotency, retries cause duplicate data.' || chr(10) || chr(10) || 'Techniques: MERGE/UPSERT instead of INSERT, deduplication keys, partition overwrite.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is idempotency in data pipelines?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is a surrogate key vs a natural key?',
        'Natural Key: A key derived from business data (e.g., email, SSN, order_number). May change over time.' || chr(10) || chr(10) || 'Surrogate Key: A system-generated key (e.g., auto-increment integer, UUID) with no business meaning. Stable and unique.' || chr(10) || chr(10) || 'Best practice: Use surrogate keys in data warehouses for stability.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a surrogate key vs a natural key?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is data normalization vs denormalization?',
        'Normalization: Organizing data to reduce redundancy by splitting into multiple related tables. Good for OLTP (transactional systems).' || chr(10) || chr(10) || 'Denormalization: Combining tables to reduce JOINs and improve read performance. Good for OLAP (analytical systems).' || chr(10) || chr(10) || 'Data warehouses are typically denormalized.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data normalization vs denormalization?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is a data contract?',
        'A formal agreement between data producers and consumers defining the schema, quality, and SLA of a dataset.' || chr(10) || chr(10) || 'Contents: Schema definition, data types, nullability, freshness SLA, ownership.' || chr(10) || chr(10) || 'Benefit: Prevents breaking changes from propagating downstream without notice.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a data contract?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is the difference between OLTP and OLAP?',
        'OLTP (Online Transaction Processing): Optimized for fast INSERT/UPDATE/DELETE. Row-oriented storage. Used in operational systems (e-commerce, banking).' || chr(10) || chr(10) || 'OLAP (Online Analytical Processing): Optimized for complex aggregations and reads. Column-oriented storage. Used in data warehouses.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between OLTP and OLAP?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_arch_topic_id, v_arch_sub_id,
        'What is columnar storage and why is it faster for analytics?',
        'Columnar storage stores each column''s values together on disk instead of storing rows together.' || chr(10) || chr(10) || 'Why faster for analytics: Queries only read the columns they need (not entire rows), better compression (similar values together), vectorized processing.' || chr(10) || chr(10) || 'Examples: Parquet, ORC, Snowflake, BigQuery, Redshift.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is columnar storage and why is it faster for analytics?');

    -- ── Orchestration Flashcards (41–55) ──────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Apache Airflow and how does it work?',
        'Airflow is a workflow orchestration platform that schedules and monitors data pipelines as DAGs (Directed Acyclic Graphs).' || chr(10) || chr(10) || 'Key components: DAG (pipeline definition), Operator (task type), Scheduler (triggers tasks), Executor (runs tasks), Metadata DB (stores state).' || chr(10) || chr(10) || 'Tasks run in dependency order defined by the DAG.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Airflow and how does it work?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is a DAG in Airflow?',
        'A DAG (Directed Acyclic Graph) is a collection of tasks with defined dependencies, where data flows in one direction with no cycles.' || chr(10) || chr(10) || 'Directed: Tasks have a defined order. Acyclic: No circular dependencies. Graph: Tasks are nodes, dependencies are edges.' || chr(10) || chr(10) || 'Each DAG has a schedule interval (cron expression or preset like @daily).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a DAG in Airflow?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Apache Kafka and what problem does it solve?',
        'Kafka is a distributed event streaming platform that acts as a high-throughput, fault-tolerant message broker.' || chr(10) || chr(10) || 'Problem it solves: Decouples producers and consumers, handles millions of events/second, retains messages for replay.' || chr(10) || chr(10) || 'Core concepts: Topic, Partition, Producer, Consumer, Consumer Group, Offset.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Kafka and what problem does it solve?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is a Kafka Consumer Group?',
        'A Consumer Group is a set of consumers that jointly consume a topic, with each partition assigned to exactly one consumer in the group.' || chr(10) || chr(10) || 'Benefit: Horizontal scaling - add more consumers to increase throughput.' || chr(10) || chr(10) || 'Rule: Number of active consumers <= number of partitions. Extra consumers are idle.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Kafka Consumer Group?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Kafka exactly-once semantics?',
        'Exactly-once semantics (EOS) guarantees that each message is processed exactly once, even in the case of failures.' || chr(10) || chr(10) || 'Levels: At-most-once (may lose messages), At-least-once (may duplicate), Exactly-once (no loss, no duplicates).' || chr(10) || chr(10) || 'Requires: Idempotent producers + transactional APIs. Available since Kafka 0.11.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Kafka exactly-once semantics?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Apache Flink and how does it differ from Spark Streaming?',
        'Flink is a true stream processing engine with native support for event time, stateful computation, and exactly-once semantics.' || chr(10) || chr(10) || 'Flink vs Spark Streaming: Flink processes one event at a time (true streaming); Spark Streaming uses micro-batches (small batches).' || chr(10) || chr(10) || 'Flink has lower latency; Spark has better batch integration.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Flink and how does it differ from Spark Streaming?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is event time vs processing time in streaming?',
        'Event time: When the event actually occurred (embedded in the event payload). More accurate but requires handling late arrivals.' || chr(10) || chr(10) || 'Processing time: When the event is processed by the system. Simpler but inaccurate for out-of-order data.' || chr(10) || chr(10) || 'Watermarks handle late-arriving events in event-time processing.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is event time vs processing time in streaming?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is backpressure in data pipelines?',
        'Backpressure occurs when a downstream component cannot process data as fast as the upstream component produces it.' || chr(10) || chr(10) || 'Handling strategies: Buffering (queue the excess), Dropping (discard excess messages), Throttling (slow down the producer).' || chr(10) || chr(10) || 'Reactive Streams and Kafka consumer lag monitoring help detect and handle backpressure.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is backpressure in data pipelines?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is dbt (data build tool) and what problem does it solve?',
        'dbt is a transformation tool that lets data analysts write SQL SELECT statements and handles the CREATE TABLE/VIEW logic automatically.' || chr(10) || chr(10) || 'Problems it solves: Version control for SQL transformations, automated testing, documentation, lineage tracking.' || chr(10) || chr(10) || 'dbt runs inside the warehouse (Snowflake, BigQuery, Redshift) - no data movement.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is dbt (data build tool) and what problem does it solve?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is the difference between a dbt model, source, and seed?',
        'Model: A SQL SELECT statement that dbt compiles into a table or view in the warehouse.' || chr(10) || chr(10) || 'Source: A reference to raw data already in the warehouse (not created by dbt). Defined in YAML.' || chr(10) || chr(10) || 'Seed: A CSV file loaded into the warehouse as a table. Used for small reference/lookup data.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between a dbt model, source, and seed?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is an Airflow XCom?',
        'XCom (Cross-Communication) allows Airflow tasks to share small amounts of data between each other.' || chr(10) || chr(10) || 'How it works: Task A pushes a value with xcom_push(); Task B pulls it with xcom_pull(task_ids=''task_a'').' || chr(10) || chr(10) || 'Limitation: XComs are stored in the metadata DB - not suitable for large data. Use S3/GCS for large payloads.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is an Airflow XCom?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Kafka Schema Registry?',
        'Schema Registry is a centralized service that stores and validates Avro/JSON/Protobuf schemas for Kafka topics.' || chr(10) || chr(10) || 'Why it matters: Ensures producers and consumers agree on message format. Prevents schema breaking changes.' || chr(10) || chr(10) || 'Compatibility modes: BACKWARD (new schema reads old data), FORWARD (old schema reads new data), FULL (both).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Kafka Schema Registry?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is the difference between push and pull in data pipelines?',
        'Push: Source system sends data to the destination when new data is available. Lower latency, source controls timing.' || chr(10) || chr(10) || 'Pull: Destination system queries the source on a schedule. Simpler to implement, destination controls timing.' || chr(10) || chr(10) || 'Kafka uses push (producers push to broker); Airflow typically uses pull (scheduled polling).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between push and pull in data pipelines?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is a watermark in stream processing?',
        'A watermark is a threshold that tells the stream processor how long to wait for late-arriving events before closing a time window.' || chr(10) || chr(10) || 'Example: Watermark of 10 minutes means the system waits 10 minutes past the window end before computing results.' || chr(10) || chr(10) || 'Trade-off: Larger watermark = more complete results but higher latency.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a watermark in stream processing?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Airflow''s CeleryExecutor vs KubernetesExecutor?',
        'CeleryExecutor: Distributes tasks to a pool of worker nodes via a message broker (Redis/RabbitMQ). Good for stable, predictable workloads.' || chr(10) || chr(10) || 'KubernetesExecutor: Spins up a new Kubernetes pod for each task. Better isolation, dynamic scaling, no idle workers.' || chr(10) || chr(10) || 'KubernetesExecutor is preferred for cloud-native deployments.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Airflow''s CeleryExecutor vs KubernetesExecutor?');

    -- ── Cloud Data Lakes Flashcards (56–70) ──────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Apache Parquet and why is it preferred for data lakes?',
        'Parquet is a columnar storage format optimized for analytics workloads.' || chr(10) || chr(10) || 'Why preferred: Columnar reads (only scan needed columns), excellent compression (similar values together), schema embedded in file, splittable for parallel processing.' || chr(10) || chr(10) || 'Comparison: Parquet (columnar, analytics) vs CSV (row, simple) vs Avro (row, streaming).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Parquet and why is it preferred for data lakes?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Delta Lake?',
        'Delta Lake is an open-source storage layer that adds ACID transactions, schema enforcement, and time travel to data lakes (S3, ADLS, GCS).' || chr(10) || chr(10) || 'Key features: ACID transactions, schema evolution, time travel (query historical versions), MERGE/UPSERT support.' || chr(10) || chr(10) || 'Built on Parquet files + a transaction log (_delta_log).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Delta Lake?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Apache Iceberg?',
        'Iceberg is an open table format for huge analytic datasets that provides ACID transactions, schema evolution, and partition evolution.' || chr(10) || chr(10) || 'Key advantage over Delta Lake: Engine-agnostic (works with Spark, Flink, Trino, Hive). Better partition evolution without rewriting data.' || chr(10) || chr(10) || 'Used by Netflix, Apple, LinkedIn at petabyte scale.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Iceberg?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Apache Hudi?',
        'Hudi (Hadoop Upserts Deletes and Incrementals) is a data lake table format optimized for incremental data processing and upserts.' || chr(10) || chr(10) || 'Key feature: Supports record-level upserts and deletes efficiently (unlike Parquet which requires rewriting entire files).' || chr(10) || chr(10) || 'Two table types: Copy-on-Write (COW) for read-heavy, Merge-on-Read (MOR) for write-heavy.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Hudi?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is S3 Select and when should you use it?',
        'S3 Select allows you to retrieve only a subset of data from an S3 object using SQL expressions, without downloading the entire file.' || chr(10) || chr(10) || 'When to use: When you need a small subset of a large CSV/JSON/Parquet file and want to reduce data transfer costs.' || chr(10) || chr(10) || 'Limitation: Only works on single objects, not across multiple files.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is S3 Select and when should you use it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is the difference between S3 Standard, S3-IA, and S3 Glacier?',
        'S3 Standard: Frequently accessed data. Low latency, high throughput. Most expensive.' || chr(10) || chr(10) || 'S3-IA (Infrequent Access): Data accessed less than once a month. Lower storage cost, retrieval fee.' || chr(10) || chr(10) || 'S3 Glacier: Long-term archival. Very low cost, retrieval takes minutes to hours. Use for compliance/backup data.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between S3 Standard, S3-IA, and S3 Glacier?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is data skew in distributed systems?',
        'Data skew occurs when data is unevenly distributed across partitions, causing some tasks to process much more data than others.' || chr(10) || chr(10) || 'Symptoms: Most tasks finish quickly but a few take much longer (stragglers).' || chr(10) || chr(10) || 'Solutions: Salting (add random prefix to keys), repartitioning, broadcast join for small tables, AQE in Spark.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data skew in distributed systems?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Z-ordering in Delta Lake?',
        'Z-ordering is a multi-dimensional clustering technique that co-locates related data in the same set of files to improve query performance.' || chr(10) || chr(10) || 'How it works: OPTIMIZE table ZORDER BY (col1, col2) reorganizes data so rows with similar values are stored together.' || chr(10) || chr(10) || 'Benefit: Reduces files scanned for queries filtering on Z-ordered columns.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Z-ordering in Delta Lake?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is time travel in Delta Lake/Iceberg?',
        'Time travel allows you to query historical versions of a table by specifying a timestamp or version number.' || chr(10) || chr(10) || 'Delta Lake syntax: SELECT * FROM table VERSION AS OF 5 or TIMESTAMP AS OF ''2024-01-01''' || chr(10) || chr(10) || 'Use cases: Auditing, reproducing ML training datasets, recovering from accidental deletes/updates.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is time travel in Delta Lake/Iceberg?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is the small files problem in data lakes?',
        'The small files problem occurs when a data lake accumulates millions of tiny files, degrading query performance.' || chr(10) || chr(10) || 'Why it happens: Streaming writes, over-partitioning, frequent small batch loads.' || chr(10) || chr(10) || 'Solutions: Delta Lake OPTIMIZE (compacts small files), Hudi compaction, Iceberg rewrite_data_files, periodic merge jobs.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the small files problem in data lakes?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is AWS Glue and when would you use it?',
        'AWS Glue is a serverless ETL service that automatically discovers, catalogs, and transforms data.' || chr(10) || chr(10) || 'Key components: Glue Catalog (metadata store), Glue Crawlers (auto-discover schemas), Glue Jobs (Spark-based ETL).' || chr(10) || chr(10) || 'When to use: Serverless ETL without managing Spark clusters. Integrates natively with S3, Redshift, RDS.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is AWS Glue and when would you use it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Google BigQuery''s architecture?',
        'BigQuery separates storage and compute: Colossus (distributed storage), Dremel (query engine), Jupiter (network).' || chr(10) || chr(10) || 'Key features: Serverless (no cluster management), columnar storage, automatic partitioning and clustering, built-in ML (BQML).' || chr(10) || chr(10) || 'Pricing: Pay per query (bytes scanned) or flat-rate slots.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Google BigQuery''s architecture?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is data catalog and why is it important?',
        'A data catalog is a centralized inventory of all data assets in an organization, with metadata, lineage, and search capabilities.' || chr(10) || chr(10) || 'Why important: Data discovery (find the right dataset), data governance (who owns what), lineage (where did this data come from).' || chr(10) || chr(10) || 'Tools: AWS Glue Catalog, Apache Atlas, Collibra, Alation, DataHub.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data catalog and why is it important?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is partition pruning and how does it improve performance?',
        'Partition pruning is an optimization where the query engine skips reading partitions that cannot contain matching rows.' || chr(10) || chr(10) || 'Example: Table partitioned by date. Query with WHERE date = ''2024-01-01'' only reads that partition, skipping all others.' || chr(10) || chr(10) || 'Requires: Filtering on the partition column. Works in Spark, Hive, BigQuery, Snowflake.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is partition pruning and how does it improve performance?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is the difference between hot, warm, and cold data storage?',
        'Hot data: Frequently accessed, requires low latency. Stored in fast, expensive storage (SSD, S3 Standard, in-memory cache).' || chr(10) || chr(10) || 'Warm data: Occasionally accessed. Balanced cost/performance (S3-IA, HDD).' || chr(10) || chr(10) || 'Cold data: Rarely accessed, archival. Cheapest storage (S3 Glacier, tape). Retrieval takes minutes to hours.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between hot, warm, and cold data storage?');

    -- ── PySpark Flashcards (71–85) ──────────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between a Spark RDD, DataFrame, and Dataset?',
        'RDD (Resilient Distributed Dataset): Low-level, untyped, no optimization. Use for unstructured data or custom transformations.' || chr(10) || chr(10) || 'DataFrame: Distributed table with named columns. Optimized by Catalyst. Most common for ETL.' || chr(10) || chr(10) || 'Dataset: Typed DataFrame (Scala/Java only). Compile-time type safety + Catalyst optimization.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between a Spark RDD, DataFrame, and Dataset?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is a Spark shuffle and why is it expensive?',
        'A shuffle redistributes data across partitions, requiring all executors to exchange data over the network.' || chr(10) || chr(10) || 'Why expensive: Network I/O, disk I/O (data spills to disk), serialization/deserialization.' || chr(10) || chr(10) || 'Triggered by: groupBy, join, distinct, repartition, orderBy.' || chr(10) || chr(10) || 'Minimize shuffles: Use broadcast joins, pre-partition data, avoid unnecessary groupBy.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Spark shuffle and why is it expensive?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is lazy evaluation in Spark?',
        'Lazy evaluation means Spark does not execute transformations immediately - it builds a logical plan and only executes when an action is called.' || chr(10) || chr(10) || 'Transformations (lazy): filter, select, groupBy, join.' || chr(10) || chr(10) || 'Actions (trigger execution): show, count, collect, write, save.' || chr(10) || chr(10) || 'Benefit: Catalyst optimizer can optimize the entire plan before execution.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is lazy evaluation in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Spark caching and when should you use it?',
        'Caching stores a DataFrame in memory (or disk) so it does not need to be recomputed on subsequent actions.' || chr(10) || chr(10) || 'When to use: When you access the same DataFrame multiple times in your pipeline.' || chr(10) || chr(10) || 'Methods: df.cache() (default: MEMORY_AND_DISK), df.persist(StorageLevel.MEMORY_ONLY).' || chr(10) || chr(10) || 'Always unpersist() when done to free memory.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Spark caching and when should you use it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the Spark Catalyst Optimizer?',
        'Catalyst is Spark''s query optimization framework that transforms logical plans into optimized physical execution plans.' || chr(10) || chr(10) || 'Optimization steps: Analysis (resolve column names), Logical optimization (predicate pushdown, constant folding), Physical planning (choose join strategy), Code generation.' || chr(10) || chr(10) || 'Result: Automatically optimizes SQL and DataFrame operations.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the Spark Catalyst Optimizer?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Adaptive Query Execution (AQE) in Spark?',
        'AQE dynamically optimizes query plans at runtime based on actual data statistics collected during execution.' || chr(10) || chr(10) || 'Key features: Dynamic coalescing of shuffle partitions (reduces small partitions), Dynamic switch to broadcast join (when table is smaller than expected), Dynamic skew join optimization.' || chr(10) || chr(10) || 'Enabled by default in Spark 3.0+.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Adaptive Query Execution (AQE) in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between repartition() and coalesce() in Spark?',
        'repartition(n): Increases or decreases partitions. Always performs a full shuffle. Use to increase parallelism.' || chr(10) || chr(10) || 'coalesce(n): Only decreases partitions. Avoids full shuffle by merging partitions locally. More efficient for reducing partitions.' || chr(10) || chr(10) || 'Rule: Use coalesce() to reduce, repartition() to increase or redistribute evenly.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between repartition() and coalesce() in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is a Spark UDF and what are its performance implications?',
        'A UDF (User-Defined Function) is a custom Python/Scala function applied to DataFrame columns.' || chr(10) || chr(10) || 'Performance issue: Python UDFs break Catalyst optimization and require serialization between JVM and Python (slow).' || chr(10) || chr(10) || 'Better alternatives: Pandas UDFs (vectorized, 10-100x faster), Spark built-in functions (no serialization overhead).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Spark UDF and what are its performance implications?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Spark Structured Streaming?',
        'Structured Streaming is Spark''s stream processing engine built on the DataFrame API, treating a stream as an unbounded table.' || chr(10) || chr(10) || 'Output modes: Append (only new rows), Complete (full result table), Update (only changed rows).' || chr(10) || chr(10) || 'Trigger types: Default (process as fast as possible), Fixed interval, Once (process all available data once).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Spark Structured Streaming?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is a Spark executor and how does it relate to cores and memory?',
        'An executor is a JVM process on a worker node that runs tasks and stores data for a Spark application.' || chr(10) || chr(10) || 'Cores: Number of tasks an executor can run in parallel. More cores = more parallelism.' || chr(10) || chr(10) || 'Memory: Split into execution memory (shuffles, joins, aggregations) and storage memory (caching). Unified memory management in Spark 1.6+.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Spark executor and how does it relate to cores and memory?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is predicate pushdown in Spark?',
        'Predicate pushdown moves filter conditions as close to the data source as possible, reducing the amount of data read.' || chr(10) || chr(10) || 'Example: Instead of reading all rows and then filtering, push the WHERE clause into the Parquet/JDBC reader.' || chr(10) || chr(10) || 'Automatic in Spark with Parquet, ORC, JDBC sources. Verify with df.explain() - look for PushedFilters.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is predicate pushdown in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between narrow and wide transformations in Spark?',
        'Narrow transformation: Each input partition contributes to only one output partition. No shuffle required. Examples: filter, select, map, union.' || chr(10) || chr(10) || 'Wide transformation: Input partitions contribute to multiple output partitions. Requires shuffle. Examples: groupBy, join, distinct, repartition.' || chr(10) || chr(10) || 'Wide transformations create stage boundaries in the DAG.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between narrow and wide transformations in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Spark''s driver program and what does it do?',
        'The driver is the main program that runs the user''s Spark application and coordinates all executors.' || chr(10) || chr(10) || 'Responsibilities: Creates SparkContext/SparkSession, builds the DAG of transformations, schedules tasks on executors, collects results.' || chr(10) || chr(10) || 'Critical: Driver must stay alive for the entire job. OOM on driver = job failure. Avoid collect() on large datasets.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Spark''s driver program and what does it do?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Delta Live Tables (DLT)?',
        'Delta Live Tables is a declarative ETL framework in Databricks that automatically manages pipeline dependencies, data quality, and infrastructure.' || chr(10) || chr(10) || 'Key features: Declare tables with @dlt.table decorator, built-in data quality expectations, automatic dependency resolution, incremental processing.' || chr(10) || chr(10) || 'Simplifies building reliable data pipelines without manual orchestration.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Delta Live Tables (DLT)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Spark''s checkpointing and when should you use it?',
        'Checkpointing saves the current state of an RDD/DataFrame to reliable storage (HDFS/S3), breaking the lineage chain.' || chr(10) || chr(10) || 'When to use: Very long lineage chains (prevents stack overflow), iterative algorithms (ML), Structured Streaming (fault tolerance).' || chr(10) || chr(10) || 'Types: Reliable checkpointing (saves to disk), Local checkpointing (saves to executor memory/disk, faster but not fault-tolerant).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Spark''s checkpointing and when should you use it?');

    -- ── System Design Flashcards (86–100) ──────────────────────────────────────
    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'How would you design a real-time analytics dashboard?',
        'Architecture: Data sources -> Kafka (event streaming) -> Flink/Spark Streaming (aggregations) -> Redis/Druid (low-latency store) -> API -> Dashboard.' || chr(10) || chr(10) || 'Key decisions: Pre-aggregate metrics (avoid real-time full scans), use time-series DB for metrics, WebSocket for live updates.' || chr(10) || chr(10) || 'SLA: Sub-second query latency, 99.9% uptime.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How would you design a real-time analytics dashboard?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'How would you design a data pipeline for 1 billion events per day?',
        'Ingestion: Kafka (partitioned by event type/user_id) -> Spark Structured Streaming or Flink.' || chr(10) || chr(10) || 'Storage: Raw events in S3 (Parquet, partitioned by date/hour) -> Delta Lake for processed data.' || chr(10) || chr(10) || 'Scale: 1B events/day = ~11,500 events/sec. Kafka: 100 partitions x 115 events/sec/partition. Spark: 50 executors x 4 cores.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How would you design a data pipeline for 1 billion events per day?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is horizontal vs vertical scaling?',
        'Vertical scaling (scale up): Add more CPU/RAM/storage to a single machine. Simple but has hardware limits and single point of failure.' || chr(10) || chr(10) || 'Horizontal scaling (scale out): Add more machines to distribute load. More complex but theoretically unlimited, fault-tolerant.' || chr(10) || chr(10) || 'Distributed systems (Kafka, Spark, Cassandra) are designed for horizontal scaling.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is horizontal vs vertical scaling?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a rate limiter and how would you implement one?',
        'A rate limiter controls how many requests a client can make in a given time window to prevent abuse and ensure fair usage.' || chr(10) || chr(10) || 'Algorithms: Token bucket (smooth bursts), Leaky bucket (constant rate), Fixed window counter (simple), Sliding window log (accurate).' || chr(10) || chr(10) || 'Implementation: Redis INCR + EXPIRE for distributed rate limiting across multiple servers.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a rate limiter and how would you implement one?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is consistent hashing and why is it used?',
        'Consistent hashing maps both data and servers to the same hash ring, so adding/removing a server only remaps a fraction of keys.' || chr(10) || chr(10) || 'Problem it solves: Traditional modulo hashing (key % N) remaps almost all keys when N changes.' || chr(10) || chr(10) || 'Used in: Cassandra, DynamoDB, Memcached, load balancers. Virtual nodes improve load distribution.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is consistent hashing and why is it used?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a message queue vs a pub/sub system?',
        'Message Queue: Point-to-point. One producer, one consumer. Message deleted after consumption. Examples: RabbitMQ, SQS.' || chr(10) || chr(10) || 'Pub/Sub: One producer, multiple subscribers. Each subscriber gets a copy. Message retained for configured period. Examples: Kafka, Google Pub/Sub.' || chr(10) || chr(10) || 'Use queue for task distribution; pub/sub for event broadcasting.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a message queue vs a pub/sub system?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a circuit breaker pattern?',
        'A circuit breaker prevents cascading failures by stopping requests to a failing service and allowing it time to recover.' || chr(10) || chr(10) || 'States: Closed (normal, requests pass through), Open (failure threshold exceeded, requests fail fast), Half-Open (test if service recovered).' || chr(10) || chr(10) || 'Libraries: Hystrix (Java), Resilience4j, Polly (.NET).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a circuit breaker pattern?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'How would you design a feature store for ML?',
        'A feature store is a centralized repository for storing, sharing, and serving ML features.' || chr(10) || chr(10) || 'Architecture: Offline store (S3/Delta Lake for training, batch features) + Online store (Redis/DynamoDB for low-latency serving).' || chr(10) || chr(10) || 'Key requirements: Feature consistency between training and serving, point-in-time correct joins, feature versioning. Tools: Feast, Tecton, Databricks Feature Store.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How would you design a feature store for ML?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is the two-phase commit (2PC) protocol?',
        'Two-phase commit is a distributed transaction protocol that ensures all participants either commit or rollback together.' || chr(10) || chr(10) || 'Phase 1 (Prepare): Coordinator asks all participants if they can commit. Each votes yes/no.' || chr(10) || chr(10) || 'Phase 2 (Commit/Abort): If all voted yes, coordinator sends commit. If any voted no, coordinator sends abort.' || chr(10) || chr(10) || 'Problem: Blocking if coordinator fails after prepare.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the two-phase commit (2PC) protocol?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a SAGA pattern in distributed systems?',
        'SAGA is a pattern for managing distributed transactions by breaking them into a sequence of local transactions, each with a compensating transaction for rollback.' || chr(10) || chr(10) || 'Types: Choreography (each service publishes events, no central coordinator) vs Orchestration (central saga orchestrator directs services).' || chr(10) || chr(10) || 'Use case: Microservices where 2PC is too slow or unavailable.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a SAGA pattern in distributed systems?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a bloom filter and when would you use it in data engineering?',
        'A bloom filter is a probabilistic data structure that tests whether an element is in a set. May have false positives, never false negatives.' || chr(10) || chr(10) || 'Data engineering uses: Spark join optimization (skip shuffle if key not in small table), Delta Lake (skip files that cannot contain a key), Cassandra (avoid disk reads for missing keys).' || chr(10) || chr(10) || 'Space-efficient: Uses bits instead of storing actual values.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a bloom filter and when would you use it in data engineering?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'How would you handle late-arriving data in a data warehouse?',
        'Strategies: Reprocessing (rerun the pipeline for the affected partition - simple but expensive), Incremental updates (MERGE/UPSERT late records into the target table), Lambda architecture (batch layer corrects speed layer results).' || chr(10) || chr(10) || 'Best practice: Partition by event_date, use MERGE to upsert late records. Set SLA for how late data is accepted.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How would you handle late-arriving data in a data warehouse?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a write-ahead log (WAL)?',
        'A WAL is a log where all changes are written before being applied to the actual data files, ensuring durability and crash recovery.' || chr(10) || chr(10) || 'How it works: Write change to WAL first -> acknowledge to client -> apply change to data files asynchronously.' || chr(10) || chr(10) || 'Used in: PostgreSQL (WAL), Delta Lake (_delta_log), Kafka (commit log). Enables CDC and point-in-time recovery.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a write-ahead log (WAL)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is the difference between synchronous and asynchronous processing?',
        'Synchronous: Caller waits for the operation to complete before continuing. Simple, predictable, but blocks the caller.' || chr(10) || chr(10) || 'Asynchronous: Caller submits work and continues without waiting. Higher throughput, non-blocking, but more complex error handling.' || chr(10) || chr(10) || 'Data engineering: Async is preferred for I/O-bound operations (API calls, DB writes) to maximize throughput.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between synchronous and asynchronous processing?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is observability in data pipelines?',
        'Observability is the ability to understand the internal state of a system from its external outputs (logs, metrics, traces).' || chr(10) || chr(10) || 'Three pillars: Logs (what happened), Metrics (how much/how fast), Traces (where time was spent).' || chr(10) || chr(10) || 'Data pipeline specific: Row counts, null rates, schema drift alerts, SLA breach notifications, data freshness monitoring. Tools: Great Expectations, Monte Carlo, dbt tests.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is observability in data pipelines?');

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Flashcard seed failed: %', SQLERRM;
END $$;
