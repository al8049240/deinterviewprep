# SQL Joins — 42-question review draft

Review draft only. No Supabase rows are changed. IDs map to the pasted export. Each item has one best answer; the options are intentionally similar in form and detail. A–D positions are draft display positions, not the existing option order.

## Junior (25)

### 1. `16ae8482-d4b9-44a9-84af-30dbbeb5dc31` — anti-join

A service registry has one row per service. `incidents` can contain many rows per service. Return services that have never had an incident. Which query is correct?

A. `SELECT s.service_id FROM services s JOIN incidents i ON i.service_id = s.service_id WHERE i.incident_id IS NULL;`
B. `SELECT s.service_id FROM services s LEFT JOIN incidents i ON i.service_id = s.service_id WHERE i.incident_id IS NULL;`
C. `SELECT s.service_id FROM services s LEFT JOIN incidents i ON i.service_id = s.service_id WHERE i.incident_id IS NOT NULL;`
D. `SELECT s.service_id FROM services s RIGHT JOIN incidents i ON i.service_id = s.service_id WHERE i.incident_id IS NULL;`

Answer: B. The service side must survive an absent incident; test a non-nullable incident key after the left join.

### 2. `96deaf09-9584-4219-bff2-ca60afe3a44c` — self-join with missing parent

`employees(employee_id, name, manager_id)` includes a CEO with no manager. The report must show every employee and their direct manager's name when present. Which join is best?

A. `employees e INNER JOIN employees m ON e.manager_id = m.employee_id`
B. `employees e LEFT JOIN employees m ON e.employee_id = m.manager_id`
C. `employees e LEFT JOIN employees m ON e.manager_id = m.employee_id`
D. `employees e LEFT JOIN employees m ON e.manager_id = m.manager_id`

Answer: C. The employee is the preserved side, and manager_id references the manager's employee_id.

### 3. `1e8383ed-c59d-45a5-b9ba-26b75fda5d14` — fact-to-dimension join

`meter_readings(reading_id, meter_id, kwh)` joins to `meters(meter_id, region)`, where meter_id is unique in `meters`. The report needs total kWh by region for readings with a known meter. Which plan is correct?

A. Join on meter_id, then `SUM(kwh) GROUP BY region`.
B. Group readings by meter_id, then sum meter IDs by region.
C. Cross join readings to meters, then `SUM(kwh) GROUP BY region`.
D. Join on region, then `SUM(kwh) GROUP BY meter_id`.

Answer: A. The dimension supplies region; the fact supplies kWh. The unique dimension key avoids multiplication.

### 4. `6481f443-b6c3-4029-b58d-e421f5e3d9f5` — intentional Cartesian product

A test matrix must contain every combination of 3 database engines and 4 storage formats, even when no test run exists yet. Which construction creates exactly 12 starting rows?

A. Inner join engines to formats on an existing test_run_id.
B. Left join engines to formats on an existing test_run_id.
C. Full outer join engines and formats on matching names.
D. Cross join engines and formats before joining test results.

Answer: D. Every engine-format pair is required; 3 × 4 gives 12 rows.

### 5. `310ac5a9-b73e-4236-adfe-61d1e1ceae3e` — intersection

A hospital wants clinician IDs present in both its credentialing registry and its shift schedule. Neither source is guaranteed to be complete. Which join best returns only IDs found in both?

A. Left join the registry to schedules and keep every registry row.
B. Inner join the two sources on clinician_id.
C. Full outer join the sources and keep unmatched rows.
D. Right join schedules to the registry and keep every registry row.

Answer: B. The requirement is the intersection; deduplicate IDs afterward if either source has repeated rows.

### 6. `d887750b-0bd9-434f-8108-0ee5ac9a432a` — self-join key direction

In `employees(employee_id, name, manager_id)`, return each employee *with a recorded manager* and that manager's name. Which ON clause connects the two roles correctly?

A. `e.employee_id = m.manager_id`
B. `e.manager_id = m.manager_id`
C. `e.employee_id = m.employee_id`
D. `e.manager_id = m.employee_id`

Answer: D. The employee's foreign key points to the manager's primary key; an inner join is acceptable because only employees with managers are requested.

### 7. `dbe040e5-8c3c-4ed6-a1d6-a9a5d98edec4` — zero completed revenue

Every account must appear with completed invoice revenue; accounts without completed invoices need zero. Which pattern meets all three requirements?

A. Start from accounts; left join invoices with status in ON; group by account; `COALESCE(SUM(amount),0)`.
B. Start from accounts; left join invoices; filter completed status in WHERE; group by account; `COALESCE(SUM(amount),0)`.
C. Start from accounts; inner join completed invoices; group by account; `COALESCE(SUM(amount),0)`.
D. Start from accounts; left join completed invoices in ON; group by account; use `SUM(amount)` without COALESCE.

Answer: A. The left join preserves accounts, ON filters matching invoices, and COALESCE converts an absent sum to zero.

### 8. `c532f777-ee67-49a4-a94d-47f27ebc02bd` — missing reference records

An inventory master has one row per SKU. A shipping catalog may lack some SKUs. Which pattern finds inventory SKUs with no catalog mapping?

A. Inner join inventory to catalog and keep rows with non-NULL catalog.sku_id.
B. Left join inventory to catalog and keep rows with non-NULL catalog.sku_id.
C. Left join inventory to catalog and keep rows with NULL catalog.sku_id.
D. Right join inventory to catalog and keep rows with NULL inventory.sku_id.

Answer: C. Preserve inventory and filter the missing catalog side; test a non-nullable catalog key.

### 9. `54d646e2-23f6-4fc8-90e3-43134242d028` — absence without duplicates

`devices` contains registered devices, while `events` can contain millions of events per device. You need each device that has never emitted an event, once. Which expression most directly states this requirement?

A. `WHERE EXISTS (SELECT 1 FROM events e WHERE e.device_id = d.device_id)`
B. `WHERE NOT EXISTS (SELECT 1 FROM events e WHERE e.device_id = d.device_id)`
C. `INNER JOIN events e ON e.device_id = d.device_id` followed by `DISTINCT`
D. `LEFT JOIN events e ON e.device_id = d.device_id` followed by `WHERE e.device_id IS NOT NULL`

Answer: B. NOT EXISTS is an anti-semi-join and does not duplicate devices when many events exist.

### 10. `29a6e139-ac49-4cb9-8141-5f2026c1aa0a` — preserved side of RIGHT JOIN

Starting with `appointments a RIGHT JOIN departments d`, what happens to a department with no appointment?

A. It disappears because appointments is written first.
B. It appears once, with NULL appointment columns.
C. It appears once for every appointment in another department.
D. It appears only if a WHERE condition tests a.appointment_id IS NOT NULL.

Answer: B. RIGHT JOIN preserves the right-hand departments table; a later WHERE predicate can still remove that row.

### 11. `c30f6471-5886-49b3-98cb-89b02bebe3c7` — zero counts after outer join

The catalog report needs every product and its number of sales, including zero-sale products. Which aggregate should follow `products p LEFT JOIN sales s ON p.product_id=s.product_id`?

A. `COUNT(*)` with `GROUP BY p.product_id`.
B. `COUNT(*)` with `GROUP BY s.product_id`.
C. `COUNT(s.sale_id)` with `GROUP BY s.product_id`.
D. `COUNT(s.sale_id)` with `GROUP BY p.product_id`.

Answer: D. Group by the preserved product key and count a non-nullable sale key; COUNT(*) would count the null-extended row.

### 12. `d98cc183-1ef6-49c5-b691-c4b0dfed3244` — right-side WHERE filter

A report starts with `assets a LEFT JOIN scans s ON s.asset_id=a.asset_id`. It then adds `WHERE s.status='PASSED'`. What happens to assets with no scan?

A. They remain, with status NULL, because LEFT JOIN always preserves them through WHERE.
B. They remain, with status PASSED, because WHERE supplies the missing value.
C. They are removed because `NULL='PASSED'` is not TRUE.
D. They are removed only when the scans table contains another asset with PASSED status.

Answer: C. WHERE null-rejects the unmatched rows; put the status predicate in ON if unscanned assets must remain.

### 13. `9da04e1b-0826-4206-820b-8e03a886d14d` — matching fact rows

A claims report needs claim amount and patient name, but only for claims whose patient_id matches a patient record. Which join from claims to patients fits?

A. Inner join on patient_id.
B. Left join on patient_id and retain unmatched claims.
C. Full outer join on patient_id and retain unmatched patients.
D. Cross join followed by a patient-name filter.

Answer: A. The report explicitly requests matched claims only. If *every* claim were needed, a left join from claims would be appropriate.

### 14. `c54bcaca-5299-407d-ac0b-ee8ed057183a` — cardinality

`courses` has one row per course; `enrollments` has 12 rows for Course A and none for Course B. What does an inner join on course_id return for those courses?

A. One Course A row and one Course B row.
B. Twelve Course A rows and one Course B row.
C. Twelve Course A rows and no Course B row.
D. One Course A row and no Course B row.

Answer: C. An inner join returns a row per matching enrollment and excludes courses with no match.

### 15. `6ccda634-22d6-4dc5-a7d2-a21fa6dc8914` — unique qualifying entities

A job can have many successful runs. The report needs each job with at least one successful run exactly once. Which *join-based* plan is correct?

A. Inner join jobs to successful runs and select job columns without deduplication.
B. Left join jobs to successful runs and keep rows where run_id IS NULL.
C. Inner join jobs to successful runs and select DISTINCT job columns.
D. Full outer join jobs and runs and select all joined rows.

Answer: C. The inner join qualifies jobs, while DISTINCT restores one row per job. EXISTS would also be good if a join were not required.

### 16. `b3601994-c01e-4476-a864-9d595d7b35dd` — complete reporting grid

For every store and every week in a 12-week reporting period, show sales or zero. Which plan creates the required 12 rows per store even when sales are missing?

A. Aggregate sales by store and week, then fill NULL amounts in existing rows.
B. Cross join stores to the 12-week calendar, left join weekly sales, then COALESCE.
C. Left join stores to weekly sales without a calendar, then COALESCE.
D. Cross join stores to the calendar, inner join weekly sales, then COALESCE.

Answer: B. The store-week grid creates missing combinations before sales are joined.

### 17. `e578cdfc-6c67-4b89-b3da-db7ba7508c71` — both-sided reconciliation

Two warehouses publish product_id lists. You must classify products as in both, only A, or only B in one result. Which join preserves every key needed for classification?

A. Inner join A to B on product_id.
B. Left join A to B on product_id.
C. Right join A to B on product_id.
D. Full outer join A to B on product_id.

Answer: D. Both source-only and target-only keys must survive; check uniqueness before classifying.

### 18. `ca940f3c-60d4-465e-a62f-61d3ee1d0743` — unified reconciliation key

After a full outer join of `source_assets s` and `target_assets t` on asset_id, which expression produces a non-NULL output key for source-only, target-only, and matched rows?

A. `s.asset_id`
B. `t.asset_id`
C. `COALESCE(s.asset_id, t.asset_id)`
D. `NULLIF(s.asset_id, t.asset_id)`

Answer: C. Either side may be absent; COALESCE selects the populated key. This tests the step after choosing FULL OUTER JOIN.

### 19. `59046e6d-99d4-4f02-8879-7831be508039` — cross-join row count

A pipeline cross joins 8 model versions with 5 regions before any filtering. How many rows are produced if each input has unique rows?

A. 8, because the left side is preserved.
B. 13, because both input counts are added.
C. 40, because every version pairs with every region.
D. At most 5, because only matching keys survive.

Answer: C. CROSS JOIN creates the Cartesian product: 8 × 5.

### 20. `a7a583ee-ece0-474d-987d-176c94a90ae8` — left-join semantics

A fleet report starts from vehicles and left joins trips on vehicle_id. Which statement holds before any WHERE filter is applied?

A. Every vehicle appears at least once; unmatched trip columns are NULL.
B. Every trip appears at least once; unmatched vehicle columns are NULL.
C. Only vehicles with at least one trip appear.
D. Every vehicle-trip pair appears regardless of vehicle_id.

Answer: A. LEFT JOIN preserves the left input, though multiple matching trips can repeat a vehicle.

### 21. `a8d1b420-3a1c-404a-b7d4-f590ff849eaa` — right-join equivalence

Which rewrite is equivalent to `readings r RIGHT JOIN meters m ON r.meter_id=m.meter_id` when selecting the same columns?

A. `meters m INNER JOIN readings r ON r.meter_id=m.meter_id`
B. `meters m LEFT JOIN readings r ON r.meter_id=m.meter_id`
C. `meters m RIGHT JOIN readings r ON r.meter_id=m.meter_id`
D. `meters m CROSS JOIN readings r`

Answer: B. Reversing table order and using LEFT JOIN preserves the same meter side.

### 22. `73f2a739-58f4-4801-a7d0-106161f05f74` — full-join output

Source A has keys {1,2}; source B has keys {2,3}, with unique keys on both sides. How many rows does a full outer join on key return?

A. One row, for key 2 only.
B. Two rows, for keys 1 and 2.
C. Two rows, for keys 2 and 3.
D. Three rows, for keys 1, 2, and 3.

Answer: D. The matched key is combined, while both unmatched keys remain.

### 23. `b3fcf6b9-8f89-444b-ad7d-827658d06d36` — inner-join output

`deployments` has IDs {10,11,12}; `reviews` has deployment IDs {11,12,13}, one row per ID. An inner join on deployment_id returns which IDs?

A. {10,11,12,13}
B. {11,12}
C. {10,11,12}
D. {11,12,13}

Answer: B. Only keys present in both inputs match.

### 24. `b4ad7f20-0613-4872-ae7f-cbea60b30813` — self-join roles

A task table has task_id and parent_task_id. To show a task with its parent task title, which ON condition uses the table twice in the correct roles?

A. `child.task_id = parent.parent_task_id`
B. `child.parent_task_id = parent.parent_task_id`
C. `child.parent_task_id = parent.task_id`
D. `child.task_id = parent.task_id`

Answer: C. The child's parent foreign key points to the parent's task ID.

### 25. `b01bd86b-e7e0-43e1-9043-72b4342b5b87` — null-extended rows

A left join from `projects` to `deployments` finds no deployment for Project P. What value appears in `deployments.deployment_id` for P before COALESCE?

A. NULL, because no right-side row matched.
B. 0, because deployment_id is numeric.
C. P's project_id, copied into the right-side key.
D. The deployment table's column default.

Answer: A. A missing joined row supplies NULLs, not zeros or defaults.

## Middle (10)

### 26. `661a74bf-dc0a-41e5-baab-23df82ab6cd3` — reconciliation classification

`source_parts` and `target_parts` each have a unique part_id. A reconciliation report needs MATCHED, SOURCE_ONLY, and TARGET_ONLY. Which plan produces all three classes?

A. Inner join and classify differing attributes as SOURCE_ONLY.
B. Left join source to target and classify NULL target keys as TARGET_ONLY.
C. Full outer join on part_id and classify by which side's key is NULL.
D. Union only the source keys and classify missing targets afterward.

Answer: C. Both unmatched sides must be retained; a full outer join supports all three classes.

### 27. `b7105d09-aad3-42c0-acf5-b087e32d1091` — hierarchical display

An org-chart export must show every employee and their direct manager name; the CEO has no manager. Which query pattern preserves the CEO without mistaking direct reports for managers?

A. `employees e LEFT JOIN employees m ON e.manager_id=m.employee_id`
B. `employees e INNER JOIN employees m ON e.manager_id=m.employee_id`
C. `employees e LEFT JOIN employees m ON e.employee_id=m.manager_id`
D. `employees e LEFT JOIN employees m ON e.manager_id=m.manager_id`

Answer: A. The left side preserves every employee; the key direction retrieves the direct manager.

### 28. `a070db41-ee27-42ee-9c33-4c36c7f02ed0` — point-in-time join

Patient coverage is versioned by patient_id with `[valid_from, valid_to)` intervals. Claims have service_time. Which join retrieves the plan active when each claim occurred?

A. Match patient_id and use the current coverage row.
B. Match patient_id and require `service_time=valid_from`.
C. Match patient_id and require `service_time<=valid_from`.
D. Match patient_id and require `service_time>=valid_from AND service_time<valid_to`.

Answer: D. A half-open validity interval attributes each claim to the version active at service time, assuming intervals do not overlap.

### 29. `54f76142-f4bd-41df-9e25-fed8422a0a6e` — boundary case in temporal join

An FX rate for an account is valid from 09:00 up to, but not including, 10:00; the next rate begins at 10:00. A transaction occurs exactly at 10:00. Which predicate assigns only the new rate?

A. `transaction_time BETWEEN effective_from AND effective_to`
B. `transaction_time >= effective_from AND transaction_time < effective_to`
C. `transaction_time > effective_from AND transaction_time <= effective_to`
D. `transaction_time = effective_from OR transaction_time = effective_to`

Answer: B. Inclusive start and exclusive end avoid two matches at the boundary.

### 30. `522b1afa-1326-4cfe-a6b6-df2dc0b94f87` — self-join pair uniqueness

Fraud analytics needs pairs of transactions on the same card, different merchants, no more than 10 minutes apart, with each pair returned once. Transaction times are distinct for a given card. Which conditions should relate t1 and t2?

A. Same card, different merchant, `t2.time>t1.time`, and `t2.time<=t1.time+10 minutes`.
B. Same card, different merchant, absolute time difference at most 10 minutes, with no pair direction.
C. Same card, same merchant, `t2.time>t1.time`, and `t2.time<=t1.time+10 minutes`.
D. Same card, different merchant, `t2.time>t1.time`, with no upper time bound.

Answer: A. The strict forward direction avoids duplicate/reversed pairs; the upper bound enforces the window.

### 31. `b3a46449-51b4-40b1-a6a5-18af38da4af4` — count versus count-star

Every instructor must appear with a session count, including zero. Which query has the right join, grouping key, and count target?

A. `instructors i LEFT JOIN sessions s ... GROUP BY i.id; COUNT(*)`
B. `instructors i INNER JOIN sessions s ... GROUP BY i.id; COUNT(s.id)`
C. `instructors i LEFT JOIN sessions s ... GROUP BY s.instructor_id; COUNT(s.id)`
D. `instructors i LEFT JOIN sessions s ... GROUP BY i.id; COUNT(s.id)`

Answer: D. Preserve and group by instructor; count a nullable right-side session ID so an unmatched instructor gets zero.

### 32. `21e07f4f-9a6b-465d-b3ba-27f25b6d4fb2` — anti-join with a filtered relationship

A SaaS team needs services with **no open incident**. Closed incidents should not disqualify a service. Which pattern is correct?

A. Left join all incidents, then `WHERE incident_id IS NULL`.
B. Left join incidents with `status='OPEN'` in ON, then `WHERE incident_id IS NULL`.
C. Inner join open incidents, then `WHERE incident_id IS NULL`.
D. Left join open incidents, then `WHERE incident_id IS NOT NULL`.

Answer: B. Only open incidents participate in the absence test; a closed-only service still qualifies.

### 33. `f66dd99e-ea58-4305-8330-7bd6c733c092` — semi-join

Pipelines can have many successful runs. The report needs one row per pipeline with at least one successful run, and no run columns. Which approach states the requirement without creating duplicate pipeline rows?

A. Inner join pipelines to successful runs and project pipeline columns.
B. Left join pipelines to successful runs and keep NULL run IDs.
C. Correlated EXISTS for a successful run per pipeline.
D. Full outer join pipelines and successful runs, then group by run ID.

Answer: C. EXISTS tests existence and does not multiply pipeline rows.

### 34. `7b5bed0d-87a8-4c3a-b282-d20e7f194e09` — metric grain after one-to-many join

`shipments` has one row and one shipment_cost per shipment. `packages` has multiple rows per shipment. After joining them, `SUM(shipment_cost)` is inflated. Which fix protects the shipment-cost metric?

A. Change LEFT JOIN to INNER JOIN without changing the aggregation.
B. Add DISTINCT across shipment and package columns before SUM.
C. Group by package_id and sum shipment_cost for every package.
D. Calculate shipment-level cost separately or reduce package data to shipment grain before combining.

Answer: D. The one-to-many join repeats a shipment-level measure for every package.

### 35. `434d3c1b-1ac4-438e-91c7-20054ba7b81d` — multiple relationships at controlled grain

A report needs every account, completed-invoice total, whether any invoice has a catalog-listed item, and whether the account has never invoiced. Which design avoids multiplying invoice amounts by invoice lines?

A. Sum completed invoices from invoices alone by account; derive catalog-item existence separately; left join results to accounts; use NOT EXISTS for never-invoiced.
B. Join accounts, invoices, lines, and products at line grain; sum invoice.amount by account; use HAVING for never-invoiced.
C. Join invoices to lines and products first; sum invoice.amount by account; full join that total to accounts.
D. Left join accounts to invoices and lines; use SUM(DISTINCT invoice.amount) to remove repeated invoice amounts.

Answer: A. Separate customer-grain measures and existence checks. `SUM(DISTINCT amount)` is unsafe when different invoices share the same amount.

## Senior (7)

### 36. `c73d6467-e34e-40a6-84f6-1d6f81272c28` — selective join input

A plan joins a large event fact to a region dimension before applying a highly selective dimension filter. The join processes far more rows than the final report. What should you test first, while preserving semantics?

A. Increase worker count without changing the number of rows entering the join.
B. Materialize the unfiltered dimension and keep its filter after aggregation.
C. Push the selective dimension predicate before the join and compare physical plans.
D. Add DISTINCT after the join to reduce only the final result size.

Answer: C. Reducing join input is the likely opportunity, but the optimizer may already push the predicate down; verify the plan.

### 37. `a9004b66-2b51-4815-b2a1-193aface5a7b` — adjacent events versus all pairs

The fraud rule now compares each card transaction only with its **immediately preceding** transaction. It flags a different merchant within 10 minutes. A self-join generates too many candidate pairs. Which rewrite preserves this *revised* rule?

A. Use LAG for merchant and time partitioned by card, ordered by time and a unique ID, then compare adjacent rows.
B. Use LAG partitioned by merchant, ordered by card, then compare adjacent merchants.
C. Keep the self-join and add DISTINCT after producing every possible pair.
D. Remove the time condition from the join and filter pairs only after the join.

Answer: A. LAG fits an adjacent-event rule; it would **not** preserve a rule requiring every qualifying pair within the window.

### 38. `528b4edb-267a-4ae4-a6dc-d641a2f12984` — cardinality estimate gap

A join estimated 12 million rows but produced 900 million after a key distribution change. Which investigation best addresses the first evidence in the plan?

A. Force a new join algorithm before checking input and output row estimates.
B. Compare key uniqueness, distribution, and statistics with actual rows at each join input.
C. Add DISTINCT to the final SELECT to reduce the visible result only.
D. Increase join memory before checking why the optimizer expected so few matches.

Answer: B. Diagnose the 75× estimate gap before trying plan or resource workarounds.

### 39. `0e264dc5-dbab-481e-a125-207c92b85682` — fact-to-fact fan-out

`usage_events` and `service_credits` each have many rows per account. A report needs account-level usage and credit totals; raw joining on account_id multiplies both measures. What redesign preserves the metrics?

A. Join raw rows and calculate both sums in one final account GROUP BY.
B. DISTINCT raw rows on all columns, then join and sum by account.
C. Full outer join raw rows, then use COALESCE on account_id before summing.
D. Aggregate each fact to account_id separately, then join the account-level results.

Answer: D. Each measure must be reduced to the required grain before combining the facts.

### 40. `0510f872-d621-4f53-acf2-9a8d7e91615a` — interpret fan-out

Joining order-level rows to item-level rows increases output 30×, then a customer revenue aggregation becomes expensive. What is the first check?

A. Whether the final GROUP BY has enough memory, ignoring the join output.
B. Whether each order has many items and an order-level revenue field is repeated at item grain.
C. Whether switching INNER to LEFT JOIN removes repeated order amounts.
D. Whether DISTINCT across all item columns makes order amounts unique.

Answer: B. The stated relationship is one-to-many; inspect metric grain and row multiplication before downstream tuning.

### 41. `2f0b85b6-907a-4451-b050-51f245ad7915` — tiny lookup access

A large transaction scan probes a lookup of fewer than 200 country codes repeatedly. The plan shows lookup access, not the fact scan, as an avoidable cost. What should you investigate?

A. Split the small lookup into more partitions for each transaction worker.
B. Re-evaluate the lookup as a correlated subquery for each fact row.
C. Test whether the engine can cache, broadcast, or materialize the lookup once.
D. Sort the large fact table before every lookup without checking sort cost.

Answer: C. A small reusable lookup may be efficient in memory, depending on the engine and plan.

### 42. `a84a6e4b-ba14-4a23-99dd-5fda462cf5a4` — sort-bound merge join

A plan spends most time sorting two large inputs before a merge join, while the merge itself is fast. Which investigation is best supported by that evidence?

A. Check whether useful key ordering, clustering, or indexes can avoid or reduce the sorts in this engine.
B. Add DISTINCT after the join to make the pre-join sorts unnecessary.
C. Force a larger merge buffer without measuring the cost of sorting.
D. Denormalize every customer attribute into orders before examining the sort operators.

Answer: A. Target the expensive sort shown in the plan; physical-design options are engine-dependent.

## Explanation and coaching text for review

These fields correspond to the revised A–D options above. The explanation names the correct reasoning and the specific flaw in each competing option. `interview_note` is the concise answer a candidate should be ready to say aloud; `pro_tips` adds a production check or caveat.

### 1 — missing incidents

Explanation: B keeps every service before testing for an absent incident. A eliminates unmatched services with INNER JOIN; C selects services *with* incidents; D preserves the incident side instead of the service registry.

Interview note: Say which table defines the population and which non-nullable key proves that no related row matched.

Pro tips: `NOT EXISTS` is another clear anti-join pattern when no incident columns are needed. Confirm incident_id cannot be NULL in a real incident row.

### 2 — employee and manager

Explanation: C follows e.manager_id to m.employee_id and preserves the CEO. A drops employees without a manager; B reverses the relationship and finds direct reports; D pairs employees who share a manager.

Interview note: Describe the two aliases as roles—employee and manager—before naming LEFT JOIN.

Pro tips: Verify whether the report needs managerless employees. That requirement decides LEFT versus INNER JOIN even when the key condition is identical.

### 3 — kWh by region

Explanation: A joins each reading to its unique meter row and sums kWh at region grain. B aggregates identifiers rather than kWh; C multiplies readings across unrelated meters; D joins and groups at the wrong grain.

Interview note: State the fact grain, the dimension key, and the requested output grain.

Pro tips: Check that meters.meter_id is unique. Duplicate dimension keys can inflate regional totals even with the right JOIN keyword.

### 4 — test combinations

Explanation: D creates the complete 3-by-4 matrix before optional results are attached. A and B depend on test runs that might not exist; C reconciles matching names rather than creating all combinations.

Interview note: CROSS JOIN is appropriate when the Cartesian product is the business requirement, not an accident.

Pro tips: Estimate the product of input row counts before using CROSS JOIN in production; a small matrix is useful, while two large inputs can be costly.

### 5 — clinicians in both systems

Explanation: B returns IDs that match in both sources. A and D preserve a whole side, including unmatched IDs; C preserves unmatched rows from both sides rather than the intersection.

Interview note: Translate “in both systems” into an intersection, then check whether the output must be unique by clinician_id.

Pro tips: A one-to-many match in either source can repeat an ID. Use DISTINCT or pre-deduplicate only if the requested output grain is one clinician.

### 6 — direct-manager ON condition

Explanation: D maps e.manager_id to m.employee_id. A reverses the roles and finds reports; B matches coworkers with the same manager; C matches each employee row to itself.

Interview note: Draw the foreign-key arrow from manager_id to employee_id before choosing an ON condition.

Pro tips: Since this item requests only employees with recorded managers, an INNER JOIN is sufficient; a LEFT JOIN would be needed to keep the CEO.

### 7 — completed invoice revenue

Explanation: A preserves accounts, matches only completed invoices, and converts an absent SUM to zero. B puts the status filter in WHERE and removes unmatched accounts; C drops them with INNER JOIN; D retains them but yields NULL instead of zero.

Interview note: Check preservation, filter placement, and zero conversion as three separate requirements.

Pro tips: `SUM` over no matching non-NULL amounts yields NULL. `COALESCE` makes the reporting default explicit rather than changing join semantics.

### 8 — missing catalog mapping

Explanation: C preserves inventory SKUs and retains only those without a catalog key. A and B return matched SKUs; D preserves the catalog side and finds records missing from inventory instead.

Interview note: For an anti-join, name the side you keep and the side whose absence you test.

Pro tips: Prefer `NOT EXISTS` if the purpose is only to test absence. If using LEFT JOIN plus IS NULL, test a key guaranteed non-NULL for real matches.

### 9 — devices with no event

Explanation: B expresses non-existence directly and returns each registered device once. A and D find devices with events; C also finds devices with events and can repeat them before DISTINCT.

Interview note: Explain why an existence test is preferable when event details are not needed.

Pro tips: On a large event table, inspect the plan and index, clustering, or partition strategy for the correlation key; syntax alone does not guarantee performance.

### 10 — preserved RIGHT JOIN side

Explanation: B is the null-extended result for an unmatched department. A incorrectly treats the first-written table as preserved; C imagines unrelated appointment multiplication; D would filter the unmatched department out.

Interview note: RIGHT JOIN preserves the right input before later filters run.

Pro tips: Rewriting as departments LEFT JOIN appointments often makes the preserved population easier to read and review.

### 11 — count zero-sale products

Explanation: D groups by each preserved product and counts real sale IDs. A counts the null-extended product row as one; B and C group by the right-side key, which is NULL for every unsold product and can merge them.

Interview note: COUNT(*) and COUNT(right_table.id) differ after a LEFT JOIN with no match.

Pro tips: Group by the preserved entity's unique key. Product names alone may not be unique enough for the reporting grain.

### 12 — scan-status WHERE

Explanation: C follows SQL's NULL logic: the unmatched scan status is NULL, so the WHERE equality is not TRUE. A ignores the later WHERE filter; B assumes SQL fills a status; D incorrectly makes removal depend on other assets.

Interview note: Walk through the query in sequence: LEFT JOIN creates a null-extended row, then WHERE removes it.

Pro tips: Put `s.status='PASSED'` in ON if the report must keep unscanned assets while only attaching passed scans.

### 13 — matched claims

Explanation: A returns only claims with a patient match. B also keeps unmatched claims; C additionally keeps patients without claims; D creates unrelated combinations.

Interview note: State explicitly whether missing patient records should remain in the result; that determines INNER versus LEFT JOIN.

Pro tips: Do not silently lose unmatched claims in an audit report. A separate data-quality check may be needed even when the main report intentionally uses INNER JOIN.

### 14 — enrollment cardinality

Explanation: C follows the stated one-to-many relationship: Course A appears 12 times and Course B has no joined row. A, B, and D incorrectly assume deduplication or preservation that INNER JOIN does not provide.

Interview note: A join's result grain is often the many-side row, not the one-side entity.

Pro tips: Before SUM or COUNT after a join, estimate expected row multiplication from the key cardinalities.

### 15 — one row per qualifying job

Explanation: C qualifies jobs by matching successful runs and then deduplicates the projected job rows. A can repeat jobs; B finds jobs without a successful run; D preserves unrelated unmatched rows.

Interview note: Matching at least one run and returning one row per job are different requirements.

Pro tips: When run columns are not needed, `EXISTS` is often clearer than INNER JOIN plus DISTINCT; the item asks specifically for a join-based plan.

### 16 — store-week grid

Explanation: B creates all required store-week rows, then fills sales from the optional activity table. A and C cannot invent weeks with no sales; D constructs the grid but discards empty combinations through INNER JOIN.

Interview note: Define the desired output grain before touching the sales fact table.

Pro tips: Generate or join a bounded calendar for the reporting period. A dense grid can become large when both entity and time ranges are broad.

### 17 — product reconciliation

Explanation: D preserves matched, A-only, and B-only product keys. A loses both unmatched classes; B loses B-only keys; C loses A-only keys.

Interview note: “Only A,” “only B,” and “both” require both sides' unmatched rows in one result.

Pro tips: If a source has duplicate product IDs, normalize or deduplicate first; otherwise classification rows can multiply.

### 18 — unified asset key

Explanation: C returns the populated key regardless of which side matched. A is NULL for target-only rows; B is NULL for source-only rows; D returns NULL for matched equal keys.

Interview note: With FULL OUTER JOIN, choose a common output key from both nullable sides.

Pro tips: Also retain separate source and target presence flags; COALESCE gives a display key but not the reconciliation class by itself.

### 19 — cross-join count

Explanation: C multiplies the input counts, 8 × 5. A confuses CROSS JOIN with left preservation; B adds rather than multiplies; D assumes a matching-key condition that is absent.

Interview note: Compute the expected Cartesian size before suggesting a CROSS JOIN.

Pro tips: Cross joins are useful for small planning grids; with large inputs, estimate the intermediate row count and memory impact.

### 20 — left-join semantics

Explanation: A preserves vehicles and uses NULL trip columns for vehicles without trips. B describes right-side preservation; C describes an inner join; D describes a cross join.

Interview note: LEFT JOIN preserves the left population but can still repeat a vehicle when it has many trips.

Pro tips: A right-table filter in WHERE may remove null-extended vehicles later, so inspect the entire query, not only the JOIN clause.

### 21 — right-to-left rewrite

Explanation: B reverses the input order while preserving meters. A drops unmatched meters; C preserves readings instead; D pairs unrelated rows.

Interview note: A RIGHT JOIN can be rewritten as a LEFT JOIN by swapping table positions and keeping the same ON relationship.

Pro tips: Use a consistent left-preserving style when it makes a complex query easier for a team to inspect.

### 22 — full-join keys

Explanation: D includes the A-only key 1, matched key 2, and B-only key 3. A is the inner-join result; B and C are left- and right-preserving results respectively.

Interview note: A matched pair becomes one row; unmatched keys from either side remain.

Pro tips: Row counts can exceed distinct-key counts when either input has duplicate join keys; this example explicitly assumes uniqueness.

### 23 — inner-join keys

Explanation: B is the intersection {11,12}. A is the union; C includes an unmatched left key; D includes an unmatched right key.

Interview note: INNER JOIN requires the ON condition to match; it does not preserve either unmatched side.

Pro tips: With non-unique keys, an inner join can return multiple rows per shared key, so distinguish key intersection from row cardinality.

### 24 — parent-task self join

Explanation: C follows child.parent_task_id to parent.task_id. A finds children of the current row; B pairs tasks sharing a parent; D matches each task to itself.

Interview note: Alias each copy of the table by role and trace the foreign key to its referenced key.

Pro tips: Use LEFT JOIN if root tasks with NULL parent_task_id must also appear in the output.

### 25 — null-extended project row

Explanation: A is SQL's value for a missing right-side match. B assumes a numeric default, C copies the left key, and D applies a stored-column default to a row that does not exist.

Interview note: An outer join produces NULL right-side columns for an unmatched row, regardless of their declared defaults.

Pro tips: Convert NULL to a business-friendly label or zero only in the presentation expression, and only when that substitution is semantically valid.

### 26 — three-way reconciliation

Explanation: C retains both sides and classifies by absent keys. A removes source-only and target-only rows; B cannot retain target-only rows; D has no target-only population to classify.

Interview note: Identify MATCHED, SOURCE_ONLY, and TARGET_ONLY using both key-presence checks.

Pro tips: Check unique part_id per source and compare matched attributes separately from presence classification.

### 27 — org-chart export

Explanation: A preserves the CEO and follows manager_id to employee_id. B loses the CEO; C reverses the relationship and finds reports; D pairs coworkers with the same manager.

Interview note: The optional manager is why LEFT JOIN matters here; the foreign-key direction identifies the manager.

Pro tips: Hierarchies can have broken manager references as well as NULL roots. A left join exposes both; profile these cases separately if needed.

### 28 — coverage version at service time

Explanation: D matches the patient's historical row whose half-open interval contains the claim time. A rewrites history using today's plan; B only matches exact change times; C matches future starts rather than the active interval.

Interview note: A point-in-time join needs both an entity key and a validity-window predicate.

Pro tips: Check for overlapping intervals and define how an open-ended valid_to is represented; otherwise one claim may match zero or multiple versions.

### 29 — rate boundary

Explanation: B includes the new interval's start at 10:00 and excludes the old interval's end. A includes both endpoints and can double-match; C assigns the old interval's end; D matches boundary timestamps without the full interval rule.

Interview note: Half-open intervals make adjacent versions meet without overlapping.

Pro tips: Use consistent timestamp types and time zones when joining transaction times to validity ranges.

### 30 — unique fraud pairs

Explanation: A requires the same card, different merchants, a forward direction, and a 10-minute upper bound. B can emit a pair twice in opposite directions; C allows only the same merchant; D allows arbitrarily distant transactions.

Interview note: The `t2.time>t1.time` direction is a pair-deduplication rule as well as a time-order rule.

Pro tips: If simultaneous transactions are possible, use a deterministic transaction-ID tie-breaker rather than relying on a strict timestamp comparison alone.

### 31 — instructor session count

Explanation: D preserves and groups by instructor and counts real session IDs. A counts a null-extended instructor row as one; B loses instructors with no sessions; C groups all unmatched instructors under NULL.

Interview note: A zero count requires counting the nullable joined-side key, not COUNT(*).

Pro tips: Use a non-nullable session primary key as the COUNT target and a unique instructor key for grouping.

### 32 — no open incidents

Explanation: B limits the relationship to OPEN incidents in ON and then tests for no matching open row. A excludes services with closed-only incidents too; C cannot find absent open incidents; D returns services with open incidents.

Interview note: Define *which* relationship must be absent before writing the anti-join.

Pro tips: A correlated `NOT EXISTS` with `status='OPEN'` is an equivalent way to express this condition without joining incident detail rows.

### 33 — successful-run existence

Explanation: C returns each qualifying pipeline once. A can repeat a pipeline for every successful run; B finds pipelines with no success; D uses a run-grain grouping that does not express the requested pipeline result.

Interview note: Use EXISTS when a related table is only a qualification test, not a source of output columns.

Pro tips: Keep the success predicate inside the EXISTS subquery; placing it after an outer join can change missing-row behavior.

### 34 — shipment-cost fan-out

Explanation: D protects the shipment-level cost before combining it with package-level data. A still repeats costs for multi-package shipments; B may retain repeated costs when package columns differ; C explicitly repeats cost per package.

Interview note: Name the measure's grain before SUM: shipment_cost belongs to shipments, not packages.

Pro tips: Pre-aggregate package facts at shipment grain when package details are not needed in the final report.

### 35 — account-quality report

Explanation: A calculates each requirement at the appropriate account or invoice grain. B and C sum invoice amounts after line-level fan-out; D can undercount when distinct invoices happen to have the same amount.

Interview note: Split revenue, existence, and never-invoiced tests instead of forcing raw one-to-many tables into one aggregate.

Pro tips: Validate each intermediate result has at most one row per account before joining it to the reporting population.

### 36 — selective dimension filter

Explanation: C tests reducing join input and verifies whether the physical plan actually changes. A and B retain the large unfiltered join; D reduces only output rows after paying the join cost.

Interview note: Explain the rewrite as a hypothesis supported by the plan, not a guarantee based on SQL text order.

Pro tips: Optimizers may push predicates down automatically; compare rows entering the join before and after the change.

### 37 — adjacent transaction comparison

Explanation: A uses LAG to compare each transaction with exactly its predecessor under a deterministic order. B partitions by the wrong entity; C pays the all-pairs self-join cost; D expands the candidate set before filtering.

Interview note: First confirm whether the rule means adjacent events or *all* pairs within 10 minutes. LAG solves only the adjacent version.

Pro tips: Add a unique transaction ID after timestamp in the window ORDER BY to make ties deterministic.

### 38 — estimate-versus-actual gap

Explanation: B investigates why the optimizer expected 12 million but saw 900 million rows. A and D change execution strategy before explaining the estimate; C shrinks only the visible final output, not the join's intermediate work.

Interview note: Lead with the measured 75× cardinality error, then inspect statistics, duplicate keys, and key distribution.

Pro tips: Compare actual versus estimated rows at both join inputs and the join output to localize where the model diverges.

### 39 — two fact tables

Explanation: D avoids the per-account usage-by-credit multiplication by aggregating each fact independently. A and C still join raw many-side rows; B does not guarantee one row per account or protect monetary totals.

Interview note: State the common output grain before joining two fact tables.

Pro tips: Decide whether accounts present in only one fact must remain; that determines the join type between the *aggregated* results.

### 40 — 30× item expansion

Explanation: B checks the first place the plan expands and whether an order-level measure is repeated at item grain. A starts downstream; C does not remove item multiplicity; D can discard legitimate item rows without fixing measure grain.

Interview note: This is a stated one-to-many relationship, not necessarily a many-to-many data error.

Pro tips: Compare the count of orders, items per order, and rows after the join; then calculate order metrics before or independently of the item-grain join.

### 41 — repeated tiny lookup

Explanation: C targets repeated access to the small table. A fragments an already tiny lookup; B may multiply evaluations; D adds a potentially costly sort without addressing the measured operator.

Interview note: Recommend a physical strategy only after identifying which plan operator is expensive.

Pro tips: Cache, broadcast, and materialization options vary by engine; validate the chosen strategy against the actual execution plan.

### 42 — sort-bound merge join

Explanation: A targets the sorts that dominate runtime. B acts after those sorts; C targets the fast merge rather than expensive preparation; D proposes a broad schema change without first addressing plan evidence.

Interview note: The join algorithm itself is not the bottleneck here—the input sorting is.

Pro tips: Investigate existing physical ordering, clustering, or index support in the specific engine, and compare the cost of maintaining that design with query savings.
