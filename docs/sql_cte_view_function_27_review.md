# SQL CTE, View & Function — 27 rewrites + 6 new questions

Review draft only. The first 27 IDs, types, option counts, and correct-answer counts match the export; answer letters are draft positions, not stored option IDs. The six additions fill PostgreSQL-specific gaps. `Remember` is a tiny example; `Pro tip` is a distinct practical check.

## Junior

### 1 · `71e07803-a2c8-4dd4-9b58-eeb0856650ad`

Q: Thirty reports classify customer spend using the same threshold. The threshold changes from 1000 to 1500. How can a shared SQL function help?

A. It changes stored spend values automatically.
B. It makes every report query free to run.
C. It lets the team change one function definition instead of 30 copied expressions.
D. It refreshes every dashboard before its next query.

Answer: C. Centralizing the rule reduces inconsistent manual edits. It does not rewrite underlying data or guarantee speed.

Remember: `tier(1200)` was High under threshold 1000; after updating the shared rule to 1500, all callers now classify 1200 below High.

Pro tip: Test callers before deploying a changed function because one shared edit can affect many reports at once.

### 2 · `cdea4aaa-5270-4d61-b681-c410375ce566`

Q: In `WITH sales AS (SELECT customer_id, SUM(amount) total FROM orders GROUP BY customer_id) SELECT * FROM sales`, what is `sales`?

A. A permanent copy of orders.
B. A named CTE producing customer-level totals for this statement.
C. A stored materialized view refreshed automatically.
D. A function called once per order row.

Answer: B. The WITH clause names an intermediate query for the following statement. It does not create a permanent table.

Remember: Orders `(A,10),(A,20)` make CTE row `(A,30)` for this SELECT; a later separate SELECT cannot refer to `sales`.

Pro tip: Naming a CTE clarifies its grain, but does not guarantee it is physically materialized.

### 3 · `f2ecfc40-da90-4dd8-b9d4-13c0c352688c`

Q: Ten queries repeat the same amount-to-tier CASE expression. What is a good reason to use a shared function?

A. Each query can call the same rule rather than maintain its own copy.
B. The function automatically indexes every amount column.
C. The function makes all results permanent.
D. The function prevents all NULL inputs.

Answer: A. A function can centralize a deterministic business transformation. It does not add indexes or storage by itself.

Remember: Amount 700 maps to Medium in ten places; one shared `tier(700)` rule helps them agree.

Pro tip: Define how NULL and negative amounts should be classified before sharing the function.

### 4 · `a6eb0382-f55d-4a4d-ad93-ff0062186532`

Q: A query first filters orders, then totals them by customer, then joins customer names. What helps name these stages in one SQL statement?

A. Three permanent tables for every query run.
B. A trigger on the orders table.
C. A CHECK constraint on customer name.
D. Several CTEs in one WITH clause.

Answer: D. CTEs can express `filtered`, `totals`, and final SELECT as named stages. They are not automatically stored permanently.

Remember: `filtered` keeps March orders; `totals` turns A's 10+20 into 30; the final join adds A's name.

Pro tip: Compare the plan if a CTE is referenced multiple times; clarity and execution cost are separate concerns.

### 5 · `00c5e47b-2e92-4eee-9605-3cc0df852717`

Q: A team uses the same spend-to-tier rule in reporting and an API query. What is the main maintainability benefit of a SQL function?

A. It guarantees both queries use the same stored result forever.
B. It lets both call one versioned rule definition.
C. It removes the need to test threshold changes.
D. It makes every call execute only once per database.

Answer: B. One function definition reduces duplicated business logic. It still needs tests and may be evaluated repeatedly.

Remember: Report and API both call `tier(1600)` and get Gold under the same rule instead of separate CASE copies.

Pro tip: Consider versioning when old reports must keep their historical classification rule.

### 6 · `50890014-4f16-4428-91f1-fa594efee0b0` · Select three

Q: A shared function replaces copied shipping-fee calculations in many queries. Which three benefits are realistic?

A. One rule change can be made centrally.
B. A meaningful function name can improve readability.
C. Callers can reuse the same business logic.
D. Function calls are guaranteed faster than inline expressions.
E. All past stored orders are automatically recalculated.

Answer: A, B, C. These are reuse and maintenance benefits. D is a performance claim that needs measurement.

Remember: Twenty reports call `shipping_fee(weight)`; changing the 5-kg threshold in one function updates their future calculations.

Pro tip: Benchmark hot-path calls and review function volatility; a convenient abstraction can still be costly.

### 7 · `40f22578-bb39-4794-815b-8fbe0abe9ea9`

Q: Analysts need a reusable name for a complex join and filter, but do not need stored results. Which object fits?

A. A regular view.
B. A materialized view that must be refreshed.
C. A permanent duplicate of every input row.
D. A one-use CTE in each analyst query.

Answer: A. A regular view provides a reusable query definition without a separately stored result. B adds refresh and storage work.

Remember: Analysts query `active_customers`; the view expands its join/filter definition when queried.

Pro tip: A regular view does not guarantee a faster query; inspect its underlying plan.

### 8 · `f4750c71-0c00-4466-a08e-6ba800a3241a`

Q: Can a CTE calculate regional revenue using JOIN, WHERE, and GROUP BY?

A. No; a CTE can only list column names.
B. Yes, but only if the CTE is permanent.
C. Yes; its query can use normal SELECT operations.
D. No; GROUP BY is allowed only outside WITH.

Answer: C. A CTE can contain an ordinary query, including joins, filters, and aggregation.

Remember: `WITH revenue AS (SELECT region, SUM(amount) ... GROUP BY region)` can produce `(East,30)` for the outer SELECT.

Pro tip: Decide the CTE's output grain before joining it to other data.

### 9 · `42902ff5-5045-4be3-b622-4d13fd4ec16c`

Q: A query needs `filtered_orders` and then `customer_totals` built from those filtered rows. Can one WITH clause define both?

A. No; SQL allows only one CTE per statement.
B. Yes; define the CTEs in sequence and reference the earlier one.
C. Yes, but both must return identical columns.
D. No; the second must be a permanent table.

Answer: B. Multiple CTEs can form named steps; a later CTE can read an earlier CTE.

Remember: `filtered_orders` has A's March sales 10 and 20; `customer_totals` reads it and produces A=30.

Pro tip: Avoid circular references unless intentionally using a valid recursive CTE.

### 10 · `75e44883-228c-44d8-b941-f778d333d520`

Q: How long can a normal CTE name be referenced?

A. Until the SQL statement that defines it finishes.
B. Until the database server restarts.
C. Until the session ends, like a temporary table.
D. Until someone explicitly refreshes it.

Answer: A. A CTE name is scoped to its statement. It is not a persistent object or session table.

Remember: `WITH recent AS (...) SELECT * FROM recent` works; a separate later `SELECT * FROM recent` does not.

Pro tip: Use a temporary table when multiple statements need to share an intermediate result.

### 11 · `b080bdd3-83f8-4da8-9a9d-2b1495085839`

Q: What does `WITH recent_orders AS (...)` create for the following SELECT?

A. A new permanent orders table.
B. A trigger that runs on every insert.
C. A named statement-scoped query result.
D. An index on recent orders.

Answer: C. A CTE gives a query a name and scope within one statement. It does not imply physical storage.

Remember: `recent_orders` may be referenced twice inside its SELECT, but not by tomorrow's separate SELECT.

Pro tip: In PostgreSQL, the optimizer may inline an eligible CTE; inspect the plan before assuming reuse.

### 12 · `ed292d49-3202-4e54-b964-dc890a6d1161`

Q: What is a regular SQL view used for?

A. Holding a separately refreshed copy of data by default.
B. Providing a reusable named query over underlying data.
C. Replacing all permissions on underlying objects automatically.
D. Guaranteeing that every query uses an index.

Answer: B. A regular view stores a definition, not a precomputed table-like result. A describes a materialized view more closely.

Remember: `CREATE VIEW open_orders AS SELECT ... WHERE status='OPEN'`; a query of open_orders reads the current matching data.

Pro tip: Review view ownership and security rules before treating a view as a data-access boundary.

### 13 · `4143f5b6-9b56-4dad-8cf0-2a1fef4aef2f`

Q: A long query nests three subqueries for filtering, grouping, and ranking. What can CTE names improve compared with anonymous nested subqueries?

A. They always reduce the number of rows scanned.
B. They permanently store each intermediate result.
C. They automatically add indexes to every stage.
D. They can make the purpose and grain of each intermediate stage easier to read.

Answer: D. Named steps can clarify intent, but do not guarantee a better plan. A is a separate performance question.

Remember: `filtered`, `daily_totals`, and `ranked` tell a reader what each stage produces.

Pro tip: A subquery can sometimes be just as clear; choose structure that helps maintenance and verify performance separately.

### 14 · `21931dd9-850d-4c51-8b6c-6071fc1b6f23`

Q: In PostgreSQL, what distinguishes a regular view from a materialized view?

A. Regular views store every result row, materialized views store only SQL text.
B. Both always refresh automatically on base-table writes.
C. A regular view stores a query definition; a materialized view stores rows that need refresh to catch source changes.
D. A materialized view can never be indexed.

Answer: C. PostgreSQL materialized views persist rows and require explicit refresh; ordinary views return results from their definition.

Remember: Base sales change from 10 to 20. Regular view reads 20 next query; materialized view may still show 10 until refreshed.

Pro tip: Design a refresh schedule and measure refresh cost before adopting a materialized view.

### 15 · `3da51e1e-2221-4544-b475-5366b4247f95`

Q: What is the main reason to use CTEs for a one-off multi-step SQL query?

A. To give important intermediate steps names and structure.
B. To make all intermediate data permanent.
C. To guarantee faster execution than a subquery.
D. To grant table permissions to the reader.

Answer: A. CTEs can make complex logic easier to follow. They do not inherently persist data or speed it up.

Remember: `base`, `per_customer`, and `final` make the flow of a three-step query visible.

Pro tip: Name CTEs after their output meaning, not generic labels such as t1 and t2.

### 16 · `11bfff56-b7f8-49a2-ad72-f32e5ba4a8cd`

Q: Which repeated task is a good candidate for a reusable SQL function?

A. Copying a complete fact table for one report.
B. Mapping an input amount to a consistent fee band.
C. Refreshing a billion-row summary after each source update.
D. Replacing every JOIN condition in the database.

Answer: B. A function can encapsulate a small input-to-output rule. C is a materialization decision, not a scalar calculation.

Remember: `fee_band(20)` returns Small and `fee_band(200)` returns Large in every caller.

Pro tip: Consider a lookup table rather than a function if business users frequently edit bands as data.

### 17 · `dcd1b932-5dfd-482c-9a55-7a67416274b6`

Q: Which keyword introduces a CTE in a SELECT statement?

A. CREATE
B. MATERIALIZE
C. REFRESH
D. WITH

Answer: D. WITH introduces named CTE definitions for the statement; CREATE defines persistent objects.

Remember: `WITH x AS (SELECT 1) SELECT * FROM x` returns 1.

Pro tip: `WITH RECURSIVE` is used when a CTE must refer to itself, such as walking a hierarchy.

### 18 · `d1408d14-200b-4028-8ea0-f9506e4e5d37`

Q: A developer wraps a slow subquery in a CTE. What is the safest performance claim?

A. The CTE always materializes and runs once.
B. The CTE always gets a new index.
C. The CTE improves structure, but performance depends on the engine and plan.
D. The CTE automatically caches results between queries.

Answer: C. CTE syntax alone does not guarantee a faster plan. In PostgreSQL, eligible CTEs may be inlined.

Remember: Renaming a 10-second subquery to `WITH heavy AS (...)` can still leave the query taking 10 seconds.

Pro tip: In PostgreSQL, compare plans before forcing `MATERIALIZED` or `NOT MATERIALIZED`.

### 19 · `64ed54a7-9d6a-475c-9c3b-72d1fd681a9d`

Q: A report needs an intermediate customer total only within one statement. What can a CTE avoid creating?

A. A permanent table solely for that intermediate step.
B. A SELECT result for the report.
C. A GROUP BY needed for the total.
D. A customer key used in a JOIN.

Answer: A. A statement-scoped CTE can hold the logical step without a permanent schema object. It does not remove required aggregation.

Remember: The report computes A=30 in `WITH totals AS (...)`; no lasting totals table appears afterward.

Pro tip: If multiple jobs need the same expensive total, a maintained table or materialized view may be more appropriate.

### 20 · `d7b5b60a-37be-4281-b5c1-df72ef5ec5d7` · Select four

Q: In PostgreSQL, which four comparisons between regular and materialized views are correct?

A. A regular view stores the query definition rather than a separate result table.
B. A materialized view persists its result rows.
C. A materialized view takes storage and refresh work.
D. A regular view reads current underlying data on query, while a materialized view can lag until refresh.
E. A materialized view updates automatically on every base-table write.

Answer: A, B, C, D. E is false in PostgreSQL: refreshing is an explicit operation. The four correct statements describe storage and freshness.

Remember: Base value 10 → 20. The regular view shows 20 next query; an unrefreshed materialized view still shows 10.

Pro tip: Some other warehouses maintain materialized views differently; always name the engine in an interview answer.

### 21 · `aa79fd75-cec8-4db3-aa0f-cb356000f6c2` · Select three

Q: What can a regular view provide to analysts who repeatedly need the same joined dataset?

A. A shared query interface.
B. A shorter query for analysts to write.
C. A place to hide join and filter details.
D. A guaranteed precomputed copy of every result row.
E. Guaranteed access to every underlying row regardless of privileges.

Answer: A, B, C. A view packages SQL logic for reuse; it is not automatically a stored result or a security bypass.

Remember: Analysts query `active_accounts` instead of rewriting the same three-table join in every report.

Pro tip: Test both performance and permissions; view semantics differ from materialized-view storage.

## Middle

### 22 · `973d5d2c-9665-4e6a-9a04-5a2ae1c59946`

Q: A dashboard repeats the same customer-level SUM over billions of transaction rows and can tolerate delayed results. What should the team test?

A. A regular view, assuming it precomputes each SUM.
B. A materialized or maintained summary with a suitable refresh policy.
C. A CTE in every dashboard, assuming it caches across runs.
D. A scalar function that scans the full table once per customer.

Answer: B. A stored summary can avoid repeated raw aggregation if freshness and maintenance costs are acceptable. A regular view alone does not store the sums.

Remember: One expensive total is run 100 times per hour; a refreshed summary can let those reads use stored totals instead.

Pro tip: In PostgreSQL, dashboards must query the materialized view explicitly; do not assume automatic query rewrite.

### 23 · `4ff21cfd-35d5-469b-bc49-249081560ebe` · Select three

Q: A dashboard repeats an expensive aggregation but can show data a few minutes old. Which three facts support testing a materialized result?

A. Precomputing can reduce repeated aggregation work.
B. The freshness tolerance may allow scheduled refresh.
C. Many requests repeat the same metric.
D. Materialization removes all storage cost.
E. A regular view always caches results automatically.

Answer: A, B, C. Reuse and tolerable lag make precomputation plausible. D and E are false assumptions.

Remember: If 60 queries each recompute 10M rows, one refreshed 100-row summary may replace much of that repeated work.

Pro tip: Compare total cost including refreshes, not only dashboard latency.

### 24 · `620e9698-f7ce-4414-99cb-9be8244ff774`

Q: In PostgreSQL, a materialized view exists, but a dashboard query still reads the original huge table. What should be checked first?

A. Whether the dashboard query explicitly reads the materialized view.
B. Whether the materialized view has the word MATERIALIZED in its name.
C. Whether a CTE was added to the original query.
D. Whether the output rows are sorted alphabetically.

Answer: A. PostgreSQL does not automatically substitute the materialized view for a query of the base table. B is just naming.

Remember: `SELECT SUM(...) FROM raw_sales` still uses raw_sales; `SELECT total FROM daily_sales_mv` reads stored MV rows.

Pro tip: Also verify that refresh timing makes the view's rows current enough for the dashboard.

### 25 · `efab8e8f-1e6d-4011-9fb3-a4934a6dff22` · Select three

Q: A team considers a materialized view for repeated sales summaries. Which three statements are reasonable?

A. It may avoid repeating an expensive scan and aggregation.
B. It adds storage and refresh work.
C. It fits best when the workload can accept its refresh behavior.
D. It guarantees zero latency for every query.
E. It automatically changes every existing base-table query to use it in PostgreSQL.

Answer: A, B, C. Precomputation trades refresh/storage cost for faster reads when the workload suits it. D and E overpromise.

Remember: Raw sales has 10M rows; the view stores 100 regional totals, but those totals must be refreshed after new sales.

Pro tip: Check whether late corrections require refreshing older periods, not only today's partition.

### 26 · `20954c7b-807b-4ea2-936c-1fecbd9b4931` · Select three

Q: A materialized summary cuts a dashboard from 40 seconds to 2, but source records change every few seconds. Which three costs or requirements matter before rollout?

A. Whether the stored result's lag meets the dashboard's freshness requirement.
B. Whether saved query work justifies its storage.
C. Whether refresh compute and scheduling are acceptable.
D. Whether the view name contains the source table name.
E. Whether refreshing can be skipped forever after creation.

Answer: A, B, C. Speed alone is not enough; freshness, storage, and refresh cost determine fitness. E would leave the data stale.

Remember: A dashboard runs in 2 seconds but its totals are 15 minutes old; that may be fine for trends, not live fraud alerts.

Pro tip: Set a measurable freshness service level and monitor last successful refresh.

### 27 · `367db815-e9a8-40c9-aa6d-5601e3b1b297` · Select three

Q: Which three workloads are plausible candidates for a materialized summary?

A. A dashboard repeatedly asks for the same daily revenue totals.
B. A stable analytical result is read often and can tolerate a refresh delay.
C. Many reports repeat the same expensive join and aggregation.
D. A one-off query runs once and is never reused.
E. A result must reflect every source write immediately with no lag.

Answer: A, B, C. Reuse and tolerated freshness lag make storage worthwhile. D has little reuse to amortize the refresh.

Remember: A daily sales total read 500 times can be stored once per refresh; a one-time ad hoc result usually need not be.

Pro tip: Some complex joins or aggregates may not be supported by a particular materialized-view implementation; test eligibility.

## Six new practical questions

### 28 · `sql_cvf_20260928_01`

Q: A PostgreSQL function should return NULL whenever its input is NULL, without executing its body for that input. Which declaration fits?

A. VOLATILE
B. STRICT (or RETURNS NULL ON NULL INPUT)
C. SECURITY DEFINER
D. PARALLEL SAFE

Answer: B. STRICT makes PostgreSQL return NULL without invoking the function body when an argument is NULL. The other attributes concern different behavior.

Remember: `fee(NULL)` returns NULL immediately; `fee(10)` runs the function body and returns its fee.

Pro tip: Use STRICT only if NULL should truly propagate; a function that maps NULL to a default value must execute its body instead.

### 29 · `sql_cvf_20260928_02`

Q: A PostgreSQL CTE runs an expensive calculation and is referenced twice. What trade-off should be checked before forcing `NOT MATERIALIZED`?

A. It may let each caller push filters in, but can repeat the calculation.
B. It permanently stores the calculation between sessions.
C. It prevents callers from applying WHERE filters.
D. It changes the CTE into a materialized view.

Answer: A. Merging the CTE into each use can enable optimization but may duplicate work.

Remember: Two references each need 1% of rows: inlining may read only needed rows twice; materializing may calculate 100% once.

Pro tip: Compare plans and runtime; the winner depends on selectivity and calculation cost.

### 30 · `sql_cvf_20260928_03`

Q: A PostgreSQL materialized view shows yesterday's total after today's source sales have committed. What operation updates its stored rows?

A. SELECT from the materialized view.
B. REFRESH MATERIALIZED VIEW.
C. ANALYZE the source table only.
D. Rename the regular view.

Answer: B. PostgreSQL refresh replaces the stored result from the defining query. SELECT only reads the current stored rows.

Remember: Stored total=100, new sale=20; after refresh, the materialized total becomes 120.

Pro tip: `REFRESH ... CONCURRENTLY` has prerequisites, including a suitable unique index, and can still cost substantial work.

### 31 · `sql_cvf_20260928_04`

Q: A PostgreSQL function depends only on its arguments and always returns the same output for the same inputs. Which volatility label describes that promise?

A. VOLATILE
B. STABLE
C. IMMUTABLE
D. MATERIALIZED

Answer: C. IMMUTABLE promises no dependence on changing database state or time. STABLE allows results to change across statements.

Remember: `celsius_to_fahrenheit(0)` always returns 32; a function reading today's exchange rate does not satisfy that promise.

Pro tip: Do not mislabel a function to gain speed; an incorrect volatility declaration can lead to wrong cached or planned results.

### 32 · `sql_cvf_20260928_05`

Q: An analyst runs a recursive CTE over an employee-manager table. What should the recursive part use to avoid looping forever if bad data contains a cycle?

A. A visited-ID or path check that stops revisiting an employee.
B. SELECT * in every recursive step.
C. ORDER BY manager_id only in the final query.
D. A regular view over the same table.

Answer: A. A cycle such as A → B → A can otherwise keep producing rows. A visited path provides a stopping rule.

Remember: Starting at A, the chain A→B→A should stop when A appears a second time.

Pro tip: Also define a depth limit when the hierarchy may be unexpectedly deep or malformed.

### 33 · `sql_cvf_20260928_06`

Q: A team exposes a PostgreSQL function to application users. It reads a private table and is marked SECURITY DEFINER. What must be reviewed carefully?

A. Whether the function can run with its owner's privileges and whether its search_path and inputs are safe.
B. Whether it is automatically a materialized view.
C. Whether it always runs with the caller's table privileges.
D. Whether it creates one database connection per row.

Answer: A. SECURITY DEFINER changes privilege context, so unsafe object lookup or input handling can expose data.

Remember: A caller cannot SELECT private_payments directly but may reach it through an owner-privileged function; the function must expose only intended results.

Pro tip: Set a safe search_path and restrict EXECUTE grants for SECURITY DEFINER functions.
