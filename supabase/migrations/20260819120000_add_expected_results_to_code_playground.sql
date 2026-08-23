-- ============================================================
-- Migration: Add expected_results column to code_playground
-- Stores the pre-computed expected output for each challenge
-- so the app can compare user output against it directly.
-- ============================================================

-- 1. Add the expected_results column
ALTER TABLE de_mobile_app.code_playground
  ADD COLUMN IF NOT EXISTS expected_results TEXT;

-- 2. Populate expected_results for all Python challenges
DO $$
BEGIN

  -- Python 1: Deduplicate User Records
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"}, {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"}, {"id": 4, "user_id": "u3", "name": "Carol", "email": null, "age": null, "score": 85.0, "status": "inactive"}, {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": null, "status": "active"}, {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active"}, {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": null, "score": 60.0, "status": "inactive"}]'
  WHERE title = 'Deduplicate User Records'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 2: Handle Missing Values
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"}, {"id": 2, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"}, {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"}, {"id": 4, "user_id": "u3", "name": "Carol", "email": "unknown@example.com", "age": 0, "score": 85.0, "status": "inactive"}, {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": 82.1, "status": "active"}, {"id": 6, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"}, {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active"}, {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": 0, "score": 60.0, "status": "inactive"}]'
  WHERE title = 'Handle Missing Values'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 3: Aggregate Records by Status
  UPDATE de_mobile_app.code_playground
  SET expected_results = '{"active": {"count": 6, "avg_score": 86.7, "unique_users": 5}, "inactive": {"count": 2, "avg_score": 72.5, "unique_users": 2}}'
  WHERE title = 'Aggregate Records by Status'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 4: Flatten Nested JSON to Tabular Records
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"user_id": "u1", "name": "Alice", "age": 28, "order_id": "o1", "order_total": 250.0}, {"user_id": "u1", "name": "Alice", "age": 28, "order_id": "o2", "order_total": 180.5}, {"user_id": "u2", "name": "Bob", "age": 35, "order_id": "o3", "order_total": 320.0}, {"user_id": "u3", "name": "Carol", "age": 31, "order_id": null, "order_total": null}, {"user_id": "u4", "name": "Dave", "age": 42, "order_id": "o4", "order_total": 95.0}, {"user_id": "u4", "name": "Dave", "age": 42, "order_id": "o5", "order_total": 410.0}]'
  WHERE title = 'Flatten Nested JSON to Tabular Records'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 5: Detect Duplicate Events
  UPDATE de_mobile_app.code_playground
  SET expected_results = '["e001"]'
  WHERE title = 'Detect Duplicate Events'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 6: Extract Purchase Events
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"user_id": "u1", "timestamp": "2024-03-01T08:15:00", "item_id": "p1", "amount": 49.99}, {"user_id": "u3", "timestamp": "2024-03-02T11:30:00", "item_id": "p2", "amount": 129.0}, {"user_id": "u2", "timestamp": "2024-03-03T14:00:00", "item_id": "p1", "amount": 49.99}]'
  WHERE title = 'Extract Purchase Events'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 7: ETL: Normalize and Enrich Sales Records
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"month": "2024-01-01", "region": "North", "revenue": 45000, "units": 120, "revenue_per_unit": 375.0}, {"month": "2024-01-01", "region": "South", "revenue": 38000, "units": 95, "revenue_per_unit": 400.0}, {"month": "2024-02-01", "region": "North", "revenue": 52000, "units": 140, "revenue_per_unit": 371.43}, {"month": "2024-02-01", "region": "South", "revenue": 41000, "units": 105, "revenue_per_unit": 390.48}, {"month": "2024-03-01", "region": "North", "revenue": 48000, "units": 130, "revenue_per_unit": 369.23}, {"month": "2024-03-01", "region": "South", "revenue": 55000, "units": 148, "revenue_per_unit": 371.62}, {"month": "2024-04-01", "region": "North", "revenue": 61000, "units": 165, "revenue_per_unit": 369.7}, {"month": "2024-04-01", "region": "South", "revenue": 49000, "units": 128, "revenue_per_unit": 382.81}]'
  WHERE title = 'ETL: Normalize and Enrich Sales Records'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 8: Validate and Classify Records
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active", "validation_status": "valid"}, {"id": 2, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active", "validation_status": "valid"}, {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active", "validation_status": "valid"}, {"id": 4, "user_id": "u3", "name": "Carol", "email": null, "age": null, "score": 85.0, "status": "inactive", "validation_status": "invalid"}, {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": null, "status": "active", "validation_status": "invalid"}, {"id": 6, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active", "validation_status": "valid"}, {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active", "validation_status": "valid"}, {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": null, "score": 60.0, "status": "inactive", "validation_status": "invalid"}]'
  WHERE title = 'Validate and Classify Records'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 9: Compute Total Purchase Revenue per User
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"user_id": "u3", "total_revenue": 129.0}, {"user_id": "u1", "total_revenue": 49.99}, {"user_id": "u2", "total_revenue": 49.99}]'
  WHERE title = 'Compute Total Purchase Revenue per User'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

  -- Python 10: Month-over-Month Growth in Python
  UPDATE de_mobile_app.code_playground
  SET expected_results = '[{"month": "2024-01", "region": "North", "revenue": 45000, "units": 120, "growth_pct": null}, {"month": "2024-02", "region": "North", "revenue": 52000, "units": 140, "growth_pct": 15.56}, {"month": "2024-03", "region": "North", "revenue": 48000, "units": 130, "growth_pct": -7.69}, {"month": "2024-04", "region": "North", "revenue": 61000, "units": 165, "growth_pct": 27.08}, {"month": "2024-01", "region": "South", "revenue": 38000, "units": 95, "growth_pct": null}, {"month": "2024-02", "region": "South", "revenue": 41000, "units": 105, "growth_pct": 7.89}, {"month": "2024-03", "region": "South", "revenue": 55000, "units": 148, "growth_pct": 34.15}, {"month": "2024-04", "region": "South", "revenue": 49000, "units": 128, "growth_pct": -10.91}]'
  WHERE title = 'Month-over-Month Growth in Python'
    AND language = 'Python'
    AND (expected_results IS NULL OR expected_results = '');

END $$;
