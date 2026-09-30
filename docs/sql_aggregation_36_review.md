# SQL Aggregation — 36-question review draft

Review only; this does not update Supabase. IDs match the supplied export. The answer letters below are draft display positions, not existing option IDs. For multi-select questions, retain the existing MCMA type and three correct flags.

Coverage: basic aggregates and NULLs (1, 7, 9, 14, 15, 20, 25); grouping, HAVING, and counting (3, 4, 6, 8, 16–19, 27); windowed aggregates and ranking (5, 11, 22–24, 30–31); deduplication (10, 12–13, 21, 28, 33–36); joins and historical attribution (26, 29, 32); physical design (2). The deduplication and physical-design items are not strictly Aggregation and could move to more precise subtopics later. Questions 10, 12, 13, 21, and 28 are multi-select, with three correct answers each.

## Junior

### 1 · `c0ef2cf9-7c77-4d8f-8356-a3b1e15eff49`

Q: Payment amounts for one account are 20, NULL, and 30. What does `SUM(amount)` return for that account?

A. 50, because SUM skips the NULL value.
B. NULL, because one input value is NULL.
C. 30, because SUM keeps only the last value.
D. 3, because SUM counts the input rows.

Answer: A. SUM adds non-NULL values; it does not turn the whole total into NULL. The tempting answer B confuses arithmetic with an aggregate: `20 + NULL` is NULL, but `SUM` skips that NULL.

Remember: For `{20, NULL, 30}`, `SUM(amount) = 50`. For `{NULL, NULL}`, SUM returns NULL, not zero.

Pro tip: Use `COALESCE(SUM(amount), 0)` only when the business meaning of no known amounts is zero.

### 2 · `60a935dd-e6db-4c38-a033-a34556385cb2`

Q: A BigQuery sales table covers five years. Reports filter one sale date and often one customer. Why might partitioning by date and clustering by customer help together?

A. Date partitioning finds the customer, while clustering removes old years.
B. Both techniques guarantee the query reads exactly one row.
C. The date filter limits partitions; clustering may reduce work inside them.
D. Clustering replaces the date filter once the table is partitioned.

Answer: C. The two techniques work at different levels. Neither guarantees one-row reads or removes the need for filters.

Remember: From five years of sales, `sale_date = Monday` narrows to Monday's partition; `customer_id = 7` may narrow data read within that partition.

Pro tip: Check bytes scanned and the query plan; clustering benefits depend on data layout and selectivity.

### 3 · `bb2c17f1-e098-497c-99fd-49de8b7bc7bc`

Q: Orders have an `order_date` DATE and an `amount`. Which BigQuery query returns one revenue total per calendar month?

A. `SELECT order_date, SUM(amount) FROM orders GROUP BY order_date`
B. `SELECT DATE_TRUNC(order_date, MONTH) AS month, SUM(amount) FROM orders GROUP BY month`
C. `SELECT MONTH(order_date) AS month, SUM(amount) FROM orders GROUP BY month`
D. `SELECT DATE_TRUNC(order_date, MONTH) AS month, amount FROM orders GROUP BY month`

Answer: B. DATE_TRUNC retains the year and month, and SUM adds amounts at that grain. C can merge January from different years.

Remember: Jan 3 and Jan 20 of 2026 with amounts 10 and 25 become `2026-01-01 → 35`; Jan 2027 stays separate.

Pro tip: If the source is a timestamp, agree on the reporting timezone before deriving the calendar month.

### 4 · `a8b01c5f-e580-4957-974e-ff75702cdfdd`

Q: An orders table has one row per order. Which query finds customers with more than five orders?

A. `SELECT customer_id FROM orders WHERE COUNT(*) > 5 GROUP BY customer_id`
B. `SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(*) >= 5`
C. `SELECT customer_id FROM orders HAVING COUNT(*) > 5`
D. `SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(*) > 5`

Answer: D. HAVING filters grouped counts, and “more than five” excludes exactly five. B includes five.

Remember: Customer A has five orders and B has six. `HAVING COUNT(*) > 5` returns B only.

Pro tip: Confirm the input really is one row per order; retries or item rows can inflate COUNT(*).

### 5 · `7dfe78e4-065c-4966-a2d2-47fbdc78b1ed`

Q: Salespeople with equal scores should share a rank, but the next rank must not skip a number. Which function fits?

A. `ROW_NUMBER()`
B. `RANK()`
C. `DENSE_RANK()`
D. `NTILE(4)`

Answer: C. DENSE_RANK shares ranks for ties without gaps; RANK leaves gaps.

Remember: Scores `{90, 90, 80}` get dense ranks `{1, 1, 2}`, while RANK gives `{1, 1, 3}`.

Pro tip: Decide whether ties should share a rank before choosing a ranking function.

### 6 · `4c798d86-d177-4353-b564-7d212a974bc9`

Q: A raw orders table has one row per order and a non-NULL `order_id`. How do you count orders for each customer?

A. `SELECT customer_id, COUNT(order_id) FROM orders GROUP BY customer_id`
B. `SELECT customer_id, SUM(order_id) FROM orders GROUP BY customer_id`
C. `SELECT customer_id, COUNT(customer_id) FROM orders GROUP BY order_id`
D. `SELECT customer_id, COUNT(order_id) FROM orders GROUP BY order_id`

Answer: A. It groups by customer and counts that customer's non-NULL order IDs. C and D group at the wrong grain.

Remember: Rows `(A, O1), (A, O2), (B, O3)` become `A → 2` and `B → 1`.

Pro tip: On a raw one-row-per-order table, `COUNT(*)` is also fine; after an outer join, count the matched order ID instead.

### 7 · `fb156b0a-a4ea-4eed-b7ea-758845cfd2d4`

Q: You need the number of rows in an orders table, including rows with NULL values in some columns. Which expression fits?

A. `COUNT(order_id)`
B. `COUNT(*)`
C. `SUM(order_id)`
D. `COUNT(DISTINCT order_id)`

Answer: B. COUNT(*) counts rows regardless of NULL column values. The other counts can exclude rows or collapse duplicates.

Remember: Rows with IDs `{1, NULL, 1}` give `COUNT(*) = 3`, `COUNT(order_id) = 2`, and `COUNT(DISTINCT order_id) = 1`.

Pro tip: State whether the request means source rows, non-NULL IDs, or distinct business entities.

### 8 · `fb1b6237-c4c6-445c-8659-0f045c77d229`

Q: A report needs every customer and their order count, including customers with zero orders. Which pattern is right?

A. Inner join customers to orders and count `orders.order_id`.
B. Left join customers to orders and count `*`.
C. Left join customers to orders and count `orders.order_id`.
D. Right join customers to orders and count `customers.customer_id`.

Answer: C. The left join preserves every customer; counting the nullable right-side order ID yields zero when none matches. B counts the placeholder row as one.

Remember: Customers `{A, B}` and orders `{A: O1}` produce `A → 1`, `B → 0` with `COUNT(o.order_id)`.

Pro tip: Group by the customer key; if you include other customer columns, follow your engine's grouping rules.

### 9 · `ea3b6e3e-7945-4008-9298-0fe4dddbaf42`

Q: HR needs the highest non-NULL salary in a table. Which expression returns it?

A. `SUM(salary)`
B. `AVG(salary)`
C. `MIN(salary)`
D. `MAX(salary)`

Answer: D. MAX returns the largest non-NULL value, not the total or average.

Remember: Salaries `{40, 60, NULL}` give `MAX(salary) = 60`.

Pro tip: If all salaries are NULL or there are no rows, MAX returns NULL; plan for that in reports.

### 10 · `ef813e71-1f72-45fc-ba64-71d4767a5041` · Select all that apply

Q: Customer records are duplicates only when both `customer_id` and `source_system` match. Keep the latest `updated_at` in each duplicate group. Which statements are correct?

A. Partition ROW_NUMBER by both `customer_id` and `source_system`.
B. Order each partition by `updated_at DESC`.
C. Partition only by `customer_id` to combine all sources.
D. Keep the row whose generated row number is one.
E. Order by `updated_at ASC` to keep the latest row.

Answer: A, B, D. The two-column partition defines the duplicate key, descending time puts the newest first, and row number one selects it. C merges distinct source records.

Remember: `(7, CRM, 10:00)`, `(7, CRM, 11:00)`, `(7, ERP, 09:00)` leave the CRM 11:00 row and the ERP 09:00 row.

Pro tip: Add a stable second sort key if two rows can share the same updated_at.

### 11 · `dbc0a54a-f60b-4620-9730-c25b49617d6e`

Q: One row holds each store's daily sales. How do you show a running sales total through each day, restarting for each store?

A. `SUM(daily_sales) OVER (ORDER BY store_id)`
B. `SUM(daily_sales) OVER (PARTITION BY store_id)`
C. `SUM(daily_sales) OVER (PARTITION BY store_id ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`
D. `SUM(daily_sales) GROUP BY store_id, sale_date`

Answer: C. It partitions by store, orders days, and defines the running frame. B gives the full store total on each row.

Remember: Store A's daily values `{Mon: 10, Tue: 5}` display running values `{Mon: 10, Tue: 15}`.

Pro tip: Use ROWS and a deterministic order when the grain can have multiple rows on the same date.

### 12 · `806714cd-fa70-45da-a680-84be835368c1` · Select all that apply

Q: An events table can contain retried copies. A duplicate is the same `(user_id, event_id)`. Keep the most recently ingested copy. Which steps are correct?

A. Partition ROW_NUMBER by `user_id, event_id`.
B. Order each group by `ingestion_time DESC`.
C. Partition only by `user_id`.
D. Keep rows where the generated row number is one.
E. Keep every row tied for the latest ingestion time.

Answer: A, B, D. These define the event key, newest-first preference, and one retained row. E could retain multiple copies.

Remember: `(U1, E1, 10:00)` and `(U1, E1, 10:05)` leave only the 10:05 copy; `(U1, E2, 09:00)` stays too.

Pro tip: If equal ingestion times occur, include a stable unique ingestion ID as a tie-breaker.

### 13 · `b58ed7c2-8fb5-480b-8a1f-63c711c044f5` · Select all that apply

Q: Two product updates have the same `product_id` and `updated_at`. A ROW_NUMBER query sorts only by updated_at. Which statements are correct?

A. Keep `PARTITION BY product_id` to separate products.
B. The chosen row may vary when timestamps tie.
C. Add a stable unique sort key after updated_at.
D. ROW_NUMBER will keep both tied rows as number one.
E. Sorting by updated_at alone guarantees the same winner.

Answer: A, B, C. A tie makes the winner unspecified unless another ordering key settles it. ROW_NUMBER still assigns different numbers.

Remember: Two updates for P1 at 12:00 need another key, such as ingestion IDs 8 and 9; ordering by time then ID selects one predictably.

Pro tip: Choose the tie-breaker according to business priority, not just whichever column happens to be unique.

### 14 · `a61ce9c4-98fb-451c-bd0b-197feea4bf0b`

Q: Products have `category` and `price`. Which query returns one average price per category?

A. `SELECT category, AVG(price) FROM products`
B. `SELECT category, AVG(price) FROM products GROUP BY price`
C. `SELECT category, SUM(price) FROM products GROUP BY category`
D. `SELECT category, AVG(price) FROM products GROUP BY category`

Answer: D. Grouping defines one result per category, and AVG computes that category's mean. C computes a total instead.

Remember: Category A prices `{10, 20}` give `A → 15`; category B price `{8}` gives `B → 8`.

Pro tip: AVG ignores NULL prices; decide whether missing prices should be excluded or reported separately.

### 15 · `ce6c2a95-23a1-4e6e-a93e-7a4aedf46d82`

Q: A product table has prices 10, 20, and 30. Which expression returns the average product price?

A. `COUNT(price)`
B. `AVG(price)`
C. `SUM(price)`
D. `MAX(price)`

Answer: B. AVG divides the total of non-NULL prices by the count of non-NULL prices.

Remember: `{10, 20, 30}` gives `AVG(price) = 20`, while `SUM(price) = 60`.

Pro tip: If the question asks for an average across categories of different sizes, a simple average of category averages may be wrong.

### 16 · `8a321092-8c1e-4bb9-b8ba-9e1343c460cc`

Q: A status table has one row per customer-month and status `active`, `inactive`, or `pending`. How can a report show each customer's count for each status in one row?

A. Group by customer and status, then return three rows per customer.
B. Count all rows three times under different column names.
C. Group by customer and sum a separate CASE expression for each status.
D. Keep only active rows, then count all three status columns.

Answer: C. Conditional aggregation counts each status while keeping one group per customer. A changes the output grain.

Remember: A has statuses `{active, active, pending}` and becomes `active=2, inactive=0, pending=1`.

Pro tip: If status can be NULL or have new values, add an “other/unknown” count to catch records outside the three known categories.

### 17 · `d7183217-4d28-42fb-8170-0a82863f23b8`

Q: You have `SUM(amount)` per customer and only want customers whose total is above 5,000. Where should the total filter go?

A. In WHERE before grouping.
B. In HAVING after grouping.
C. In ORDER BY after sorting.
D. In the JOIN condition before grouping.

Answer: B. HAVING filters the grouped SUM; WHERE filters individual input rows.

Remember: Customer A has purchases 3,000 and 2,500. Neither row is above 5,000, but their grouped sum is 5,500 and passes HAVING.

Pro tip: Put row-level conditions in WHERE and group-level conditions in HAVING; pushing the wrong condition changes the result.

### 18 · `e3bb16f6-c06f-4d84-b9ed-58b8afb10b75`

Q: Sales has `department_id` and `amount`. Which query returns departments with total sales over 100,000?

A. `SELECT department_id FROM sales WHERE SUM(amount) > 100000 GROUP BY department_id`
B. `SELECT department_id FROM sales GROUP BY department_id HAVING amount > 100000`
C. `SELECT department_id FROM sales GROUP BY department_id HAVING SUM(amount) >= 100000`
D. `SELECT department_id FROM sales GROUP BY department_id HAVING SUM(amount) > 100000`

Answer: D. The filter applies to the group's SUM and uses strict “over.” C incorrectly includes exactly 100,000.

Remember: Dept A has sales 60,000 and 50,000, so its total 110,000 passes; Dept B totals exactly 100,000 and does not.

Pro tip: Make the boundary explicit: “over” means `>`, while “at least” means `>=`.

### 19 · `d5fa927d-a95f-4374-9a6b-2602b59dc995`

Q: Sales has one row per sale with `customer_id` and `amount`. Which query returns total revenue per customer?

A. `SELECT customer_id, SUM(amount) FROM sales GROUP BY customer_id`
B. `SELECT customer_id, SUM(amount) FROM sales GROUP BY amount`
C. `SELECT customer_id, COUNT(amount) FROM sales GROUP BY customer_id`
D. `SELECT customer_id, amount FROM sales GROUP BY customer_id`

Answer: A. Customer is the output grain; SUM adds each customer's amounts. C counts sales, not money.

Remember: Rows `(A, 10), (A, 15), (B, 7)` become `(A, 25), (B, 7)`.

Pro tip: If sales can be reversed or refunded, confirm whether negative amounts are already included in the source.

### 20 · `d26573b8-ee0b-4f05-a9f8-96ed9e7d54d7`

Q: A sales table has an `amount` column. Which expression adds all non-NULL amounts into one total?

A. `COUNT(amount)`
B. `AVG(amount)`
C. `SUM(amount)`
D. `MAX(amount)`

Answer: C. SUM calculates the total; COUNT counts known values, and AVG calculates their mean.

Remember: Amounts `{5, 7, NULL}` give `SUM = 12`, `COUNT(amount) = 2`, and `AVG = 6`.

Pro tip: Check the amount's units and currency before summing across sources.

### 21 · `0d687b1e-87d5-4ffc-8f3c-1feaad020d50` · Select all that apply

Q: A customer API sends several versions of the same `customer_id`. You need the latest `updated_at` version of each customer. Which statements are correct?

A. Partition ROW_NUMBER by `customer_id`.
B. Sort versions by `updated_at DESC`.
C. Keep the row assigned number one.
D. Partition by `updated_at` so versions remain together.
E. Sort by `updated_at ASC` to keep the latest.

Answer: A, B, C. The customer ID defines the group, descending time favors the latest, and row number one keeps it. D groups unrelated customers by time.

Remember: Customer 7 at 09:00 and 11:00 leaves the 11:00 row; customer 8 at 10:00 remains separately.

Pro tip: Use a deterministic tie-breaker when two versions share the same updated_at.

### 22 · `918da746-57da-493c-b9bd-c0bcf89a90e1`

Q: For each purchase, show the previous purchase amount for the same customer. Which function fits?

A. `LEAD(amount) OVER (PARTITION BY customer_id ORDER BY purchase_date)`
B. `LAG(amount) OVER (PARTITION BY customer_id ORDER BY purchase_date)`
C. `SUM(amount) OVER (PARTITION BY customer_id ORDER BY purchase_date)`
D. `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY purchase_date)`

Answer: B. LAG looks backward within each customer's ordered purchases; LEAD looks forward.

Remember: Customer A buys 10 on Monday and 20 on Tuesday. Tuesday's previous amount is 10; Monday's is NULL.

Pro tip: Add a unique second sort key if multiple purchases share the same date.

### 23 · `36151633-1055-4f06-8a3d-f5b7794d485a`

Q: Each product has one revenue row per month. For each month, show that product's following month's revenue. Which function fits?

A. `LAG(revenue) OVER (PARTITION BY product_id ORDER BY month)`
B. `SUM(revenue) OVER (PARTITION BY product_id ORDER BY month)`
C. `ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY month)`
D. `LEAD(revenue) OVER (PARTITION BY product_id ORDER BY month)`

Answer: D. LEAD reads the next row in product-month order. LAG reads the prior row.

Remember: Product A has Jan 100 and Feb 120. Jan's next-row revenue is 120; Feb's is NULL if no March row exists.

Pro tip: LEAD means next available row, not necessarily next calendar month; create a complete month grid if gaps matter.

### 24 · `9f35b846-eb4d-4e68-8e4f-8b5bcd1e57b8`

Q: Assign a unique sequence number to each customer's orders from earliest to latest. Which function fits?

A. `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id)`
B. `RANK() OVER (PARTITION BY customer_id ORDER BY order_date)`
C. `COUNT(*) OVER (PARTITION BY customer_id)`
D. `ROW_NUMBER() OVER (ORDER BY customer_id)`

Answer: A. It restarts per customer and gives each order a unique position; order_id settles same-date ties. RANK can repeat numbers.

Remember: A's two orders become 1 and 2; B's first order starts again at 1.

Pro tip: Always define a stable order if downstream logic relies on the sequence.

### 25 · `9fa1946f-01f7-46aa-8a6f-d3151266d87b`

Q: A weather table has readings of 12, 8, and NULL degrees. Which expression returns the lowest known temperature?

A. `MAX(temperature)`
B. `AVG(temperature)`
C. `MIN(temperature)`
D. `COUNT(temperature)`

Answer: C. MIN chooses the smallest non-NULL reading; NULL is skipped.

Remember: `{12, 8, NULL}` gives `MIN = 8` and `MAX = 12`.

Pro tip: MIN over all-NULL rows returns NULL, not a made-up zero-degree reading.

### 26 · `dc71df13-dc32-4ee0-b82c-e5f639795e04`

Q: An employees table stores `employee_id` and `manager_id`. How can you count direct reports for each manager, including managers with none?

A. Group employees by their own employee_id and count all rows.
B. Start from managers, left join employees on `employee.manager_id = manager.employee_id`, then count employee IDs.
C. Start from managers, inner join employees on `employee.manager_id = manager.employee_id`, then count managers.
D. Start from managers, left join employees on `employee.employee_id = manager.manager_id`, then count all rows.

Answer: B. The join follows the manager relationship, preserves managers with no reports, and counts matched employees. An inner join would lose zero-report managers.

Remember: Manager M has employees A and B reporting to M, while N has none. The result is `M → 2`, `N → 0`.

Pro tip: Define which employees qualify as managers; starting from every employee will also show non-managers with zero reports.

### 27 · `1a5bd134-2673-4652-b44a-7ed4699116d6`

Q: A BigQuery customers table has repeated email values. Which query finds non-NULL emails that occur more than once?

A. `SELECT email FROM customers WHERE COUNT(*) > 1 GROUP BY email`
B. `SELECT email FROM customers GROUP BY email HAVING COUNT(email) >= 1`
C. `SELECT DISTINCT email FROM customers WHERE email IS NOT NULL`
D. `SELECT email FROM customers WHERE email IS NOT NULL GROUP BY email HAVING COUNT(*) > 1`

Answer: D. It excludes NULL emails, groups equal emails, and keeps groups with multiple rows. C lists unique values without identifying duplicates.

Remember: Emails `{a@x, a@x, b@x, NULL}` return only `a@x`.

Pro tip: Decide whether case and whitespace should be normalized before treating two emails as equal.

### 28 · `dd5d83d0-3717-4ef0-bedc-3ea749c0f3f8` · Select all that apply

Q: Order events can be resent. Keep the most recently ingested row for each `order_id`. Which steps are appropriate?

A. Partition ROW_NUMBER by `order_id`.
B. Order each order's rows by `ingested_at DESC`.
C. Keep only rows assigned number one.
D. Partition by `status` instead of order ID.
E. Keep every row tied for the newest ingestion time.

Answer: A, B, C. These define one latest row per order. Grouping by status mixes different orders, and keeping ties can retain duplicates.

Remember: O1 arrives at 10:00 then 10:05; O2 arrives at 09:00. The kept rows are O1 at 10:05 and O2 at 09:00.

Pro tip: A later ingestion is not always a later business event; verify which timestamp defines “latest” for the requirement.

### 29 · `f4090e01-9a4f-4127-8d68-ff7803b3186d`

Q: Show total order amount for customers who placed at least one order. Customers with no orders should not appear. Which pattern fits?

A. Start from customers, left join orders, and sum amounts by customer.
B. Start from customers, cross join orders, and sum amounts by customer.
C. Inner join customers to orders on customer ID, then sum amounts by customer.
D. Group customers without joining orders, then sum customer IDs.

Answer: C. The inner join keeps only customers with a matching order and provides amounts to sum. A also includes no-order customers.

Remember: Customers `{A, B}` and one order `(A, 20)` produce only `A → 20`.

Pro tip: If orders are split into item rows, aggregate at the intended grain before joining to avoid inflated totals.

## Middle

### 30 · `4cd33218-21c3-483f-8aaf-58c5299af824`

Q: A dashboard shows each store's year-to-date sales for the current year. The table holds daily sales across several years. Which approach is suitable?

A. Sum all years per store and show that total on each current-year day.
B. Filter to the current year's days, then run a store-partitioned cumulative SUM ordered by date.
C. Filter to only today's rows, then run a store-partitioned cumulative SUM.
D. Run a cumulative SUM across every store and year without partitioning.

Answer: B. Year-to-date needs all days in the current year through each displayed day, separately for each store. C lacks earlier days.

Remember: Store A has Jan 1 = 10 and Jan 2 = 5; Jan 2 YTD is 15. Last December's 100 is excluded.

Pro tip: If the report spans several years, partition by both store and year instead of filtering to one year.

### 31 · `c65b52f3-929c-41be-8f55-48f4a69e3a13`

Q: A huge transaction table calculates a 30-day rolling average, but the report displays only the last 90 days. What input reduction should you investigate?

A. Filter to the last 90 days before the window, with no earlier input.
B. Calculate over all history, then filter to 90 days, without checking cost.
C. Filter to the last 30 days before the window, then display 90 days.
D. Include the 90 displayed days plus enough earlier rows for their 30-day frames, then filter the output.

Answer: D. The first displayed day's average still needs earlier data. A can make the first 30 days' results incomplete.

Remember: If output starts Apr 1, its 30-day average may need March 3–31 transactions even though those rows are not displayed.

Pro tip: State whether “30-day” means a calendar-time range or 30 prior rows; the SQL frame and required lookback differ.

### 32 · `94a21941-07c3-46cc-8ae1-83233386dc7e`

Q: Customer segments change over time in a Type 2 history table. How do you report monthly order revenue under the segment valid when each order happened?

A. Join orders to the customer's current segment, then group by month.
B. Group orders by month first, then join to any matching customer history row.
C. Join each order to the history row whose validity period contains its order time, then group by month and segment.
D. Join each order to every history row for that customer, then group by month and segment.

Answer: C. The time-valid join attributes each order to one historical segment before aggregation. A rewrites past revenue under today's segment.

Remember: Customer 7 is Basic in January and Pro in February. A Jan order of 10 counts under Basic; a Feb order of 20 counts under Pro.

Pro tip: Use non-overlapping half-open validity ranges such as `valid_from <= order_time < valid_to` and check for missing history.

### 33 · `f7363c99-a9f8-43cc-a106-600717fb9c1d`

Q: Email duplicates should be removed separately within each source system. Which ROW_NUMBER partition matches that rule?

A. `PARTITION BY email, source_system`
B. `PARTITION BY email`
C. `PARTITION BY source_system`
D. `PARTITION BY updated_at, source_system`

Answer: A. Both fields define the duplicate group. B would merge the same email from different systems.

Remember: `(a@x, CRM)` and `(a@x, ERP)` are two groups, so one version of each can remain.

Pro tip: Define how NULL emails are handled; partitioning all NULL emails together may incorrectly collapse unrelated people.

### 34 · `97dcca46-d9cf-4dd7-94fa-6d268138b503`

Q: A payment source resends the same `transaction_id` with later corrections. How do you retain its newest `updated_at` version?

A. Group by transaction ID and take MAX(amount).
B. Partition ROW_NUMBER by transaction ID, sort by updated_at descending, and keep row one.
C. Select DISTINCT transaction ID, amount, and status.
D. Partition ROW_NUMBER by updated_at, sort by transaction ID, and keep row one.

Answer: B. It selects a complete row from the latest version. A can combine a maximum amount with the wrong status.

Remember: T1 at 10:00 says 20/pending; T1 at 11:00 says 18/settled. Keep the 11:00 row with both 18 and settled.

Pro tip: Resolve timestamp ties deterministically, and confirm whether corrections can arrive out of order.

### 35 · `6093403a-bae4-48a1-bc9a-1d560b684e71`

Q: Product updates can share the same `product_id` and `updated_at`. What makes a ROW_NUMBER deduplication result predictable?

A. Replace ROW_NUMBER with COUNT(*).
B. Add DISTINCT after ROW_NUMBER.
C. Order by updated_at DESC plus a stable unique tie-breaker.
D. Remove product_id from the partition.

Answer: C. A second key determines which equal-timestamp row wins. DISTINCT does not define winner priority.

Remember: P1 has two updates at 12:00, ingestion IDs 4 and 5. Ordering by time DESC, ID DESC always favors ID 5.

Pro tip: Record why the tie-breaker reflects the preferred version; “largest ID” is not automatically the latest business state.

### 36 · `6d1f5eb1-8f4f-4353-864c-8fed01068ce3`

Q: ETL retries produce several rows per `order_id` in staging. Keep the latest `load_timestamp` row for each order. Which design fits?

A. Group by order ID and select MAX(load_timestamp) beside arbitrary other columns.
B. Keep every row whose load timestamp equals the table-wide maximum.
C. Partition ROW_NUMBER by load timestamp, then sort by order ID.
D. Partition ROW_NUMBER by order ID, sort by load timestamp DESC, then keep row one.

Answer: D. It chooses one complete latest row for each order. A does not reliably take all columns from the same row.

Remember: O1 loaded at 08:00 and 09:00, while O2 loaded at 08:30. Keep O1 09:00 and O2 08:30.

Pro tip: If the source can backfill old business versions, distinguish latest load from latest business update.
