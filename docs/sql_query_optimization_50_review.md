# SQL Query Optimization — 50 rewrites + 6 new questions

Review only. For the first 50, IDs, question types, option counts, and numbers of correct answers match the supplied export. Questions 51–56 are new. Answer letters are draft display positions, not existing option IDs. Examples show a small observable result; pro tips give a separate real-world check. Engine-specific claims name BigQuery or remain conditional on the plan.

## Junior

### 1 · `3942d40d-3302-4282-a03d-ae0d550dc310`

Q: A BigQuery events table is partitioned by `event_date`. A report needs only January 2026. Which filter is the best starting point for pruning?

A. `WHERE customer_id IS NOT NULL`
B. `WHERE event_date >= DATE '2026-01-01' AND event_date < DATE '2026-02-01'`
C. `WHERE EXTRACT(YEAR FROM event_date) = 2026`
D. `WHERE event_date IS NOT NULL`

Answer: B. The bounded predicate directly limits the partition column to January. C requests the full year and may complicate pruning.

Remember: From 36 monthly partitions, a January range needs one month; a year-only filter needs 12.

Pro tip: Confirm bytes scanned in BigQuery's job details; pruning does not guarantee the remaining partition is cheap.

### 2 · `c87e60b0-31e5-4908-975f-6cd6cd7fd59d` · Select all that apply

Q: A warehouse report is expensive. Which changes can reduce work without changing its answer?

A. Select only columns the report uses.
B. Apply a safe selective row filter before costly processing.
C. Remove a DISTINCT or sort only when it is not required.
D. Add DISTINCT to every intermediate result.
E. Keep SELECT * so the engine has more optimization choices.

Answer: A, B, C. They can reduce read, shuffle, or sort work while preserving the result. D can add work and change semantics.

Remember: A report needs 4 of 80 columns and one week of 52. Reading the needed columns and week can cut input before aggregation.

Pro tip: Check the actual plan and bytes processed; optimizers may already push some filters down.

### 3 · `42c70c3b-0fcc-4498-adec-8c052e7573d9` · Select all that apply

Q: A query is slow, but no one has inspected its execution details. Which first checks are useful before buying more capacity?

A. Compare input and output row counts at costly stages.
B. Review the execution plan for scan, join, sort, and shuffle costs.
C. Check whether joins, DISTINCT, or sorting are needed.
D. Add more partitions without checking the filter pattern.
E. Increase memory before identifying the slow operator.

Answer: A, B, C. They locate where work grows or stalls. D and E make changes without evidence.

Remember: A scan reads 1M rows, but a join emits 50M. Investigate the join before tuning the scan.

Pro tip: Compare repeated runs and exclude cache effects when judging an optimization.

### 4 · `0860d2b1-1e08-484a-8b8f-c1a33fb499de`

Q: A dashboard needs 3 fields from a 100-column customer table. Which projection is most appropriate?

A. Select all columns and remove 97 in the app.
B. Select all columns in a subquery, then keep 3 outside.
C. Select only the 3 required columns from the table.
D. Duplicate the table before selecting the 3 fields.

Answer: C. Columnar engines can avoid reading unnecessary column data when the query requests only needed fields. An outer projection may be optimized, but C states the intent clearly.

Remember: If the report needs ID, country, and signup date, return those 3 columns, not the other 97.

Pro tip: Inspect bytes read; nested fields and joins can affect how much is saved.

### 5 · `16de2cfa-70f3-4438-9d0d-0f35f1010cc2`

Q: Why can replacing `SELECT *` with five required columns lower work in a columnar warehouse?

A. It can avoid reading and moving unused column data.
B. It automatically removes duplicate rows.
C. It guarantees a single-partition scan.
D. It eliminates every downstream join.

Answer: A. Columnar storage reads selected columns, so a narrower projection can reduce I/O. It does not change row filters or join requirements.

Remember: A table stores 50 fields but a chart uses 5; only those 5 need to feed the chart query.

Pro tip: Avoid `SELECT * EXCEPT(...)` when most columns are still unused; list the small required set.

### 6 · `74d9db99-073e-4acc-8cfe-b7dd96a10f5d`

Q: A report joins orders to customers for customer name, but selects all columns from both tables. What should you change first?

A. Keep all fields and add DISTINCT after the join.
B. Remove the customer join but still show customer name.
C. Join all fields and drop unused fields after export.
D. Select only the needed order fields and customer name.

Answer: D. The join is needed for the name, but unused columns need not be read and shuffled. A adds work without narrowing inputs.

Remember: If output needs order ID, amount, and customer name, project just those fields from the two tables.

Pro tip: Also verify customers has one row per customer ID; duplicate dimension matches can multiply orders.

### 7 · `ad235183-6414-4a02-a74b-656622220563`

Q: A table has five years of monthly partitions, and a report intentionally asks for all five years. Which claim is false?

A. The query may need data from all five years.
B. The plan should be checked for other expensive stages.
C. Partitioning guarantees only the newest month is scanned.
D. A selective date filter would help a different query.

Answer: C. A partition layout cannot skip required history. A full-history report may legitimately read every month.

Remember: A five-year trend needs 60 monthly totals; a one-month scan cannot produce the full trend from raw data.

Pro tip: For repeated full-history summaries, consider a maintained aggregate after checking freshness and refresh cost.

### 8 · `48304fec-6591-4476-a1de-473ab8555e86`

Q: A table's largest country partition holds 40% of rows. Which statement about pruning is false?

A. Filtering to that country may still read a large amount.
B. Pruning is only successful when under 10% of the table is read.
C. The benefit depends on which countries the query needs.
D. A plan can show pruning while the query remains costly.

Answer: B. There is no universal 10% success threshold; a 40% scan can still skip 60% of the table.

Remember: US=40%, Vietnam=30%, Japan=20%, other=10%. A US-only query skips 60%, yet still reads a large partition.

Pro tip: Partitioning by country is engine-dependent; BigQuery does not support arbitrary STRING column partitioning.

### 9 · `b3853006-8e01-46f8-9a89-779a2ba6ca7e` · Select two

Q: A query scans one date partition but still runs slowly. Which two conclusions are reasonable?

A. The date filter probably pruned other partitions.
B. A join, sort, or aggregation after the scan may dominate runtime.
C. Partition pruning guarantees fast execution.
D. The partition key must be changed before inspecting the plan.

Answer: A, B. A narrowed scan and a slow downstream stage can coexist. C confuses scan reduction with total runtime.

Remember: One partition reads 100 GB in 4 seconds, then a skewed GROUP BY takes 40 seconds.

Pro tip: Compare stage-level row counts, shuffle, and task time rather than optimizing only total bytes read.

### 10 · `0e1aa4a7-34ef-45bf-b4c9-daec5588d819`

Q: A date-partitioned table is filtered with `EXTRACT(YEAR FROM order_date) = 2026`. Which claim is too absolute?

A. A direct date range may make pruning easier to verify.
B. The plan should show which partitions are scanned.
C. Function handling can differ among warehouse engines.
D. Any function on a partition column always causes a full scan.

Answer: D. Optimizers differ; a function is a reason to inspect pruning, not proof of a full scan.

Remember: A 2026-only range should target that year's partitions. Compare scanned partitions for the expression and a direct range.

Pro tip: Prefer typed date literals and a half-open range when it preserves the intended dates.

### 11 · `e48aa907-a99a-4ae7-9da4-f2d43cb03ccc`

Q: Which claim about pruning a date-partitioned table is false?

A. A date filter can skip unrelated partitions.
B. A query needing every date may scan every partition.
C. Partitioning guarantees every query reads only a small amount.
D. A selected partition can still hold many rows.

Answer: C. Query predicates and data distribution determine how much is read; partitioning alone is not a guarantee.

Remember: A table has 12 monthly partitions. A full-year report needs all 12 even though the table is partitioned.

Pro tip: Estimate the size of the selected partitions, not just their count.

### 12 · `e341c14b-f644-4ef3-849c-f74928d8a98d`

Q: Orders is partitioned by `order_date`. A query filters only `customer_id = 7`. Which statement is false?

A. The customer may have orders on many dates.
B. The customer filter automatically prunes date partitions.
C. A customer-oriented access path might help if supported.
D. The plan can show which date partitions were read.

Answer: B. Customer ID does not by itself identify a narrow date set. C may be clustering or an index, depending on engine.

Remember: Customer 7 ordered in January and September; filtering only customer ID cannot assume either month is irrelevant.

Pro tip: BigQuery clustering or search indexes may help selected customer lookups, but check actual scan metrics.

### 13 · `f4038026-105b-4333-bb36-e4dc1ac68ade` · Select two

Q: Orders is partitioned by date. Which two predicates may leave many date partitions eligible?

A. `order_date = DATE '2026-08-10'`
B. `order_date >= DATE '2026-08-01' AND order_date < DATE '2026-09-01'`
C. `customer_id = 7` with no date condition.
D. `order_date = DATE '2026-08-10' OR customer_id = 7`.

Answer: C, D. A customer can appear across many dates, and the OR branch must include those rows. A and B bound dates.

Remember: Customer 7 has a January order. An August-date OR customer-7 query must still include January.

Pro tip: Test any UNION-based rewrite for overlap and total scan cost; it is not automatically faster.

### 14 · `76c1cc67-c0c0-47a9-afb3-bfeed987acca` · Select two

Q: When is date partition pruning most likely to remove substantial input?

A. A predicate selects one date from several years.
B. A predicate selects a short date range from several years.
C. A report asks for every recorded date.
D. A filter uses only an unrelated customer key.

Answer: A, B. Both bound the partition column to a small share of dates. C and D provide no comparable date restriction.

Remember: From 1,000 daily partitions, a seven-day range can target seven instead of all 1,000.

Pro tip: Check whether selected dates are unusually large; partition counts alone do not equal bytes scanned.

### 15 · `e0f92c2b-a547-4ce4-af45-385ffba462fd` · Select two

Q: Before choosing a warehouse partition key, which two observations matter most?

A. How often important queries filter on the candidate key.
B. Whether those filters exclude a meaningful share of data.
C. Whether the column name is short.
D. Whether the first sample row contains a value.

Answer: A, B. A useful key aligns with common selective filters. C and D say little about pruning value.

Remember: If 90% of reports ask for the last week, date is a better partition candidate than an unused status field.

Pro tip: Also check partition count, size, and write/update patterns before finalizing physical design.

### 16 · `2a8d2a22-c4d9-431e-8772-12c1fbf1922c`

Q: A date-partitioned table's query transforms `sales_date` before comparing it. What should you investigate?

A. Whether the transformation changes the result grain.
B. Whether the report needs more columns.
C. Whether a direct date predicate can express the same filter and prune partitions.
D. Whether more ORDER BY columns can force pruning.

Answer: C. A direct predicate can make partition eligibility clearer; compare plans before and after. D concerns sorting, not date pruning.

Remember: Compare `DATE_TRUNC(sales_date, MONTH) = Jan 1` with `sales_date >= Jan 1 AND sales_date < Feb 1` for the same month.

Pro tip: Preserve timezone and boundary semantics when rewriting timestamp filters.

### 17 · `3b8e005f-8233-4b60-8420-2b784121ea6d` · Select two

Q: An integer customer key is used for partition or range pruning. The query compares it with `'12345'`. Which two actions are sound?

A. Compare it with a typed numeric value such as `12345`.
B. Inspect the plan for casts and actual partitions scanned.
C. Assume a quoted value always disables pruning.
D. Cast the integer column to text in every query.

Answer: A, B. Matching types avoids reliance on implicit conversion; the plan reveals actual behavior. C is too absolute.

Remember: `customer_id` is INT and the target is 12345. Use `customer_id = 12345`, then verify the selected range or partitions.

Pro tip: In BigQuery, integer-range partitioning uses ranges, not one partition for each customer ID.

### 18 · `c1671f16-cf8e-4f05-b5a6-7eb2521a9915`

Q: A report needs customers with more than 100 orders. Which approach applies the threshold at the right grain?

A. Filter each order row with `WHERE order_id > 100`.
B. Group orders by customer ID and use `HAVING COUNT(*) > 100`.
C. Group by order ID and use `HAVING COUNT(*) > 100`.
D. Limit the orders table to 100 rows before grouping.

Answer: B. The threshold is a per-customer aggregate, so it belongs after grouping. A filters IDs rather than counts.

Remember: Customer A has 101 order rows and B has 99. HAVING keeps A only.

Pro tip: This tests SQL correctness more than optimization; reduce input only with filters that preserve the requested order count.

### 19 · `ddb4a2e9-5ef3-46c7-b1b7-caa3862f32f1`

Q: A table contains years of sales, but a report needs revenue for one month. Which input reduction is safe?

A. Filter to the requested month, then SUM amount.
B. SUM all years, then label the total with the requested month.
C. Sort all years before SUM to make addition faster.
D. Keep all years and add DISTINCT to amounts.

Answer: A. Rows outside the requested month cannot contribute to that month's total. B changes the answer.

Remember: January sales are 10 and 20; February is 40. January revenue is 30, not 70.

Pro tip: Use a direct partition-date range when available and verify pruning.

### 20 · `543c4251-33ae-4e22-961f-e44e19bdf066`

Q: A report joins a very large sales fact to customers but only needs this year's sales. What should you test first?

A. Join every year, then filter final rows by customer name.
B. CROSS JOIN sales to customers, then remove extras.
C. Sort all sales by customer ID before applying the year filter.
D. Apply the year filter to the sales input before the costly join, when semantics allow.

Answer: D. Fewer fact rows may enter the join. A and B process unnecessary matches.

Remember: If 2B sale rows span five years but 400M are current-year, the join may need only those 400M.

Pro tip: The optimizer may push the predicate down already; compare the actual plan before rewriting SQL solely for appearance.

## Leader

### 21 · `3f989490-f7a6-4f7b-9f4e-196c70c3e15a` · Select three

Q: Hundreds of dashboards repeat customer-level joins and totals over a 100 TB date-partitioned fact. Which three decisions deserve testing together?

A. Keep date pruning for dashboards that ask for recent days.
B. Evaluate a shared precomputed customer-level result with an explicit refresh policy.
C. Test whether filtered fact rows can join the shared result at the correct grain.
D. Create a separate full copy of the fact for every dashboard.
E. Remove date filters because the shared result exists.

Answer: A, B, C. They retain useful pruning and test reuse without changing metric grain. D adds maintenance and storage cost.

Remember: If 100 dashboards repeat one customer total, compute and maintain that total once where supported, then measure reuse.

Pro tip: Validate materialized-view feature limits and freshness on the actual warehouse; a regular maintained table may be more suitable.

### 22 · `d16d7cae-09d0-4a0a-8ea2-8f862487b42a` · Select two

Q: Most event queries filter recent dates; a few dashboards repeat the same seven-day metrics. Which two design choices fit those measured patterns?

A. Retain date partitioning for the common recent-date access path.
B. Consider precomputing the repeated metrics after checking refresh cost and freshness.
C. Persist every intermediate expression as a separate table.
D. Remove partitioning so the dashboards can read all history.

Answer: A, B. The access pattern supports pruning, while repeated expensive metrics may justify reuse. C creates unnecessary objects.

Remember: Out of 100 queries, 95 ask for recent dates; 5 repeat the same seven-day total. Solve those two workloads separately.

Pro tip: Measure whether the precomputed result is actually reused and cheaper after refresh/storage cost.

### 23 · `7f2cfb14-dd71-4535-8129-2c1a2ce008f8` · Select two

Q: Seventy percent of reports repeat the same daily revenue join and aggregation; source data refreshes once daily. Which two choices are promising?

A. Centralize the metric definition in one maintained result.
B. Refresh a compatible precomputed result after the daily source load.
C. Copy the 80-line SQL independently into every report.
D. Refresh every minute without a freshness requirement.

Answer: A, B. They can reduce repeated computation and definition drift. C multiplies maintenance work.

Remember: If 70 of 100 reports calculate the same daily number, one refreshed daily summary can serve them after the load.

Pro tip: Check late-arriving corrections; daily refresh may need to recompute affected older dates.

### 24 · `ce713f97-fc39-456c-a579-e0f5f84effca`

Q: A complex ETL query runs twice a day, and no other consumer needs its intermediate results. What is a reasonable first step for clearer SQL without a new permanent object?

A. Materialize every intermediate stage permanently.
B. Put every expression into a scalar function.
C. Organize the logic with CTEs or a pipeline-scoped temporary result, then inspect the plan.
D. Copy the same subquery throughout the pipeline.

Answer: C. It improves organization with limited lifecycle cost. But a CTE does not guarantee reuse or materialization.

Remember: One pipeline uses the result at 08:00 and 20:00; a temporary stage can disappear after each run.

Pro tip: Measure repeated subquery execution in the plan before deciding whether a temp table is worth its write cost.

### 25 · `e9058066-34bb-40ef-a25c-1e963725328b` · Select two

Q: Sixty dashboards use the same customer-segmentation rules. When choosing a function versus a precomputed result, which two distinctions matter?

A. A function can centralize dynamic row-level logic but may still compute it on each query.
B. A precomputed result can save repeated expensive work if its refresh lag is acceptable.
C. A function always stores its output for all future queries.
D. A precomputed result is free to refresh and maintain.

Answer: A, B. Code reuse and computation reuse are different benefits. C and D ignore execution and maintenance cost.

Remember: A rule `spend > threshold` with changing threshold fits dynamic evaluation; a fixed weekly segment reused 60 times may merit precomputation.

Pro tip: Check tool support: materialized views may restrict joins or expressions, so a scheduled table can be the practical choice.

## Middle

### 26 · `f163f23e-5871-4175-945f-d439ad1bdd0c`

Q: A huge transaction table has 80M customers but most queries filter transaction date, sometimes customer. Which BigQuery layout is worth testing?

A. One partition per customer ID.
B. Date partitions with customer-ID clustering within them.
C. No date partitioning and a copy per customer.
D. Partition by a rarely filtered status field.

Answer: B. Date partitioning aligns with common time filters, and clustering may help customer lookups within selected partitions. A creates impractical cardinality.

Remember: A seven-day report first narrows dates; within those dates, customer clustering may reduce data read for ID 7.

Pro tip: BigQuery supports time or integer-range partitioning, not arbitrary one-partition-per-customer design.

### 27 · `14263c67-b39a-426a-ba00-53a818810af1`

Q: A query prunes 365 days to seven, but one aggregation worker handles 900 GB while peers handle under 20 GB. What is the likely bottleneck?

A. A hot grouping key causes uneven work after the scan.
B. Date pruning did not happen at all.
C. Selecting fewer output columns guarantees equal workers.
D. Every worker is waiting on the same tiny partition.

Answer: A. The large task imbalance is consistent with skew in grouping or shuffle keys. B contradicts the observed pruning.

Remember: If one customer owns most of the seven days' rows, its group can dominate one worker.

Pro tip: Inspect heavy key frequencies and stage timing before choosing a skew-mitigation strategy.

### 28 · `832185f8-e9bd-4b50-bbbe-bec8721301d7` · Select two

Q: BigQuery IoT reports mainly filter event dates; investigations also search device IDs. Which two layout choices are sensible to test?

A. Partition by event date.
B. Cluster by device ID within date partitions.
C. Create one partition for each of 100M devices.
D. Partition by an unfiltered payload field.

Answer: A, B. They match the common time filter and secondary device search. C is not a practical BigQuery partition scheme.

Remember: A week query visits seven date partitions; a device filter may then benefit from clustered blocks in them.

Pro tip: A device-only query may still touch many dates; test a search index or alternate access path if that workload is important.

### 29 · `d469ee22-371b-455c-82fd-a36417b9e2c4`

Q: A BigQuery order fact is usually filtered by date range and then by customer ID. Which physical design is a reasonable starting point?

A. Partition by each customer and cluster by order date.
B. Partition by order status and ignore dates.
C. Partition by order date and cluster by customer ID.
D. Create a separate table for each date-customer pair.

Answer: C. The date range limits partitions; clustering can organize customer data within them. A's customer cardinality is excessive.

Remember: For a March report on customer 7, first narrow to March, then target customer 7 inside March data.

Pro tip: Compare against date-only partitioning; clustering benefit depends on table size, data distribution, and workload.

### 30 · `a3c4ac97-702e-478a-bd33-ea9320886eee`

Q: A Silver table is partitioned by created_date. After deduplicating changes, a merge reads MIN and MAX affected dates. What may this help?

A. It proves every date between MIN and MAX changed.
B. It can bound the target date partitions considered by the merge.
C. It removes the need to match customer IDs.
D. It guarantees only changed rows are scanned.

Answer: B. The range can exclude dates outside it, but may still include unchanged dates inside it. A overstates what MIN/MAX means.

Remember: Changes on Aug 1 and Aug 30 give a range covering Aug 1–30, not only two dates.

Pro tip: If changes are sparse, distinct affected dates may prune more than a broad MIN/MAX range, subject to engine support.

### 31 · `eebb0554-836b-45b1-893a-0d4eb6d3f532`

Q: A query reads the right date partition but spends most time sorting and aggregating. What should be investigated next?

A. Remove the date filter so more workers can scan.
B. Check sort, grouping keys, row counts, and shuffle in the plan.
C. Repartition the table before examining downstream stages.
D. Add DISTINCT after the final result regardless of semantics.

Answer: B. The measured bottleneck is downstream of the scan; inspect it directly. C may not address it.

Remember: Scan takes 3 seconds, sort and group take 40. Improving the scan cannot remove most of the 40 seconds.

Pro tip: Test whether pre-aggregation reduces rows before a large shuffle without changing the metric.

### 32 · `e4e031c6-bfd8-4d55-92f3-55ca173c3777`

Q: A country-partitioned warehouse query asks for countries holding 90% of rows. The plan reads 90%. What is the best interpretation?

A. Pruning is broken because more than half the table is read.
B. Pruning can be working, but the filter keeps most data.
C. An index guarantees the read drops below 10%.
D. The query only needs the 10% of other countries.

Answer: B. The plan matches the requested countries' data share. Partitioning cannot exclude rows the report needs.

Remember: US 40% + Vietnam 30% + Japan 20% = 90% requested, so reading around 90% is expected.

Pro tip: This is a generic warehouse example; BigQuery does not partition on arbitrary STRING country values.

### 33 · `sql_q1`

Q: A 500 GB table is read on every run, but the query is slow. What is the best first diagnostic step?

A. Add a materialized view immediately.
B. Inspect the plan and stage metrics to locate scan, join, sort, or shuffle cost.
C. Add DISTINCT to shrink the result.
D. Increase capacity without comparing stages.

Answer: B. A large scan may be the bottleneck, but the plan is needed to distinguish it from downstream work. A may help only a reused calculation.

Remember: A 500 GB scan may take 5 seconds while a join takes 60; fix decisions should follow the 60-second stage.

Pro tip: Record a baseline of bytes, slot time, row counts, and wall time before making a change.

### 34 · `a5576b0c-fa09-458e-b7c0-98d2ff685b42`

Q: A proposal would create a separate partition for each of 100M customers. What is the main design concern?

A. Customer IDs are too small to filter.
B. Partitioning would remove all query costs.
C. An enormous number of tiny partitions creates overhead or exceeds engine limits.
D. Every customer must have the same transaction count.

Answer: C. High-cardinality per-customer partitions are generally impractical. A customer-oriented cluster or index may be more suitable.

Remember: 100M customers would imply 100M partitions in this proposal, versus about 365 daily partitions per year.

Pro tip: Check the target warehouse's supported partition types and limits before proposing physical design.

### 35 · `db44c7da-07cd-4321-a081-c11a8d7158d0`

Q: A five-year report intentionally reads five years from a date-partitioned table. What should the engineer expect?

A. Date pruning may save little because the report needs nearly every partition.
B. The engine must read only the newest partition.
C. Partitioning turns the report into a constant-time query.
D. Filtering on an unrelated customer ID prunes all dates.

Answer: A. A full-history request requires full-history input unless a separate summary can answer it.

Remember: A report covering Jan 2021–Dec 2025 needs data from all 60 monthly partitions.

Pro tip: For repeated full-history metrics, evaluate incremental summaries and correction handling.

### 36 · `aaac3041-11fb-420c-b148-a5020e5ebb72`

Q: A query asks for one order date OR one customer ID and scans many date partitions. Why?

A. OR always disables every index in every engine.
B. The customer-ID branch can match rows on many other dates.
C. The date branch requests every month.
D. Partitioning rewrites OR into AND.

Answer: B. Results from the customer branch must be included even outside the chosen date. A is too absolute.

Remember: Date=Aug 10 OR customer=7 must include customer 7's January order.

Pro tip: A split-branch plan may help, but preserve overlap semantics and measure total cost.

### 37 · `6061085d-498d-4932-b6ca-59da0cd72231`

Q: A date-partitioned query uses `EXTRACT(YEAR FROM order_date) = 2026` and reads more than expected. What should be checked first?

A. Whether the expression maps to expected partitions, compared with an equivalent direct date range.
B. Whether sorting output by order ID changes the year.
C. Whether every row has a non-NULL customer ID.
D. Whether adding DISTINCT removes old partitions.

Answer: A. It tests whether the predicate form affects pruning while preserving the year requirement. B and D are unrelated.

Remember: The equivalent bounded filter is `order_date >= Jan 1 2026 AND order_date < Jan 1 2027`; compare scans.

Pro tip: Do not claim all functions disable pruning; use the engine's plan and job metrics.

### 38 · `0d928e00-9e61-4acf-a487-7568550776eb`

Q: A date filter selects one partition, but a customer filter inside it still processes millions of rows. What does this show?

A. The date partition filter is not working.
B. Every customer must exist on all dates.
C. Customer ID has become the partition key.
D. Date pruning worked, but work inside the selected partition remains.

Answer: D. Pruning removes other dates, not unrelated customers within the chosen date. A contradicts the plan.

Remember: One daily partition holds 10M sales; selecting customer 7 may still require searching within those 10M.

Pro tip: Test clustering or an appropriate index for repeated selective customer lookups.

### 39 · `d944929e-2dbe-4e36-80c4-d03f8792b002` · Select two

Q: A batch deduplicates customer changes, then computes MIN and MAX created dates for a date-partitioned Silver merge. Which two statements are true?

A. Deduplication can reduce repeated versions to one preferred row per customer.
B. The MIN/MAX range can exclude Silver partitions outside the affected dates.
C. MIN/MAX proves every date inside the range changed.
D. Deduplication makes the target join key unnecessary.

Answer: A, B. They reduce source versions and bound target dates. C mistakes a continuous range for a set of changed dates.

Remember: Changes for Aug 1 and Aug 30 produce two changed dates but a 30-day MIN/MAX range.

Pro tip: Compare a distinct-date strategy when affected days are sparse, and include a stable dedup tie-breaker.

### 40 · `f799cdc2-4324-423e-a06f-d6780eabc71f`

Q: A table is partitioned by created_date, but most queries search by customer ID without a date. What is the key mismatch?

A. Customer ID searches do not provide a narrow created-date range.
B. A customer filter automatically narrows created-date partitions.
C. Date partitioning prevents any customer lookup.
D. All customer IDs must have been created on the same date.

Answer: A. The physical layout serves date filters better than customer-only filters. C is too strong: lookups still work, but may cost more.

Remember: Customer 7 could have been created in any of 60 monthly partitions; the query does not name one.

Pro tip: Consider clustering or an alternate access path based on the measured lookup workload.

### 41 · `3892ffc9-e1af-4668-92d8-75fc9c114ccb`

Q: An order-date-partitioned table is filtered only by customer ID, and the plan reads nearly all dates. What is the right conclusion?

A. Date pruning is limited because no date predicate bounds the partitions.
B. The customer predicate is logically equivalent to a one-day filter.
C. Partitioning is corrupted and must be recreated.
D. An outer ORDER BY will prune dates.

Answer: A. The observed scan follows the filter pattern; customer ID does not identify order dates. C is unsupported.

Remember: One customer's orders may span 2022–2026, so all years can remain eligible.

Pro tip: If users frequently search only by customer, test a customer-oriented index or layout in your engine.

### 42 · `2c4561fa-41fa-4600-9825-1dfaf6a8b240`

Q: An integer-keyed table is filtered with `customer_id = '12345'`. What should an engineer do rather than assume a performance result?

A. Assume quoted values always cause a full scan.
B. Compare with a typed integer literal and inspect casts and scan behavior in the plan.
C. Cast the integer column to STRING in every query.
D. Remove the predicate to let the optimizer decide.

Answer: B. Engines may implicitly convert the literal, but typed comparison is clearer and measurable. A is too absolute.

Remember: Compare `id = '12345'` with `id = 12345`; check which one reads the intended key range.

Pro tip: Parameter types matter too; bind an integer parameter for an integer column.

## Senior

### 43 · `004288da-3de9-46cd-b396-5b3460ae0563`

Q: A date-partitioned order fact is filtered for August 2026 OR cancelled orders. Why can the plan read nearly every date?

A. The August branch always requires every historical date.
B. The status branch can match cancelled orders outside August.
C. A DATE column cannot be partitioned.
D. OR is equivalent to an AND between its branches.

Answer: B. To preserve the OR result, the engine must consider cancelled rows from other dates. A confuses the two branches.

Remember: An order cancelled in March must appear even though it is not an August order.

Pro tip: Measure the status branch separately; if cancellation spans most dates, rewriting syntax alone may not reduce total scan.

### 44 · `11b7113a-411f-4984-ba49-4de15c712a1d`

Q: A date-partitioned sales query asks for August rows OR all ONLINE rows, and ONLINE sales occur across years. Which rewrite is safe to test?

A. Keep only August; ONLINE outside August is optional.
B. Change OR to AND so both filters prune.
C. Use two disjoint UNION ALL branches: August rows, and ONLINE rows outside August; compare the full plan.
D. Use two identical branches, both without filters.

Answer: C. Disjoint branches preserve the OR result without duplicating August-ONLINE rows. The second branch may still scan many dates.

Remember: August ONLINE appears in the August branch; July ONLINE appears in the outside-August branch, each once.

Pro tip: Do not assume UNION ALL is faster; its two reads may cost as much or more than the original query.

### 45 · `df3bbc5d-41ef-4c4d-9ba4-662bb9ee6b49` · Select two

Q: An account-ID-partitioned banking fact is queried for account 1000001 OR any FRAUD transaction. Fraud can occur under any account. Which two tests are worthwhile?

A. Compare a correctly typed account-ID predicate and inspect whether the account branch prunes.
B. Test a separate access path for the rare fraud predicate and measure a split-branch plan.
C. Assume fraud rarity means the account partitions can all be skipped.
D. Convert the account column to text in every row before comparing.

Answer: A, B. They address the two different access paths. Rarity of fraud does not locate which account partitions contain it.

Remember: One fraud row can live in account 8, one in account 900; the fraud branch cannot be answered from account 1000001 alone.

Pro tip: Use disjoint UNION ALL branches or deduplicate by a stable row key to preserve OR semantics when splitting.

### 46 · `61f9516b-24d6-4d36-8ec2-317d97d6343b`

Q: A physically date-partitioned event table is queried for one day, yet nearly every partition is read. Which diagnostic is most useful first?

A. Check whether the actual predicate directly constrains the physical partition column and inspect the plan.
B. Add DISTINCT to the final event rows.
C. Increase ORDER BY columns until pruning starts.
D. Assume the table was never partitioned despite metadata.

Answer: A. A transformed or different date expression, an OR branch, or a view can make the apparent one-day request fail to bound the real partition key. D ignores the known metadata.

Remember: A table partitioned by event_date cannot infer a one-day event_date range from every unrelated timestamp expression.

Pro tip: Check the resolved query after views or parameter binding, not just the dashboard's displayed date control.

### 47 · `5c290193-1bdf-4cdb-9b2e-4eb45a7cc311`

Q: Trades is partitioned by trade_date. A query filters `DATE(trade_timestamp) = Aug 10 OR trade_type = 'OPTION'` and reads nearly all dates. What should be diagnosed?

A. Only the timestamp conversion; the OR branch cannot affect dates.
B. Only the trade type; the timestamp expression is guaranteed to prune trade_date.
C. Both whether the timestamp predicate maps to trade_date and whether OPTION rows span dates.
D. The number of output columns, which determines date partitions.

Answer: C. The filter does not directly bound trade_date, and the OR branch can match other dates. Either can limit pruning.

Remember: An OPTION trade in June is required; an Aug 10 timestamp filter alone cannot exclude it.

Pro tip: Preserve timezone and trade-date business rules when replacing timestamp expressions with partition-date predicates.

### 48 · `e0a05286-510e-4186-a16e-af061f509018`

Q: An INT region key is compared with `'10'`, and the plan shows an implicit cast plus more scanning than expected. What should be tested first?

A. Cast every stored region value to STRING.
B. Remove the date filter to simplify the query.
C. Assume all casts always prevent pruning.
D. Use a typed INT literal or parameter, then compare cast placement and scan metrics.

Answer: D. A type-matched comparison removes ambiguity; the plan confirms whether the cast had a real effect. C is an unsupported universal claim.

Remember: Compare `region_code = '10'` with `region_code = 10`; inspect which side the engine converts and how much it reads.

Pro tip: If region 10 itself is large, typed predicates may be correct yet still scan substantial data.

### 49 · `9224c69e-91b3-4096-9b44-c7c65cada1a9` · Select two

Q: A change batch affects only Aug 1 and Aug 30, but a MIN/MAX target filter scans every date between them. Which two improvements merit testing?

A. Collect the distinct affected partition dates rather than only MIN/MAX.
B. Test a target filter or join against those dates, then compare plan and scan cost.
C. Drop Aug 30 changes so the range becomes one day.
D. Scan all history to ensure no date is missed.

Answer: A, B. Sparse changed-date keys can avoid the 28 unchanged days between them if the engine can use that filter. C loses data.

Remember: `{Aug 1, Aug 30}` is two target dates; `MIN..MAX` covers 30 dates.

Pro tip: Verify the optimizer actually prunes a dynamic key-list or join; some MERGE plans still scan broadly.

### 50 · `0caa954f-0cb5-41bc-9431-a086e4c8eabb` · Select two

Q: An integer-device-partitioned IoT table is filtered by `device_id = '9001' OR error_code = 'E500'`, and the plan scans almost everything. Which two observations matter?

A. The error-code branch may match rows across many device partitions.
B. Inspect the implicit type conversion and compare a typed device-ID literal.
C. A rare error code guarantees the engine reads one device partition.
D. Converting device_id to STRING always improves pruning.

Answer: A, B. The OR branch is not limited to device 9001, and the type mismatch deserves inspection. C confuses selectivity with physical location.

Remember: Device 9001 has a normal event, while device 3 has E500. Both must be returned.

Pro tip: BigQuery integer-range partitions group IDs into ranges; do not assume one partition per device.

## Six new gap-covering questions

### 51 · `sql_opt_20260928_01`

Q: A BigQuery plan shows a join receiving 1M orders and 2M item rows but producing 40M rows. What should you inspect first?

A. Whether join keys are unique at the intended grain and whether the predicate is complete.
B. Whether the final SELECT has too few output columns.
C. Whether adding ORDER BY after the join will reduce matches.
D. Whether removing the date filter will distribute the join.

Answer: A. Unexpected row growth points to many-to-many matches or an incomplete join condition. Sorting cannot correct join cardinality.

Remember: If one order matches 20 rows on each side, a broad key can make 400 pairs for that order.

Pro tip: Compare input and output rows at the join stage before treating DISTINCT as a repair.

### 52 · `sql_opt_20260928_02`

Q: A report needs order count per customer plus customer name. Orders has 500M rows; customers has one row per ID. Which plan may reduce join work?

A. Join every order to customers, then sort all rows.
B. Count orders by customer ID first, then join the smaller result to customers.
C. CROSS JOIN orders to customers, then group by customer.
D. Join raw orders twice so the optimizer sees more rows.

Answer: B. Pre-aggregation can turn many order rows into one count per customer before the dimension join.

Remember: Customer A has 1,000 orders. Grouping first sends one `(A, 1000)` row to the join instead of 1,000 rows.

Pro tip: Confirm the dimension is unique by customer ID and that no order-level columns are needed later.

### 53 · `sql_opt_20260928_03`

Q: A BigQuery dashboard counts distinct visitors over billions of events. The product owner accepts a documented estimate. Which change is worth testing?

A. Replace COUNT(DISTINCT user_id) with COUNT(*) and label it distinct.
B. Replace COUNT(DISTINCT user_id) with SUM(user_id).
C. Compare APPROX_COUNT_DISTINCT(user_id) with exact count for error and cost.
D. Remove duplicate events before defining what a visitor means.

Answer: C. APPROX_COUNT_DISTINCT is an estimate designed for large distinct counts; its error must fit the use case.

Remember: If exact distinct visitors are 1,000,000, an approximate result may be near that value but need not equal it.

Pro tip: Keep exact counts for billing, compliance, or other decisions requiring exactness.

### 54 · `sql_opt_20260928_04`

Q: A BigQuery query spends most of its time shuffling a large GROUP BY, and job insights show shuffle spill to disk. What should you investigate?

A. Reducing rows or grouping cardinality before the shuffle, without changing the metric.
B. Adding more output aliases to the final SELECT.
C. Removing filters so the shuffle has more data.
D. Sorting the final results twice after aggregation.

Answer: A. Spill indicates shuffle memory pressure; reducing data entering the stage can help. The other choices do not target the expensive stage.

Remember: A stage shuffles 800 GB and spills 300 GB; an earlier valid reduction to 80 GB directly addresses that pressure.

Pro tip: Check whether a hot key, not only total bytes, causes a few tasks to spill.

### 55 · `sql_opt_20260928_05`

Q: A query seems ten times faster on its second run. Before claiming a SQL rewrite caused the improvement, what should you check?

A. Whether the second run benefited from cached results or warmed storage.
B. Whether the query text has more line breaks.
C. Whether the output column names changed.
D. Whether the first run happened on a weekday.

Answer: A. Cache effects can make repeated runs incomparable even with identical SQL.

Remember: The same query takes 20 seconds cold and 2 seconds when cached; no SQL change was needed for that difference.

Pro tip: Compare bytes processed, cache-hit status, and multiple representative runs when benchmarking.

### 56 · `sql_opt_20260928_06`

Q: A join plan estimated 10K rows but actually returned 50M after a recent data load. What should be checked before forcing a join method?

A. Only the spelling of the table alias.
B. Key duplication, value distribution, and the engine's table statistics or estimates.
C. Whether the final ORDER BY is alphabetical.
D. Whether adding DISTINCT hides the extra rows.

Answer: B. A large estimate error may come from changed key distribution or missing statistics; first determine whether the 50M rows are logically correct.

Remember: A key once matched one dimension row but now matches 50; a 1M-row fact can grow toward 50M join rows.

Pro tip: Statistics controls vary by engine; inspect actual-versus-estimated rows and the loaded data before changing physical design.
