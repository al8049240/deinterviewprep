"""Seed 30 original PostgreSQL, HackerRank-inspired multiple-choice SQL challenges."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "supabase/migrations/20260928210000_seed_sql_coding_practice_30.sql"
items = []

def add(level, prompt, options, correct, why, mistake, tip):
    assert level in ("easy", "medium", "hard")
    assert len(options) == 4 and 0 <= correct < 4
    assert mistake.startswith("Don't ")
    number = len(items) + 1
    items.append({
        "id": f"sql_coding_20260928_{number:02d}", "level": level,
        "question": prompt, "options": options, "correct": correct,
        "explaination": why, "interview_note": mistake, "pro_tips": tip,
    })

add("easy", "Table employees(id, name, department, salary). Return the names of Engineering employees earning at least 80000. Which PostgreSQL query fits?",
    ["SELECT name FROM employees WHERE department = 'Engineering' AND salary >= 80000;",
     "SELECT name FROM employees WHERE department = 'Engineering' OR salary >= 80000;",
     "SELECT name FROM employees WHERE department = 'Engineering' AND salary > 80000;",
     "SELECT name FROM employees HAVING department = 'Engineering' AND salary >= 80000;"], 0,
    "A applies both row filters and includes exactly 80000. B admits either condition, C excludes the boundary, and D uses HAVING without grouping instead of WHERE.",
    "Don't swap AND for OR or overlook an inclusive salary boundary.", "In a payroll extract, test one employee at exactly 80000 and one outside Engineering.")
add("easy", "Table products(id, name, price). Show the three most expensive products, with a stable order when prices tie. Which query fits?",
    ["SELECT name, price FROM products ORDER BY price DESC LIMIT 3;",
     "SELECT name, price FROM products ORDER BY price DESC, id ASC LIMIT 3;",
     "SELECT name, price FROM products ORDER BY price ASC, id ASC LIMIT 3;",
     "SELECT name, price FROM products LIMIT 3 ORDER BY price DESC, id ASC;"], 1,
    "B sorts high prices first and uses id to break ties. A lacks deterministic tie ordering, C chooses the cheapest, and D puts LIMIT before ORDER BY.",
    "Don't rely on unspecified row order when LIMIT is used with ties.", "For a price leaderboard, use a unique tie-breaker so repeated runs return the same products.")
add("easy", "Table events(user_id, event_type). Return each user_id once for users who have a purchase event. Which query fits?",
    ["SELECT user_id FROM events WHERE event_type = 'purchase';",
     "SELECT DISTINCT event_type FROM events WHERE event_type = 'purchase';",
     "SELECT DISTINCT user_id FROM events WHERE event_type = 'purchase';",
     "SELECT user_id FROM events GROUP BY event_type;"], 2,
    "C deduplicates the requested user IDs. A can repeat a buyer, B returns event types, and D groups by the wrong column.",
    "Don't use DISTINCT on a different column from the entity you want once.", "A buyer may purchase several times; verify that the output still has one row per buyer.")
add("easy", "Table tickets(id, resolved_at). Find tickets that have not been resolved. Which predicate is correct?",
    ["WHERE resolved_at = NULL", "WHERE resolved_at <> NULL", "WHERE resolved_at = ''", "WHERE resolved_at IS NULL"], 3,
    "D tests a SQL NULL. A and B compare with NULL and do not return true; C tests an empty string, which is not a timestamp NULL.",
    "Don't use = NULL or <> NULL in SQL predicates.", "In incident queues, distinguish an unresolved NULL timestamp from a resolved timestamp.")
add("easy", "Table customers(id, email). Return emails ending in '.edu'. Which predicate fits?",
    ["WHERE email LIKE '%.edu'", "WHERE email LIKE '.edu%'", "WHERE email = '%.edu'", "WHERE email LIKE '%._edu'"], 0,
    "A matches any prefix followed by the literal .edu suffix. B checks a prefix, C treats % literally, and D uses _ as a single-character wildcard.",
    "Don't confuse SQL LIKE wildcards with literal equality.", "For domain filters, remember that LIKE can be case-sensitive in PostgreSQL; use ILIKE if case-insensitive matching is required.")
add("easy", "Table orders(id, status). Keep orders whose status is either 'paid' or 'refunded'. Which WHERE clause is correct?",
    ["WHERE status = 'paid' AND status = 'refunded'", "WHERE status IN ('paid', 'refunded')", "WHERE status IN ('paid' AND 'refunded')", "WHERE status <> 'open'"], 1,
    "B expresses either allowed value. A asks one status to equal both, C does not supply a value list, and D includes unrelated statuses.",
    "Don't replace an explicit allowed-status list with a broad exclusion.", "Payment dashboards should enumerate the statuses included in the metric.")
add("easy", "Table deliveries(id, delivery_date). Include dates from 2026-01-01 through 2026-01-31 inclusive. The column is DATE. Which filter fits?",
    ["WHERE delivery_date > DATE '2026-01-01' AND delivery_date < DATE '2026-01-31'",
     "WHERE delivery_date >= DATE '2026-01-01' AND delivery_date < DATE '2026-01-31'",
     "WHERE delivery_date BETWEEN DATE '2026-01-01' AND DATE '2026-01-31'",
     "WHERE delivery_date = DATE '2026-01-01' OR DATE '2026-01-31'"], 2,
    "C includes both endpoint dates for a DATE column. A and B miss at least one endpoint; D is not a valid pair of comparisons.",
    "Don't forget whether the requested date boundaries are inclusive.", "For TIMESTAMP columns prefer a half-open range ending at February 1; this question explicitly uses DATE.")
add("easy", "Table payments(id, coupon_code), where coupon_code can be NULL. Count every payment row. Which expression fits?",
    ["COUNT(coupon_code)", "COUNT(DISTINCT coupon_code)", "SUM(coupon_code)", "COUNT(*)"], 3,
    "D counts rows regardless of NULL coupon values. A skips NULLs, B counts distinct non-NULL coupons, and C attempts to sum a code.",
    "Don't use COUNT(nullable_column) when the metric is total rows.", "If many payments have no coupon, compare COUNT(*) with COUNT(coupon_code) to spot the difference.")
add("easy", "Table jobs(id, team). Show the number of jobs for each team. Which query fits?",
    ["SELECT team, COUNT(*) FROM jobs GROUP BY team;",
     "SELECT team, COUNT(*) FROM jobs ORDER BY team;",
     "SELECT team, COUNT(*) FROM jobs GROUP BY id;",
     "SELECT COUNT(*) FROM jobs WHERE team;"], 0,
    "A groups at team grain. B lacks GROUP BY, C groups at job grain, and D neither selects teams nor provides a Boolean condition.",
    "Don't group by a unique job ID when the requested output is one row per team.", "Check whether the query returns exactly one row for each team represented in jobs.")
add("easy", "Table orders(id, store_id). Return stores with at least five orders. Which query fits?",
    ["SELECT store_id FROM orders WHERE COUNT(*) >= 5 GROUP BY store_id;",
     "SELECT store_id FROM orders GROUP BY store_id HAVING COUNT(*) >= 5;",
     "SELECT store_id FROM orders GROUP BY store_id HAVING id >= 5;",
     "SELECT store_id FROM orders WHERE id >= 5 GROUP BY store_id;"], 1,
    "B filters grouped stores by their aggregate count. A uses an aggregate in WHERE, while C and D filter order IDs instead of order volume.",
    "Don't put an aggregate condition in WHERE; use HAVING after grouping.", "For store activity thresholds, test a store with exactly five orders.")

add("medium", "Tables customers(id, name) and orders(id, customer_id). Show customer names for customers who placed at least one order, once per customer. Which query fits?",
    ["SELECT c.name FROM customers c JOIN orders o ON c.id = o.customer_id;",
     "SELECT DISTINCT c.name FROM customers c JOIN orders o ON c.id = o.customer_id;",
     "SELECT c.name FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);",
     "SELECT c.name FROM customers c JOIN orders o ON c.id = o.id;"], 2,
    "C tests order existence without multiplying customer rows. A repeats customers with many orders, B can collapse two different customers with the same name, and D joins unrelated IDs.",
    "Don't deduplicate by name when customer identity is the real key.", "Two customers named Alex should each remain represented; use the customer ID as the entity key.")
add("medium", "Tables products(id, name) and sales(id, product_id). Show every product with its sale count, including zero-sale products. Which expression should count sales after a LEFT JOIN?",
    ["COUNT(*)", "COUNT(p.id)", "COUNT(DISTINCT p.name)", "COUNT(s.id)"], 3,
    "D counts a non-NULL right-table sale ID and gives zero for unmatched products. A and B count the preserved product row; C counts names rather than sales.",
    "Don't use COUNT(*) after a LEFT JOIN when unmatched rows must show zero matches.", "Use a product with no sales as the test case for a zero-count report.")
add("medium", "Tables services(id) and incidents(id, service_id, severity). Keep every service but count only critical incidents. Which JOIN clause preserves services with zero critical incidents?",
    ["LEFT JOIN incidents i ON i.service_id = s.id AND i.severity = 'critical'",
     "LEFT JOIN incidents i ON i.service_id = s.id WHERE i.severity = 'critical'",
     "INNER JOIN incidents i ON i.service_id = s.id AND i.severity = 'critical'",
     "CROSS JOIN incidents i WHERE i.severity = 'critical'"], 0,
    "A filters right-table matches within ON while preserving every left service. B removes NULL-extended services, C is an inner join, and D produces unrelated combinations.",
    "Don't move a right-side filter into WHERE when zero-match left rows must stay.", "An incident-free service should still appear with a count of zero.")
add("medium", "Tables employees(id, department_id, salary). Show total salary per department only when that total exceeds 500000. Which query fits?",
    ["SELECT department_id, SUM(salary) FROM employees WHERE salary > 500000 GROUP BY department_id;",
     "SELECT department_id, SUM(salary) FROM employees GROUP BY department_id HAVING SUM(salary) > 500000;",
     "SELECT department_id, SUM(salary) FROM employees HAVING SUM(salary) > 500000;",
     "SELECT department_id, salary FROM employees GROUP BY department_id HAVING salary > 500000;"], 1,
    "B aggregates salary at department grain and filters the total. A filters individual salaries, C omits the grouping needed for department_id, and D selects an ungrouped salary.",
    "Don't substitute an individual-row salary filter for a department-total threshold.", "A department can exceed 500000 even when no single employee does.")
add("medium", "Table payments(order_id, amount, status). Show each order's paid amount; failed payments should contribute zero. Which expression fits within a GROUP BY order_id query?",
    ["COUNT(*) FILTER (WHERE status = 'paid')", "SUM(amount) FILTER (WHERE status <> 'paid')",
     "SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END)", "SUM(amount) WHERE status = 'paid'"], 2,
    "C sums paid amounts and contributes zero for other statuses. A counts payments rather than money, B sums non-paid amounts, and D puts WHERE inside an aggregate expression incorrectly.",
    "Don't count payment rows when the requested measure is money.", "A paid order with two partial payments should sum both amounts.")
add("medium", "Tables current_users(user_id) and archived_users(user_id). Return every user_id from both sources while removing duplicates. Which operator fits?",
    ["UNION ALL", "INNER JOIN", "EXCEPT", "UNION"], 3,
    "D combines both sets and removes duplicate rows. UNION ALL keeps duplicates, INNER JOIN keeps only matches, and EXCEPT removes rows from one side.",
    "Don't choose UNION ALL when the task explicitly requires unique output.", "For a merged user directory, decide whether duplicate IDs should be retained or collapsed before choosing the set operator.")
add("medium", "Table orders(id, customer_id, ordered_at). Keep one latest order per customer, breaking timestamp ties by larger id. Which pattern fits?",
    ["ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ordered_at DESC, id DESC) = 1, filtered in an outer query",
     "ROW_NUMBER() OVER (ORDER BY ordered_at DESC) = 1, filtered in an outer query",
     "RANK() OVER (PARTITION BY customer_id ORDER BY ordered_at DESC) = 1, filtered in an outer query",
     "GROUP BY customer_id, MAX(ordered_at), id"], 0,
    "A numbers orders separately by customer with a deterministic tie-breaker. B keeps one global order, C can keep tied rows, and D does not select a complete latest order correctly.",
    "Don't forget both PARTITION BY customer_id and a unique tie-breaker.", "Late-arriving orders can share timestamps; use an immutable ID to make deduplication repeatable.")
add("medium", "Tables customers(id) and orders(customer_id). Find customers with no orders. Which predicate is safest even if orders.customer_id contains NULL?",
    ["id NOT IN (SELECT customer_id FROM orders)",
     "NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)",
     "id <> (SELECT customer_id FROM orders)",
     "EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)"], 1,
    "B is a correlated anti-existence test. A can yield no rows when the subquery contains NULL, C is not valid for multiple returned IDs, and D finds customers who do have orders.",
    "Don't use NOT IN blindly against a nullable subquery column.", "Test an orders row with NULL customer_id before trusting an anti-join result.")
add("medium", "Table events(id, occurred_at TIMESTAMP). Count events by calendar day. Which PostgreSQL grouping expression fits?",
    ["GROUP BY occurred_at", "GROUP BY EXTRACT(HOUR FROM occurred_at)",
     "GROUP BY occurred_at::date", "GROUP BY id"], 2,
    "C groups timestamps by their date portion. A groups exact timestamps, B groups hour-of-day across dates, and D groups events individually.",
    "Don't group by full timestamps when the report requests one row per day.", "For timezone-aware timestamps, decide the business timezone before converting to a reporting date.")
add("medium", "Table orders(id, customer_id, amount). Return customers whose total order amount is at least 1000 while retaining one row per customer. Which query fits?",
    ["SELECT customer_id FROM orders WHERE amount >= 1000;",
     "SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(*) >= 1000;",
     "SELECT customer_id, amount FROM orders GROUP BY customer_id HAVING SUM(amount) >= 1000;",
     "SELECT customer_id FROM orders GROUP BY customer_id HAVING SUM(amount) >= 1000;"], 3,
    "D groups by customer and filters the sum. A checks one order, B checks order count, and C selects an ungrouped amount.",
    "Don't confuse an individual order threshold with a customer's total spend.", "A customer with two 600 orders should qualify even though neither order reaches 1000.")

add("hard", "Table sales(store_id, sale_date, amount) has one row per store per day. Return each row with cumulative store revenue through that date. Which window expression fits?",
    ["SUM(amount) OVER (PARTITION BY store_id ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)",
     "SUM(amount) OVER (PARTITION BY store_id)",
     "SUM(amount) OVER (ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)",
     "AVG(amount) OVER (PARTITION BY store_id ORDER BY sale_date)"], 0,
    "A resets per store and accumulates through the current date. B gives the full store total on every row, C mixes stores, and D calculates an average.",
    "Don't omit the store partition from a per-store running total.", "For a store revenue chart, the cumulative value should reset at each new store and never decrease for nonnegative sales.")
add("hard", "Table employee_sales(employee_id, revenue). Return every employee tied for the highest revenue, even if several share first place. Which filter pattern fits?",
    ["ROW_NUMBER() OVER (ORDER BY revenue DESC) = 1 in an outer query",
     "RANK() OVER (ORDER BY revenue DESC) = 1 in an outer query",
     "ORDER BY revenue DESC LIMIT 1",
     "NTILE(2) OVER (ORDER BY revenue DESC) = 1 in an outer query"], 1,
    "B gives all top ties rank 1. ROW_NUMBER and LIMIT 1 choose one row; NTILE splits rows into buckets, not just the maximum.",
    "Don't use ROW_NUMBER when every first-place tie must appear.", "A leaderboard can have two employees with the same top revenue; test that both survive.")
add("hard", "Table store_sales(store_id, region, monthly_sales) has one row per store. Keep each store and show its share of region sales. Which denominator fits?",
    ["SUM(monthly_sales) OVER ()", "AVG(monthly_sales) OVER (PARTITION BY region)",
     "SUM(monthly_sales) OVER (PARTITION BY region)",
     "SUM(monthly_sales) OVER (PARTITION BY store_id)"], 2,
    "C repeats the regional total beside each store. A is a company-wide total, B is the average store value, and D is effectively the store's own value.",
    "Don't partition by the store when the denominator is regional.", "Shares for stores in one region should total about 100%, allowing for rounding.")
add("hard", "Table daily_metrics(service_id, day, errors) has one row for every calendar day per service. Compute each day's seven-day trailing error total, including the current day. Which frame fits?",
    ["ROWS BETWEEN 7 PRECEDING AND CURRENT ROW", "ROWS BETWEEN 6 FOLLOWING AND CURRENT ROW",
     "ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW", "ROWS BETWEEN 6 PRECEDING AND CURRENT ROW"], 3,
    "D includes the current day plus six previous rows, seven days because the table has one row per day. A includes eight rows, B has reversed bounds, and C is a lifetime running total.",
    "Don't forget the current row counts as one of the seven rows.", "If dates can be missing, first create a complete date spine or use a true date-range strategy; ROWS counts records, not elapsed days.")
add("hard", "Table login_days(user_id, login_date DATE) contains at most one row per user per day. Find adjacent login days for a user. Which PostgreSQL test on an ordered window result fits?",
    ["login_date = LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date) + 1",
     "login_date = LAG(login_date) OVER (ORDER BY login_date) + 1",
     "login_date = MAX(login_date) OVER (PARTITION BY user_id) + 1",
     "login_date = LEAD(login_date) OVER (PARTITION BY user_id ORDER BY login_date) + 1"], 0,
    "A compares each date with the previous date for the same user plus one day. B can cross users, C uses the user's maximum date, and D looks ahead in the wrong direction.",
    "Don't let a session-streak calculation compare rows from different users.", "For daily retention, deduplicate multiple same-day logins before searching for consecutive dates.")
add("hard", "Tables price_history(product_id, effective_at, price) and orders(id, product_id, ordered_at). For each order, use the latest price effective no later than ordered_at. Which PostgreSQL approach fits?",
    ["JOIN price_history p ON p.product_id=o.product_id AND p.effective_at=o.ordered_at",
     "LEFT JOIN LATERAL (SELECT price FROM price_history p WHERE p.product_id=o.product_id AND p.effective_at<=o.ordered_at ORDER BY p.effective_at DESC LIMIT 1) p ON true",
     "JOIN price_history p ON p.product_id=o.product_id ORDER BY p.effective_at DESC LIMIT 1",
     "LEFT JOIN price_history p ON p.product_id=o.product_id AND p.effective_at>=o.ordered_at"], 1,
    "B finds the last eligible effective price separately for each order. A requires an exact timestamp, C returns only one global row, and D looks at future prices.",
    "Don't attach a future price to a historical order.", "For an as-of join, index price history by product and effective time, and decide what to show before any price exists.")
add("hard", "Table events(user_id, event_type, occurred_at). For each user's first signup month, count users who also purchased within 30 days of their signup timestamp. Which approach avoids multiplying users with several purchases?",
    ["JOIN every signup to every purchase and COUNT(*)",
     "COUNT(DISTINCT event_type) for each month",
     "Find one signup per user, then use EXISTS for a qualifying purchase before counting users by signup month",
     "Count purchase rows by purchase month"], 2,
    "C establishes signup cohort grain and uses existence so multiple purchases count once. A overcounts, B counts event types, and D groups by the wrong event date.",
    "Don't count purchases when the metric is users who purchased.", "A user with three purchases in the window should contribute one converted user to their signup cohort.")
add("hard", "Table intervals(resource_id, starts_at, ends_at) uses half-open intervals [starts_at, ends_at). Two intervals for the same resource overlap only when which predicate holds?",
    ["a.ends_at <= b.starts_at OR b.ends_at <= a.starts_at",
     "a.starts_at <= b.ends_at AND b.starts_at <= a.ends_at",
     "a.starts_at = b.starts_at",
     "a.starts_at < b.ends_at AND b.starts_at < a.ends_at"], 3,
    "D is the half-open overlap test. A describes non-overlap, B treats touching endpoints as overlap, and C misses intervals with different starts.",
    "Don't count two bookings that only touch at an endpoint as overlapping when the end is exclusive.", "For room bookings, [09:00,10:00) and [10:00,11:00) can share the same room.")
add("hard", "Tables orders(id, customer_id, amount) and order_items(order_id, item_id). You need total order amount per customer. What should you do before joining items?",
    ["Sum orders.amount after joining every item, assuming each order appears once",
     "Use SUM(DISTINCT orders.amount) after the join",
     "Aggregate orders to customer grain first, or avoid the item join if item data is not needed",
     "Count item rows and multiply by average order amount"], 2,
    "C preserves order grain before a one-to-many item join. A multiplies order amounts, B wrongly collapses equal-valued different orders, and D estimates rather than computes the requested total.",
    "Don't use DISTINCT to hide join fan-out in financial totals.", "An order with three items and amount 100 should add 100, not 300, to its customer's revenue.")
add("hard", "Tables candidates(id) and skills(candidate_id, skill). Find candidates who have all three required skills SQL, Python, and Airflow. Which grouping condition fits?",
    ["HAVING COUNT(*) >= 3",
     "HAVING COUNT(DISTINCT skill) FILTER (WHERE skill IN ('SQL','Python','Airflow')) = 3",
     "WHERE skill IN ('SQL','Python','Airflow') LIMIT 3",
     "HAVING COUNT(DISTINCT skill) >= 3"], 1,
    "B counts the three distinct required skills per candidate. A can count duplicates or unrelated skills, C returns rows rather than candidate qualification, and D can count unrelated skills.",
    "Don't equate three skill rows with possession of three specific skills.", "A candidate with SQL listed twice and Python once is still missing Airflow.")

assert len(items) == 30
assert [sum(q["level"] == level for q in items) for level in ("easy", "medium", "hard")] == [10,10,10]
assert len({q["id"] for q in items}) == 30

payload = json.dumps(items, ensure_ascii=False, indent=2)
assert "$coding$" not in payload
sql = """-- Original PostgreSQL SQL coding-practice quiz, inspired by the skill categories
-- on HackerRank's SQL domain; no challenge text or data is copied from HackerRank.
-- 10 easy, 10 medium, 10 hard. Four options per question, one correct answer.
BEGIN;
INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
VALUES ('SQL Coding Practice', 'Original query-writing and query-reading challenges, from basic SELECT to advanced analytics', 'code')
ON CONFLICT (name) DO NOTHING;

DO $topic_check$
BEGIN
  IF (SELECT count(*) FROM de_mobile_app."topics-legacy" WHERE name='SQL Coding Practice')<>1 THEN
    RAISE EXCEPTION 'SQL Coding Practice topic is missing or duplicated';
  END IF;
END $topic_check$;

INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
SELECT t.id, v.name, v.description
FROM de_mobile_app."topics-legacy" t
CROSS JOIN (VALUES
  ('Easy', 'Basic SELECT, filters, sorting, NULLs, and grouping'),
  ('Medium', 'Joins, aggregation, anti-joins, dates, and deduplication'),
  ('Hard', 'Window functions, time-based joins, cohorts, intervals, and grain')) v(name,description)
WHERE t.name='SQL Coding Practice'
  AND NOT EXISTS (SELECT 1 FROM de_mobile_app."subtopics-legacy" s
                  WHERE s.topic_id=t.id AND s.name=v.name);

CREATE TEMP TABLE coding_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO coding_payload VALUES ($coding$""" + payload + """$coding$::jsonb);
CREATE TEMP TABLE coding_questions ON COMMIT DROP AS
SELECT x->>'id' AS question_id, x->>'level' AS difficulty,
       x->>'question' AS question, x->>'explaination' AS explaination,
       x->>'interview_note' AS interview_note, x->>'pro_tips' AS pro_tips
FROM coding_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x;
CREATE TEMP TABLE coding_answers ON COMMIT DROP AS
SELECT x->>'id' AS question_id,
       x->>'id' || '_' || chr(96+a.position::integer) AS option_id,
       a.answer #>> '{}' AS option_text,
       (a.position::integer-1)=(x->>'correct')::integer AS is_correct,
       a.position::integer AS position
FROM coding_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x
CROSS JOIN LATERAL jsonb_array_elements(x->'options') WITH ORDINALITY AS a(answer,position);

DO $preflight$
DECLARE v_topic bigint;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='SQL Coding Practice';
  IF (SELECT count(*) FROM de_mobile_app."subtopics-legacy" WHERE topic_id=v_topic AND name IN ('Easy','Medium','Hard'))<>3 THEN
    RAISE EXCEPTION 'Expected three difficulty subtopics';
  END IF;
  IF (SELECT count(*) FROM coding_questions)<>30 OR (SELECT count(*) FROM coding_answers)<>120
     OR (SELECT count(DISTINCT question_id) FROM coding_questions)<>30
     OR (SELECT count(DISTINCT option_id) FROM coding_answers)<>120 THEN
    RAISE EXCEPTION 'Challenge seed count mismatch';
  END IF;
  IF EXISTS (SELECT 1 FROM coding_questions q LEFT JOIN coding_answers a USING (question_id)
             GROUP BY q.question_id HAVING count(a.option_id)<>4
                OR count(*) FILTER (WHERE a.is_correct)<>1) THEN
    RAISE EXCEPTION 'Each challenge needs four options and exactly one correct answer';
  END IF;
  IF EXISTS (SELECT 1 FROM coding_questions c JOIN de_mobile_app."quiz-question" q ON q.question_id::text=c.question_id
             WHERE q.topic IS DISTINCT FROM v_topic) THEN
    RAISE EXCEPTION 'A challenge ID belongs to another topic';
  END IF;
  IF EXISTS (SELECT 1 FROM coding_answers c JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=c.option_id
             WHERE a.question_id::text IS DISTINCT FROM c.question_id) THEN
    RAISE EXCEPTION 'An option ID belongs to another question';
  END IF;
END $preflight$;

INSERT INTO de_mobile_app."quiz-question"
  (question_id,topic,sub_topics,type,difficulty,question,explaination,interview_note,interview_tips,pro_tips)
SELECT c.question_id,t.id,s.id,'mcq',c.difficulty,c.question,c.explaination,
       c.interview_note,c.interview_note,c.pro_tips
FROM coding_questions c JOIN de_mobile_app."topics-legacy" t ON t.name='SQL Coding Practice'
JOIN de_mobile_app."subtopics-legacy" s ON s.topic_id=t.id AND s.name=initcap(c.difficulty)
WHERE true
ON CONFLICT (question_id) DO UPDATE SET type=EXCLUDED.type,difficulty=EXCLUDED.difficulty,
  question=EXCLUDED.question,explaination=EXCLUDED.explaination,
  interview_note=EXCLUDED.interview_note,interview_tips=EXCLUDED.interview_tips,
  pro_tips=EXCLUDED.pro_tips;
INSERT INTO de_mobile_app."quiz-answer" (option_id,question_id,"order",option_text,is_correct)
SELECT option_id,question_id,position,option_text,is_correct FROM coding_answers
ON CONFLICT (option_id) DO UPDATE SET "order"=EXCLUDED."order",
  option_text=EXCLUDED.option_text,is_correct=EXCLUDED.is_correct;

DO $postcheck$
DECLARE v_topic bigint;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='SQL Coding Practice';
  IF (SELECT count(*) FROM coding_questions c JOIN de_mobile_app."quiz-question" q ON q.question_id::text=c.question_id
      WHERE q.topic=v_topic AND q.question=c.question AND q.difficulty=c.difficulty)<>30
     OR (SELECT count(*) FROM coding_answers c JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=c.option_id
         WHERE a.question_id::text=c.question_id AND a.option_text=c.option_text
           AND a.is_correct=c.is_correct AND a."order"=c.position)<>120 THEN
    RAISE EXCEPTION 'SQL coding practice seed verification failed';
  END IF;
END $postcheck$;
COMMIT;
"""
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: {len(items)} questions / {sum(len(q['options']) for q in items)} options")
