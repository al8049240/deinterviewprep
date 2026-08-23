-- Migration: Seed 60 additional flashcards (v3) into de_mobile_app.flashcards
-- Timestamp: 20260822000000
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
    v_sql_topic_id       := COALESCE(v_sql_topic_id, v_fallback_topic_id);
    v_arch_topic_id      := COALESCE(v_arch_topic_id, v_fallback_topic_id);
    v_orch_topic_id      := COALESCE(v_orch_topic_id, v_fallback_topic_id);
    v_cloud_topic_id     := COALESCE(v_cloud_topic_id, v_fallback_topic_id);
    v_spark_topic_id     := COALESCE(v_spark_topic_id, v_fallback_topic_id);
    v_sysdesign_topic_id := COALESCE(v_sysdesign_topic_id, v_fallback_topic_id);

    -- Fetch subtopic IDs
    SELECT id INTO v_sql_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_sql_topic_id LIMIT 1;
    SELECT id INTO v_arch_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_arch_topic_id LIMIT 1;
    SELECT id INTO v_orch_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_orch_topic_id LIMIT 1;
    SELECT id INTO v_cloud_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_cloud_topic_id LIMIT 1;
    SELECT id INTO v_spark_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_spark_topic_id LIMIT 1;
    SELECT id INTO v_sysdesign_sub_id FROM "de_mobile_app"."subtopics-legacy" WHERE topic_id = v_sysdesign_topic_id LIMIT 1;

    -- Apply subtopic fallbacks
    v_sql_sub_id       := COALESCE(v_sql_sub_id, v_fallback_sub_id);
    v_arch_sub_id      := COALESCE(v_arch_sub_id, v_fallback_sub_id);
    v_orch_sub_id      := COALESCE(v_orch_sub_id, v_fallback_sub_id);
    v_cloud_sub_id     := COALESCE(v_cloud_sub_id, v_fallback_sub_id);
    v_spark_sub_id     := COALESCE(v_spark_sub_id, v_fallback_sub_id);
    v_sysdesign_sub_id := COALESCE(v_sysdesign_sub_id, v_fallback_sub_id);

    -- ── SQL Advanced Flashcards (1–15) ────────────────────────────────────────

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a lateral join and when do you use it?',
        'A LATERAL join allows a subquery to reference columns from preceding tables in the FROM clause — like a correlated subquery but in the FROM position.' || chr(10) || chr(10) || 'Use case: Unnesting arrays (LATERAL FLATTEN in Snowflake), getting top-N rows per group, or applying a function to each row.' || chr(10) || chr(10) || 'Example: SELECT u.id, top_orders.amount FROM users u, LATERAL (SELECT amount FROM orders WHERE user_id = u.id ORDER BY amount DESC LIMIT 3) top_orders'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a lateral join and when do you use it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between NTILE, PERCENT_RANK, and CUME_DIST?',
        'NTILE(n): Divides rows into n equal buckets. E.g., NTILE(4) creates quartiles (1, 2, 3, 4).' || chr(10) || chr(10) || 'PERCENT_RANK(): Relative rank as a percentage. Formula: (rank - 1) / (total rows - 1). Range: 0 to 1.' || chr(10) || chr(10) || 'CUME_DIST(): Cumulative distribution. Fraction of rows <= current row. Range: 0 to 1.' || chr(10) || chr(10) || 'Use NTILE for bucketing, PERCENT_RANK/CUME_DIST for percentile analysis.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between NTILE, PERCENT_RANK, and CUME_DIST?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'How do you calculate a 7-day rolling average in SQL?',
        'Use a window function with ROWS BETWEEN 6 PRECEDING AND CURRENT ROW:' || chr(10) || chr(10) || 'SELECT date, revenue,' || chr(10) || '  AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7d_avg' || chr(10) || 'FROM daily_sales' || chr(10) || chr(10) || 'Key: ROWS BETWEEN is physical row count; RANGE BETWEEN is value-based. Use ROWS for rolling windows.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How do you calculate a 7-day rolling average in SQL?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between LAG and LEAD window functions?',
        'LAG(col, n): Returns the value of col from n rows BEFORE the current row. Used to compare current vs previous.' || chr(10) || chr(10) || 'LEAD(col, n): Returns the value of col from n rows AFTER the current row. Used to compare current vs next.' || chr(10) || chr(10) || 'Example: LAG(revenue, 1) OVER (ORDER BY date) gives yesterday''s revenue for day-over-day comparison.' || chr(10) || chr(10) || 'Both accept a default value as 3rd argument for NULL handling.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between LAG and LEAD window functions?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a PIVOT operation in SQL and how do you implement it?',
        'PIVOT transforms rows into columns — turning category values into column headers with aggregated values.' || chr(10) || chr(10) || 'Snowflake/SQL Server: PIVOT(SUM(amount) FOR category IN (''A'', ''B'', ''C''))' || chr(10) || chr(10) || 'Standard SQL (CASE WHEN): SELECT id, SUM(CASE WHEN cat=''A'' THEN val END) AS A, SUM(CASE WHEN cat=''B'' THEN val END) AS B FROM t GROUP BY id' || chr(10) || chr(10) || 'Use CASE WHEN approach for portability across databases.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a PIVOT operation in SQL and how do you implement it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a surrogate key vs a natural key?',
        'Natural Key: A real-world identifier that exists in the data (e.g., email, SSN, order_number). May change over time.' || chr(10) || chr(10) || 'Surrogate Key: A system-generated identifier with no business meaning (e.g., auto-increment ID, UUID). Never changes.' || chr(10) || chr(10) || 'Best practice: Use surrogate keys as primary keys in data warehouses. Natural keys as unique constraints for deduplication.' || chr(10) || chr(10) || 'SCD Type 2 requires surrogate keys to track multiple versions of the same entity.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a surrogate key vs a natural key?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a MERGE (UPSERT) statement in SQL?',
        'MERGE combines INSERT, UPDATE, and DELETE in a single statement based on a matching condition.' || chr(10) || chr(10) || 'Syntax: MERGE INTO target USING source ON (target.id = source.id)' || chr(10) || 'WHEN MATCHED THEN UPDATE SET ...' || chr(10) || 'WHEN NOT MATCHED THEN INSERT ...' || chr(10) || 'WHEN NOT MATCHED BY SOURCE THEN DELETE' || chr(10) || chr(10) || 'Use case: Incremental loads — update existing rows, insert new ones, delete removed ones.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a MERGE (UPSERT) statement in SQL?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is BigQuery partitioning vs clustering?',
        'Partitioning: Divides a table into segments by a date/timestamp column or integer range. Queries that filter on the partition column only scan matching partitions.' || chr(10) || chr(10) || 'Clustering: Sorts data within each partition by up to 4 columns. Enables block pruning for equality/range filters on clustered columns.' || chr(10) || chr(10) || 'Best practice: Partition by date, cluster by frequently filtered dimensions (e.g., user_id, country). Reduces bytes billed significantly.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is BigQuery partitioning vs clustering?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between TRUNCATE and DELETE in SQL?',
        'DELETE: Removes rows one at a time, logs each deletion, can use WHERE clause, can be rolled back. Slower for large tables.' || chr(10) || chr(10) || 'TRUNCATE: Removes all rows at once by deallocating data pages, minimal logging, cannot use WHERE, faster.' || chr(10) || chr(10) || 'Key difference: DELETE fires row-level triggers; TRUNCATE does not. TRUNCATE resets identity/sequence counters.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between TRUNCATE and DELETE in SQL?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a Fact Table vs a Dimension Table?',
        'Fact Table: Contains measurable, quantitative data (metrics/events). Has foreign keys to dimension tables. Examples: sales_fact, events_fact. Rows represent transactions.' || chr(10) || chr(10) || 'Dimension Table: Contains descriptive attributes about entities. Examples: customer_dim, product_dim, date_dim.' || chr(10) || chr(10) || 'Fact tables are tall and narrow (many rows, few columns). Dimension tables are short and wide (few rows, many columns).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Fact Table vs a Dimension Table?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a degenerate dimension?',
        'A degenerate dimension is a dimension key that exists in the fact table but has no corresponding dimension table because it has no additional attributes.' || chr(10) || chr(10) || 'Examples: Order number, invoice number, ticket number.' || chr(10) || chr(10) || 'These are stored directly in the fact table as they are useful for filtering/grouping but do not warrant a separate dimension table.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a degenerate dimension?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is Snowflake Time Travel and how long does it last?',
        'Time Travel allows you to query data as it existed at a specific point in the past using AT or BEFORE clauses.' || chr(10) || chr(10) || 'Syntax: SELECT * FROM orders AT (TIMESTAMP => ''2024-01-01 12:00:00''::TIMESTAMP)' || chr(10) || chr(10) || 'Duration: Standard edition = 1 day. Enterprise edition = up to 90 days.' || chr(10) || chr(10) || 'Use cases: Recover accidentally deleted data, audit historical changes, reproduce past query results.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Snowflake Time Travel and how long does it last?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is a junk dimension in data warehousing?',
        'A junk dimension combines multiple low-cardinality flags and indicators into a single dimension table to avoid cluttering the fact table.' || chr(10) || chr(10) || 'Example: Instead of 5 boolean columns (is_promo, is_return, is_gift, is_online, is_rush) in the fact table, create one junk_dim with all combinations.' || chr(10) || chr(10) || 'Benefit: Reduces fact table width, organizes miscellaneous attributes cleanly.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a junk dimension in data warehousing?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is the difference between CROSS JOIN and SELF JOIN?',
        'CROSS JOIN: Returns the Cartesian product of two tables — every row from table A paired with every row from table B. N x M rows total. No join condition.' || chr(10) || chr(10) || 'SELF JOIN: A table joined to itself using an alias. Used to compare rows within the same table.' || chr(10) || chr(10) || 'Self JOIN example: Finding employees and their managers from the same employees table: SELECT e.name, m.name AS manager FROM employees e JOIN employees m ON e.manager_id = m.id'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between CROSS JOIN and SELF JOIN?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sql_topic_id, v_sql_sub_id,
        'What is Redshift Spectrum and when do you use it?',
        'Redshift Spectrum allows you to query data directly in S3 (Parquet, ORC, CSV) without loading it into Redshift.' || chr(10) || chr(10) || 'Use cases: Querying cold/archival data, joining S3 data with Redshift tables, cost-effective analytics on infrequently accessed data.' || chr(10) || chr(10) || 'Pricing: Pay per TB scanned. Use columnar formats (Parquet) and partitioning to minimize scan costs.' || chr(10) || chr(10) || 'Requires an external schema pointing to a Glue/Hive metastore.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Redshift Spectrum and when do you use it?');

    -- ── PySpark Flashcards (16–30) ────────────────────────────────────────────

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between a Spark RDD, DataFrame, and Dataset?',
        'RDD (Resilient Distributed Dataset): Low-level, untyped, functional API. No query optimization. Use for unstructured data or custom transformations.' || chr(10) || chr(10) || 'DataFrame: Distributed table with named columns. Uses Catalyst optimizer and Tungsten execution engine. Best performance for structured data.' || chr(10) || chr(10) || 'Dataset: Typed DataFrame (Scala/Java only). Compile-time type safety + Catalyst optimization. Not available in PySpark (Python uses DataFrame).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between a Spark RDD, DataFrame, and Dataset?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is lazy evaluation in Spark?',
        'Spark does not execute transformations immediately. It builds a DAG (Directed Acyclic Graph) of operations and only executes when an action is called.' || chr(10) || chr(10) || 'Transformations (lazy): filter(), select(), groupBy(), join(), withColumn()' || chr(10) || 'Actions (trigger execution): show(), count(), collect(), write(), take()' || chr(10) || chr(10) || 'Benefit: Spark can optimize the entire pipeline before executing, combining steps and eliminating unnecessary work.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is lazy evaluation in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is a Spark shuffle and why is it expensive?',
        'A shuffle occurs when Spark needs to redistribute data across partitions — typically during groupBy, join, distinct, or repartition operations.' || chr(10) || chr(10) || 'Why expensive: Data is serialized, written to disk, transferred over the network, and deserialized on the receiving executor.' || chr(10) || chr(10) || 'How to minimize: Use broadcast joins for small tables, pre-partition data on join keys, avoid unnecessary distinct/groupBy, use reduceByKey instead of groupByKey in RDDs.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Spark shuffle and why is it expensive?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is data skew in Spark and how do you fix it?',
        'Data skew occurs when some partitions have significantly more data than others, causing a few tasks to run much longer (straggler tasks).' || chr(10) || chr(10) || 'Symptoms: Most tasks finish in 2s, but 2-3 tasks take 10+ minutes.' || chr(10) || chr(10) || 'Fixes:' || chr(10) || '1. Salting: Add a random prefix to skewed keys to distribute load.' || chr(10) || '2. Broadcast join: If one side is small, broadcast it.' || chr(10) || '3. Repartition: repartition(n) to redistribute data.' || chr(10) || '4. AQE (Adaptive Query Execution): Spark 3.0+ automatically handles skew.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data skew in Spark and how do you fix it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between cache() and persist() in Spark?',
        'cache(): Stores the DataFrame in memory (MEMORY_AND_DISK storage level). Shortcut for persist(StorageLevel.MEMORY_AND_DISK).' || chr(10) || chr(10) || 'persist(level): Allows you to specify the storage level:' || chr(10) || '- MEMORY_ONLY: Fastest, but spills if memory is full' || chr(10) || '- MEMORY_AND_DISK: Spills to disk if memory is full (default for cache())' || chr(10) || '- DISK_ONLY: Slowest, but handles very large datasets' || chr(10) || chr(10) || 'Use when: A DataFrame is used multiple times in the same job. Call unpersist() when done.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between cache() and persist() in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Adaptive Query Execution (AQE) in Spark 3.0?',
        'AQE dynamically optimizes query plans at runtime based on actual data statistics collected during execution.' || chr(10) || chr(10) || 'Three key features:' || chr(10) || '1. Dynamic coalescing of shuffle partitions: Merges small partitions after shuffle to reduce overhead.' || chr(10) || '2. Dynamic switching of join strategies: Converts sort-merge join to broadcast join if one side turns out small.' || chr(10) || '3. Dynamic skew join optimization: Splits skewed partitions automatically.' || chr(10) || chr(10) || 'Enable: spark.sql.adaptive.enabled = true (default in Spark 3.2+)'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Adaptive Query Execution (AQE) in Spark 3.0?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between repartition() and coalesce() in Spark?',
        'repartition(n): Creates exactly n partitions by performing a full shuffle. Can increase or decrease partition count. Use when you need evenly distributed partitions.' || chr(10) || chr(10) || 'coalesce(n): Reduces partitions WITHOUT a full shuffle by merging existing partitions. More efficient for reducing partitions.' || chr(10) || chr(10) || 'Rule of thumb: Use coalesce() to reduce partitions (e.g., before writing). Use repartition() to increase partitions or rebalance skewed data.' || chr(10) || chr(10) || 'Optimal partition size: 128MB-256MB per partition.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between repartition() and coalesce() in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is a Spark UDF and what are its performance implications?',
        'A UDF (User Defined Function) is a custom Python/Scala function registered with Spark to be used in DataFrame operations.' || chr(10) || chr(10) || 'Performance issue: Python UDFs break the JVM execution pipeline — data is serialized from JVM to Python, processed row-by-row, then serialized back. Very slow.' || chr(10) || chr(10) || 'Better alternatives:' || chr(10) || '1. Use built-in Spark SQL functions (fastest — stay in JVM)' || chr(10) || '2. Pandas UDFs (vectorized UDFs) — process data in batches using Arrow, 10-100x faster than row UDFs' || chr(10) || '3. Scala UDFs — stay in JVM, no serialization overhead'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Spark UDF and what are its performance implications?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Spark Structured Streaming?',
        'Structured Streaming is Spark''s stream processing engine built on the DataFrame/Dataset API. It treats a stream as an unbounded table that grows continuously.' || chr(10) || chr(10) || 'Key concepts:' || chr(10) || '- Trigger: How often to process (processingTime, once, continuous)' || chr(10) || '- Output modes: append (new rows only), complete (full result), update (changed rows)' || chr(10) || '- Watermarking: Handles late-arriving data by defining a time threshold' || chr(10) || chr(10) || 'Sources: Kafka, files, sockets. Sinks: Kafka, Delta Lake, files, console.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Spark Structured Streaming?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the Catalyst Optimizer in Spark?',
        'Catalyst is Spark''s query optimization framework that transforms logical query plans into optimized physical execution plans.' || chr(10) || chr(10) || 'Optimization steps:' || chr(10) || '1. Analysis: Resolves column names and types' || chr(10) || '2. Logical optimization: Predicate pushdown, constant folding, column pruning' || chr(10) || '3. Physical planning: Selects join strategies (broadcast vs sort-merge)' || chr(10) || '4. Code generation: Generates optimized JVM bytecode via Tungsten' || chr(10) || chr(10) || 'Why it matters: Catalyst is why DataFrames are faster than RDDs.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the Catalyst Optimizer in Spark?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Delta Lake and what problems does it solve?',
        'Delta Lake is an open-source storage layer that adds ACID transactions, schema enforcement, and time travel to data lakes (S3, ADLS, GCS).' || chr(10) || chr(10) || 'Problems it solves:' || chr(10) || '- No ACID: Multiple writers corrupt data -> Delta uses optimistic concurrency control' || chr(10) || '- No schema enforcement: Bad data silently enters -> Delta enforces schema on write' || chr(10) || '- No time travel: Cannot query historical data -> Delta transaction log enables versioning' || chr(10) || '- Slow reads: Small files problem -> OPTIMIZE command compacts files'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Delta Lake and what problems does it solve?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the small files problem in Spark and how do you fix it?',
        'When Spark writes data with many partitions, it creates many small files (e.g., 10,000 x 1MB files instead of 100 x 100MB files).' || chr(10) || chr(10) || 'Problems: Slow reads (metadata overhead), high S3/HDFS API costs, slow Spark job startup.' || chr(10) || chr(10) || 'Fixes:' || chr(10) || '1. coalesce(n) before writing to reduce output files' || chr(10) || '2. Delta Lake OPTIMIZE command: Compacts small files into 1GB target files' || chr(10) || '3. Set spark.sql.files.maxPartitionBytes = 128MB' || chr(10) || '4. Use Auto Optimize in Databricks (optimizeWrite + autoCompact)'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the small files problem in Spark and how do you fix it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is Z-Ordering in Delta Lake?',
        'Z-Ordering is a multi-dimensional clustering technique that co-locates related data in the same set of files to improve query performance.' || chr(10) || chr(10) || 'Command: OPTIMIZE events ZORDER BY (user_id, event_date)' || chr(10) || chr(10) || 'How it works: Sorts data using a Z-curve (space-filling curve) so that rows with similar values on multiple columns end up in the same files.' || chr(10) || chr(10) || 'Result: Queries filtering on Z-ordered columns skip more files (data skipping). Best for high-cardinality columns used in WHERE clauses.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Z-Ordering in Delta Lake?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is the difference between Parquet, ORC, and Avro file formats?',
        'Parquet: Columnar format. Best for analytical queries (SELECT few columns from wide tables). Excellent compression. Default for Spark/Delta Lake.' || chr(10) || chr(10) || 'ORC: Columnar format. Similar to Parquet but optimized for Hive. Better predicate pushdown in Hive ecosystem.' || chr(10) || chr(10) || 'Avro: Row-based format. Best for streaming/write-heavy workloads and schema evolution. Used as Kafka message format.' || chr(10) || chr(10) || 'Rule: Parquet for analytics, Avro for streaming ingestion, ORC for Hive-heavy environments.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between Parquet, ORC, and Avro file formats?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_spark_topic_id, v_spark_sub_id,
        'What is a Spark DAG and how does it relate to stages and tasks?',
        'DAG (Directed Acyclic Graph): Spark''s representation of the sequence of computations. Each node is an RDD/DataFrame, each edge is a transformation.' || chr(10) || chr(10) || 'Stage: A set of transformations that can run without a shuffle. Stages are separated by shuffle boundaries (wide transformations).' || chr(10) || chr(10) || 'Task: The smallest unit of work. One task processes one partition. If a stage has 200 partitions, it has 200 tasks.' || chr(10) || chr(10) || 'Job -> Stages -> Tasks. View in Spark UI under the DAG Visualization tab.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Spark DAG and how does it relate to stages and tasks?');

    -- ── Kafka / Orchestration Flashcards (31–45) ─────────────────────────────

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Apache Kafka and what problem does it solve?',
        'Kafka is a distributed event streaming platform designed for high-throughput, fault-tolerant, real-time data pipelines.' || chr(10) || chr(10) || 'Problem it solves: Point-to-point integrations between N producers and M consumers create N*M connections. Kafka acts as a central hub — producers write to topics, consumers read independently at their own pace.' || chr(10) || chr(10) || 'Key properties: Durable (messages persisted to disk), scalable (partitioned), replayable (consumers can re-read from any offset).'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Kafka and what problem does it solve?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is a Kafka topic, partition, and offset?',
        'Topic: A named category/feed to which messages are published. Like a database table for events.' || chr(10) || chr(10) || 'Partition: A topic is split into N ordered, immutable logs. Enables parallelism — each partition can be consumed by one consumer in a group.' || chr(10) || chr(10) || 'Offset: The sequential position of a message within a partition. Consumers track their offset to know where they left off.' || chr(10) || chr(10) || 'Key insight: More partitions = more parallelism, but also more overhead. Rule of thumb: partitions = max expected consumers.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Kafka topic, partition, and offset?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is a Kafka Consumer Group?',
        'A consumer group is a set of consumers that jointly consume a topic. Each partition is assigned to exactly one consumer in the group.' || chr(10) || chr(10) || 'Scaling: Add consumers to a group to increase throughput (up to the number of partitions). Extra consumers beyond partition count are idle.' || chr(10) || chr(10) || 'Multiple groups: Different consumer groups each get their own copy of all messages — enabling fan-out to multiple downstream systems independently.' || chr(10) || chr(10) || 'Rebalancing: When a consumer joins/leaves, partitions are reassigned across the group.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a Kafka Consumer Group?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Kafka exactly-once semantics (EOS)?',
        'Exactly-once semantics ensures each message is processed exactly once — no duplicates, no data loss.' || chr(10) || chr(10) || 'Three delivery guarantees:' || chr(10) || '- At-most-once: Messages may be lost, never duplicated. Fast.' || chr(10) || '- At-least-once: Messages never lost, may be duplicated. Most common.' || chr(10) || '- Exactly-once: No loss, no duplicates. Requires idempotent producers + transactional API.' || chr(10) || chr(10) || 'Enable: enable.idempotence=true + transactional.id on producer. Kafka Streams and Flink support EOS natively.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Kafka exactly-once semantics (EOS)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is the role of Zookeeper in Kafka and why is it being removed?',
        'Zookeeper: Manages Kafka broker metadata — leader election, topic configs, consumer group offsets (older versions), cluster membership.' || chr(10) || chr(10) || 'Problems: Separate system to manage, operational complexity, limits Kafka scalability to ~200K partitions.' || chr(10) || chr(10) || 'KRaft (Kafka Raft): Kafka 3.3+ replaces Zookeeper with a built-in Raft consensus protocol. Kafka manages its own metadata.' || chr(10) || chr(10) || 'Benefits of KRaft: Simpler operations, supports millions of partitions, faster controller failover.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the role of Zookeeper in Kafka and why is it being removed?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Apache Airflow and what is a DAG in Airflow?',
        'Airflow is a workflow orchestration platform for scheduling, monitoring, and managing data pipelines.' || chr(10) || chr(10) || 'DAG (Directed Acyclic Graph): A Python file defining a workflow as a graph of tasks with dependencies. No cycles allowed.' || chr(10) || chr(10) || 'Key components:' || chr(10) || '- Scheduler: Triggers DAGs based on schedule or external events' || chr(10) || '- Executor: Runs tasks (LocalExecutor, CeleryExecutor, KubernetesExecutor)' || chr(10) || '- Metadata DB: Stores DAG state, task history' || chr(10) || '- Web UI: Monitor and manage DAG runs'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Airflow and what is a DAG in Airflow?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is the difference between Airflow Operators, Sensors, and Hooks?',
        'Operator: Defines a single task in a DAG. Examples: PythonOperator, BashOperator, SparkSubmitOperator, BigQueryOperator.' || chr(10) || chr(10) || 'Sensor: A special operator that waits for a condition to be true before proceeding. Examples: S3KeySensor (waits for file), ExternalTaskSensor (waits for another DAG).' || chr(10) || chr(10) || 'Hook: A connection interface to external systems (databases, APIs, cloud services). Operators use Hooks internally. Examples: PostgresHook, S3Hook, HttpHook.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between Airflow Operators, Sensors, and Hooks?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Airflow backfill and how does it work?',
        'Backfill re-runs a DAG for historical dates that were missed or need to be reprocessed.' || chr(10) || chr(10) || 'Command: airflow dags backfill -s 2024-01-01 -e 2024-01-31 my_dag_id' || chr(10) || chr(10) || 'Key concept: Airflow uses execution_date (the logical date of the run, not when it actually ran). Backfill creates DAG runs for each scheduled interval in the date range.' || chr(10) || chr(10) || 'Idempotency: Tasks should be idempotent (same result if run multiple times) to safely support backfill.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Airflow backfill and how does it work?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is the difference between Airflow CeleryExecutor and KubernetesExecutor?',
        'CeleryExecutor: Uses a Celery worker pool + message broker (Redis/RabbitMQ). Workers are always running. Fast task startup. Good for high-frequency, short tasks.' || chr(10) || chr(10) || 'KubernetesExecutor: Spins up a new Kubernetes pod for each task. Zero idle workers. Perfect isolation. Slower startup (~30s). Good for resource-intensive, long-running tasks.' || chr(10) || chr(10) || 'CeleryKubernetesExecutor: Hybrid — uses Celery for lightweight tasks, Kubernetes for heavy tasks.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between Airflow CeleryExecutor and KubernetesExecutor?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is Apache Flink and how does it differ from Spark Streaming?',
        'Flink: True stream-first processing engine. Processes events one at a time with sub-millisecond latency. Native support for event time, watermarks, and stateful processing.' || chr(10) || chr(10) || 'Spark Structured Streaming: Micro-batch by default (processes small batches every few seconds). Continuous mode available but less mature.' || chr(10) || chr(10) || 'Key difference: Flink is event-driven (true streaming); Spark Streaming is micro-batch (mini-batch processing).' || chr(10) || chr(10) || 'Use Flink for: fraud detection, real-time recommendations, sub-second latency requirements.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Flink and how does it differ from Spark Streaming?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is dbt (data build tool) and what problem does it solve?',
        'dbt is a transformation tool that allows data analysts and engineers to write SQL SELECT statements and dbt handles the CREATE TABLE/VIEW, dependency management, and testing.' || chr(10) || chr(10) || 'Problems it solves:' || chr(10) || '- No version control for SQL transformations' || chr(10) || '- No dependency management between models' || chr(10) || '- No automated testing for data quality' || chr(10) || '- No documentation for data lineage' || chr(10) || chr(10) || 'Key features: Models (SQL files), Tests (schema tests), Sources, Seeds, Macros (Jinja templating), Lineage graph.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is dbt (data build tool) and what problem does it solve?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is the difference between dbt run, dbt test, and dbt build?',
        'dbt run: Executes all models (SQL transformations) and creates/replaces tables/views in the warehouse.' || chr(10) || chr(10) || 'dbt test: Runs data quality tests defined in schema.yml (not_null, unique, accepted_values, relationships).' || chr(10) || chr(10) || 'dbt build: Runs models AND tests together in dependency order. If a model''s test fails, downstream models are skipped.' || chr(10) || chr(10) || 'Best practice: Use dbt build in production pipelines to ensure data quality before downstream models consume bad data.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between dbt run, dbt test, and dbt build?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is event time vs processing time in stream processing?',
        'Event time: When the event actually occurred (embedded in the event payload). More accurate for analytics.' || chr(10) || chr(10) || 'Processing time: When the event is processed by the streaming system. Simpler but affected by network delays and late arrivals.' || chr(10) || chr(10) || 'Late data problem: Events can arrive out of order due to network delays. Watermarks define how long to wait for late events before closing a time window.' || chr(10) || chr(10) || 'Example: A mobile app event with timestamp 10:00 may arrive at the server at 10:05 due to poor connectivity.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is event time vs processing time in stream processing?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is a dead letter queue (DLQ) in data pipelines?',
        'A DLQ is a separate queue/topic where messages that fail processing are sent instead of being dropped or blocking the main pipeline.' || chr(10) || chr(10) || 'Use cases: Malformed JSON, schema violations, downstream system unavailable, processing exceptions.' || chr(10) || chr(10) || 'Benefits: Pipeline continues processing valid messages; failed messages can be inspected, fixed, and replayed.' || chr(10) || chr(10) || 'Implementation: Kafka DLQ topic, SQS Dead Letter Queue, Airflow on_failure_callback routing to error handler.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a dead letter queue (DLQ) in data pipelines?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_orch_topic_id, v_orch_sub_id,
        'What is schema registry in Kafka and why is it important?',
        'A Schema Registry is a centralized service that stores and enforces Avro/Protobuf/JSON schemas for Kafka messages.' || chr(10) || chr(10) || 'Why important: Without it, producers can change message structure and silently break consumers.' || chr(10) || chr(10) || 'How it works: Producer registers schema -> gets schema ID -> serializes message with ID. Consumer fetches schema by ID -> deserializes correctly.' || chr(10) || chr(10) || 'Schema evolution: Supports backward, forward, and full compatibility modes. Prevents breaking changes from reaching consumers.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is schema registry in Kafka and why is it important?');

    -- ── Cloud Data Lakes / Architecture Flashcards (46–60) ───────────────────

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Apache Iceberg and how does it differ from Delta Lake?',
        'Both are open table formats adding ACID transactions to data lakes, but differ in ecosystem and features:' || chr(10) || chr(10) || 'Iceberg: Open standard, multi-engine (Spark, Flink, Trino, Hive, Dremio). Better hidden partitioning and partition evolution. Supported by AWS (Glue, Athena).' || chr(10) || chr(10) || 'Delta Lake: Tightly integrated with Databricks/Spark. Better Databricks-specific features (Auto Optimize, Photon). Simpler for Spark-only shops.' || chr(10) || chr(10) || 'Trend: Iceberg gaining adoption for multi-engine environments; Delta Lake dominant in Databricks shops.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Iceberg and how does it differ from Delta Lake?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is Apache Hudi and what are its write operations?',
        'Hudi (Hadoop Upserts Deletes and Incrementals) is an open table format optimized for incremental data processing and upserts on data lakes.' || chr(10) || chr(10) || 'Three write operations:' || chr(10) || '- UPSERT: Insert new records, update existing ones (most common)' || chr(10) || '- INSERT: Append-only, no deduplication' || chr(10) || '- BULK_INSERT: Fast initial load, no index lookup' || chr(10) || chr(10) || 'Two table types: Copy-on-Write (COW) for read-heavy; Merge-on-Read (MOR) for write-heavy with compaction.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is Apache Hudi and what are its write operations?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is the medallion architecture (Bronze, Silver, Gold)?',
        'A data lakehouse design pattern with three layers:' || chr(10) || chr(10) || 'Bronze (Raw): Exact copy of source data, no transformations. Append-only. Preserves full history for reprocessing.' || chr(10) || chr(10) || 'Silver (Cleaned): Deduplicated, validated, joined data. Conformed to standard schemas. Source of truth for most analytics.' || chr(10) || chr(10) || 'Gold (Aggregated): Business-level aggregations optimized for specific use cases (dashboards, ML features, reports). Highest quality, lowest latency.' || chr(10) || chr(10) || 'Also called: Multi-hop architecture.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the medallion architecture (Bronze, Silver, Gold)?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is AWS Glue and how does it fit in a data lake architecture?',
        'AWS Glue is a fully managed ETL service and data catalog on AWS.' || chr(10) || chr(10) || 'Key components:' || chr(10) || '- Glue Catalog: Central metadata repository (database/table definitions) used by Athena, Redshift Spectrum, EMR' || chr(10) || '- Glue Crawlers: Automatically scan S3 and infer schemas, populating the catalog' || chr(10) || '- Glue ETL Jobs: Serverless Spark jobs for transformations' || chr(10) || '- Glue DataBrew: Visual data preparation (no-code)' || chr(10) || chr(10) || 'Role: Acts as the metadata layer connecting S3 storage to query engines.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is AWS Glue and how does it fit in a data lake architecture?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is the difference between S3 Standard, S3-IA, and S3 Glacier?',
        'S3 Standard: Frequently accessed data. High availability (99.99%), low latency. Most expensive per GB.' || chr(10) || chr(10) || 'S3 Standard-IA (Infrequent Access): Lower storage cost, higher retrieval cost. Use for data accessed monthly. Same durability as Standard.' || chr(10) || chr(10) || 'S3 Glacier: Archival storage. Very low cost. Retrieval takes minutes to hours. Use for compliance data, old backups.' || chr(10) || chr(10) || 'Data engineering tip: Use S3 Lifecycle policies to automatically move data from Standard -> IA -> Glacier as it ages.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between S3 Standard, S3-IA, and S3 Glacier?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is data lineage and why does it matter?',
        'Data lineage tracks the origin, movement, and transformation of data throughout its lifecycle — from source systems to final reports.' || chr(10) || chr(10) || 'Why it matters:' || chr(10) || '- Debugging: Trace where bad data entered the pipeline' || chr(10) || '- Impact analysis: Understand what breaks if a source table changes' || chr(10) || '- Compliance: Prove to auditors where sensitive data came from and how it was processed' || chr(10) || '- Trust: Data consumers can verify data quality and freshness' || chr(10) || chr(10) || 'Tools: dbt lineage graph, Apache Atlas, OpenLineage, DataHub, Alation.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data lineage and why does it matter?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is a data catalog and what are its key features?',
        'A data catalog is a centralized inventory of all data assets in an organization, with metadata, lineage, and search capabilities.' || chr(10) || chr(10) || 'Key features:' || chr(10) || '- Discovery: Search for datasets by name, tag, or description' || chr(10) || '- Schema metadata: Column names, types, descriptions' || chr(10) || '- Lineage: Where data came from and where it flows' || chr(10) || '- Data quality metrics: Freshness, completeness, accuracy scores' || chr(10) || '- Access control: Who can see/use which datasets' || chr(10) || chr(10) || 'Tools: AWS Glue Catalog, Databricks Unity Catalog, DataHub, Alation, Collibra.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a data catalog and what are its key features?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is idempotency in data pipelines and why is it critical?',
        'An idempotent operation produces the same result whether run once or multiple times.' || chr(10) || chr(10) || 'Why critical: Pipelines fail and need to be retried. Without idempotency, retries cause duplicate data.' || chr(10) || chr(10) || 'How to implement:' || chr(10) || '- Use MERGE/UPSERT instead of INSERT' || chr(10) || '- Partition overwrite: Overwrite entire date partition instead of appending' || chr(10) || '- Deduplication: Use ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) to keep latest' || chr(10) || '- Unique constraints: Enforce at DB level' || chr(10) || chr(10) || 'Airflow: Use execution_date in file paths to make each run write to a unique location.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is idempotency in data pipelines and why is it critical?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is data observability and what are its five pillars?',
        'Data observability is the ability to understand, monitor, and troubleshoot the health of data in your pipelines.' || chr(10) || chr(10) || 'Five pillars (Monte Carlo framework):' || chr(10) || '1. Freshness: Is data up to date? When was it last updated?' || chr(10) || '2. Volume: Did the expected amount of data arrive? Sudden drops/spikes?' || chr(10) || '3. Distribution: Are values within expected ranges? Null rates normal?' || chr(10) || '4. Schema: Did column names or types change unexpectedly?' || chr(10) || '5. Lineage: Which upstream tables/pipelines affect this dataset?' || chr(10) || chr(10) || 'Tools: Monte Carlo, Bigeye, Great Expectations, dbt tests.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is data observability and what are its five pillars?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_cloud_topic_id, v_cloud_sub_id,
        'What is the difference between hot, warm, and cold data storage tiers?',
        'Hot data: Frequently accessed (daily/hourly). Stored in fast, expensive storage (SSD, in-memory, S3 Standard). Examples: Recent transactions, live dashboards.' || chr(10) || chr(10) || 'Warm data: Accessed occasionally (weekly/monthly). Moderate cost storage (S3-IA, HDD). Examples: Last 90 days of data.' || chr(10) || chr(10) || 'Cold data: Rarely accessed (compliance, archival). Cheapest storage (S3 Glacier, tape). Examples: 7-year audit logs.' || chr(10) || chr(10) || 'Strategy: Automate tiering with lifecycle policies based on data age and access patterns.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between hot, warm, and cold data storage tiers?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'How would you design a real-time fraud detection pipeline?',
        'Architecture:' || chr(10) || '1. Ingest: Payment events -> Kafka topic (partitioned by user_id for ordering)' || chr(10) || '2. Stream processing: Flink/Spark Streaming reads events, enriches with user profile from Redis cache' || chr(10) || '3. Feature computation: Calculate real-time features (transactions in last 5 min, velocity, geo-distance)' || chr(10) || '4. ML scoring: Call fraud model (sub-10ms latency requirement)' || chr(10) || '5. Decision: Block/allow transaction, write result to Kafka response topic' || chr(10) || '6. Storage: Write all events to Delta Lake for model retraining' || chr(10) || chr(10) || 'Key: End-to-end latency < 100ms. Use Redis for low-latency feature lookups.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How would you design a real-time fraud detection pipeline?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'How would you design a data pipeline for 1 billion daily events?',
        'Scale considerations at 1B events/day (~11,500 events/sec):' || chr(10) || chr(10) || 'Ingestion: Kafka with 50+ partitions, 3x replication. Producers batch messages (linger.ms=10).' || chr(10) || chr(10) || 'Processing: Spark Structured Streaming with micro-batches every 30s. 50+ executors.' || chr(10) || chr(10) || 'Storage: Parquet on S3 partitioned by date/hour. Compaction job runs hourly.' || chr(10) || chr(10) || 'Serving: Aggregated metrics in Redshift/BigQuery. Raw events in S3 queried via Athena.' || chr(10) || chr(10) || 'Monitoring: Kafka consumer lag, Spark task duration, data freshness SLAs.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'How would you design a data pipeline for 1 billion daily events?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a feature store and why do ML teams need it?',
        'A feature store is a centralized repository for storing, sharing, and serving ML features for both training and real-time inference.' || chr(10) || chr(10) || 'Problems it solves:' || chr(10) || '- Training-serving skew: Features computed differently offline vs online' || chr(10) || '- Duplication: Multiple teams recomputing the same features' || chr(10) || '- Freshness: Stale features in production models' || chr(10) || chr(10) || 'Architecture: Offline store (S3/warehouse for training) + Online store (Redis/DynamoDB for real-time serving).' || chr(10) || chr(10) || 'Tools: Feast, Tecton, Databricks Feature Store, AWS SageMaker Feature Store.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a feature store and why do ML teams need it?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is the difference between push-based and pull-based data ingestion?',
        'Push-based: Source system sends data to the destination when events occur. Lower latency, real-time. Examples: Webhooks, Kafka producers, CDC (Debezium).' || chr(10) || chr(10) || 'Pull-based: Destination system queries the source on a schedule. Simpler to implement, higher latency. Examples: Airflow DAGs polling APIs, JDBC batch extracts.' || chr(10) || chr(10) || 'Trade-offs: Push = real-time but requires source system changes. Pull = simple but adds load to source and has latency.' || chr(10) || chr(10) || 'Hybrid: CDC (push) for databases, polling (pull) for REST APIs.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is the difference between push-based and pull-based data ingestion?');

    INSERT INTO "de_mobile_app"."flashcards" (flashcard_id, topic_id, subtopic_id, name, explanation)
    SELECT gen_random_uuid(), v_sysdesign_topic_id, v_sysdesign_sub_id,
        'What is a data contract and why is it important?',
        'A data contract is a formal agreement between data producers and consumers defining the schema, semantics, SLAs, and quality expectations of a dataset.' || chr(10) || chr(10) || 'What it includes:' || chr(10) || '- Schema: Column names, types, nullability' || chr(10) || '- Semantics: What each field means' || chr(10) || '- SLAs: Freshness guarantees (data available by 8am)' || chr(10) || '- Quality: Acceptable null rates, value ranges' || chr(10) || '- Ownership: Who is responsible for the data' || chr(10) || chr(10) || 'Why important: Prevents silent breaking changes from upstream teams from breaking downstream pipelines and dashboards.'
    WHERE NOT EXISTS (SELECT 1 FROM "de_mobile_app"."flashcards" WHERE name = 'What is a data contract and why is it important?');

END $$;
