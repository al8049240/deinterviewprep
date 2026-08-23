-- Migration: Seed all 10 interview topics and their subtopics
-- Tables: de_mobile_app."topics-legacy", de_mobile_app."subtopics-legacy"
-- This migration is idempotent (safe to run multiple times)

DO $$
DECLARE
  v_spark_id    BIGINT;
  v_sql_id      BIGINT;
  v_python_id   BIGINT;
  v_kafka_id    BIGINT;
  v_airflow_id  BIGINT;
  v_dm_id       BIGINT;
  v_dw_id       BIGINT;
  v_cloud_id    BIGINT;
  v_devops_id   BIGINT;
  v_bigdata_id  BIGINT;
BEGIN

  -- ── 1. Upsert Topics ──────────────────────────────────────────────────────

  -- Apache Spark (may already exist with id=758910)
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Apache Spark', 'Distributed data processing engine', 'bolt')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_spark_id FROM de_mobile_app."topics-legacy" WHERE name = 'Apache Spark' LIMIT 1;

  -- SQL
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('SQL', 'Structured Query Language for data engineering', 'storage')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_sql_id FROM de_mobile_app."topics-legacy" WHERE name = 'SQL' LIMIT 1;

  -- Python
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Python', 'Python programming for data engineering', 'code')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_python_id FROM de_mobile_app."topics-legacy" WHERE name = 'Python' LIMIT 1;

  -- Kafka
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Kafka', 'Apache Kafka distributed streaming platform', 'stream')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_kafka_id FROM de_mobile_app."topics-legacy" WHERE name = 'Kafka' LIMIT 1;

  -- Apache Airflow
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Apache Airflow', 'Workflow orchestration platform', 'air')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_airflow_id FROM de_mobile_app."topics-legacy" WHERE name = 'Apache Airflow' LIMIT 1;

  -- Data Modeling
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Data Modeling', 'Data modeling concepts and patterns', 'schema')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_dm_id FROM de_mobile_app."topics-legacy" WHERE name = 'Data Modeling' LIMIT 1;

  -- Data Warehouse
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Data Warehouse', 'Cloud data warehouse platforms', 'warehouse')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_dw_id FROM de_mobile_app."topics-legacy" WHERE name = 'Data Warehouse' LIMIT 1;

  -- Cloud
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Cloud', 'Cloud platforms for data engineering', 'cloud')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_cloud_id FROM de_mobile_app."topics-legacy" WHERE name = 'Cloud' LIMIT 1;

  -- Docker & DevOps
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Docker & DevOps', 'Containerization and DevOps practices', 'inventory_2')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_devops_id FROM de_mobile_app."topics-legacy" WHERE name = 'Docker & DevOps' LIMIT 1;

  -- Big Data Fundamentals
  INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
  VALUES ('Big Data Fundamentals', 'Core big data concepts and technologies', 'dataset')
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_bigdata_id FROM de_mobile_app."topics-legacy" WHERE name = 'Big Data Fundamentals' LIMIT 1;

  -- ── 2. Upsert Subtopics ───────────────────────────────────────────────────

  -- Apache Spark subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_spark_id, 'Spark Core', 'RDDs, transformations, actions, partitioning, caching, and the Spark execution model'),
    (v_spark_id, 'DataFrame & SQL', 'DataFrames, Datasets, Spark SQL queries and structured data processing'),
    (v_spark_id, 'Catalyst Optimizer', 'Query planning, logical and physical plan optimization'),
    (v_spark_id, 'Tungsten Engine', 'Off-heap memory management and code generation'),
    (v_spark_id, 'Shuffle & Partitioning', 'Data redistribution, shuffle mechanics and partition strategies'),
    (v_spark_id, 'Memory Management', 'Executor memory, storage vs execution memory, spill'),
    (v_spark_id, 'Performance Tuning', 'Broadcast joins, bucketing, caching, and tuning configs'),
    (v_spark_id, 'Structured Streaming', 'Micro-batch and continuous streaming with Spark')
  ON CONFLICT DO NOTHING;

  -- SQL subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_sql_id, 'SQL Fundamentals', 'SELECT, WHERE, GROUP BY, ORDER BY, basic SQL syntax'),
    (v_sql_id, 'Joins', 'INNER, LEFT, RIGHT, FULL OUTER, CROSS, SELF joins'),
    (v_sql_id, 'Aggregation', 'GROUP BY, HAVING, aggregate functions'),
    (v_sql_id, 'Window Functions', 'ROW_NUMBER, RANK, LAG, LEAD, PARTITION BY'),
    (v_sql_id, 'CTE & View & Function', 'Common Table Expressions, Views, and User-Defined Functions'),
    (v_sql_id, 'Query Optimization', 'Indexes, execution plans, query performance'),
    (v_sql_id, 'Transactions', 'ACID properties, isolation levels, locking')
  ON CONFLICT DO NOTHING;

  -- Python subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_python_id, 'Core Python', 'Data types, control flow, functions, modules'),
    (v_python_id, 'OOP', 'Classes, inheritance, polymorphism, encapsulation'),
    (v_python_id, 'Collections', 'Lists, dicts, sets, tuples, comprehensions'),
    (v_python_id, 'Generators', 'Iterators, generators, yield, lazy evaluation'),
    (v_python_id, 'Pandas', 'DataFrames, Series, data manipulation and analysis'),
    (v_python_id, 'Performance', 'Profiling, vectorization, multiprocessing, optimization')
  ON CONFLICT DO NOTHING;

  -- Kafka subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_kafka_id, 'Producer', 'Kafka producer API, acks, batching, compression'),
    (v_kafka_id, 'Consumer', 'Kafka consumer API, polling, deserialization'),
    (v_kafka_id, 'Consumer Groups', 'Group coordination, rebalancing, partition assignment'),
    (v_kafka_id, 'Offset', 'Offset management, auto-commit, manual commit'),
    (v_kafka_id, 'Partition', 'Partitioning strategies, partition keys, ordering'),
    (v_kafka_id, 'Replication', 'Leader-follower replication, ISR, fault tolerance'),
    (v_kafka_id, 'Exactly Once', 'Idempotent producers, transactions, exactly-once semantics')
  ON CONFLICT DO NOTHING;

  -- Apache Airflow subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_airflow_id, 'DAG', 'Directed Acyclic Graphs, DAG definition, structure'),
    (v_airflow_id, 'Operators', 'BashOperator, PythonOperator, custom operators'),
    (v_airflow_id, 'Scheduling', 'Cron expressions, schedule intervals, backfill'),
    (v_airflow_id, 'Sensors', 'FileSensor, ExternalTaskSensor, poke mode'),
    (v_airflow_id, 'XCom', 'Cross-communication between tasks, push and pull'),
    (v_airflow_id, 'Executors', 'LocalExecutor, CeleryExecutor, KubernetesExecutor')
  ON CONFLICT DO NOTHING;

  -- Data Modeling subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_dm_id, 'Star Schema', 'Fact and dimension tables in star schema design'),
    (v_dm_id, 'Snowflake Schema', 'Normalized dimension tables in snowflake design'),
    (v_dm_id, 'SCD', 'Slowly Changing Dimensions types 1, 2, 3, 4, 6'),
    (v_dm_id, 'Fact Tables', 'Transactional, periodic snapshot, accumulating snapshot facts'),
    (v_dm_id, 'Dimension Tables', 'Conformed, degenerate, junk, role-playing dimensions'),
    (v_dm_id, 'Data Vault', 'Hubs, links, satellites in Data Vault modeling')
  ON CONFLICT DO NOTHING;

  -- Data Warehouse subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_dw_id, 'Snowflake', 'Snowflake architecture, virtual warehouses, clustering'),
    (v_dw_id, 'BigQuery', 'Google BigQuery, partitioning, clustering, slots'),
    (v_dw_id, 'Redshift', 'Amazon Redshift, distribution keys, sort keys, VACUUM'),
    (v_dw_id, 'Databricks SQL', 'Databricks SQL analytics, Delta Lake, photon engine')
  ON CONFLICT DO NOTHING;

  -- Cloud subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_cloud_id, 'AWS', 'Amazon Web Services data engineering services'),
    (v_cloud_id, 'Azure', 'Microsoft Azure data engineering services'),
    (v_cloud_id, 'GCP', 'Google Cloud Platform data engineering services')
  ON CONFLICT DO NOTHING;

  -- Docker & DevOps subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_devops_id, 'Docker', 'Containers, images, Dockerfile, Docker Compose'),
    (v_devops_id, 'Kubernetes', 'Pods, deployments, services, Helm charts'),
    (v_devops_id, 'Linux', 'Shell commands, file system, permissions, scripting'),
    (v_devops_id, 'Git', 'Version control, branching, merging, rebasing'),
    (v_devops_id, 'CI/CD', 'Continuous integration and deployment pipelines')
  ON CONFLICT DO NOTHING;

  -- Big Data Fundamentals subtopics
  INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
  VALUES
    (v_bigdata_id, 'Hadoop', 'Hadoop ecosystem, HDFS, MapReduce, YARN'),
    (v_bigdata_id, 'HDFS', 'Hadoop Distributed File System, blocks, replication'),
    (v_bigdata_id, 'YARN', 'Yet Another Resource Negotiator, resource management'),
    (v_bigdata_id, 'MapReduce', 'Map and Reduce paradigm, job execution'),
    (v_bigdata_id, 'Distributed Systems', 'CAP theorem, consistency, availability, partition tolerance'),
    (v_bigdata_id, 'Data Lake', 'Data lake architecture, zones, governance'),
    (v_bigdata_id, 'Lakehouse', 'Delta Lake, Iceberg, Hudi, lakehouse architecture')
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'All 10 topics and subtopics seeded successfully.';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seeding failed: %', SQLERRM;
END $$;
