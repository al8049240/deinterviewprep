# CTE, View & Function — 27 mixed practice questions

Review draft only; nothing here has been applied to Supabase. The set has nine definition checks, nine read/fix-SQL questions, and nine write-SQL challenges. It uses PostgreSQL syntax. For coding challenges, accept equivalent queries that produce the stated result; do not require an exact text match.

## CTEs

### 1. [Definition] Name a query step

**Question:** What does a CTE (`WITH ... AS`) primarily give you?

A. A named result available to the current statement.  
B. A permanent copy of a table.  
C. An index on the source table.  
D. A result shared by all future sessions.

**Answer: A.** A CTE is a named query step for one statement.

**Easy example:** Name the March orders `march_orders`; the rest of that query can read `march_orders`.

### 2. [Read/Fix] Read a filtered CTE

**Question:** `orders` contains `(1, 'paid'), (2, 'open'), (3, 'paid')`. What IDs does this query return?

```sql
WITH paid_orders AS (
  SELECT order_id FROM orders WHERE status = 'paid'
)
SELECT order_id FROM paid_orders ORDER BY order_id;
```

A. 1 and 3.  
B. 1, 2, and 3.  
C. 2 only.  
D. No rows.

**Answer: A.** The CTE keeps only paid rows; the final query reads those rows.

**Easy example:** Think of the CTE as a labeled tray holding orders 1 and 3.

### 3. [Write SQL] Total March orders by store

**Task:** Given `orders(order_id, store_id, order_date, amount)`, write a query using a CTE to return `store_id, total_amount` for orders in March 2026. Include stores only if they have March orders.

**Reference solution:**

```sql
WITH march_orders AS (
  SELECT store_id, amount
  FROM orders
  WHERE order_date >= DATE '2026-03-01'
    AND order_date < DATE '2026-04-01'
)
SELECT store_id, SUM(amount) AS total_amount
FROM march_orders
GROUP BY store_id;
```

**Check:** One output row per store; two March amounts of 10 and 20 for the same store give 30. A half-open date range also works when `order_date` is a timestamp.

### 4. [Definition] Reuse across statements

**Question:** Two separate statements in one session need the same intermediate rows. Which option can hold rows for both statements?

A. A temporary table.  
B. A CTE declared in the first statement.  
C. A column alias in the first statement.  
D. An `ORDER BY` clause.

**Answer: A.** A CTE's name ends with its statement; a temporary table can be read by later statements in its session.

**Easy example:** Prepare the rows once in a temporary table, then use them in two reports.

### 5. [Read/Fix] Fix a missing grouping column

**Question:** This query should return one total per customer. What is missing?

```sql
WITH customer_totals AS (
  SELECT customer_id, SUM(amount) AS total_amount
  FROM orders
)
SELECT * FROM customer_totals;
```

A. `GROUP BY customer_id` inside the CTE.  
B. `ORDER BY amount` inside the CTE.  
C. `DISTINCT` in the outer query.  
D. `LIMIT 1` in the outer query.

**Answer: A.** The CTE selects `customer_id` alongside an aggregate, so it must group by customer.

**Easy example:** To give Ana and Bo separate totals, tell SQL to make one group for Ana and one for Bo.

### 6. [Write SQL] Find customers above a threshold

**Task:** Given `orders(customer_id, amount)`, use a CTE to return `customer_id, total_amount` for customers whose total amount is greater than 100.

**Reference solution:**

```sql
WITH customer_totals AS (
  SELECT customer_id, SUM(amount) AS total_amount
  FROM orders
  GROUP BY customer_id
)
SELECT customer_id, total_amount
FROM customer_totals
WHERE total_amount > 100;
```

**Check:** A customer with orders of 60 and 50 appears with 110; a customer with exactly 100 does not.

### 7. [Definition] CTE performance

**Question:** You wrap a slow query in a PostgreSQL CTE. Which claim is safe?

A. The CTE can make the logic clearer, but its execution plan still needs checking.  
B. The CTE always creates an index.  
C. The CTE always materializes its rows.  
D. The CTE always makes the query faster.

**Answer: A.** PostgreSQL can fold suitable CTEs into the parent query; wrapping SQL in `WITH` is not a speed guarantee.

**Easy example:** Putting a recipe in a labeled box makes it easier to read, but does not automatically make the cooking faster.

### 8. [Read/Fix] Avoid counting duplicated totals

**Question:** `customer_totals` has one row for Ana with `total_amount = 100`. `customer_tags` has two rows for Ana. After joining them, what does `SUM(ct.total_amount)` return for Ana?

```sql
WITH customer_totals AS (
  SELECT customer_id, SUM(amount) AS total_amount
  FROM orders GROUP BY customer_id
)
SELECT ct.customer_id, SUM(ct.total_amount)
FROM customer_totals ct
JOIN customer_tags t ON t.customer_id = ct.customer_id
GROUP BY ct.customer_id;
```

A. 200, because the join repeats Ana's total twice.  
B. 100, because the CTE prevents duplicates.  
C. 50, because the total is divided by tag count.  
D. No row, because aggregates cannot be joined.

**Answer: A.** Joining a one-row-per-customer total to two tag rows duplicates that total. If the goal is to keep tagged customers, use `EXISTS` or deduplicate tags before joining.

**Easy example:** Writing “100” on two tag cards and adding both cards gives 200, although Ana spent only 100.

### 9. [Write SQL] Follow an employee hierarchy

**Task:** Given `employees(employee_id, manager_id, employee_name)`, return employee 1 and all employees below them, with `depth = 0` for employee 1. Assume the hierarchy contains no cycles.

**Reference solution:**

```sql
WITH RECURSIVE team AS (
  SELECT employee_id, manager_id, employee_name, 0 AS depth
  FROM employees WHERE employee_id = 1
  UNION ALL
  SELECT e.employee_id, e.manager_id, e.employee_name, t.depth + 1
  FROM employees e
  JOIN team t ON e.manager_id = t.employee_id
)
SELECT employee_id, employee_name, depth
FROM team
ORDER BY depth, employee_id;
```

**Check:** A direct report has depth 1; that person's report has depth 2. In real data, add cycle protection if loops are possible.

## Views

### 10. [Definition] Regular view

**Question:** What does a regular PostgreSQL view save?

A. A query definition.  
B. A permanent copy of its result rows.  
C. A new index on every source table.  
D. A scheduled refresh job.

**Answer: A.** A regular view runs its defining query when it is queried.

**Easy example:** A view is a saved recipe; it does not keep a cooked meal on the shelf.

### 11. [Read/Fix] See current source data

**Question:** A view selects rows where `status = 'open'`. Order 7 is open, then its status is updated to `closed`. What happens when you query the regular view again?

A. Order 7 no longer appears.  
B. Order 7 stays until the view is refreshed.  
C. Order 7 appears twice.  
D. The view is deleted.

**Answer: A.** A regular view reads current source data when queried.

**Easy example:** The recipe checks today's order status, not yesterday's list.

### 12. [Write SQL] Expose only useful customer fields

**Task:** Given `customers(customer_id, customer_name, email, status)`, create a regular view `active_customers` that exposes only `customer_id` and `customer_name` for active customers.

**Reference solution:**

```sql
CREATE VIEW active_customers AS
SELECT customer_id, customer_name
FROM customers
WHERE status = 'active';
```

**Check:** The view has no `email` column. This narrows what the view exposes, but actual access still depends on database privileges.

### 13. [Definition] Shared reusable query

**Question:** Several reports need the same customer classification logic, and the team wants to maintain one shared definition. What is the best fit?

A. A view.  
B. A CTE copied into each report.  
C. A column alias copied into each report.  
D. An `ORDER BY` copied into each report.

**Answer: A.** A view gives multiple statements a shared query definition.

**Easy example:** Fix the classification rule once in the view instead of editing five reports.

### 14. [Read/Fix] Repair a view's aggregate

**Question:** A view should have one row per store. Which clause fixes this definition?

```sql
CREATE VIEW store_sales AS
SELECT store_id, SUM(amount) AS total_amount
FROM sales;
```

A. Add `GROUP BY store_id` after `FROM sales`.  
B. Add `LIMIT 1` after `FROM sales`.  
C. Add `ORDER BY amount` after `FROM sales`.  
D. Replace `SUM(amount)` with `amount`.

**Answer: A.** Grouping defines the store-level result.

**Easy example:** If Store A sells 10 and 20, its view row should show A and 30.

### 15. [Write SQL] Create a readable order view

**Task:** Given `orders(order_id, customer_id, amount)` and `customers(customer_id, customer_name)`, create a regular view `order_summary` with `order_id, customer_name, amount`. Assume every order has a matching customer.

**Reference solution:**

```sql
CREATE VIEW order_summary AS
SELECT o.order_id, c.customer_name, o.amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id;
```

**Check:** An order for customer Ana shows Ana's name and the original amount; it is not aggregated.

### 16. [Definition] Materialized view freshness

**Question:** A new sale is inserted after a materialized view was populated. When does the stored result include it?

A. After the materialized view is refreshed.  
B. Immediately, like a regular view.  
C. Only after restarting PostgreSQL.  
D. Never; materialized views cannot change.

**Answer: A.** A materialized view stores query results and needs refresh to replace them with current results.

**Easy example:** It is a photo of sales; take a new photo to include new sales.

### 17. [Read/Fix] Query the intended object

**Question:** You created a materialized view named `daily_sales` from `sales`. Which query reads its stored rows?

A. `SELECT * FROM daily_sales;`  
B. `SELECT * FROM sales;`  
C. `SELECT * FROM pg_views;`  
D. `REFRESH MATERIALIZED VIEW sales;`

**Answer: A.** Query the materialized view by its own name. Querying `sales` still reads the source table.

**Easy example:** Ask for the saved daily summary, not the raw receipts.

### 18. [Write SQL] Build and refresh a daily summary

**Task:** Given `sales(sale_date date, amount)`, create a materialized view `daily_sales` with one row per date and its total amount. Show the statement to update its stored result later.

**Reference solution:**

```sql
CREATE MATERIALIZED VIEW daily_sales AS
SELECT sale_date, SUM(amount) AS total_amount
FROM sales
GROUP BY sale_date;

REFRESH MATERIALIZED VIEW daily_sales;
```

**Check:** Two sales of 10 and 20 on one date produce a total of 30. The refresh statement is for later, after source data changes.

## Functions

### 19. [Definition] Reusable calculation

**Question:** Many queries use the same small calculation with different input amounts. What can package that calculation behind one name?

A. A function with an input parameter.  
B. An `ORDER BY` clause.  
C. A CTE in one unrelated query.  
D. An index alone.

**Answer: A.** A function accepts input and returns a result that callers can reuse.

**Easy example:** Call `add_tax(100)` and `add_tax(200)` instead of copying the tax formula everywhere.

### 20. [Read/Fix] Read a function call

**Question:** What does `double_amount(7)` return?

```sql
CREATE FUNCTION double_amount(value numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE
AS $$ SELECT value * 2 $$;
```

A. 14.  
B. 7.  
C. 2.  
D. NULL.

**Answer: A.** The input replaces `value`, so the expression is `7 * 2`.

**Easy example:** The function is a small calculator with one input slot.

### 21. [Write SQL] Calculate a shipping fee

**Task:** Write a PostgreSQL SQL function `shipping_fee(weight_kg numeric)` returning 5 when weight is at most 5 kg, otherwise 10. Assume nonnegative, non-NULL weight.

**Reference solution:**

```sql
CREATE FUNCTION shipping_fee(weight_kg numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE STRICT
AS $$
  SELECT CASE WHEN weight_kg <= 5 THEN 5 ELSE 10 END
$$;
```

**Check:** `shipping_fee(5)` is 5; `shipping_fee(6)` is 10. `STRICT` also makes a NULL input return NULL.

### 22. [Definition] NULL input and STRICT

**Question:** For a PostgreSQL function declared `STRICT`, what happens when an input argument is NULL?

A. The function returns NULL without running its body.  
B. The function treats NULL as zero.  
C. The function always raises an error.  
D. The function drops the input row.

**Answer: A.** `STRICT` (also called `RETURNS NULL ON NULL INPUT`) skips evaluation for NULL arguments.

**Easy example:** If a calculator requires a weight and no weight is supplied, it gives no fee rather than guessing zero.

### 23. [Read/Fix] Choose a truthful volatility label

**Question:** A function returns `CURRENT_DATE`. Why is `IMMUTABLE` the wrong label?

A. Its result can differ on another day; `STABLE` is appropriate for a date that stays fixed within a statement.  
B. `CURRENT_DATE` is always NULL in functions.  
C. Only PL/pgSQL functions may use `CURRENT_DATE`.  
D. `IMMUTABLE` means the function may change tables.

**Answer: A.** An immutable function must not depend on time or other changing external state.

**Easy example:** “What day is it?” does not have the same answer forever.

### 24. [Write SQL] Classify a customer's spend

**Task:** Write `spend_tier(total numeric)` returning `'high'` for totals at least 1000, `'medium'` for totals at least 100 but below 1000, and `'low'` otherwise. Assume nonnegative, non-NULL totals.

**Reference solution:**

```sql
CREATE FUNCTION spend_tier(total numeric)
RETURNS text LANGUAGE sql IMMUTABLE STRICT
AS $$
  SELECT CASE
    WHEN total >= 1000 THEN 'high'
    WHEN total >= 100 THEN 'medium'
    ELSE 'low'
  END
$$;
```

**Check:** 1000 is high; 100 is medium; 99 is low. The order of the conditions matters.

### 25. [Definition] Function access rights

**Question:** A function is declared `SECURITY DEFINER`. Whose database privileges does it generally use while running?

A. The function owner's.  
B. The caller's, exactly as with `SECURITY INVOKER`.  
C. Every database user's combined privileges.  
D. No privileges at all.

**Answer: A.** This can be useful but needs careful privilege and `search_path` design.

**Easy example:** The function runs with the owner's key, so do not let it open doors the caller should not access.

### 26. [Read/Fix] Treat a missing discount correctly

**Question:** A NULL discount means no discount. What is the result of `100 - COALESCE(NULL, 0)`?

A. 100.  
B. 0.  
C. NULL.  
D. An error.

**Answer: A.** `COALESCE` uses zero when the discount is NULL.

**Easy example:** If no discount is recorded, subtract nothing from 100.

### 27. [Write SQL] Return a net amount

**Task:** Write `net_amount(gross numeric, discount numeric)` to return gross minus discount. Treat a NULL discount as zero. Assume gross is non-NULL and both numbers are nonnegative.

**Reference solution:**

```sql
CREATE FUNCTION net_amount(gross numeric, discount numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE
AS $$
  SELECT gross - COALESCE(discount, 0)
$$;
```

**Check:** `net_amount(100, 20)` is 80; `net_amount(100, NULL)` is 100. Do not mark this version `STRICT`: then a NULL discount would return NULL before `COALESCE` runs.

## Review rubric

- Definition checks: one best answer; distractors should reflect a plausible misconception, not a joke answer.
- Read/fix questions: assess what the SQL actually does, including row counts and NULL behavior.
- Write-SQL challenges: grade the output and edge cases, accepting equivalent SQL. In an app, use a safe test database or a structured rubric rather than literal string comparison.
- If this format feels right, the same mix can be used for other subtopics; the coding share can be reduced for topics with little meaningful SQL to write.
