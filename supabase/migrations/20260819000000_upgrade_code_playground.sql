-- ============================================================
-- Migration: Upgrade code_playground with solution, verification,
--            timestamps, and seed 20 realistic DE challenges
-- ============================================================

-- 0. Ensure unique constraint on dataset_name for ON CONFLICT to work
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'code_playground_datasets_dataset_name_key'
      AND conrelid = 'de_mobile_app.code_playground_datasets'::regclass
  ) THEN
    ALTER TABLE de_mobile_app.code_playground_datasets
      ADD CONSTRAINT code_playground_datasets_dataset_name_key UNIQUE (dataset_name);
  END IF;
END $$;

-- 1. Add missing columns to de_mobile_app.code_playground
ALTER TABLE de_mobile_app.code_playground
  ADD COLUMN IF NOT EXISTS solution_code TEXT,
  ADD COLUMN IF NOT EXISTS solution_explanation TEXT,
  ADD COLUMN IF NOT EXISTS verification_config JSONB,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 2. Ensure RLS is enabled and policies exist
ALTER TABLE de_mobile_app.code_playground ENABLE ROW LEVEL SECURITY;
ALTER TABLE de_mobile_app.code_playground_datasets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_code_playground" ON de_mobile_app.code_playground;
CREATE POLICY "public_read_code_playground"
  ON de_mobile_app.code_playground
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "public_read_code_playground_datasets" ON de_mobile_app.code_playground_datasets;
CREATE POLICY "public_read_code_playground_datasets"
  ON de_mobile_app.code_playground_datasets
  FOR SELECT TO public USING (true);

-- 3. Seed datasets (idempotent via ON CONFLICT on dataset_name)
DO $$
DECLARE
  ds_ecommerce UUID;
  ds_hr UUID;
  ds_events UUID;
  ds_transactions UUID;
  ds_python_records UUID;
  ds_python_events UUID;
  ds_python_nested UUID;
  ds_python_sales UUID;
BEGIN

  -- ── Dataset: E-Commerce (customers + orders + order_items) ──────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('E-Commerce', '{
    "customers": [
      {"customer_id": 1, "customer_name": "Alice Chen", "country": "US"},
      {"customer_id": 2, "customer_name": "Bob Martinez", "country": "MX"},
      {"customer_id": 3, "customer_name": "Sarah Kim", "country": "KR"},
      {"customer_id": 4, "customer_name": "David Lee", "country": "US"},
      {"customer_id": 5, "customer_name": "Emma Wilson", "country": "GB"},
      {"customer_id": 6, "customer_name": "Frank Nguyen", "country": "VN"},
      {"customer_id": 7, "customer_name": "Grace Patel", "country": "IN"}
    ],
    "orders": [
      {"order_id": 101, "customer_id": 1, "order_date": "2024-01-05", "amount": 250.00, "status": "completed"},
      {"order_id": 102, "customer_id": 1, "order_date": "2024-01-20", "amount": 180.50, "status": "completed"},
      {"order_id": 103, "customer_id": 2, "order_date": "2024-01-08", "amount": 320.00, "status": "completed"},
      {"order_id": 104, "customer_id": 3, "order_date": "2024-01-12", "amount": 95.00, "status": "completed"},
      {"order_id": 105, "customer_id": 4, "order_date": "2024-01-15", "amount": 410.00, "status": "completed"},
      {"order_id": 106, "customer_id": 1, "order_date": "2024-02-03", "amount": 130.00, "status": "completed"},
      {"order_id": 107, "customer_id": 2, "order_date": "2024-02-10", "amount": 275.00, "status": "completed"},
      {"order_id": 108, "customer_id": 5, "order_date": "2024-02-14", "amount": 520.00, "status": "completed"},
      {"order_id": 109, "customer_id": 6, "order_date": "2024-02-18", "amount": 88.00, "status": "completed"},
      {"order_id": 110, "customer_id": 3, "order_date": "2024-03-01", "amount": 340.00, "status": "completed"},
      {"order_id": 111, "customer_id": 1, "order_date": "2024-03-05", "amount": 210.00, "status": "completed"},
      {"order_id": 112, "customer_id": 4, "order_date": "2024-03-10", "amount": 175.00, "status": "completed"},
      {"order_id": 113, "customer_id": 7, "order_date": "2024-03-15", "amount": 460.00, "status": "completed"},
      {"order_id": 114, "customer_id": 2, "order_date": "2024-03-20", "amount": 90.00, "status": "cancelled"},
      {"order_id": 115, "customer_id": 5, "order_date": "2024-03-25", "amount": 310.00, "status": "completed"}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_ecommerce;

  IF ds_ecommerce IS NULL THEN
    SELECT dataset_id INTO ds_ecommerce FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'E-Commerce';
  END IF;

  -- ── Dataset: HR Employees ────────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('HR Employees', '{
    "employees": [
      {"emp_id": 1, "name": "Alice Chen", "dept": "Engineering", "salary": 95000, "hire_date": "2020-03-15", "manager_id": null},
      {"emp_id": 2, "name": "Bob Martinez", "dept": "Engineering", "salary": 88000, "hire_date": "2021-06-01", "manager_id": 1},
      {"emp_id": 3, "name": "Sarah Kim", "dept": "Marketing", "salary": 72000, "hire_date": "2019-11-20", "manager_id": null},
      {"emp_id": 4, "name": "David Lee", "dept": "Engineering", "salary": 91000, "hire_date": "2020-08-10", "manager_id": 1},
      {"emp_id": 5, "name": "Emma Wilson", "dept": "Marketing", "salary": 68000, "hire_date": "2022-01-05", "manager_id": 3},
      {"emp_id": 6, "name": "Frank Nguyen", "dept": "Sales", "salary": 65000, "hire_date": "2021-09-15", "manager_id": null},
      {"emp_id": 7, "name": "Grace Patel", "dept": "Sales", "salary": 70000, "hire_date": "2020-05-22", "manager_id": 6},
      {"emp_id": 8, "name": "Henry Brown", "dept": "Engineering", "salary": 85000, "hire_date": "2022-03-01", "manager_id": 1},
      {"emp_id": 9, "name": "Iris Zhang", "dept": "Marketing", "salary": 75000, "hire_date": "2021-07-14", "manager_id": 3},
      {"emp_id": 10, "name": "Jack Davis", "dept": "Sales", "salary": 62000, "hire_date": "2023-02-28", "manager_id": 6}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_hr;

  IF ds_hr IS NULL THEN
    SELECT dataset_id INTO ds_hr FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'HR Employees';
  END IF;

  -- ── Dataset: User Events ─────────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('User Events', '{
    "events": [
      {"event_id": "e001", "user_id": "u1", "event_type": "login", "ts": "2024-03-01 08:00:00", "session_id": "s1"},
      {"event_id": "e002", "user_id": "u1", "event_type": "page_view", "ts": "2024-03-01 08:02:00", "session_id": "s1"},
      {"event_id": "e003", "user_id": "u1", "event_type": "purchase", "ts": "2024-03-01 08:15:00", "session_id": "s1"},
      {"event_id": "e004", "user_id": "u1", "event_type": "logout", "ts": "2024-03-01 08:30:00", "session_id": "s1"},
      {"event_id": "e005", "user_id": "u2", "event_type": "login", "ts": "2024-03-01 09:00:00", "session_id": "s2"},
      {"event_id": "e006", "user_id": "u2", "event_type": "page_view", "ts": "2024-03-01 09:05:00", "session_id": "s2"},
      {"event_id": "e007", "user_id": "u1", "event_type": "login", "ts": "2024-03-02 10:00:00", "session_id": "s3"},
      {"event_id": "e008", "user_id": "u1", "event_type": "page_view", "ts": "2024-03-02 10:03:00", "session_id": "s3"},
      {"event_id": "e009", "user_id": "u3", "event_type": "login", "ts": "2024-03-02 11:00:00", "session_id": "s4"},
      {"event_id": "e010", "user_id": "u2", "event_type": "login", "ts": "2024-03-03 14:00:00", "session_id": "s5"},
      {"event_id": "e011", "user_id": "u2", "event_type": "purchase", "ts": "2024-03-03 14:20:00", "session_id": "s5"},
      {"event_id": "e012", "user_id": "u2", "event_type": "logout", "ts": "2024-03-03 14:45:00", "session_id": "s5"}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_events;

  IF ds_events IS NULL THEN
    SELECT dataset_id INTO ds_events FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'User Events';
  END IF;

  -- ── Dataset: Transactions ────────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('Transactions', '{
    "transactions": [
      {"txn_id": 1, "account_id": "A1", "txn_date": "2024-01-05", "amount": 100.00, "type": "credit"},
      {"txn_id": 2, "account_id": "A1", "txn_date": "2024-01-10", "amount": 250.00, "type": "credit"},
      {"txn_id": 3, "account_id": "A1", "txn_date": "2024-01-15", "amount": -80.00, "type": "debit"},
      {"txn_id": 4, "account_id": "A2", "txn_date": "2024-01-07", "amount": 500.00, "type": "credit"},
      {"txn_id": 5, "account_id": "A2", "txn_date": "2024-01-20", "amount": -200.00, "type": "debit"},
      {"txn_id": 6, "account_id": "A1", "txn_date": "2024-02-01", "amount": 300.00, "type": "credit"},
      {"txn_id": 7, "account_id": "A1", "txn_date": "2024-02-10", "amount": -150.00, "type": "debit"},
      {"txn_id": 8, "account_id": "A2", "txn_date": "2024-02-05", "amount": 400.00, "type": "credit"},
      {"txn_id": 9, "account_id": "A3", "txn_date": "2024-02-08", "amount": 750.00, "type": "credit"},
      {"txn_id": 10, "account_id": "A3", "txn_date": "2024-02-15", "amount": -300.00, "type": "debit"}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_transactions;

  IF ds_transactions IS NULL THEN
    SELECT dataset_id INTO ds_transactions FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'Transactions';
  END IF;

  -- ── Dataset: Python Records ──────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('Python Records', '{
    "records": [
      {"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"},
      {"id": 2, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"},
      {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"},
      {"id": 4, "user_id": "u3", "name": "Carol", "email": null, "age": null, "score": 85.0, "status": "inactive"},
      {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": null, "status": "active"},
      {"id": 6, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"},
      {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active"},
      {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": null, "score": 60.0, "status": "inactive"}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_python_records;

  IF ds_python_records IS NULL THEN
    SELECT dataset_id INTO ds_python_records FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'Python Records';
  END IF;

  -- ── Dataset: Python Events ───────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('Python Events', '{
    "events": [
      {"event_id": "e001", "user_id": "u1", "event_type": "click", "timestamp": "2024-03-01T08:00:00", "properties": {"page": "home", "button": "signup"}},
      {"event_id": "e002", "user_id": "u1", "event_type": "purchase", "timestamp": "2024-03-01T08:15:00", "properties": {"item_id": "p1", "amount": 49.99}},
      {"event_id": "e003", "user_id": "u2", "event_type": "click", "timestamp": "2024-03-01T09:00:00", "properties": {"page": "product", "button": "add_to_cart"}},
      {"event_id": "e004", "user_id": "u1", "event_type": "click", "timestamp": "2024-03-02T10:00:00", "properties": {"page": "checkout", "button": "pay"}},
      {"event_id": "e005", "user_id": "u3", "event_type": "purchase", "timestamp": "2024-03-02T11:30:00", "properties": {"item_id": "p2", "amount": 129.00}},
      {"event_id": "e006", "user_id": "u2", "event_type": "purchase", "timestamp": "2024-03-03T14:00:00", "properties": {"item_id": "p1", "amount": 49.99}},
      {"event_id": "e001", "user_id": "u1", "event_type": "click", "timestamp": "2024-03-01T08:00:00", "properties": {"page": "home", "button": "signup"}}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_python_events;

  IF ds_python_events IS NULL THEN
    SELECT dataset_id INTO ds_python_events FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'Python Events';
  END IF;

  -- ── Dataset: Nested JSON ─────────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('Nested JSON', '{
    "api_response": {
      "status": "ok",
      "data": {
        "users": [
          {"id": "u1", "profile": {"name": "Alice", "age": 28}, "orders": [{"order_id": "o1", "total": 250.00}, {"order_id": "o2", "total": 180.50}]},
          {"id": "u2", "profile": {"name": "Bob", "age": 35}, "orders": [{"order_id": "o3", "total": 320.00}]},
          {"id": "u3", "profile": {"name": "Carol", "age": 31}, "orders": []},
          {"id": "u4", "profile": {"name": "Dave", "age": 42}, "orders": [{"order_id": "o4", "total": 95.00}, {"order_id": "o5", "total": 410.00}]}
        ]
      }
    }
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_python_nested;

  IF ds_python_nested IS NULL THEN
    SELECT dataset_id INTO ds_python_nested FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'Nested JSON';
  END IF;

  -- ── Dataset: Sales Monthly ───────────────────────────────────────────────
  INSERT INTO de_mobile_app.code_playground_datasets (dataset_name, dataset)
  VALUES ('Sales Monthly', '{
    "sales": [
      {"month": "2024-01", "region": "North", "revenue": 45000, "units": 120},
      {"month": "2024-01", "region": "South", "revenue": 38000, "units": 95},
      {"month": "2024-02", "region": "North", "revenue": 52000, "units": 140},
      {"month": "2024-02", "region": "South", "revenue": 41000, "units": 105},
      {"month": "2024-03", "region": "North", "revenue": 48000, "units": 130},
      {"month": "2024-03", "region": "South", "revenue": 55000, "units": 148},
      {"month": "2024-04", "region": "North", "revenue": 61000, "units": 165},
      {"month": "2024-04", "region": "South", "revenue": 49000, "units": 128}
    ]
  }'::jsonb)
  ON CONFLICT (dataset_name) DO NOTHING
  RETURNING dataset_id INTO ds_python_sales;

  IF ds_python_sales IS NULL THEN
    SELECT dataset_id INTO ds_python_sales FROM de_mobile_app.code_playground_datasets WHERE dataset_name = 'Sales Monthly';
  END IF;

  -- ====================================================================
  -- SQL CHALLENGES (10)
  -- ====================================================================

  -- SQL 1: Top Customers by Revenue
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_ecommerce,
    'Top Customers by Revenue',
    'Find the top 5 customers by total revenue from completed orders. Return customer_id, customer_name, and total_revenue ordered by total_revenue descending.',
    'SQL', 'Junior',
    E'-- Find the top 5 customers by total revenue\n-- Join customers with orders, filter completed orders\n-- Group by customer and sum the amounts\n\nSELECT\n  -- your query here\nFROM orders o\nJOIN customers c ON o.customer_id = c.customer_id\nWHERE o.status = ''completed''\n-- add GROUP BY, ORDER BY, LIMIT',
    E'SELECT\n  c.customer_id,\n  c.customer_name,\n  SUM(o.amount) AS total_revenue\nFROM orders o\nJOIN customers c ON o.customer_id = c.customer_id\nWHERE o.status = ''completed''\nGROUP BY c.customer_id, c.customer_name\nORDER BY total_revenue DESC\nLIMIT 5;',
    'Join orders to customers, filter for completed status, group by customer, sum amounts, and order descending. LIMIT 5 returns only the top results.',
    '{"type": "sql_result", "check_columns": ["customer_id", "customer_name", "total_revenue"], "expected_row_count": 5, "order_matters": true, "expected_result": [{"customer_id": 1, "customer_name": "Alice Chen", "total_revenue": 770.5}, {"customer_id": 4, "customer_name": "David Lee", "total_revenue": 585.0}, {"customer_id": 2, "customer_name": "Bob Martinez", "total_revenue": 595.0}, {"customer_id": 5, "customer_name": "Emma Wilson", "total_revenue": 830.0}, {"customer_id": 3, "customer_name": "Sarah Kim", "total_revenue": 435.0}]}'::jsonb,
    ARRAY['Use SUM() with GROUP BY to aggregate revenue per customer', 'Filter with WHERE status = ''completed'' before grouping', 'ORDER BY total_revenue DESC puts the highest first', 'LIMIT 5 returns only the top 5 rows']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Top Customers by Revenue'
  );

  -- SQL 2: Running Total
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_transactions,
    'Running Balance per Account',
    'Calculate the running balance for each account ordered by transaction date. Return account_id, txn_date, amount, and running_balance.',
    'SQL', 'Middle',
    E'-- Calculate running balance using a window function\n-- The running balance is the cumulative sum of amounts\n-- ordered by date within each account\n\nSELECT\n  account_id,\n  txn_date,\n  amount,\n  -- add your window function here\nFROM transactions\nORDER BY account_id, txn_date;',
    E'SELECT\n  account_id,\n  txn_date,\n  amount,\n  SUM(amount) OVER (\n    PARTITION BY account_id\n    ORDER BY txn_date\n    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW\n  ) AS running_balance\nFROM transactions\nORDER BY account_id, txn_date;',
    'SUM() OVER with PARTITION BY account_id resets the running total per account. ORDER BY txn_date inside the window determines the accumulation order. ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW is the standard frame for running totals.',
    '{"type": "sql_result", "check_columns": ["account_id", "txn_date", "amount", "running_balance"], "order_matters": true, "expected_row_count": 10}'::jsonb,
    ARRAY['SUM() OVER() is a window function — it does not collapse rows like GROUP BY', 'PARTITION BY resets the running total for each account', 'ORDER BY inside OVER() controls the accumulation order', 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW is the explicit frame for running totals']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Running Balance per Account'
  );

  -- SQL 3: Deduplication with ROW_NUMBER
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_ecommerce,
    'Deduplicate Orders per Customer',
    'Each customer should appear only once. Keep only the most recent order per customer. Return customer_id and their latest order_id and order_date.',
    'SQL', 'Middle',
    E'-- Use ROW_NUMBER() to rank orders per customer by date\n-- Then filter to keep only rank = 1 (most recent)\n\nWITH ranked AS (\n  SELECT\n    customer_id,\n    order_id,\n    order_date,\n    -- add ROW_NUMBER() here\n  FROM orders\n  WHERE status = ''completed''\n)\nSELECT customer_id, order_id, order_date\nFROM ranked\nWHERE rn = 1;',
    E'WITH ranked AS (\n  SELECT\n    customer_id,\n    order_id,\n    order_date,\n    ROW_NUMBER() OVER (\n      PARTITION BY customer_id\n      ORDER BY order_date DESC\n    ) AS rn\n  FROM orders\n  WHERE status = ''completed''\n)\nSELECT customer_id, order_id, order_date\nFROM ranked\nWHERE rn = 1\nORDER BY customer_id;',
    'ROW_NUMBER() assigns a sequential rank within each customer partition, ordered by date descending so the most recent order gets rank 1. Filtering WHERE rn = 1 in the outer query keeps only the latest order per customer.',
    '{"type": "sql_result", "check_columns": ["customer_id", "order_id", "order_date"], "order_matters": false, "expected_row_count": 7}'::jsonb,
    ARRAY['ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) ranks orders newest-first per customer', 'Wrap in a CTE, then filter WHERE rn = 1 in the outer SELECT', 'This pattern is the standard deduplication technique in SQL']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Deduplicate Orders per Customer'
  );

  -- SQL 4: Highest Paid per Department
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_hr,
    'Highest Paid Employee per Department',
    'Find the highest-paid employee in each department. Return dept, name, and salary. If there is a tie, return all tied employees.',
    'SQL', 'Junior',
    E'-- Use RANK() or DENSE_RANK() to find the top salary per department\n\nWITH ranked AS (\n  SELECT\n    dept,\n    name,\n    salary,\n    -- add your ranking window function here\n  FROM employees\n)\nSELECT dept, name, salary\nFROM ranked\nWHERE rnk = 1\nORDER BY dept;',
    E'WITH ranked AS (\n  SELECT\n    dept,\n    name,\n    salary,\n    DENSE_RANK() OVER (\n      PARTITION BY dept\n      ORDER BY salary DESC\n    ) AS rnk\n  FROM employees\n)\nSELECT dept, name, salary\nFROM ranked\nWHERE rnk = 1\nORDER BY dept;',
    'DENSE_RANK() handles ties by assigning the same rank to equal salaries. PARTITION BY dept resets the ranking per department. Filtering WHERE rnk = 1 returns the top earner(s) per department.',
    '{"type": "sql_result", "check_columns": ["dept", "name", "salary"], "order_matters": false, "expected_row_count": 3}'::jsonb,
    ARRAY['DENSE_RANK() vs ROW_NUMBER(): DENSE_RANK handles ties, ROW_NUMBER does not', 'PARTITION BY dept resets the rank counter for each department', 'Filter WHERE rnk = 1 in the outer query after the CTE']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Highest Paid Employee per Department'
  );

  -- SQL 5: Month-over-Month Growth
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_sales,
    'Month-over-Month Revenue Growth',
    'Calculate the month-over-month revenue growth percentage for the North region. Return month, revenue, prev_revenue, and growth_pct rounded to 2 decimal places.',
    'SQL', 'Middle',
    E'-- Use LAG() to access the previous month revenue\n-- Calculate growth as (current - previous) / previous * 100\n\nSELECT\n  month,\n  revenue,\n  -- add LAG() window function for prev_revenue\n  -- calculate growth_pct\nFROM sales\nWHERE region = ''North''\nORDER BY month;',
    E'SELECT\n  month,\n  revenue,\n  LAG(revenue) OVER (ORDER BY month) AS prev_revenue,\n  ROUND(\n    (revenue - LAG(revenue) OVER (ORDER BY month))::numeric\n    / LAG(revenue) OVER (ORDER BY month) * 100,\n    2\n  ) AS growth_pct\nFROM sales\nWHERE region = ''North''\nORDER BY month;',
    'LAG(revenue) OVER (ORDER BY month) retrieves the previous row''s revenue value. The growth formula is (current - previous) / previous * 100. The first row will have NULL for prev_revenue and growth_pct since there is no prior month.',
    '{"type": "sql_result", "check_columns": ["month", "revenue", "prev_revenue", "growth_pct"], "order_matters": true, "expected_row_count": 4}'::jsonb,
    ARRAY['LAG(col) OVER (ORDER BY date) returns the value from the previous row', 'Growth formula: (current - previous) / previous * 100', 'The first row will have NULL for prev_revenue — that is expected', 'Cast to numeric before division to avoid integer truncation']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Month-over-Month Revenue Growth'
  );

  -- SQL 6: Sessionization
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_events,
    'Count Events per Session',
    'Count the number of events in each session. Return session_id, user_id, and event_count ordered by session_id.',
    'SQL', 'Junior',
    E'-- Count events grouped by session\n-- Each row in the events table belongs to a session_id\n\nSELECT\n  session_id,\n  user_id,\n  -- count events here\nFROM events\nGROUP BY session_id, user_id\nORDER BY session_id;',
    E'SELECT\n  session_id,\n  user_id,\n  COUNT(*) AS event_count\nFROM events\nGROUP BY session_id, user_id\nORDER BY session_id;',
    'Simple GROUP BY aggregation. COUNT(*) counts all rows per group. Including user_id in GROUP BY is necessary because it is selected but not aggregated.',
    '{"type": "sql_result", "check_columns": ["session_id", "user_id", "event_count"], "order_matters": true, "expected_row_count": 5}'::jsonb,
    ARRAY['GROUP BY session_id, user_id groups all events belonging to the same session', 'COUNT(*) counts every row in the group regardless of NULLs', 'Include all non-aggregated SELECT columns in GROUP BY']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Count Events per Session'
  );

  -- SQL 7: Rolling 3-Month Average
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_sales,
    'Rolling 3-Month Revenue Average',
    'Calculate the 3-month rolling average revenue for the South region. Return month, revenue, and rolling_avg_3m rounded to 2 decimal places.',
    'SQL', 'Senior',
    E'-- Use AVG() with a window frame to compute a rolling average\n-- The frame should include the current row and 2 preceding rows\n\nSELECT\n  month,\n  revenue,\n  -- add rolling average window function here\nFROM sales\nWHERE region = ''South''\nORDER BY month;',
    E'SELECT\n  month,\n  revenue,\n  ROUND(\n    AVG(revenue::numeric) OVER (\n      ORDER BY month\n      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW\n    ),\n    2\n  ) AS rolling_avg_3m\nFROM sales\nWHERE region = ''South''\nORDER BY month;',
    'AVG() OVER with ROWS BETWEEN 2 PRECEDING AND CURRENT ROW creates a sliding window of up to 3 rows. For the first two rows, the average is computed over fewer rows since there are not enough preceding rows.',
    '{"type": "sql_result", "check_columns": ["month", "revenue", "rolling_avg_3m"], "order_matters": true, "expected_row_count": 4}'::jsonb,
    ARRAY['ROWS BETWEEN 2 PRECEDING AND CURRENT ROW defines a 3-row sliding window', 'The first row average is just itself; the second row averages 2 rows', 'Cast to numeric before AVG to avoid integer arithmetic', 'This pattern is used for smoothing time-series data']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Rolling 3-Month Revenue Average'
  );

  -- SQL 8: Inactive Customers
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_ecommerce,
    'Find Customers with No Orders in 2024-03',
    'Find customers who placed at least one order before March 2024 but placed no completed orders in March 2024. Return customer_id and customer_name.',
    'SQL', 'Middle',
    E'-- Find customers active before March 2024 but absent in March 2024\n-- Use NOT EXISTS or LEFT JOIN with NULL check\n\nSELECT c.customer_id, c.customer_name\nFROM customers c\nWHERE EXISTS (\n  -- had an order before March 2024\n  SELECT 1 FROM orders o\n  WHERE o.customer_id = c.customer_id\n    AND o.order_date < ''2024-03-01''\n)\nAND NOT EXISTS (\n  -- no completed order in March 2024\n  -- add your condition here\n);',
    E'SELECT c.customer_id, c.customer_name\nFROM customers c\nWHERE EXISTS (\n  SELECT 1 FROM orders o\n  WHERE o.customer_id = c.customer_id\n    AND o.order_date < ''2024-03-01''\n)\nAND NOT EXISTS (\n  SELECT 1 FROM orders o\n  WHERE o.customer_id = c.customer_id\n    AND o.order_date >= ''2024-03-01''\n    AND o.order_date < ''2024-04-01''\n    AND o.status = ''completed''\n)\nORDER BY c.customer_id;',
    'EXISTS checks if a subquery returns any rows. NOT EXISTS returns true when the subquery returns no rows. This pattern efficiently finds customers present in one time window but absent in another.',
    '{"type": "sql_result", "check_columns": ["customer_id", "customer_name"], "order_matters": false, "expected_row_count": 3}'::jsonb,
    ARRAY['EXISTS / NOT EXISTS is more readable than LEFT JOIN + IS NULL for this pattern', 'Filter the inner subquery by both date range and status', 'Customers with only cancelled orders in March should still count as inactive']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Find Customers with No Orders in 2024-03'
  );

  -- SQL 9: Salary Percentile
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_hr,
    'Employee Salary Percentile Rank',
    'Calculate the percentile rank of each employee''s salary within their department. Return name, dept, salary, and salary_percentile rounded to 2 decimal places.',
    'SQL', 'Senior',
    E'-- Use PERCENT_RANK() to compute the percentile rank\n-- PERCENT_RANK returns a value between 0 and 1\n\nSELECT\n  name,\n  dept,\n  salary,\n  -- add PERCENT_RANK() window function here\nFROM employees\nORDER BY dept, salary DESC;',
    E'SELECT\n  name,\n  dept,\n  salary,\n  ROUND(\n    PERCENT_RANK() OVER (\n      PARTITION BY dept\n      ORDER BY salary\n    )::numeric,\n    2\n  ) AS salary_percentile\nFROM employees\nORDER BY dept, salary DESC;',
    'PERCENT_RANK() returns the relative rank of a row as a fraction between 0 and 1. The lowest salary in each department gets 0.0. PARTITION BY dept ensures the percentile is computed within each department independently.',
    '{"type": "sql_result", "check_columns": ["name", "dept", "salary", "salary_percentile"], "order_matters": false, "expected_row_count": 10}'::jsonb,
    ARRAY['PERCENT_RANK() = (rank - 1) / (total_rows - 1)', 'PARTITION BY dept computes the percentile within each department', 'The lowest value in each partition always gets 0.0', 'Cast to numeric before ROUND to avoid type errors']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Employee Salary Percentile Rank'
  );

  -- SQL 10: Purchase Funnel
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_events,
    'User Purchase Funnel',
    'Count distinct users at each funnel stage: login, page_view, and purchase. Return event_type and user_count ordered by user_count descending.',
    'SQL', 'Junior',
    E'-- Count distinct users per event type to build a funnel\n-- Filter for the three funnel stages: login, page_view, purchase\n\nSELECT\n  event_type,\n  -- count distinct users here\nFROM events\nWHERE event_type IN (''login'', ''page_view'', ''purchase'')\nGROUP BY event_type\nORDER BY user_count DESC;',
    E'SELECT\n  event_type,\n  COUNT(DISTINCT user_id) AS user_count\nFROM events\nWHERE event_type IN (''login'', ''page_view'', ''purchase'')\nGROUP BY event_type\nORDER BY user_count DESC;',
    'COUNT(DISTINCT user_id) counts unique users rather than total events. Filtering by event_type IN (...) limits the funnel to the relevant stages. Ordering by user_count DESC shows the widest funnel stage first.',
    '{"type": "sql_result", "check_columns": ["event_type", "user_count"], "order_matters": true, "expected_row_count": 3}'::jsonb,
    ARRAY['COUNT(DISTINCT user_id) counts unique users, not total event rows', 'Use WHERE event_type IN (...) to filter only funnel stages', 'A funnel typically shows decreasing counts from awareness to conversion']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'User Purchase Funnel'
  );

  -- ====================================================================
  -- PYTHON CHALLENGES (10)
  -- ====================================================================

  -- Python 1: Deduplicate Records
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_records,
    'Deduplicate User Records',
    'Remove duplicate records from the list. A duplicate is a record with the same user_id. Keep the record with the lowest id. Return a list of unique records sorted by id.',
    'Python', 'Junior',
    E'# The dataset is available as: data["records"]\n# Each record has: id, user_id, name, email, age, score, status\n\ndef deduplicate(records):\n    seen = set()\n    result = []\n    # iterate records sorted by id\n    # keep first occurrence of each user_id\n    for record in sorted(records, key=lambda r: r["id"]):\n        pass  # your logic here\n    return result\n\nresult = deduplicate(data["records"])\nprint(result)',
    E'def deduplicate(records):\n    seen = set()\n    result = []\n    for record in sorted(records, key=lambda r: r["id"]):\n        if record["user_id"] not in seen:\n            seen.add(record["user_id"])\n            result.append(record)\n    return result\n\nresult = deduplicate(data["records"])\nprint(result)',
    'Sort records by id ascending so the lowest id comes first. Use a set to track seen user_ids. Skip any record whose user_id is already in the set. This keeps the first (lowest id) occurrence of each user.',
    '{"type": "python_output", "check_type": "list_length", "expected_length": 6, "check_field": "user_id", "unique_field": true}'::jsonb,
    ARRAY['Sort by id first so you always keep the record with the lowest id', 'Use a set() to track which user_ids you have already seen', 'Append to result only when user_id is NOT in the seen set']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Deduplicate User Records'
  );

  -- Python 2: Handle Missing Values
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_records,
    'Handle Missing Values',
    'Clean the records by filling missing values: replace null email with "unknown@example.com", replace null age with 0, replace null score with the average score of non-null records. Return the cleaned list.',
    'Python', 'Junior',
    E'# The dataset is available as: data["records"]\n\ndef clean_records(records):\n    # Step 1: compute average score from non-null scores\n    scores = [r["score"] for r in records if r["score"] is not None]\n    avg_score = sum(scores) / len(scores) if scores else 0\n    \n    cleaned = []\n    for r in records:\n        rec = dict(r)  # copy\n        # fill missing email\n        # fill missing age\n        # fill missing score\n        cleaned.append(rec)\n    return cleaned\n\nresult = clean_records(data["records"])\nprint(result)',
    E'def clean_records(records):\n    scores = [r["score"] for r in records if r["score"] is not None]\n    avg_score = round(sum(scores) / len(scores), 2) if scores else 0\n    \n    cleaned = []\n    for r in records:\n        rec = dict(r)\n        rec["email"] = rec["email"] if rec["email"] is not None else "unknown@example.com"\n        rec["age"] = rec["age"] if rec["age"] is not None else 0\n        rec["score"] = rec["score"] if rec["score"] is not None else avg_score\n        cleaned.append(rec)\n    return cleaned\n\nresult = clean_records(data["records"])\nprint(result)',
    'Compute the average score first from non-null values. Then iterate records, copy each dict, and replace None values with the appropriate defaults. Using dict(r) creates a shallow copy so the original data is not mutated.',
    '{"type": "python_output", "check_type": "no_nulls", "fields": ["email", "age", "score"], "expected_length": 8}'::jsonb,
    ARRAY['Compute average score before the loop so you only iterate once', 'Use dict(r) to copy each record — never mutate the original list', 'Check for None explicitly: r["field"] is not None']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Handle Missing Values'
  );

  -- Python 3: Aggregate Records
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_records,
    'Aggregate Records by Status',
    'Group the records by status and compute: count, average score (rounded to 2 decimal places), and list of unique user_ids. Return a dict keyed by status.',
    'Python', 'Junior',
    E'# The dataset is available as: data["records"]\n\ndef aggregate_by_status(records):\n    result = {}\n    for r in records:\n        status = r["status"]\n        if status not in result:\n            result[status] = {"count": 0, "scores": [], "user_ids": set()}\n        # update count, scores, user_ids\n    \n    # convert to final format\n    return {\n        s: {\n            "count": v["count"],\n            "avg_score": round(sum(v["scores"]) / len(v["scores"]), 2) if v["scores"] else 0,\n            "unique_users": len(v["user_ids"])\n        }\n        for s, v in result.items()\n    }\n\nresult = aggregate_by_status(data["records"])\nprint(result)',
    E'def aggregate_by_status(records):\n    result = {}\n    for r in records:\n        status = r["status"]\n        if status not in result:\n            result[status] = {"count": 0, "scores": [], "user_ids": set()}\n        result[status]["count"] += 1\n        if r["score"] is not None:\n            result[status]["scores"].append(r["score"])\n        result[status]["user_ids"].add(r["user_id"])\n    \n    return {\n        s: {\n            "count": v["count"],\n            "avg_score": round(sum(v["scores"]) / len(v["scores"]), 2) if v["scores"] else 0,\n            "unique_users": len(v["user_ids"])\n        }\n        for s, v in result.items()\n    }\n\nresult = aggregate_by_status(data["records"])\nprint(result)',
    'Use a dict to accumulate counts, score lists, and user_id sets per status. A set automatically deduplicates user_ids. After the loop, compute averages and convert sets to counts in a dict comprehension.',
    '{"type": "python_output", "check_type": "dict_keys", "expected_keys": ["active", "inactive"]}'::jsonb,
    ARRAY['Use a dict of dicts to accumulate per-group statistics', 'A set() automatically deduplicates — use it for unique user_ids', 'Guard against None scores before appending to the scores list', 'Dict comprehensions are clean for the final transformation step']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Aggregate Records by Status'
  );

  -- Python 4: Transform Nested JSON
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_nested,
    'Flatten Nested JSON to Tabular Records',
    'Transform the nested API response into a flat list of records. Each output record should have: user_id, name, age, order_id, order_total. Users with no orders should produce one record with null order fields.',
    'Python', 'Middle',
    E'# The dataset is available as: data["api_response"]\n# Navigate: data["api_response"]["data"]["users"]\n\ndef flatten_users(api_response):\n    users = api_response["data"]["users"]\n    result = []\n    for user in users:\n        user_id = user["id"]\n        name = user["profile"]["name"]\n        age = user["profile"]["age"]\n        orders = user["orders"]\n        if not orders:\n            # append one record with null order fields\n            pass\n        else:\n            for order in orders:\n                # append one record per order\n                pass\n    return result\n\nresult = flatten_users(data["api_response"])\nprint(result)',
    E'def flatten_users(api_response):\n    users = api_response["data"]["users"]\n    result = []\n    for user in users:\n        user_id = user["id"]\n        name = user["profile"]["name"]\n        age = user["profile"]["age"]\n        orders = user["orders"]\n        if not orders:\n            result.append({"user_id": user_id, "name": name, "age": age, "order_id": None, "order_total": None})\n        else:\n            for order in orders:\n                result.append({"user_id": user_id, "name": name, "age": age, "order_id": order["order_id"], "order_total": order["total"]})\n    return result\n\nresult = flatten_users(data["api_response"])\nprint(result)',
    'Navigate the nested structure to reach the users list. For each user, extract profile fields. If the user has no orders, emit one row with None for order fields. If the user has orders, emit one row per order — this is a one-to-many expansion.',
    '{"type": "python_output", "check_type": "list_length", "expected_length": 6}'::jsonb,
    ARRAY['Navigate nested dicts with chained key access: obj["key1"]["key2"]', 'Users with no orders should still produce one row with None order fields', 'One-to-many expansion: one user with 2 orders produces 2 output rows', 'Use a flat list and append() for each output row']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Flatten Nested JSON to Tabular Records'
  );

  -- Python 5: Detect Duplicate Events
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_events,
    'Detect Duplicate Events',
    'Find all duplicate events in the list. A duplicate is an event with the same event_id appearing more than once. Return a list of duplicate event_ids.',
    'Python', 'Junior',
    E'# The dataset is available as: data["events"]\n# Each event has: event_id, user_id, event_type, timestamp, properties\n\ndef find_duplicates(events):\n    counts = {}\n    for event in events:\n        eid = event["event_id"]\n        counts[eid] = counts.get(eid, 0) + 1\n    # return list of event_ids that appear more than once\n    return []\n\nresult = find_duplicates(data["events"])\nprint(result)',
    E'def find_duplicates(events):\n    counts = {}\n    for event in events:\n        eid = event["event_id"]\n        counts[eid] = counts.get(eid, 0) + 1\n    return [eid for eid, cnt in counts.items() if cnt > 1]\n\nresult = find_duplicates(data["events"])\nprint(result)',
    'Count occurrences of each event_id using a dict. dict.get(key, 0) safely returns 0 for missing keys. After counting, filter to keys with count > 1 using a list comprehension.',
    '{"type": "python_output", "check_type": "list_length", "expected_length": 1}'::jsonb,
    ARRAY['Use dict.get(key, 0) to safely increment a counter', 'A list comprehension filters the counts dict in one line', 'This pattern generalises to any deduplication check by key']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Detect Duplicate Events'
  );

  -- Python 6: Parse Event Data
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_events,
    'Extract Purchase Events',
    'Filter the events list to return only purchase events. For each purchase event, extract: user_id, timestamp, item_id (from properties), and amount (from properties). Return a list of dicts.',
    'Python', 'Junior',
    E'# The dataset is available as: data["events"]\n# properties dict contains: page, button, item_id, amount (varies by event type)\n\ndef extract_purchases(events):\n    result = []\n    for event in events:\n        if event["event_type"] == "purchase":\n            props = event["properties"]\n            result.append({\n                "user_id": event["user_id"],\n                "timestamp": event["timestamp"],\n                "item_id": props.get("item_id"),\n                "amount": props.get("amount")\n            })\n    return result\n\nresult = extract_purchases(data["events"])\nprint(result)',
    E'def extract_purchases(events):\n    result = []\n    for event in events:\n        if event["event_type"] == "purchase":\n            props = event["properties"]\n            result.append({\n                "user_id": event["user_id"],\n                "timestamp": event["timestamp"],\n                "item_id": props.get("item_id"),\n                "amount": props.get("amount")\n            })\n    return result\n\nresult = extract_purchases(data["events"])\nprint(result)',
    'Filter events by event_type == "purchase". Access nested properties using dict.get() which returns None if the key is missing — safer than direct key access. Build a flat dict for each purchase event.',
    '{"type": "python_output", "check_type": "list_length", "expected_length": 3}'::jsonb,
    ARRAY['Filter with if event["event_type"] == "purchase"', 'Use dict.get("key") instead of dict["key"] for optional fields', 'Properties vary by event type — always use .get() for nested fields']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Extract Purchase Events'
  );

  -- Python 7: ETL Transformation
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_sales,
    'ETL: Normalize and Enrich Sales Records',
    'Transform the sales records: add a revenue_per_unit column (revenue / units, rounded to 2 decimals), convert month to a date string "YYYY-MM-01", and filter out records where units is 0. Return the transformed list.',
    'Python', 'Middle',
    E'# The dataset is available as: data["sales"]\n# Each record: month (YYYY-MM), region, revenue, units\n\ndef transform_sales(sales):\n    result = []\n    for record in sales:\n        if record["units"] == 0:\n            continue  # skip zero-unit records\n        transformed = dict(record)\n        # add revenue_per_unit\n        # convert month to date string\n        result.append(transformed)\n    return result\n\nresult = transform_sales(data["sales"])\nprint(result)',
    E'def transform_sales(sales):\n    result = []\n    for record in sales:\n        if record["units"] == 0:\n            continue\n        transformed = dict(record)\n        transformed["revenue_per_unit"] = round(record["revenue"] / record["units"], 2)\n        transformed["month"] = record["month"] + "-01"\n        result.append(transformed)\n    return result\n\nresult = transform_sales(data["sales"])\nprint(result)',
    'This is a standard ETL transformation: filter (skip zero units), enrich (add derived column), and reshape (convert month format). Using dict(record) copies the record so the original is not mutated.',
    '{"type": "python_output", "check_type": "list_length", "expected_length": 8, "check_field": "revenue_per_unit", "field_exists": true}'::jsonb,
    ARRAY['dict(record) creates a shallow copy — always copy before mutating', 'String concatenation "YYYY-MM" + "-01" produces a valid date string', 'Guard against division by zero with an if check before dividing', 'This Extract-Transform-Load pattern is the foundation of data pipelines']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'ETL: Normalize and Enrich Sales Records'
  );

  -- Python 8: Validate Records
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_records,
    'Validate and Classify Records',
    'Validate each record and classify it as "valid" or "invalid". A record is invalid if: email is null, age is null or negative, or score is outside 0-100. Return a list of dicts with all original fields plus a "validation_status" field.',
    'Python', 'Middle',
    E'# The dataset is available as: data["records"]\n\ndef validate_records(records):\n    result = []\n    for r in records:\n        rec = dict(r)\n        is_valid = True\n        # check email\n        # check age\n        # check score\n        rec["validation_status"] = "valid" if is_valid else "invalid"\n        result.append(rec)\n    return result\n\nresult = validate_records(data["records"])\nprint(result)',
    E'def validate_records(records):\n    result = []\n    for r in records:\n        rec = dict(r)\n        is_valid = (\n            rec["email"] is not None\n            and rec["age"] is not None\n            and rec["age"] >= 0\n            and rec["score"] is not None\n            and 0 <= rec["score"] <= 100\n        )\n        rec["validation_status"] = "valid" if is_valid else "invalid"\n        result.append(rec)\n    return result\n\nresult = validate_records(data["records"])\nprint(result)',
    'Chain all validation conditions with and. Python short-circuits: if email is None, the remaining conditions are not evaluated. The ternary expression assigns "valid" or "invalid" based on the boolean result.',
    '{"type": "python_output", "check_type": "field_exists", "field": "validation_status", "expected_length": 8}'::jsonb,
    ARRAY['Chain conditions with and — Python short-circuits on the first False', 'Check for None before comparing numeric values to avoid TypeError', 'Use a ternary: "valid" if condition else "invalid"', 'Always copy the record with dict(r) before adding new fields']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Validate and Classify Records'
  );

  -- Python 9: Compute Revenue per User
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_events,
    'Compute Total Purchase Revenue per User',
    'From the events list, compute the total purchase revenue per user. Only include purchase events. Return a list of dicts with user_id and total_revenue (rounded to 2 decimals), sorted by total_revenue descending.',
    'Python', 'Middle',
    E'# The dataset is available as: data["events"]\n# Purchase events have properties["amount"]\n\ndef revenue_per_user(events):\n    totals = {}\n    for event in events:\n        if event["event_type"] == "purchase":\n            uid = event["user_id"]\n            amount = event["properties"].get("amount", 0)\n            totals[uid] = totals.get(uid, 0) + amount\n    # convert to sorted list of dicts\n    return []\n\nresult = revenue_per_user(data["events"])\nprint(result)',
    E'def revenue_per_user(events):\n    totals = {}\n    for event in events:\n        if event["event_type"] == "purchase":\n            uid = event["user_id"]\n            amount = event["properties"].get("amount", 0)\n            totals[uid] = totals.get(uid, 0) + amount\n    return sorted(\n        [{"user_id": uid, "total_revenue": round(rev, 2)} for uid, rev in totals.items()],\n        key=lambda x: x["total_revenue"],\n        reverse=True\n    )\n\nresult = revenue_per_user(data["events"])\nprint(result)',
    'Accumulate revenue per user_id in a dict using dict.get(key, 0) for safe increment. After the loop, convert the dict to a list of dicts using a list comprehension, then sort by total_revenue descending using sorted() with reverse=True.',
    '{"type": "python_output", "check_type": "list_length", "expected_length": 3}'::jsonb,
    ARRAY['Use dict.get(uid, 0) to safely accumulate without KeyError', 'sorted() with key=lambda x: x["field"] and reverse=True sorts descending', 'List comprehension converts a dict to a list of dicts in one line']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Compute Total Purchase Revenue per User'
  );

  -- Python 10: Month-over-Month Growth in Python
  INSERT INTO de_mobile_app.code_playground (
    playground_id, dataset_id, title, description, language, difficulty,
    starter_code, solution_code, solution_explanation, verification_config, tips
  )
  SELECT
    gen_random_uuid(), ds_python_sales,
    'Month-over-Month Growth in Python',
    'Compute month-over-month revenue growth for each region. Sort records by month, then for each record compute growth_pct = (current - previous) / previous * 100 rounded to 2 decimals. The first month per region has null growth_pct. Return the enriched list.',
    'Python', 'Senior',
    E'# The dataset is available as: data["sales"]\n# Each record: month, region, revenue, units\n\ndef compute_mom_growth(sales):\n    # Group by region, sort by month within each group\n    from collections import defaultdict\n    by_region = defaultdict(list)\n    for r in sales:\n        by_region[r["region"]].append(r)\n    \n    result = []\n    for region, records in by_region.items():\n        records.sort(key=lambda r: r["month"])\n        prev_revenue = None\n        for r in records:\n            rec = dict(r)\n            # compute growth_pct using prev_revenue\n            rec["growth_pct"] = None  # replace with your logic\n            prev_revenue = r["revenue"]\n            result.append(rec)\n    return result\n\nresult = compute_mom_growth(data["sales"])\nprint(result)',
    E'from collections import defaultdict\n\ndef compute_mom_growth(sales):\n    by_region = defaultdict(list)\n    for r in sales:\n        by_region[r["region"]].append(r)\n    \n    result = []\n    for region, records in by_region.items():\n        records.sort(key=lambda r: r["month"])\n        prev_revenue = None\n        for r in records:\n            rec = dict(r)\n            if prev_revenue is not None and prev_revenue != 0:\n                rec["growth_pct"] = round((r["revenue"] - prev_revenue) / prev_revenue * 100, 2)\n            else:\n                rec["growth_pct"] = None\n            prev_revenue = r["revenue"]\n            result.append(rec)\n    return result\n\nresult = compute_mom_growth(data["sales"])\nprint(result)',
    'Group records by region using defaultdict(list). Sort each group by month. Track prev_revenue as you iterate. Compute growth only when prev_revenue is not None and not zero. This mirrors the SQL LAG() pattern in pure Python.',
    '{"type": "python_output", "check_type": "field_exists", "field": "growth_pct", "expected_length": 8}'::jsonb,
    ARRAY['defaultdict(list) auto-initialises missing keys with an empty list', 'Sort each group by month before computing growth', 'Guard against None and zero prev_revenue before dividing', 'This is the Python equivalent of SQL LAG() window function']
  WHERE NOT EXISTS (
    SELECT 1 FROM de_mobile_app.code_playground WHERE title = 'Month-over-Month Growth in Python'
  );

END $$;
