# CTEs, Views & Functions — 27 practical MCQ/MCMA questions

Review draft only. PostgreSQL is the reference dialect unless a question says otherwise. **MCQ** means choose one; **MCMA** means choose all correct answers. Each MCMA has two correct answers. These questions mix the concepts in the supplied 20-question set with concrete query-reading and design situations. No Supabase data has been changed.

## CTEs

### 1. [MCQ] CTE or temporary table?

Two separate SQL statements in a session need to read the same prepared set of customer totals. Which object can hold it across both statements?

A. A temporary table created before both statements.  
B. A CTE declared in the first statement.  
C. A subquery alias in the first statement.  
D. A `WITH` clause after the first statement's semicolon.

**Answer: A.** A CTE's name lasts for its statement; a temporary table can remain available later in the session. **pro_tips:** In an ETL job with separate validation and load statements, put reusable intermediate rows in a temporary table; use a CTE for steps needed by just one statement.

### 2. [MCMA] Read a CTE result

`orders` contains `(1, 'paid', 20)`, `(2, 'open', 30)`, `(3, 'paid', 40)` as `(order_id, status, amount)`.

```sql
WITH paid AS (
  SELECT order_id, amount FROM orders WHERE status = 'paid'
)
SELECT order_id, amount FROM paid ORDER BY order_id;
```

Which statements are true? Choose all that apply.

A. The output has two rows.  
B. The output includes order 2.  
C. The amounts returned are 20 and 40.  
D. A later, separate statement can query `paid` without defining it again.

**Answers: A, C.** The filter keeps paid orders 1 and 3. **pro_tips:** When checking a payment report, run the CTE's inner `SELECT` on its own first to confirm which orders qualify before adding the final aggregation.

### 3. [MCQ] Recursive CTE parts

What is the usual shape of a PostgreSQL recursive CTE that walks an employee hierarchy?

A. A starting query, then `UNION` or `UNION ALL`, then a query referring to the CTE.  
B. Two unrelated queries joined with `CROSS JOIN`.  
C. A `GROUP BY` followed by a window function.  
D. A temporary table followed by an index.

**Answer: A.** The starting query supplies the first employees; the recursive query finds the next level. `UNION ALL` is common, but `UNION` is also valid. **pro_tips:** Use this pattern to expand a category tree or bill of materials from a chosen parent, then attach a `depth` column so reports can distinguish levels.

### 4. [MCMA] Avoid a looping hierarchy

An employee hierarchy has bad data: A reports to B and B reports to A. Which approaches can keep a recursive query from running indefinitely? Choose all that apply.

A. Track visited IDs and reject a repeated ID.  
B. Stop after a maximum depth.  
C. Add `ORDER BY employee_id` only.  
D. Rename the recursive CTE.

**Answers: A, B.** Cycle tracking addresses the actual loop; a depth cap is a safety bound, although it may truncate valid deep hierarchies. **pro_tips:** For organizational or dependency data imported from another system, detect repeated IDs and alert on cycles; keep a depth cap as an extra safeguard, not the only data-quality rule.

### 5. [MCQ] Repeated CTE references

A PostgreSQL query uses the same expensive, side-effect-free CTE twice. What should you check before assuming it runs twice?

A. Its actual plan: PostgreSQL normally materializes a CTE referenced more than once, while `NOT MATERIALIZED` can permit repeated work.  
B. Whether its name starts with `temp_`.  
C. Whether the base table has a primary key.  
D. Whether the query ends with `ORDER BY`.

**Answer: A.** Reuse and predicate pushdown are a trade-off; inspect the plan rather than applying a universal rule. **pro_tips:** If a report joins the same expensive customer CTE twice, compare actual plans before changing it: computing once may save work, while folding may let each branch filter earlier.

### 6. [MCMA] Choose materialization deliberately

For a side-effect-free PostgreSQL CTE, which statements are accurate? Choose all that apply.

A. `AS MATERIALIZED` can prevent folding it into the parent query.  
B. `AS NOT MATERIALIZED` can allow parent filters to be pushed into it, potentially duplicating computation.  
C. `AS MATERIALIZED` creates a permanent table for future sessions.  
D. Both keywords guarantee a faster query.

**Answers: A, B.** The best choice depends on the work repeated and the filters each reference needs. **pro_tips:** For a large orders table, test `MATERIALIZED` versus `NOT MATERIALIZED` with real customer/date filters and compare `EXPLAIN (ANALYZE, BUFFERS)` before adopting either as a default.

### 7. [MCQ] Fill missing reporting dates

A dashboard must show all seven days, including days with zero sales. In PostgreSQL, which plan is clearest for this fixed date range?

A. Generate the seven dates with `generate_series`, left join daily sales, and use `COALESCE` for missing totals.  
B. Start from sales and use an inner join to a date list.  
C. Add `ORDER BY sale_date` to sales.  
D. Use `DISTINCT` on sales dates.

**Answer: A.** Start from the complete calendar, then attach sparse sales. A recursive CTE can also generate dates, but PostgreSQL's `generate_series` is usually simpler here. **pro_tips:** Build a calendar series before joining daily pipeline runs so a day with no run appears as zero instead of disappearing from an operations chart.

### 8. [MCMA] Check the level of detail

A CTE returns one row per customer with `total_amount`. It is joined to `customer_tags`, which has three rows for one customer. Which statements are true? Choose all that apply.

A. The joined result can have three rows for that customer.  
B. Summing `total_amount` after the join can triple that customer's total.  
C. A CTE automatically prevents join duplication.  
D. Adding `ORDER BY` to the CTE fixes the total.

**Answers: A, B.** A join can change the result's level of detail. **pro_tips:** Before joining a customer-level revenue table to multi-valued tags, check counts at both levels; otherwise a dashboard may overstate revenue for customers with several tags.

### 9. [MCQ] Fix the customer total

You only want customer IDs that have at least one tag, along with their original customer totals. Which approach avoids multiplying a customer's total by tag count?

A. Select from `customer_totals` and filter with `EXISTS (SELECT 1 FROM customer_tags WHERE customer_id = ...)`.  
B. Join all tags and sum `total_amount` again.  
C. Cross join customer totals with tags.  
D. Join tags and divide by a fixed number of three.

**Answer: A.** `EXISTS` tests whether a tag exists without adding tag rows. **pro_tips:** Use `EXISTS` to filter orders to customers with a fraud-review flag when you do not need any columns from the flag table; this avoids duplicating orders with multiple flags.

## Views

### 10. [MCQ] Regular view behavior

A regular view selects open orders. Order 7 changes from `open` to `closed`. What does a new query against the view show?

A. Order 7 disappears, assuming the change is visible to that query.  
B. Order 7 stays until `REFRESH MATERIALIZED VIEW` runs.  
C. The view becomes invalid.  
D. Order 7 appears twice.

**Answer: A.** A regular view does not store a separate snapshot of result rows. **pro_tips:** Use a regular view for a support queue that should reflect newly closed tickets on the next query, subject to the transaction's visibility rules.

### 11. [MCMA] Make a view useful and safe

A support dashboard needs customer ID and name, but not email. Which actions support that design? Choose all that apply.

A. Define the view to select only ID and name.  
B. Give the support role access to the view and review its direct access to the base table.  
C. Assume excluding email in the view revokes all existing base-table privileges.  
D. Assume every view automatically encrypts its base table.

**Answers: A, B.** Projection narrows what the view exposes; permissions determine whether users can bypass it. **pro_tips:** Give analysts a customer view without email or phone, then verify their role cannot select those fields directly from the base table.

### 12. [MCQ] Dashboard performance trade-off

A daily dashboard repeatedly reads an expensive store-level summary and can tolerate data that is up to one hour old. Which option is worth testing?

A. A materialized view refreshed on an agreed schedule.  
B. A regular view with no performance testing.  
C. A view with `ORDER BY` but no aggregation.  
D. A CTE in one dashboard query that persists across refreshes.

**Answer: A.** Stored results may reduce repeated work, but need storage and refresh planning. **pro_tips:** A regional sales dashboard that refreshes hourly may benefit from a stored aggregate; show its last-refresh time so viewers know how current the figures are.

### 13. [MCMA] Plan materialized-view refresh

What should a team decide before using a PostgreSQL materialized view for a report? Choose all that apply.

A. How stale the report may be and when refresh will run.  
B. Whether refresh cost and storage fit the workload.  
C. How to disable all database permissions.  
D. Whether `SELECT` automatically refreshes it.

**Answers: A, B.** `SELECT` reads stored results; it does not refresh them. **pro_tips:** Schedule refresh after the upstream sales load succeeds, then alert if the materialized view is older than the dashboard's freshness target.

### 14. [MCQ] Correct an aggregate view

```sql
CREATE VIEW store_sales AS
SELECT store_id, SUM(amount) AS total_amount
FROM sales;
```

The goal is one row per store. Which change is needed?

A. Add `GROUP BY store_id`.  
B. Add `ORDER BY amount`.  
C. Add `LIMIT 1`.  
D. Replace `SUM(amount)` with `COUNT(*)`.

**Answer: A.** The grouping column defines one output row per store. **pro_tips:** In a store-performance view, document that each row is one store; add `sale_date` to `GROUP BY` only when consumers actually need one row per store per day.

### 15. [MCMA] dbt model choices

A dbt project defines SQL models. Which statements are accurate? Choose all that apply.

A. A `view` materialization can create a view from the model query.  
B. A `table` materialization can persist the model result as a table.  
C. Every dbt model runs entirely in Python without the warehouse.  
D. Every dbt model is a PostgreSQL materialized view.

**Answers: A, B.** The chosen materialization controls how dbt builds the relation in the warehouse. **pro_tips:** Start a small transformation as a dbt view, then benchmark a table materialization if repeated dashboard reads make recomputation expensive.

### 16. [MCQ] Updating a simple view

In PostgreSQL, `active_customers` is a simple view over one table, selecting ordinary columns and filtering `status = 'active'`. What may happen when a permitted user updates a customer's name through that view?

A. PostgreSQL can update the underlying customer row.  
B. Only a materialized view can accept updates.  
C. The update changes only the stored SQL definition.  
D. Every regular view rejects updates.

**Answer: A.** Simple views can be automatically updatable; aggregate and complex views generally are not. **pro_tips:** A support tool may update a customer's display name through a simple view; test permissions and `WITH CHECK OPTION` if updates must keep rows inside the view's filter.

### 17. [MCMA] Many layers of views

A report reads a view built on a view built on several more views. What are sensible review steps? Choose all that apply.

A. Inspect the final query plan and actual runtime.  
B. Trace the underlying joins and filters for redundant work or unexpected row multiplication.  
C. Assume every nested view is slow.  
D. Remove all indexes because the report uses views.

**Answers: A, B.** Nesting can make behavior harder to understand, but it is not automatically slow. **pro_tips:** If a dashboard overcounts or slows down, trace each view layer to the base joins and inspect the final plan before flattening the models.

### 18. [MCQ] Freshness check

A materialized view was refreshed at 09:00, and a sale was committed at 09:05. At 09:10, before another refresh, what should the dashboard expect from that materialized view?

A. It may omit the new sale.  
B. It must contain the new sale.  
C. It stops accepting `SELECT`.  
D. It reads the new sale only when `ORDER BY` is present.

**Answer: A.** Its stored result reflects the last refresh, not every subsequent source change. **pro_tips:** For near-real-time incident metrics, compare the required freshness with the refresh schedule; use a regular view or base-table query if a five-minute delay is unacceptable.

## Functions

### 19. [MCQ] Reusable calculation

Several reports need to label amounts as `small`, `medium`, or `large` using the same thresholds. What is a reasonable way to centralize that calculation?

A. A function taking an amount and returning a label.  
B. A separate `ORDER BY` in each report.  
C. An index that stores the labels automatically.  
D. A CTE defined in one unrelated report.

**Answer: A.** A function can package a reusable input-to-output rule. **pro_tips:** Centralize a stable order-size classification used by several reports so a threshold change is made in one place and tested once.

### 20. [MCMA] Read a fee function

```sql
CREATE FUNCTION shipping_fee(weight_kg numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE STRICT
AS $$ SELECT CASE WHEN weight_kg <= 5 THEN 5 ELSE 10 END $$;
```

Which statements are true? Choose all that apply.

A. `shipping_fee(5)` returns 5.  
B. `shipping_fee(6)` returns 10.  
C. `shipping_fee(NULL)` returns 10.  
D. `IMMUTABLE` means the function can change the shipping table.

**Answers: A, B.** The boundary is inclusive; `STRICT` makes a NULL input return NULL. **pro_tips:** Before using the fee function in checkout reporting, test weights 5, 5.01, and NULL to catch boundary and missing-data mistakes.

### 21. [MCQ] Avoid an incorrect volatility label

A function returns `CURRENT_DATE`. Which PostgreSQL volatility label fits better than `IMMUTABLE`?

A. `STABLE`.  
B. `IMMUTABLE`, because today's date never changes.  
C. `PARALLEL SAFE`, which is a volatility label.  
D. `STRICT`, which guarantees a constant date.

**Answer: A.** The date is stable within a statement but can change over time. **pro_tips:** When writing a reporting function that labels rows as overdue based on today, use a truthful volatility label so planned or cached execution does not treat the date-dependent result as timeless.

### 22. [MCMA] NULL discount

A function should return `gross - discount`, treating a NULL discount as zero. Which design details are appropriate? Choose all that apply.

A. Use `COALESCE(discount, 0)` in the calculation.  
B. Do not mark this version `STRICT` if a NULL discount must still produce a number.  
C. Use `gross - discount` alone; subtraction turns NULL into zero.  
D. Mark it `STRICT`; that makes NULL discounts become zero.

**Answers: A, B.** In SQL, arithmetic with NULL yields NULL, and `STRICT` returns NULL before the body runs. **pro_tips:** If an order feed omits optional discounts, normalize them with `COALESCE` before calculating net revenue, and test that missing discount leaves gross unchanged.

### 23. [MCQ] Side effects in PostgreSQL functions

Which statement is accurate for PostgreSQL?

A. A `VOLATILE` function can perform database-changing work; functions are not universally side-effect-free.  
B. Every function is read-only, regardless of language and volatility.  
C. Only procedures can take parameters.  
D. An `IMMUTABLE` function is intended to update tables on each call.

**Answer: A.** Procedures and functions differ, but “functions can never change data” is not a valid PostgreSQL rule. **pro_tips:** Review a `VOLATILE` audit-logging function for side effects before calling it from a large `SELECT`, because it may execute for many rows.

### 24. [MCMA] Function performance

A scalar function is called for millions of rows in a report. What should you do before deciding it is the bottleneck? Choose all that apply.

A. Measure the actual plan and runtime with realistic data.  
B. Check whether the work can be expressed efficiently as set-based SQL.  
C. Assume every scalar function disables every index.  
D. Assume every scalar function is automatically inlined.

**Answers: A, B.** Per-row calls can be costly, but the effect depends on the function and engine. **pro_tips:** Benchmark a function over realistic event volumes; if it dominates runtime, compare it with an equivalent `CASE`, join, or other set-based expression.

### 25. [MCQ] Function versus view

A report needs the same customer filter but with a different `min_spend` value each time. Which object naturally accepts `min_spend` as an argument in PostgreSQL?

A. A set-returning function.  
B. A regular view with a parameter list.  
C. A materialized view with a parameter list.  
D. A column alias with a parameter list.

**Answer: A.** A function can accept parameters and return rows; a regular view has no caller-supplied parameter list. **pro_tips:** Use a set-returning function when an operations report must request orders for a chosen customer ID without maintaining a separate view per customer.

### 26. [MCMA] Safe `SECURITY DEFINER` use

A function must run with its owner's privileges. Which precautions are appropriate? Choose all that apply.

A. Grant execute access only to intended roles.  
B. Control object lookup with a safe `search_path` and schema-qualified references where appropriate.  
C. Assume every caller becomes a database superuser.  
D. Ignore base-table permissions because the function is never a security boundary.

**Answers: A, B.** Elevated execution context requires tight access and predictable name resolution. **pro_tips:** For a controlled support action that reads protected data, grant execution only to the support role and pin the function's object lookup to trusted schemas.

### 27. [MCQ] Pick an implementation for reusable filtering

You need `orders_for_customer(customer_id)` so several queries can pass different IDs and receive that customer's orders. Which SQL shape best matches the requirement?

A. `CREATE FUNCTION orders_for_customer(p_id bigint) RETURNS TABLE (...) ... WHERE customer_id = p_id`.  
B. `CREATE VIEW orders_for_customer(p_id bigint) AS ...`.  
C. `CREATE MATERIALIZED VIEW orders_for_customer(p_id bigint) AS ...`.  
D. `WITH orders_for_customer(p_id bigint) AS (...)` shared by all future statements.

**Answer: A.** A set-returning function can parameterize a row-producing query. **pro_tips:** A customer-detail screen can pass its selected customer ID to one tested function instead of fetching all customers' orders and filtering them in the app.

## Editorial checks before publishing

- Keep **MCQ** and **MCMA** explicit in both the database and UI; do not make learners infer it from wording alone.
- Store correct options as stable option IDs, not exact answer text. For MCMA, grade the selected set against the correct set; decide separately whether partial credit is allowed.
- The supplied set mixed PostgreSQL, SQL Server, and warehouse-specific claims. These questions use PostgreSQL where engine behavior matters. If your app targets multiple engines, add a dialect tag or replace engine-specific questions.
- Several distractors remain intentionally simple for a first review. Before shipping, pilot-test them and replace choices that almost nobody selects with plausible mistakes from real learner responses.

## Verification sources

- PostgreSQL: `WITH` queries and recursive CTEs: https://www.postgresql.org/docs/current/queries-with.html
- PostgreSQL: views and automatic updatability: https://www.postgresql.org/docs/current/sql-createview.html
- PostgreSQL: function volatility: https://www.postgresql.org/docs/current/xfunc-volatility.html
- dbt: SQL model materializations: https://docs.getdbt.com/docs/build/sql-models
