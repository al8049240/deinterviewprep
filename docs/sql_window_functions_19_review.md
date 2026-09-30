# SQL Window Functions — 19-question review draft

The 19 existing IDs and their one-correct-answer format are retained. Answer letters below are draft positions, not Supabase option IDs. Six proposed new questions are in the accompanying migration. Examples use small input/output cases; pro tips address a separate practical edge case.

### 1 · `8fb932f2-0756-456d-96aa-8ea364aab238`

Q: A table has one revenue row per customer per recorded month. Which expression shows each customer's previous *recorded* revenue?

A. `LEAD(revenue) OVER (PARTITION BY customer_id ORDER BY month)`
B. `LAG(revenue) OVER (PARTITION BY customer_id ORDER BY month)`
C. `SUM(revenue) OVER (PARTITION BY customer_id ORDER BY month)`
D. `LAG(revenue) OVER (ORDER BY customer_id, month)`

Answer: B. LAG reads the preceding row inside each customer's month-ordered partition. D can read another customer's row because it lacks PARTITION BY.

Remember: A has Jan=10 and Mar=30. Mar's previous recorded revenue is 10 from Jan, not an invented February value.

Pro tip: For previous calendar month rather than previous recorded row, build a complete customer-month grid first.

### 2 · `03828074-c0c0-4558-b4c8-776848a2b0ea`

Q: Sales has several transactions on one date. A report needs one daily revenue value and a daily running total. What should happen before the window SUM?

A. Rank transactions by amount and keep one per date.
B. Apply the window SUM directly to transactions, then take one arbitrary row per date.
C. Aggregate transaction amounts to one row per date, then apply the running SUM.
D. Count transactions per date, then run SUM on those counts.

Answer: C. The report's grain is one day, so first produce daily revenue. B can give different running totals within the same day.

Remember: Monday has sales 10 and 5; Tuesday has 7. Daily rows are Mon=15 and Tue=7; running totals are 15 and 22.

Pro tip: Include a store or region key in both the daily grouping and window partition when totals must restart for each group.

### 3 · `cbb7890c-89e7-458a-b3f3-d68bba3ed2b1`

Q: Two sellers tie for first place. Both should rank 1 and the next seller should rank 3. Which function fits?

A. `RANK()`
B. `DENSE_RANK()`
C. `ROW_NUMBER()`
D. `NTILE(3)`

Answer: A. RANK gives equal values the same position and leaves a gap after ties. DENSE_RANK would give the next seller rank 2.

Remember: Revenues `{100, 100, 80}` receive RANK values `{1, 1, 3}`.

Pro tip: Decide how ties should behave before implementing top-N reports; rank <= N can return more than N rows.

### 4 · `896fb833-247e-4de6-9860-03fca246fd2c`

Q: Return exactly one highest-paid employee per department. If salaries tie, prefer the smaller employee ID. Which pattern fits?

A. `RANK() OVER (PARTITION BY department_id ORDER BY salary DESC)` and keep rank 1.
B. `ROW_NUMBER() OVER (ORDER BY salary DESC)` and keep row 1.
C. `MAX(salary) GROUP BY department_id` and select any employee name.
D. `ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC, employee_id)` and keep row 1.

Answer: D. ROW_NUMBER chooses one complete row per department, and employee ID settles ties. A can return multiple tied employees.

Remember: Dept A has employees 4 and 7, both paid 90. The chosen row is employee 4; Dept B is ranked separately.

Pro tip: A tie-breaker should be stable and agreed with the business, not depend on input row order.

### 5 · `3c4c1fd1-228c-4e0e-9ee0-f6f7ef973c55`

Q: Customer versions can share the same updated_at. The largest unique ingestion_id should win a timestamp tie. How should the versions be ordered inside each customer partition?

A. `updated_at DESC, ingestion_id DESC`
B. `updated_at DESC` only
C. `ingestion_id DESC, updated_at DESC`
D. `updated_at ASC, ingestion_id DESC`

Answer: A. Updated time is the first priority; ingestion ID breaks only equal-time ties. C can choose an older update with a larger ID.

Remember: C1 has `(10:00, id=9)` and `(11:00, id=3)`: the 11:00 row wins. If both are 11:00, the larger ID wins.

Pro tip: Verify that ingestion_id is stable and unique; a non-unique tie-breaker does not guarantee a repeatable winner.

### 6 · `26daf1c9-acce-4ce9-93f8-d527cd89110c`

Q: In BigQuery, customer rows have `updated_at` and unique `ingestion_id`. Keep the latest row for each customer using ROW_NUMBER. Which clause can filter the window result in the same SELECT block?

A. `WHERE ROW_NUMBER() OVER (...) = 1`
B. `HAVING ROW_NUMBER() OVER (...) = 1`
C. `QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC, ingestion_id DESC) = 1`
D. `GROUP BY customer_id HAVING MAX(updated_at)`

Answer: C. BigQuery's QUALIFY filters after window calculation. WHERE is evaluated before window functions.

Remember: Customer A has rows at 09:00 and 10:00. QUALIFY row number 1 leaves only A's 10:00 row.

Pro tip: Add a deterministic tie-breaker, and select the whole row rather than mixing MAX(updated_at) with unrelated columns.

### 7 · `07e7849a-796c-46b2-b47c-64b5b789303b`

Q: A table holds one status row per order event. You want to show the final status on *every* event row. In BigQuery, which window expression is safest when ordered by event_time and unique event_id?

A. `LAST_VALUE(status) OVER (PARTITION BY order_id ORDER BY event_time, event_id)`
B. `LAG(status) OVER (PARTITION BY order_id ORDER BY event_time, event_id)`
C. `MAX(status) OVER (PARTITION BY order_id)`
D. `LAST_VALUE(status) OVER (PARTITION BY order_id ORDER BY event_time, event_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)`

Answer: D. LAST_VALUE reads the last row of its frame; an explicit full-partition frame makes that the final event for every row. A's default ordered frame does not necessarily reach future rows.

Remember: An order moves NEW → PACKED → SHIPPED. With the full frame, all three rows display final status SHIPPED.

Pro tip: LAST_VALUE is about the frame, not automatically the entire partition; inspect the frame whenever ORDER BY appears.

### 8 · `5aaa5cdb-97a7-4942-87a9-4815779b2e50`

Q: A table has exactly one row per store per calendar day, including zero-sales days. Which window computes a seven-calendar-day moving average?

A. `AVG(revenue) OVER (PARTITION BY store_id ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)`
B. `AVG(revenue) OVER (PARTITION BY store_id ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`
C. `AVG(revenue) OVER (PARTITION BY store_id ORDER BY day)`
D. `AVG(revenue) OVER (PARTITION BY store_id)`

Answer: B. With one row for every day, six prior rows plus the current row cover seven days. A covers eight rows.

Remember: Days 1–7 each have revenue 7. Day 7's seven-row average is 7; day 8 drops day 1 and includes day 8.

Pro tip: If dates are missing, ROWS means seven recorded rows, not seven calendar days; fill the date grid or use a suitable time-range frame.

### 9 · `f0e19197-bcb0-4fe1-8726-749e5a807e1b`

Q: A table has exactly one revenue row per day. Which expression returns daily revenue beside a cumulative total through that day?

A. `SUM(revenue) OVER (ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`
B. `SUM(revenue) OVER ()`
C. `SUM(revenue) OVER (ORDER BY sale_date ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)`
D. `SUM(revenue) GROUP BY sale_date`

Answer: A. It includes all earlier days through the current day while retaining each daily row. B repeats the grand total on every row.

Remember: Daily revenue 10, 5, 8 yields running totals 10, 15, 23.

Pro tip: If multiple rows share a date, aggregate to daily grain first or specify a stable within-day order.

### 10 · `0edaf01e-9b78-478e-9e9e-f221840617b1`

Q: Each account balance record contains customer_id, balance, transaction_time, and unique transaction_id. Which approach returns the balance from the latest complete record per customer?

A. Group by customer_id and select MAX(balance).
B. Group by customer_id and select MAX(transaction_time) beside any balance.
C. ROW_NUMBER by customer_id ordered by transaction_time DESC, transaction_id DESC; keep row 1.
D. ROW_NUMBER over all customers ordered by transaction_time DESC; keep row 1.

Answer: C. It selects the whole newest row for each customer; the largest balance need not be the newest. D keeps one row across all customers.

Remember: A's balances are 100 at 09:00 and 80 at 10:00. Current balance is 80, not MAX(balance)=100.

Pro tip: Confirm that transaction_time, rather than ingestion time, defines “current” for the source system.

### 11 · `c2a9c475-2ef5-4e47-9fa6-beaa1f1c49f2`

Q: Keep every service-day monitoring row but show that service's average daily error count beside it. Which expression fits?

A. `AVG(error_count) OVER (PARTITION BY service_id)`
B. `AVG(error_count) GROUP BY service_id`
C. `AVG(error_count) OVER (ORDER BY day)`
D. `SUM(error_count) OVER (PARTITION BY service_id ORDER BY day)`

Answer: A. It gives each row its service-wide average without collapsing daily rows. B produces one grouped row per service.

Remember: Service S has daily errors 2 and 4. Both daily rows stay visible, each with average 3.

Pro tip: AVG ignores NULL error counts; decide whether NULL means missing measurement or zero errors.

### 12 · `635eb35b-1ed6-4d09-b2c9-997d84686e0c`

Q: Rank employees within each region. Equal revenue should share a rank, and the next rank must have no gap. Which expression fits?

A. `RANK() OVER (PARTITION BY region ORDER BY revenue DESC)`
B. `DENSE_RANK() OVER (ORDER BY revenue DESC)`
C. `ROW_NUMBER() OVER (PARTITION BY region ORDER BY revenue DESC)`
D. `DENSE_RANK() OVER (PARTITION BY region ORDER BY revenue DESC)`

Answer: D. DENSE_RANK preserves ties without gaps and PARTITION BY restarts each region. A leaves rank gaps.

Remember: East revenues `{100, 100, 80}` rank `{1, 1, 2}`; West starts again at 1.

Pro tip: For exactly one row per rank position, decide how to break ties; dense rank can return multiple people at one rank.

### 13 · `e51e9421-0e8f-42bc-b12e-01fb00b2283a`

Q: For each employee sale, show current amount minus that employee's previous sale amount. Which expression supplies the previous amount?

A. `LEAD(amount) OVER (PARTITION BY employee_id ORDER BY sale_time, sale_id)`
B. `LAG(amount) OVER (PARTITION BY employee_id ORDER BY sale_time, sale_id)`
C. `LAG(amount) OVER (ORDER BY employee_id, sale_time)`
D. `AVG(amount) OVER (PARTITION BY employee_id)`

Answer: B. LAG reads the previous sale inside that employee's ordered rows. C can cross employee boundaries.

Remember: Employee E sells 10 then 15. The second row gets previous=10 and difference=5; the first has no previous sale.

Pro tip: Define a stable order when two sales share the same timestamp.

### 14 · `e56b9dec-a729-42c9-bf7c-98dea4868200`

Q: A report must keep every sale row and show the employee's total sales beside each sale. Which expression fits?

A. `SUM(amount) GROUP BY employee_id`
B. `SUM(amount) OVER (ORDER BY sale_time)`
C. `SUM(amount) OVER (PARTITION BY employee_id)`
D. `COUNT(amount) OVER (PARTITION BY employee_id)`

Answer: C. The partition total is repeated beside each sale without collapsing rows. A produces one row per employee instead.

Remember: E has sales 10 and 20. Both rows remain, each showing employee total 30.

Pro tip: If a join repeats sale rows before the window, the window total will also be inflated; check grain first.

### 15 · `cb4b2f28-236b-4af6-859c-7b5e2199ded9`

Q: Return exactly three highest-revenue days per store. Same-revenue days should still be ordered consistently. Which approach fits?

A. RANK by revenue within store and keep ranks <= 3.
B. ROW_NUMBER over all stores by revenue and keep rows <= 3.
C. DENSE_RANK by revenue within store and keep ranks <= 3.
D. ROW_NUMBER by store ordered by revenue DESC, day DESC; keep numbers <= 3.

Answer: D. ROW_NUMBER returns at most three rows per store; the day settles equal-revenue ties. RANK can include extra tied rows.

Remember: Store A has day revenues `{20, 20, 15, 10}`. Ordered by revenue then day, the first three days are returned.

Pro tip: If the requirement is “include all days tied for third,” use a ranking function instead and accept more than three rows.

### 16 · `12734067-5058-451d-a71f-d8245e87eaa5`

Q: Order statuses can tie on updated_at. Each row has unique ingestion_id. Which pattern keeps one latest complete status row per order?

A. `MAX(updated_at), MAX(status)` grouped by order_id.
B. ROW_NUMBER partitioned by order_id, ordered by updated_at DESC and ingestion_id DESC; keep row 1.
C. RANK partitioned by order_id, ordered by updated_at DESC; keep rank 1.
D. ROW_NUMBER partitioned by status, ordered by updated_at DESC; keep row 1.

Answer: B. It defines the order group and breaks timestamp ties, retaining one complete row. C can keep multiple tied rows.

Remember: O1 has PAID at 10:00/id=2 and REFUNDED at 10:00/id=3. Keep REFUNDED/id=3.

Pro tip: A later ingestion ID wins only if that matches the source's version priority; verify the rule.

### 17 · `bbb84b30-87c1-4752-bee3-8967b085bc88`

Q: Return one complete highest-value order per customer. For equal amounts, prefer the larger order_id. Which pattern fits?

A. `MAX(amount), MAX(order_id)` grouped by customer_id.
B. RANK by amount DESC per customer and keep rank 1.
C. ROW_NUMBER by customer_id ordered by amount DESC, order_id DESC; keep row 1.
D. ROW_NUMBER over all orders ordered by amount DESC; keep row 1.

Answer: C. It selects one whole order row within each customer and uses order ID to resolve amount ties. A can combine values from different rows.

Remember: A has O1=50 and O2=50. O2 wins the tie; B's orders are considered in a separate partition.

Pro tip: Do not use independent MAX values to reconstruct a record; select an actual row.

### 18 · `dfa12371-9cfc-4917-9a0e-97bf95fc5ea0`

Q: What is the main difference between `SUM(amount) GROUP BY customer_id` and `SUM(amount) OVER (PARTITION BY customer_id)`?

A. Both always return one row per customer.
B. GROUP BY collapses to customer rows; the window sum keeps each input row and adds its customer total.
C. The window sum always sorts customers by amount.
D. GROUP BY ignores NULL amounts, but the window sum does not.

Answer: B. Window calculations add results to input rows; grouped aggregation changes the row grain. Both SUM forms ignore NULL inputs.

Remember: A has sales 10 and 20. GROUP BY gives one `A=30` row; the window version keeps two rows, each showing 30.

Pro tip: Choose output grain before choosing GROUP BY or a window expression.

### 19 · `d7c1e73f-e363-4a06-bc6a-e342252e1919`

Q: Customer events can be resent. Rows have `ingested_at` and unique `ingestion_id`. A duplicate means the same `(customer_id, event_type)`, and the latest ingested row should remain. Which pattern fits?

A. ROW_NUMBER partitioned by customer_id and event_type, ordered by ingested_at DESC and unique ingestion_id DESC; keep row 1.
B. ROW_NUMBER partitioned by customer_id, ordered by event_type; keep row 1.
C. RANK partitioned by event_type, ordered by ingested_at DESC; keep rank 1.
D. GROUP BY customer_id and event_type, then select any event_time.

Answer: A. The composite partition matches the duplicate key, and the order picks one latest complete row. B would wrongly merge distinct event types.

Remember: A has OPEN at 09:00 and 10:00 plus CLOSE at 09:30. Keep OPEN 10:00 and CLOSE 09:30.

Pro tip: Add a stable tie-breaker for equal ingested_at; do not assume ingestion timestamps are unique.
