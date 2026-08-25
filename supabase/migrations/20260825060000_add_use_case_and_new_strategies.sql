-- ============================================================
-- Migration: Add use_case column, update existing entries,
--            and seed 20 new DE strategy entries (SQL, Python, Spark)
-- ============================================================

-- 1. Add use_case column if not exists
ALTER TABLE de_mobile_app.code_playground
  ADD COLUMN IF NOT EXISTS use_case TEXT;

-- 2. Add language value 'Spark' support (already text, no enum change needed)

-- 3. Update existing SQL entries with use_case descriptions
UPDATE de_mobile_app.code_playground
SET use_case = 'Crucial for deduplicating records, calculating running totals, or finding the latest status/event for a user without collapsing the entire dataset using a standard GROUP BY.'
WHERE title IN ('Running Balance per Account', 'Deduplicate Orders per Customer', 'Employee Salary Percentile Rank', 'Rolling 3-Month Revenue Average', 'Month-over-Month Revenue Growth')
  AND language = 'SQL';

UPDATE de_mobile_app.code_playground
SET use_case = 'Breaking down complex, multi-step business logic into readable, modular blocks instead of nesting deeply nested subqueries.'
WHERE title IN ('Highest Paid Employee per Department', 'Find Customers with No Orders in 2024-03', 'User Purchase Funnel')
  AND language = 'SQL';

UPDATE de_mobile_app.code_playground
SET use_case = 'Categorizing raw attributes into clean business dimensions — mapping user IDs to segments or bucketing transaction sizes for downstream reporting.'
WHERE title IN ('Top Customers by Revenue', 'Count Events per Session')
  AND language = 'SQL';

UPDATE de_mobile_app.code_playground
SET use_case = 'Filtering loads by date or timestamp columns to avoid full table scans on massive multi-terabyte log tables and enable efficient incremental pipeline runs.'
WHERE language = 'SQL' AND use_case IS NULL;

-- 4. Update existing Python entries with use_case descriptions
UPDATE de_mobile_app.code_playground
SET use_case = 'Standard routines used to sanitize datasets before they touch a database — handling nulls, duplicates, and type mismatches in raw ingested data.'
WHERE title IN ('Handle Missing Values', 'Deduplicate User Records', 'Validate and Classify Records')
  AND language = 'Python';

UPDATE de_mobile_app.code_playground
SET use_case = 'Avoid slow row-by-row for loops in Pandas. Use vectorized expressions or map functions to process millions of rows efficiently in memory.'
WHERE title IN ('Aggregate Records by Status', 'Compute Total Purchase Revenue per User', 'Month-over-Month Growth in Python')
  AND language = 'Python';

UPDATE de_mobile_app.code_playground
SET use_case = 'Handling multi-page API responses, nested JSON payloads, and event stream parsing — the backbone of modern data ingestion pipelines.'
WHERE title IN ('Flatten Nested JSON to Tabular Records', 'Extract Purchase Events', 'Detect Duplicate Events', 'ETL: Normalize and Enrich Sales Records')
  AND language = 'Python';

UPDATE de_mobile_app.code_playground
SET use_case = 'Structuring pipeline payloads and transformations using typed patterns to ensure data contracts are explicitly validated before processing.'
WHERE language = 'Python' AND use_case IS NULL;

-- 5. Seed 20 new DE strategy entries (SQL, Python, Spark)
DO $$
BEGIN

  -- ── SQL Strategy 1: Window Functions for Deduplication ──────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Window Functions: Deduplication Strategy',
    'Use ROW_NUMBER() partitioned by a business key to deduplicate a large events table, keeping only the most recent record per user per day.',
    'Crucial for deduplicating records, calculating running totals, or finding the latest status/event for a user without collapsing the entire dataset using a standard GROUP BY.',
    'SQL', 'Middle',
    E'WITH deduped AS (\n  SELECT *,\n    ROW_NUMBER() OVER (\n      PARTITION BY user_id, DATE(event_ts)\n      ORDER BY event_ts DESC\n    ) AS rn\n  FROM raw_events\n)\nSELECT * FROM deduped WHERE rn = 1;',
    'ROW_NUMBER() assigns a unique rank within each (user_id, date) partition ordered by timestamp descending. Filtering WHERE rn = 1 in the outer query retains only the latest event per user per day, eliminating duplicates without a GROUP BY collapse.',
    ARRAY['PARTITION BY defines the deduplication key — usually a business entity ID', 'ORDER BY inside OVER() determines which row is "best" — use DESC for latest', 'Wrap in a CTE for readability; filter rn = 1 in the outer SELECT', 'This pattern scales to billions of rows in columnar warehouses like BigQuery and Redshift']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Window Functions: Deduplication Strategy'
  );

  -- ── SQL Strategy 2: CTEs for Complex Business Logic ─────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'CTEs: Modular Pipeline Logic',
    'Refactor a deeply nested subquery pipeline into readable CTEs — staging raw orders, filtering actives, computing revenue, and ranking customers.',
    'Breaking down complex, multi-step business logic into readable, modular blocks instead of nesting deeply nested subqueries.',
    'SQL', 'Middle',
    E'WITH raw_orders AS (\n  SELECT * FROM orders WHERE status = ''completed''\n),\nrevenue_by_customer AS (\n  SELECT customer_id, SUM(amount) AS total_revenue\n  FROM raw_orders\n  GROUP BY customer_id\n),\nranked_customers AS (\n  SELECT *,\n    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank\n  FROM revenue_by_customer\n)\nSELECT c.name, r.total_revenue, r.revenue_rank\nFROM ranked_customers r\nJOIN customers c USING (customer_id)\nWHERE r.revenue_rank <= 10;',
    'Each CTE represents one logical transformation step. raw_orders filters the source. revenue_by_customer aggregates. ranked_customers applies a window function. The final SELECT joins and filters. This mirrors a layered data model (Bronze → Silver → Gold).',
    ARRAY['Name CTEs after what they produce, not what they do: revenue_by_customer not calculate_revenue', 'CTEs are evaluated once and referenced multiple times — no repeated subquery execution', 'This pattern maps directly to dbt models: each CTE becomes a separate model file', 'Use WITH RECURSIVE for hierarchical data like org charts or category trees']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'CTEs: Modular Pipeline Logic'
  );

  -- ── SQL Strategy 3: CASE WHEN for Dimension Mapping ─────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'CASE WHEN: Business Dimension Mapping',
    'Use CASE WHEN to map raw transaction amounts into business-meaningful size buckets and classify users as Internal vs External based on email domain.',
    'Categorizing raw attributes into clean business dimensions — mapping user IDs to segments or bucketing transaction sizes for downstream reporting.',
    'SQL', 'Junior',
    E'SELECT\n  t.transaction_id,\n  t.amount,\n  CASE\n    WHEN t.amount < 100 THEN ''Small''\n    WHEN t.amount < 1000 THEN ''Medium''\n    WHEN t.amount < 10000 THEN ''Large''\n    ELSE ''Enterprise''\n  END AS transaction_tier,\n  CASE\n    WHEN u.email LIKE ''%@company.com'' THEN ''Internal''\n    ELSE ''External''\n  END AS user_type\nFROM transactions t\nJOIN users u ON t.user_id = u.user_id;',
    'CASE WHEN evaluates conditions top-to-bottom and returns the first matching result. The transaction_tier bucket uses numeric ranges. The user_type classification uses a LIKE pattern match on email domain. Both produce clean categorical columns for BI tools.',
    ARRAY['CASE WHEN evaluates top-to-bottom — order your conditions from most specific to least', 'Use ELSE to handle unexpected values rather than returning NULL silently', 'CASE WHEN inside COUNT() or SUM() enables conditional aggregation: SUM(CASE WHEN status=''active'' THEN 1 ELSE 0 END)', 'This pattern is the SQL equivalent of pandas .map() or np.where()']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'CASE WHEN: Business Dimension Mapping'
  );

  -- ── SQL Strategy 4: Incremental Loading ─────────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Incremental Loading with Partition Pruning',
    'Design an incremental SQL load that filters by event_date to process only yesterday''s data, avoiding full table scans on a multi-terabyte partitioned log table.',
    'Filtering loads by date or timestamp columns to avoid full table scans on massive multi-terabyte log tables and enable efficient incremental pipeline runs.',
    'SQL', 'Senior',
    E'-- Incremental load: process only new records since last run\nINSERT INTO analytics.daily_user_activity\nSELECT\n  user_id,\n  DATE(event_ts) AS activity_date,\n  COUNT(*) AS event_count,\n  COUNT(DISTINCT session_id) AS session_count,\n  SUM(CASE WHEN event_type = ''purchase'' THEN 1 ELSE 0 END) AS purchase_count\nFROM raw.events\nWHERE event_date >= CURRENT_DATE - INTERVAL ''1 day''\n  AND event_date < CURRENT_DATE\nGROUP BY user_id, DATE(event_ts)\nON CONFLICT (user_id, activity_date)\nDO UPDATE SET\n  event_count = EXCLUDED.event_count,\n  session_count = EXCLUDED.session_count,\n  purchase_count = EXCLUDED.purchase_count;',
    'The WHERE clause on event_date enables partition pruning — the query engine skips all partitions outside the date range. ON CONFLICT DO UPDATE (upsert) makes the load idempotent: re-running it for the same date updates rather than duplicates rows.',
    ARRAY['Always filter on the partition column (event_date) to enable partition pruning', 'Use CURRENT_DATE - INTERVAL to make the filter dynamic and pipeline-safe', 'ON CONFLICT DO UPDATE makes incremental loads idempotent — safe to re-run', 'Store the last successful run timestamp in a metadata table for robust watermarking']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Incremental Loading with Partition Pruning'
  );

  -- ── SQL Strategy 5: SCD Type 2 Pattern ──────────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Slowly Changing Dimension Type 2 (SCD2)',
    'Implement an SCD Type 2 pattern to track historical changes to customer records — closing old rows and inserting new ones when attributes change.',
    'Tracking historical changes to dimension records in a data warehouse, preserving the full audit trail of how attributes like address or tier changed over time.',
    'SQL', 'Senior',
    E'-- Step 1: Close expired rows where attributes have changed\nUPDATE dim_customers\nSET valid_to = CURRENT_DATE - 1,\n    is_current = FALSE\nWHERE is_current = TRUE\n  AND customer_id IN (\n    SELECT s.customer_id\n    FROM staging_customers s\n    JOIN dim_customers d ON s.customer_id = d.customer_id\n    WHERE d.is_current = TRUE\n      AND (s.email <> d.email OR s.tier <> d.tier)\n  );\n\n-- Step 2: Insert new versions for changed + new customers\nINSERT INTO dim_customers (customer_id, email, tier, valid_from, valid_to, is_current)\nSELECT\n  s.customer_id, s.email, s.tier,\n  CURRENT_DATE AS valid_from,\n  ''9999-12-31''::date AS valid_to,\n  TRUE AS is_current\nFROM staging_customers s\nLEFT JOIN dim_customers d\n  ON s.customer_id = d.customer_id AND d.is_current = TRUE\nWHERE d.customer_id IS NULL\n   OR s.email <> d.email\n   OR s.tier <> d.tier;',
    'SCD2 uses valid_from/valid_to date ranges and an is_current flag to track history. Step 1 closes rows where attributes changed. Step 2 inserts new current rows. Querying WHERE is_current = TRUE returns the latest state; joining on a date range returns historical state.',
    ARRAY['valid_to = 9999-12-31 is the sentinel value for currently active rows', 'Always update (close) before inserting to avoid duplicate current rows', 'Add a surrogate key (serial/uuid) as the primary key — not customer_id', 'dbt snapshots automate this pattern with strategy: timestamp or check']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Slowly Changing Dimension Type 2 (SCD2)'
  );

  -- ── Python Strategy 1: Data Cleaning with pandas ─────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'pandas: Data Cleaning Pipeline',
    'Build a reusable pandas cleaning pipeline using .fillna(), .dropna(), .drop_duplicates(), and .astype() to sanitize a raw CSV ingestion before loading to a database.',
    'Standard routines used to sanitize datasets before they touch a database — handling nulls, duplicates, and type mismatches in raw ingested data.',
    'Python', 'Junior',
    E'import pandas as pd\n\ndef clean_pipeline(df: pd.DataFrame) -> pd.DataFrame:\n    # 1. Drop fully empty rows\n    df = df.dropna(how=''all'')\n    \n    # 2. Deduplicate on business key\n    df = df.drop_duplicates(subset=[''user_id'', ''event_date''])\n    \n    # 3. Fill missing values\n    df[''country''] = df[''country''].fillna(''Unknown'')\n    df[''amount''] = df[''amount''].fillna(0.0)\n    \n    # 4. Type coercion\n    df[''event_date''] = pd.to_datetime(df[''event_date''])\n    df[''amount''] = df[''amount''].astype(float)\n    df[''user_id''] = df[''user_id''].astype(str)\n    \n    # 5. Strip whitespace from string columns\n    str_cols = df.select_dtypes(include=''object'').columns\n    df[str_cols] = df[str_cols].apply(lambda col: col.str.strip())\n    \n    return df',
    'Each step in the pipeline addresses a specific data quality issue. dropna(how=''all'') removes ghost rows. drop_duplicates() on a composite key prevents double-counting. fillna() provides safe defaults. astype() enforces schema types. str.strip() removes invisible whitespace that breaks joins.',
    ARRAY['.drop_duplicates(subset=[...]) deduplicates on a composite business key, not all columns', '.fillna() on numeric columns with 0 vs NaN matters — choose based on business logic', 'pd.to_datetime() with errors=''coerce'' converts unparseable dates to NaT instead of crashing', 'select_dtypes(include=''object'') targets only string columns for strip operations']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'pandas: Data Cleaning Pipeline'
  );

  -- ── Python Strategy 2: Vectorized Operations ─────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Vectorized Operations over Row Loops',
    'Replace a slow row-by-row for loop with vectorized pandas operations and np.where() to process 10M rows in seconds instead of minutes.',
    'Avoid slow row-by-row for loops in Pandas. Use vectorized expressions or map functions to process millions of rows efficiently in memory.',
    'Python', 'Middle',
    E'import pandas as pd\nimport numpy as np\n\n# ❌ Slow: row-by-row loop (O(n) Python overhead per row)\ndef classify_slow(df):\n    results = []\n    for _, row in df.iterrows():\n        if row[''amount''] > 1000:\n            results.append(''High'')\n        elif row[''amount''] > 100:\n            results.append(''Medium'')\n        else:\n            results.append(''Low'')\n    df[''tier''] = results\n    return df\n\n# ✅ Fast: vectorized with np.where (C-speed operations)\ndef classify_fast(df):\n    df[''tier''] = np.where(\n        df[''amount''] > 1000, ''High'',\n        np.where(df[''amount''] > 100, ''Medium'', ''Low'')\n    )\n    return df\n\n# ✅ Also fast: pd.cut for binning\ndef classify_bins(df):\n    df[''tier''] = pd.cut(\n        df[''amount''],\n        bins=[0, 100, 1000, float(''inf'')],\n        labels=[''Low'', ''Medium'', ''High'']\n    )\n    return df',
    'iterrows() applies Python-level logic per row — extremely slow on large DataFrames. np.where() and pd.cut() operate at C speed on the entire column array simultaneously. For 10M rows, the vectorized version is typically 100-500x faster.',
    ARRAY['Never use iterrows() for transformations — it is the slowest pandas pattern', 'np.where(condition, true_val, false_val) is the vectorized ternary operator', 'pd.cut() is cleaner than nested np.where() for numeric binning', 'For complex logic, .apply() with a function is faster than iterrows() but slower than pure vectorization']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Vectorized Operations over Row Loops'
  );

  -- ── Python Strategy 3: API Ingestion with Pagination ─────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'API Ingestion with Pagination & Backoff',
    'Build a robust API ingestion handler using requests.get() in a while loop with cursor-based pagination, exponential backoff, and raise_for_status() error handling.',
    'Using requests.get() wrapped in while loops to handle multi-page API responses, paired with exponential backoff and error handling to prevent pipeline crashes.',
    'Python', 'Middle',
    E'import requests\nimport time\nfrom typing import List, Dict, Any\n\ndef fetch_all_pages(\n    base_url: str,\n    headers: Dict[str, str],\n    page_size: int = 100,\n    max_retries: int = 3\n) -> List[Dict[str, Any]]:\n    all_records = []\n    cursor = None\n    \n    while True:\n        params = {"limit": page_size}\n        if cursor:\n            params["cursor"] = cursor\n        \n        for attempt in range(max_retries):\n            try:\n                response = requests.get(base_url, headers=headers, params=params, timeout=30)\n                response.raise_for_status()  # raises on 4xx/5xx\n                break\n            except requests.exceptions.RequestException as e:\n                if attempt == max_retries - 1:\n                    raise\n                wait = 2 ** attempt  # exponential backoff: 1s, 2s, 4s\n                time.sleep(wait)\n        \n        data = response.json()\n        records = data.get("data", [])\n        all_records.extend(records)\n        \n        cursor = data.get("next_cursor")\n        if not cursor or not records:\n            break\n    \n    return all_records',
    'The outer while True loop continues until no next_cursor is returned. The inner for loop implements retry with exponential backoff (2^attempt seconds). raise_for_status() converts HTTP error codes into Python exceptions. timeout=30 prevents hanging on slow APIs.',
    ARRAY['raise_for_status() is essential — never assume a 200 response means success without it', 'Exponential backoff (2^attempt) prevents hammering a rate-limited API', 'Always set timeout= on requests.get() — default is no timeout (hangs forever)', 'Store cursor/offset in a checkpoint file to resume interrupted ingestion jobs']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'API Ingestion with Pagination & Backoff'
  );

  -- ── Python Strategy 4: Dataclass & Type Hinting ──────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Dataclass & Type Hinting for Pipeline Contracts',
    'Use @dataclass and typing module to define explicit data contracts for pipeline payloads, enabling early validation and IDE autocompletion across pipeline stages.',
    'Structuring pipeline payloads using @dataclass and typing modules to ensure data contracts are explicitly validated before processing.',
    'Python', 'Middle',
    E'from dataclasses import dataclass, field\nfrom typing import Optional, List, Dict, Any\nfrom datetime import datetime\n\n@dataclass\nclass RawEvent:\n    event_id: str\n    user_id: str\n    event_type: str\n    timestamp: datetime\n    properties: Dict[str, Any] = field(default_factory=dict)\n    session_id: Optional[str] = None\n\n@dataclass\nclass EnrichedEvent:\n    event_id: str\n    user_id: str\n    event_type: str\n    timestamp: datetime\n    date: str  # derived: YYYY-MM-DD\n    hour: int  # derived: 0-23\n    is_purchase: bool\n    revenue: float = 0.0\n\ndef enrich_event(raw: RawEvent) -> EnrichedEvent:\n    return EnrichedEvent(\n        event_id=raw.event_id,\n        user_id=raw.user_id,\n        event_type=raw.event_type,\n        timestamp=raw.timestamp,\n        date=raw.timestamp.strftime(''%Y-%m-%d''),\n        hour=raw.timestamp.hour,\n        is_purchase=raw.event_type == ''purchase'',\n        revenue=raw.properties.get(''amount'', 0.0)\n    )\n\n# Usage\nevents: List[EnrichedEvent] = [enrich_event(e) for e in raw_events]',
    'Dataclasses provide typed, self-documenting data structures with zero boilerplate. The transformation function enrich_event() has an explicit input/output contract: RawEvent → EnrichedEvent. This makes pipeline stages composable, testable, and IDE-friendly.',
    ARRAY['@dataclass auto-generates __init__, __repr__, and __eq__ from field annotations', 'Optional[str] = None is the correct pattern for nullable fields', 'field(default_factory=dict) is required for mutable defaults — never use = {} directly', 'Use @dataclass(frozen=True) for immutable records that should not be modified after creation']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Dataclass & Type Hinting for Pipeline Contracts'
  );

  -- ── Python Strategy 5: Generator for Large File Processing ───────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Generator Pattern for Large File Processing',
    'Use Python generators to process a 10GB CSV file in constant memory by yielding one batch at a time instead of loading the entire file into RAM.',
    'Processing files too large to fit in memory by streaming records in batches — essential for log file processing, large CSV ingestion, and ETL on constrained infrastructure.',
    'Python', 'Senior',
    E'import csv\nfrom typing import Generator, List, Dict, Any\n\ndef read_csv_in_batches(\n    filepath: str,\n    batch_size: int = 10_000\n) -> Generator[List[Dict[str, Any]], None, None]:\n    """Yields batches of rows from a large CSV without loading it all into memory."""\n    batch = []\n    with open(filepath, ''r'', encoding=''utf-8'') as f:\n        reader = csv.DictReader(f)\n        for row in reader:\n            batch.append(dict(row))\n            if len(batch) >= batch_size:\n                yield batch\n                batch = []  # reset for next batch\n        if batch:  # yield remaining rows\n            yield batch\n\ndef process_large_file(filepath: str) -> None:\n    total_rows = 0\n    for batch in read_csv_in_batches(filepath, batch_size=50_000):\n        # Process each batch: clean, transform, load\n        cleaned = [clean_record(r) for r in batch]\n        load_to_database(cleaned)\n        total_rows += len(batch)\n        print(f"Processed {total_rows:,} rows...")',
    'The generator function uses yield to pause execution and return a batch to the caller. Memory usage stays constant at batch_size rows regardless of file size. The caller processes each batch and the generator resumes from where it left off.',
    ARRAY['yield pauses the function and returns a value — execution resumes on the next iteration', 'Memory usage = batch_size rows, not total file size — critical for 10GB+ files', 'Always flush the final partial batch after the loop with if batch: yield batch', 'Combine with multiprocessing.Pool to process batches in parallel across CPU cores']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Generator Pattern for Large File Processing'
  );

  -- ── Spark Strategy 1: DataFrame Transformations ──────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Spark: DataFrame Transformations & Lazy Evaluation',
    'Build a Spark transformation pipeline using select(), filter(), withColumn(), and groupBy() — understanding that transformations are lazy and only execute on an action like .show() or .write().',
    'Processing distributed datasets across a cluster using Spark''s lazy evaluation model — transformations build a DAG that only executes when an action is triggered, enabling query optimization.',
    'Spark', 'Middle',
    E'from pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\nfrom pyspark.sql.types import DoubleType\n\nspark = SparkSession.builder.appName("DE Pipeline").getOrCreate()\n\n# Read partitioned data\ndf = spark.read.parquet("s3://bucket/events/event_date=2024-03-01/")\n\n# Transformations (lazy — no execution yet)\ndf_clean = (\n    df\n    .filter(F.col("event_type").isin(["purchase", "click"]))\n    .withColumn("amount_usd", F.col("amount").cast(DoubleType()))\n    .withColumn("event_hour", F.hour(F.col("event_ts")))\n    .withColumn(\n        "user_segment",\n        F.when(F.col("amount_usd") > 100, "High Value")\n         .when(F.col("amount_usd") > 10, "Mid Value")\n         .otherwise("Low Value")\n    )\n)\n\n# Aggregation (still lazy)\ndf_agg = (\n    df_clean\n    .groupBy("user_id", "user_segment")\n    .agg(\n        F.count("*").alias("event_count"),\n        F.sum("amount_usd").alias("total_revenue"),\n        F.countDistinct("session_id").alias("session_count")\n    )\n)\n\n# Action triggers execution of the entire DAG\ndf_agg.write.mode("overwrite").parquet("s3://bucket/output/user_summary/")',
    'Spark builds a DAG (Directed Acyclic Graph) of transformations. No data moves until an action (.write, .show, .count) is called. This allows Catalyst optimizer to reorder, push down filters, and combine operations for maximum efficiency across the cluster.',
    ARRAY['Transformations are lazy — they build a plan. Actions execute the plan.', 'F.when().when().otherwise() is the Spark equivalent of SQL CASE WHEN', 'Always use F.col() instead of string column names for type safety', 'filter() early in the pipeline reduces data volume for all downstream steps']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Spark: DataFrame Transformations & Lazy Evaluation'
  );

  -- ── Spark Strategy 2: Partitioning Strategy ──────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Spark: Partitioning & Repartitioning Strategy',
    'Optimize a Spark job by choosing the right number of partitions, using repartition() vs coalesce(), and writing output partitioned by date for efficient downstream reads.',
    'Controlling data distribution across Spark executors to avoid skew, optimize shuffle performance, and write output in a partition layout that enables predicate pushdown in downstream queries.',
    'Spark', 'Senior',
    E'from pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName("Partition Demo").getOrCreate()\n\ndf = spark.read.parquet("s3://bucket/raw/events/")\n\n# Check current partition count\nprint(f"Initial partitions: {df.rdd.getNumPartitions()}")\n\n# repartition() — full shuffle, use when increasing partitions or fixing skew\n# Rule of thumb: ~128MB per partition\ndf_repartitioned = df.repartition(200, F.col("user_id"))\n\n# coalesce() — no shuffle, use only when reducing partitions\ndf_small = df.coalesce(10)  # for small output files\n\n# Write partitioned by date for efficient downstream reads\ndf_repartitioned.write \\\n    .mode("overwrite") \\\n    .partitionBy("event_date", "event_type") \\\n    .parquet("s3://bucket/processed/events/")\n\n# Avoid small files: repartition before writing\ndf.repartition(1).write.mode("overwrite").csv("s3://bucket/report/daily_summary.csv")',
    'repartition() performs a full shuffle and can increase or decrease partition count. coalesce() avoids a shuffle but can only reduce partitions. partitionBy() on write creates a directory structure (event_date=2024-03-01/event_type=purchase/) that enables partition pruning in downstream SQL queries.',
    ARRAY['repartition(n, col) distributes data evenly by column — fixes data skew', 'coalesce(n) is cheaper than repartition() but only works for reducing partitions', 'Target ~128MB per partition for optimal task execution time', 'partitionBy() on write enables partition pruning — downstream queries skip irrelevant partitions']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Spark: Partitioning & Repartitioning Strategy'
  );

  -- ── Spark Strategy 3: Broadcast Join ─────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Spark: Broadcast Join for Small-Large Table Joins',
    'Use broadcast() hint to join a large fact table with a small dimension table without a shuffle — reducing join time from minutes to seconds on a 100GB dataset.',
    'Eliminating expensive shuffle operations when joining a large distributed table with a small lookup/dimension table by broadcasting the small table to every executor.',
    'Spark', 'Senior',
    E'from pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\nfrom pyspark.sql.functions import broadcast\n\nspark = SparkSession.builder.appName("Broadcast Join").getOrCreate()\n\n# Large fact table: 100GB, 500M rows\nfact_events = spark.read.parquet("s3://bucket/fact/events/")\n\n# Small dimension table: 10MB, 5000 rows\ndim_products = spark.read.parquet("s3://bucket/dim/products/")\n\n# ❌ Without broadcast: Spark shuffles both tables (expensive)\nresult_slow = fact_events.join(dim_products, on="product_id", how="left")\n\n# ✅ With broadcast: dim_products sent to every executor (no shuffle)\nresult_fast = fact_events.join(\n    broadcast(dim_products),\n    on="product_id",\n    how="left"\n)\n\n# Auto-broadcast threshold (default 10MB)\nspark.conf.set("spark.sql.autoBroadcastJoinThreshold", 50 * 1024 * 1024)  # 50MB\n\nresult_fast.write.mode("overwrite").parquet("s3://bucket/output/enriched_events/")',
    'A regular join shuffles both tables across the network to co-locate matching keys — expensive for large tables. broadcast() sends the entire small table to every executor so each executor can perform the join locally without any network shuffle.',
    ARRAY['Use broadcast() when one table is < 200MB — the default threshold is 10MB', 'broadcast() eliminates the shuffle stage entirely — check the Spark UI to confirm', 'Increase spark.sql.autoBroadcastJoinThreshold for slightly larger dimension tables', 'Never broadcast a table that changes frequently — the broadcast copy is immutable during the job']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Spark: Broadcast Join for Small-Large Table Joins'
  );

  -- ── Spark Strategy 4: Window Functions in Spark ──────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Spark: Window Functions for Running Totals & Ranking',
    'Use Spark Window functions to compute running totals, rank users by revenue, and calculate lag/lead values across a distributed dataset without collecting to the driver.',
    'Applying analytical window functions across distributed partitions in Spark — computing running totals, rankings, and time-series lag/lead values at scale.',
    'Spark', 'Senior',
    E'from pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\nfrom pyspark.sql.window import Window\n\nspark = SparkSession.builder.appName("Window Functions").getOrCreate()\n\ndf = spark.read.parquet("s3://bucket/transactions/")\n\n# Define window specs\nuser_window = Window.partitionBy("user_id").orderBy("txn_date")\nrevenue_window = Window.partitionBy("user_id").orderBy(F.col("total_revenue").desc())\nrolling_window = Window.partitionBy("user_id").orderBy("txn_date").rowsBetween(-6, 0)\n\n# Running total per user\ndf_with_running = df.withColumn(\n    "running_balance",\n    F.sum("amount").over(user_window)\n)\n\n# Rank by revenue within user\ndf_with_rank = df.withColumn(\n    "revenue_rank",\n    F.dense_rank().over(revenue_window)\n)\n\n# 7-day rolling average\ndf_with_rolling = df.withColumn(\n    "rolling_7d_avg",\n    F.avg("amount").over(rolling_window)\n)\n\n# LAG: previous transaction amount\ndf_with_lag = df.withColumn(\n    "prev_amount",\n    F.lag("amount", 1).over(user_window)\n)',
    'Spark Window functions mirror SQL window functions but operate on distributed DataFrames. Window.partitionBy() defines the group. orderBy() defines the sort within the group. rowsBetween() defines the frame. All operations execute in parallel across the cluster.',
    ARRAY['Window.partitionBy() is the Spark equivalent of SQL PARTITION BY', 'rowsBetween(-6, 0) creates a 7-row sliding window (6 preceding + current)', 'F.lag(col, n) accesses the value n rows before the current row', 'Window functions trigger a shuffle — partition your data by the window key first to minimize shuffle size']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Spark: Window Functions for Running Totals & Ranking'
  );

  -- ── Spark Strategy 5: Handling Data Skew ─────────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Spark: Handling Data Skew with Salting',
    'Fix a skewed groupBy aggregation where 80% of data belongs to one key by applying a salting technique to distribute the hot key across multiple partitions.',
    'Resolving data skew in Spark jobs where a few keys dominate the dataset — causing some tasks to run 100x longer than others and stalling the entire stage.',
    'Spark', 'Senior',
    E'from pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName("Skew Handling").getOrCreate()\n\ndf = spark.read.parquet("s3://bucket/events/")\n\n# ❌ Skewed: user_id ''bot_user'' has 80% of all rows\nskewed_result = df.groupBy("user_id").agg(F.sum("amount").alias("total"))\n\n# ✅ Salting: distribute hot key across N buckets\nN_SALT = 10\n\n# Step 1: Add salt to the large table\ndf_salted = df.withColumn(\n    "salted_user_id",\n    F.concat(\n        F.col("user_id"),\n        F.lit("_"),\n        (F.rand() * N_SALT).cast("int").cast("string")\n    )\n)\n\n# Step 2: Aggregate on salted key\ndf_partial = df_salted.groupBy("salted_user_id", "user_id").agg(\n    F.sum("amount").alias("partial_total")\n)\n\n# Step 3: Final aggregation to merge salt buckets\ndf_final = df_partial.groupBy("user_id").agg(\n    F.sum("partial_total").alias("total")\n)',
    'Salting appends a random integer (0 to N-1) to the skewed key, splitting one hot partition into N smaller partitions. The first aggregation reduces data within each salt bucket. The second aggregation merges the N partial results into the final answer.',
    ARRAY['Identify skew with df.groupBy(key).count().orderBy(F.desc("count")).show()', 'Salt only the skewed keys — apply conditional salting to avoid over-shuffling normal keys', 'N_SALT = 10-50 is typical; higher values reduce skew but increase the second aggregation cost', 'Spark 3.x AQE (Adaptive Query Execution) can handle skew automatically — enable with spark.sql.adaptive.enabled=true']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Spark: Handling Data Skew with Salting'
  );

  -- ── SQL Strategy 6: Pivot / Unpivot ──────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'SQL: Pivot Rows to Columns with CASE WHEN',
    'Transform a normalized event_type/count table into a wide pivot table with one column per event type using conditional aggregation.',
    'Converting long-format data (one row per metric) into wide-format (one column per metric) for reporting dashboards and BI tools that expect pivoted data.',
    'SQL', 'Middle',
    E'-- Long format: one row per user per event_type\n-- Goal: pivot to one row per user with columns per event_type\n\nSELECT\n  user_id,\n  SUM(CASE WHEN event_type = ''login'' THEN 1 ELSE 0 END) AS login_count,\n  SUM(CASE WHEN event_type = ''page_view'' THEN 1 ELSE 0 END) AS page_view_count,\n  SUM(CASE WHEN event_type = ''purchase'' THEN 1 ELSE 0 END) AS purchase_count,\n  SUM(CASE WHEN event_type = ''logout'' THEN 1 ELSE 0 END) AS logout_count,\n  COUNT(*) AS total_events\nFROM events\nGROUP BY user_id\nORDER BY total_events DESC;',
    'Conditional aggregation with CASE WHEN inside SUM() is the standard SQL pivot technique. Each CASE WHEN evaluates to 1 for matching rows and 0 for non-matching rows. SUM() then counts the matching rows per group. This works in all SQL dialects without proprietary PIVOT syntax.',
    ARRAY['SUM(CASE WHEN condition THEN 1 ELSE 0 END) is the universal SQL pivot pattern', 'Works in all SQL dialects — no proprietary PIVOT keyword required', 'Add a total column with COUNT(*) to validate that pivoted counts sum correctly', 'For dynamic pivot columns (unknown values), use dynamic SQL or dbt macros']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'SQL: Pivot Rows to Columns with CASE WHEN'
  );

  -- ── Python Strategy 6: Schema Validation with Pydantic ───────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Schema Validation with Pydantic Models',
    'Use Pydantic BaseModel to validate incoming API payloads and pipeline records at runtime — catching schema violations before they corrupt downstream tables.',
    'Enforcing data contracts at pipeline boundaries — validating that incoming records match the expected schema before they are written to a database or passed to the next stage.',
    'Python', 'Middle',
    E'from pydantic import BaseModel, validator, Field\nfrom typing import Optional, List\nfrom datetime import datetime\nfrom enum import Enum\n\nclass EventType(str, Enum):\n    LOGIN = "login"\n    PURCHASE = "purchase"\n    PAGE_VIEW = "page_view"\n    LOGOUT = "logout"\n\nclass IncomingEvent(BaseModel):\n    event_id: str = Field(..., min_length=1)\n    user_id: str = Field(..., min_length=1)\n    event_type: EventType\n    timestamp: datetime\n    amount: Optional[float] = Field(None, ge=0)  # must be >= 0 if present\n    session_id: Optional[str] = None\n    \n    @validator(''amount'')\n    def purchase_requires_amount(cls, v, values):\n        if values.get(''event_type'') == EventType.PURCHASE and v is None:\n            raise ValueError(''Purchase events must have an amount'')\n        return v\n\ndef validate_batch(raw_records: List[dict]) -> tuple:\n    valid, invalid = [], []\n    for record in raw_records:\n        try:\n            valid.append(IncomingEvent(**record))\n        except Exception as e:\n            invalid.append({"record": record, "error": str(e)})\n    return valid, invalid\n\nvalid_events, errors = validate_batch(incoming_data)\nprint(f"Valid: {len(valid_events)}, Invalid: {len(errors)}")',
    'Pydantic validates types, constraints, and cross-field rules at instantiation time. EventType enum restricts event_type to known values. Field(ge=0) enforces non-negative amounts. The @validator decorator implements cross-field business rules. validate_batch() separates valid from invalid records for dead-letter queue handling.',
    ARRAY['Pydantic raises ValidationError with detailed field-level messages — log these for debugging', 'Use Enum fields to restrict string values to a known set — prevents typos in event types', 'Field(ge=0, le=100) adds numeric range constraints without custom validators', '@validator with pre=True runs before type coercion — useful for cleaning raw strings']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Schema Validation with Pydantic Models'
  );

  -- ── Spark Strategy 6: Delta Lake Upsert ──────────────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Spark: Delta Lake MERGE for Upserts',
    'Use Delta Lake MERGE INTO to perform an idempotent upsert — updating existing records and inserting new ones in a single atomic operation on a large Delta table.',
    'Implementing idempotent incremental loads on Delta Lake tables — merging new/changed records without duplicating existing data, enabling safe pipeline re-runs.',
    'Spark', 'Senior',
    E'from pyspark.sql import SparkSession\nfrom delta.tables import DeltaTable\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder \\\n    .appName("Delta Upsert") \\\n    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \\\n    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \\\n    .getOrCreate()\n\n# Load incremental batch from staging\ndf_new = spark.read.parquet("s3://bucket/staging/customers/")\n\n# Reference the target Delta table\ndelta_table = DeltaTable.forPath(spark, "s3://bucket/delta/customers/")\n\n# MERGE: upsert new records into the Delta table\ndelta_table.alias("target").merge(\n    df_new.alias("source"),\n    "target.customer_id = source.customer_id"\n).whenMatchedUpdate(set={\n    "email": "source.email",\n    "tier": "source.tier",\n    "updated_at": F.current_timestamp()\n}).whenNotMatchedInsert(values={\n    "customer_id": "source.customer_id",\n    "email": "source.email",\n    "tier": "source.tier",\n    "created_at": F.current_timestamp(),\n    "updated_at": F.current_timestamp()\n}).execute()',
    'Delta Lake MERGE is the distributed equivalent of SQL UPSERT. whenMatchedUpdate() updates existing rows. whenNotMatchedInsert() inserts new rows. The operation is atomic and ACID-compliant. Running the same merge twice produces the same result — making the pipeline idempotent.',
    ARRAY['MERGE is atomic — either all changes commit or none do (ACID guarantee)', 'whenMatchedUpdateAll() and whenNotMatchedInsertAll() copy all columns without listing them', 'Add a whenMatchedDelete() clause to handle soft deletes from the source', 'Delta MERGE is significantly faster than DROP + INSERT for incremental loads on large tables']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Spark: Delta Lake MERGE for Upserts'
  );

  -- ── SQL Strategy 7: Recursive CTE for Hierarchy ──────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Recursive CTE: Org Chart Hierarchy Traversal',
    'Use a recursive CTE to traverse a self-referencing employee table and compute the full management chain from any employee up to the CEO.',
    'Traversing hierarchical data structures like org charts, category trees, or bill-of-materials using recursive SQL instead of application-level loops.',
    'SQL', 'Senior',
    E'WITH RECURSIVE org_hierarchy AS (\n  -- Base case: start with the target employee\n  SELECT\n    emp_id,\n    name,\n    manager_id,\n    dept,\n    salary,\n    0 AS level,\n    name::text AS path\n  FROM employees\n  WHERE manager_id IS NULL  -- start from CEO\n  \n  UNION ALL\n  \n  -- Recursive case: join to find direct reports\n  SELECT\n    e.emp_id,\n    e.name,\n    e.manager_id,\n    e.dept,\n    e.salary,\n    h.level + 1,\n    h.path || '' > '' || e.name\n  FROM employees e\n  INNER JOIN org_hierarchy h ON e.manager_id = h.emp_id\n)\nSELECT\n  emp_id,\n  name,\n  dept,\n  salary,\n  level,\n  path AS management_chain\nFROM org_hierarchy\nORDER BY level, name;',
    'A recursive CTE has two parts separated by UNION ALL. The base case selects the starting rows (CEO with no manager). The recursive case joins the CTE back to itself to find the next level of the hierarchy. The recursion stops when no new rows are found.',
    ARRAY['WITH RECURSIVE requires UNION ALL between base case and recursive case', 'Add a depth limit (WHERE level < 10) to prevent infinite loops on circular references', 'The path column builds a breadcrumb trail by concatenating names at each level', 'Use CYCLE detection (PostgreSQL 14+) with CYCLE emp_id SET is_cycle USING path']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Recursive CTE: Org Chart Hierarchy Traversal'
  );

  -- ── Python Strategy 7: Logging & Observability ───────────────────────────
  INSERT INTO de_mobile_app.code_playground (
    playground_id, title, description, use_case, language, difficulty,
    solution_code, solution_explanation, tips
  )
  SELECT
    gen_random_uuid(),
    'Pipeline Observability with Structured Logging',
    'Implement structured JSON logging and pipeline metrics tracking in a data pipeline — capturing row counts, durations, and error rates for monitoring dashboards.',
    'Adding observability to data pipelines so failures, data quality issues, and performance regressions are detected immediately rather than discovered days later in downstream reports.',
    'Python', 'Middle',
    E'import logging\nimport json\nimport time\nfrom datetime import datetime\nfrom typing import Dict, Any\n\n# Configure structured JSON logger\nclass JSONFormatter(logging.Formatter):\n    def format(self, record):\n        log_data = {\n            "timestamp": datetime.utcnow().isoformat(),\n            "level": record.levelname,\n            "message": record.getMessage(),\n            "pipeline": getattr(record, "pipeline", "unknown"),\n            "stage": getattr(record, "stage", "unknown"),\n        }\n        if record.exc_info:\n            log_data["exception"] = self.formatException(record.exc_info)\n        return json.dumps(log_data)\n\nlogger = logging.getLogger("de_pipeline")\nhandler = logging.StreamHandler()\nhandler.setFormatter(JSONFormatter())\nlogger.addHandler(handler)\nlogger.setLevel(logging.INFO)\n\ndef run_stage(stage_name: str, func, *args) -> Dict[str, Any]:\n    """Wrapper that logs metrics for any pipeline stage."""\n    start = time.time()\n    extra = {"pipeline": "daily_etl", "stage": stage_name}\n    logger.info(f"Starting stage: {stage_name}", extra=extra)\n    try:\n        result = func(*args)\n        duration = time.time() - start\n        logger.info(\n            f"Stage completed: {stage_name}",\n            extra={**extra, "duration_seconds": round(duration, 2), "rows": len(result) if hasattr(result, ''__len__'') else -1}\n        )\n        return result\n    except Exception as e:\n        logger.error(f"Stage failed: {stage_name} — {e}", extra=extra, exc_info=True)\n        raise',
    'Structured JSON logging makes pipeline logs queryable in tools like Datadog, CloudWatch, or Elasticsearch. The run_stage() wrapper captures duration and row counts for every stage automatically. exc_info=True attaches the full stack trace to error logs.',
    ARRAY['JSON-formatted logs are queryable in log aggregation tools — avoid plain text logs in production', 'Always log row counts at stage boundaries to detect silent data loss', 'Use extra={} to add structured fields to log records without string formatting', 'Wrap every pipeline stage in a try/except that logs and re-raises — never swallow exceptions silently']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Pipeline Observability with Structured Logging'
  );

END $$;
