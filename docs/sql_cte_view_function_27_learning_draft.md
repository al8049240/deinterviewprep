# CTE, View & Function — 27 learning questions

New review draft, not tied to the current question IDs and not applied to Supabase. Each question has one best answer. The **Easy example** is deliberately plain language; **Try next** is an optional follow-up, not part of grading. PostgreSQL behavior is named when it matters.

## CTEs

### 1. Give a query step a name

**Question:** You want to name a filtered list of orders and use it later in the same query. What is a CTE good for?

A. Giving that query step a name.  
B. Creating a permanent copy of orders.  
C. Building an index on orders.  
D. Refreshing old orders automatically.

**Answer: A.** A CTE names a query step for one statement. It does not create a permanent table.

**Easy example:** Call the March orders `march_orders`. The rest of the query can read that name instead of repeating the March filter.

**Try next:** Would a separate query run tomorrow still know the name `march_orders`?

### 2. Know when the name disappears

**Question:** A query defines `WITH recent_orders AS (...)`. When does that CTE name stop being available?

A. When the current statement finishes.  
B. When the current session ends.  
C. When the source table is refreshed.  
D. When the database restarts.

**Answer: A.** A normal CTE belongs to its SQL statement, not the whole session.

**Easy example:** One query can read `recent_orders`. A second, separate query cannot read it unless it defines it again.

**Try next:** What would you use if two separate statements must share an intermediate result?

### 3. Build steps in order

**Question:** A report must filter sales to March, then total them by store. How can two CTEs help?

A. The first filters sales; the second totals the filtered rows.  
B. The first stores all sales forever; the second deletes old rows.  
C. Both CTEs must produce the same columns.  
D. The second CTE cannot read the first one.

**Answer: A.** A later CTE can use the earlier CTE's result, making the calculation stages clear.

**Easy example:** March sales are 10 and 20 for Store A. The filter step keeps both; the total step produces A = 30.

**Try next:** Where would you add a filter for stores whose March total exceeds 25?

### 4. Check the result's grain

**Question:** A CTE groups orders by customer and returns `customer_id` and `total_amount`. What does one CTE row represent?

A. One customer.  
B. One order.  
C. One order item.  
D. One day.

**Answer: A.** Grouping by customer makes one total row per customer. This matters before joining it to another table.

**Easy example:** Ana has orders of 10 and 15. The CTE has one Ana row with total 25.

**Try next:** What might happen if you join this customer total to a table with five rows per customer and then sum the total again?

### 5. Choose a CTE or a temporary table

**Question:** Two different SQL statements in the same job need the same intermediate customer totals. Which choice can let both statements read the result?

A. A temporary table created for the job.  
B. A CTE defined only in the first statement.  
C. An alias for the first SELECT column.  
D. An ORDER BY in the first statement.

**Answer: A.** A temporary table can survive across statements in its session or transaction. The first statement's CTE cannot.

**Easy example:** Step 1 calculates 100 customer totals. Steps 2 and 3 both read the temporary result instead of separately rebuilding it.

**Try next:** Would storing that result be worth it if only one statement uses it once?

### 6. Do not assume a CTE is stored

**Question:** A PostgreSQL developer wraps a slow subquery in a CTE. Which expectation is safest?

A. The SQL is easier to organize, but speed must be checked.  
B. The CTE is always saved and reused between queries.  
C. The CTE always gets an index.  
D. The CTE always runs faster than the subquery.

**Answer: A.** PostgreSQL may fold an eligible CTE into the outer query. A CTE name alone is not a performance feature.

**Easy example:** A calculation takes 10 seconds. Naming it `totals` may make the SQL clearer while it still takes 10 seconds.

**Try next:** What would you inspect to see how PostgreSQL actually ran the CTE?

### 7. Reuse can have a cost

**Question:** A PostgreSQL CTE is used twice. Each use needs only a small, different part of its rows. What trade-off should you test?

A. Computing the full CTE once versus letting each use filter its own rows.  
B. Creating a new permanent source table for each use.  
C. Removing both filters so the result is more complete.  
D. Turning every CTE column into an index.

**Answer: A.** Materializing once can avoid repeated computation; folding into each use may allow more selective work. The plan decides which is better.

**Easy example:** One use needs Store A and another Store B. Computing all 1,000 stores once may cost more than reading just A and B separately.

**Try next:** Could the answer change if each use needs 900 of the 1,000 stores?

### 8. Walk a hierarchy

**Question:** Employees store their manager's ID. You need all people under one manager, including indirect reports. Which CTE feature fits?

A. A recursive CTE.  
B. A one-row VALUES clause.  
C. A materialized view refresh.  
D. A scalar fee function.

**Answer: A.** A recursive CTE repeatedly follows the manager relationship to find another level.

**Easy example:** Mia manages Ben; Ben manages Lee. Starting with Mia, the recursion finds Ben, then Lee.

**Try next:** What should happen if bad data says Lee manages Mia?

### 9. Stop a cycle

**Question:** Bad employee data creates a loop: A reports to B, and B reports to A. What should a recursive hierarchy query do?

A. Track visited employees and stop before revisiting one.  
B. Sort the final names alphabetically.  
C. Run the recursive step forever.  
D. Remove the initial employee from the result only.

**Answer: A.** A visited-path or cycle check stops the loop; final sorting cannot fix endless recursion.

**Easy example:** The path goes A → B. When the next step would return to A, the query stops that path.

**Try next:** Why might a maximum depth be useful even when you check for cycles?

## Views

### 10. Reuse a query across reports

**Question:** Ten reports need the same join of orders and customers. Which object can give that join one reusable name without storing separate result rows?

A. A regular view.  
B. A materialized view.  
C. A CTE inside only one report.  
D. A new copy of both source tables.

**Answer: A.** A regular view stores the query definition for multiple callers. A materialized view stores a separate result.

**Easy example:** Reports query `orders_with_customer` instead of each writing the same orders-to-customers join.

**Try next:** Does creating the view alone guarantee that the join becomes faster?

### 11. See a new source row

**Question:** A regular PostgreSQL view shows today's orders. A new order commits. What should the next query of the view normally see?

A. The new order, because the view reads the underlying data.  
B. Only yesterday's orders until REFRESH is run.  
C. No rows until the view is recreated.  
D. The new order only after a database restart.

**Answer: A.** A regular view does not keep its own old copy of the result. REFRESH applies to materialized views.

**Easy example:** The view shows 2 open orders. A third open order commits. The next query can show 3.

**Try next:** How would the answer differ for a materialized view that has not been refreshed?

### 12. Choose a view or a CTE

**Question:** A calculation is shared by twenty reports written by different teams. Why might a view fit better than repeating a CTE in every report?

A. The view gives the teams one shared definition.  
B. The view guarantees every report is faster.  
C. The view permanently stores the result rows.  
D. A CTE cannot contain a JOIN.

**Answer: A.** A view centralizes reusable SQL across statements. A CTE is defined separately inside each statement.

**Easy example:** When the “active customer” rule changes, twenty reports can keep querying the same updated view.

**Try next:** What risk comes with changing a view that many reports depend on?

### 13. Do not confuse reuse with speed

**Question:** A report becomes easier to read after its large join is moved into a regular view. What should you conclude about runtime?

A. Check the plan; the underlying join may still cost the same.  
B. The join now runs only once per day.  
C. The view automatically stores all joined rows.  
D. The view always removes duplicate rows.

**Answer: A.** A regular view organizes SQL; it does not promise to cache the result.

**Easy example:** The original join takes 8 seconds. Querying the view may still take about 8 seconds because it performs that join.

**Try next:** If hundreds of reports repeat the same expensive total, what stored result might you evaluate?

### 14. Review what a view exposes

**Question:** A view is created to show customer name and city but not a private phone number. What must the team verify before granting analysts access?

A. That the view exposes only intended columns and its permissions behave as expected.  
B. That the phone column is alphabetically last.  
C. That the view has an ORDER BY clause.  
D. That every analyst can query the source table directly.

**Answer: A.** A view can be part of an access design, but its definition and PostgreSQL security settings must be reviewed.

**Easy example:** An analyst querying the view sees “Ana, Hanoi,” not Ana's private phone number.

**Try next:** What if the view calls a function that can reveal the hidden field?

### 15. Understand a stored summary

**Question:** In PostgreSQL, what does a materialized view add compared with a regular view?

A. Stored result rows that can be read until the next refresh.  
B. An automatic refresh after every source write.  
C. A guarantee that every query against the source uses it.  
D. A replacement for all source-table constraints.

**Answer: A.** PostgreSQL persists materialized-view rows; they can become stale until refreshed.

**Easy example:** The stored daily total is 100. A new sale of 20 arrives; the materialized view may still show 100.

**Try next:** What command would make it show 120?

### 16. Decide if stale data is acceptable

**Question:** A dashboard runs the same costly daily total every minute. It can be five minutes behind. What should be evaluated?

A. A refreshed materialized view or maintained summary.  
B. A regular view as a guaranteed cache.  
C. A new source table for every dashboard visit.  
D. A CTE that remains stored between visits.

**Answer: A.** A stored summary can trade refresh work and small data lag for faster repeated reads.

**Easy example:** The source total changes to 120 at 10:01. A dashboard that permits five-minute lag may show 100 until the next refresh.

**Try next:** Would this still fit a dashboard that must display every sale immediately?

### 17. Query the object you intended

**Question:** A PostgreSQL team creates `daily_sales_mv`, but a dashboard still queries raw `sales` and remains slow. What should it inspect first?

A. Whether the dashboard query actually reads `daily_sales_mv`.  
B. Whether `sales` was renamed after refresh.  
C. Whether a CTE appears in the dashboard query.  
D. Whether the materialized view has a longer name.

**Answer: A.** PostgreSQL does not automatically replace an arbitrary raw-table query with the materialized view.

**Easy example:** Asking raw sales for the daily total still reads raw sales; asking the summary reads its stored daily row.

**Try next:** What else must be checked before switching the dashboard—speed or freshness?

### 18. Refresh while people are reading

**Question:** A PostgreSQL materialized view is read constantly, and a normal refresh blocks readers too long. What option may help if its requirements are met?

A. `REFRESH MATERIALIZED VIEW CONCURRENTLY`.  
B. `SELECT *` from the materialized view twice.  
C. `DROP VIEW` before every dashboard query.  
D. `ORDER BY` in the view definition only.

**Answer: A.** Concurrent refresh can allow reads during refresh, but PostgreSQL requires an eligible unique index and a populated view.

**Easy example:** A refresh takes 20 seconds. With concurrent refresh set up correctly, readers can keep using the previous stored result during that work.

**Try next:** Does “concurrent” mean the refresh costs no CPU or I/O?

## Functions

### 19. Share one calculation

**Question:** Several reports turn a product weight into the same shipping fee. What is a good reason to create a SQL function for that calculation?

A. Call one shared rule instead of copying it into every report.  
B. Store all report results permanently.  
C. Automatically refresh every product weight.  
D. Remove every JOIN from the reports.

**Answer: A.** A function packages a reusable input-to-output calculation. It does not store report results.

**Easy example:** Both checkout and the finance report call `shipping_fee(2)` and get the same fee.

**Try next:** What should be tested before changing that shared fee rule?

### 20. Decide what NULL means

**Question:** A fee function should return NULL immediately when its input weight is NULL. Which PostgreSQL function setting expresses that rule?

A. `STRICT`.  
B. `SECURITY DEFINER`.  
C. `VOLATILE`.  
D. `PARALLEL SAFE`.

**Answer: A.** A STRICT function is not called when an argument is NULL; its result is NULL instead.

**Easy example:** `shipping_fee(NULL)` returns NULL without trying to calculate a fee. `shipping_fee(2)` calculates normally.

**Try next:** Would STRICT fit if a missing weight should instead use a default weight of 1?

### 21. Choose code or data

**Question:** Shipping-rate bands change frequently and business staff maintain them. Why might a rate table fit better than hard-coded thresholds in a function?

A. Staff can update the bands as data without deploying new function code.  
B. A table guarantees every lookup is faster than a function.  
C. A function cannot accept numeric input.  
D. A rate table cannot contain overlapping ranges.

**Answer: A.** Frequently changed business values are often easier to manage as data. Speed and range correctness still need checking.

**Easy example:** The 2-kg fee changes from 5 to 6. Updating one approved rate row can make new quotes use 6.

**Try next:** What check would prevent two rate bands from matching the same weight?

### 22. Label a fixed calculation

**Question:** A PostgreSQL function converts Celsius to Fahrenheit and depends only on the input temperature. Which volatility label fits?

A. `IMMUTABLE`.  
B. `STABLE`.  
C. `VOLATILE`.  
D. `SECURITY DEFINER`.

**Answer: A.** The same input always gives the same output, independent of time or database changes.

**Easy example:** Zero degrees Celsius always converts to 32 degrees Fahrenheit.

**Try next:** Would a function reading today's exchange rate still be immutable?

### 23. Label a value stable for one statement

**Question:** A PostgreSQL function reads a configuration value that can change between statements but remains fixed during one statement. Which label describes that promise?

A. `IMMUTABLE`.  
B. `STABLE`.  
C. `VOLATILE`.  
D. `STRICT`.

**Answer: B.** STABLE promises consistent results within a statement, but permits a different result in a later statement.

**Easy example:** A report uses today's tax setting throughout one query. After an admin changes the setting, a later query may use the new value.

**Try next:** Why would labeling this function IMMUTABLE be unsafe?

### 24. Recognize a changing result

**Question:** A PostgreSQL function returns a random number, so two calls with the same arguments may differ even in one query. Which label fits?

A. `IMMUTABLE`.  
B. `STABLE`.  
C. `VOLATILE`.  
D. `STRICT`.

**Answer: C.** VOLATILE tells PostgreSQL not to assume repeat calls give the same result.

**Easy example:** Two calls to `random()` might return 0.2 and 0.8 in the same query.

**Try next:** Why could marking `random()` IMMUTABLE produce a wrong optimization?

### 25. Review elevated privileges

**Question:** A PostgreSQL function reads a private table using `SECURITY DEFINER`. What is the most important review before allowing app users to call it?

A. Check its owner privileges, allowed inputs, search path, and EXECUTE grants.  
B. Confirm its name is shorter than the table name.  
C. Add ORDER BY to every query inside it.  
D. Assume callers automatically get all private rows.

**Answer: A.** SECURITY DEFINER can run with its owner's permissions, so a mistake can expose data the caller cannot read directly.

**Easy example:** A user cannot open the private payments table, but can call a function that returns one approved payment status—not the whole table.

**Try next:** What could go wrong if an untrusted schema appears first in the function's `search_path`?

### 26. Measure a function in a large query

**Question:** A function is called for every row in a report over 100 million rows. What should you do before claiming that replacing a CASE expression with the function improves speed?

A. Compare execution plans and runtime for the real workload.  
B. Assume functions always run once per query.  
C. Assume functions always get an index.  
D. Count the characters in the SQL text.

**Answer: A.** A function can improve reuse but may still be evaluated many times. Performance must be measured.

**Easy example:** If the report reads 100 million rows, a row-level fee rule may be called many times—not just once because it has a name.

**Try next:** Would calculating the fee earlier and storing it be worth the extra maintenance cost?

### 27. Change a shared rule safely

**Question:** A shared customer-tier function changes its Gold threshold from 1000 to 1500. What should the team check before deploying it?

A. Which callers expect the old rule, including historical reports.  
B. Whether every caller has the same SQL formatting.  
C. Whether the function name is alphabetically first.  
D. Whether all source tables can be dropped afterward.

**Answer: A.** One shared change affects every future call; some reports may need to preserve the rule that applied at the time.

**Easy example:** A customer who spent 1200 was Gold under the old rule but not under the new one. A historical report must decide which label it should show.

**Try next:** How could you store or version the rule so last year's report remains reproducible?

---

Technical checks: [PostgreSQL WITH queries](https://www.postgresql.org/docs/current/queries-with.html), [materialized views](https://www.postgresql.org/docs/current/rules-materializedviews.html), [refresh behavior](https://www.postgresql.org/docs/current/sql-refreshmaterializedview.html), and [function volatility](https://www.postgresql.org/docs/current/xfunc-volatility.html).
