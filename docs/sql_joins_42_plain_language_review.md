# SQL Joins — 42 plain-language questions (review draft)

This is a review draft, not a Supabase migration. IDs link each rewrite to the existing question. The answer letter is a draft display position; existing option IDs and flags have not been changed. `Remember` is the proposed new use of `interview_note`: a small example, not another explanation.

## Junior

### 1 · `16ae8482-d4b9-44a9-84af-30dbbeb5dc31`

Q: You have a list of all services and a list of service incidents. How do you find services that have never had an incident?

A. Inner join services to incidents and keep rows with a missing incident ID.
B. Left join services to incidents and keep rows with a missing incident ID.
C. Left join services to incidents and keep rows with an incident ID.
D. Right join services to incidents and keep rows with a missing incident ID.

Answer: B. A left join keeps services even when no incident matches; the missing incident ID identifies them.

Remember: `services = {A, B}` and `incidents = {A}`. After a left join, B has a NULL incident ID, so B is the answer.

Pro tip: Test a column that cannot be NULL for a real incident, such as its primary key.

### 2 · `96deaf09-9584-4219-bff2-ca60afe3a44c`

Q: One employee table stores each person's manager ID. You need every employee's name and their manager's name, including the CEO who has no manager. Which join works?

A. Inner join the employee table to itself using employee.manager_id = manager.employee_id.
B. Left join the employee table to itself using employee.employee_id = manager.manager_id.
C. Left join the employee table to itself using employee.manager_id = manager.employee_id.
D. Left join the employee table to itself using employee.manager_id = manager.manager_id.

Answer: C. The left join keeps the CEO, and manager_id points to the manager's employee_id.

Remember: `Ana.manager_id = 7` and `Ben.employee_id = 7`; Ana matches Ben. The CEO has `manager_id = NULL` and still appears with a blank manager name.

Pro tip: Give the two copies of the table clear names such as employee and manager.

### 3 · `1e8383ed-c59d-45a5-b9ba-26b75fda5d14`

Q: Sales rows have product_id and amount. A products table has one row per product and its category. How do you find total sales amount by category?

A. Join sales to products on product_id, then sum amount by category.
B. Join sales to products on category, then sum amount by product_id.
C. Cross join sales to products, then sum amount by category.
D. Group sales by product_id without using the products table.

Answer: A. The products table supplies category; the sales table supplies the amount to add.

Remember: Sales of 10 and 20 for products in category A become `A = 30` after joining products and grouping by category.

Pro tip: Make sure product_id is unique in products, or the join can repeat sales amounts.

### 4 · `6481f443-b6c3-4029-b58d-e421f5e3d9f5`

Q: A shop wants every possible combination of 3 shirt sizes and 4 colors. Which join creates the 12 combinations?

A. Inner join sizes and colors on a matching name.
B. Left join sizes to colors on a matching name.
C. Full join sizes and colors on a matching name.
D. Cross join sizes and colors.

Answer: D. A cross join pairs every size with every color: 3 × 4.

Remember: `sizes = {S, M}` and `colors = {red, blue}` produce `(S, red)`, `(S, blue)`, `(M, red)`, `(M, blue)`.

Pro tip: Estimate the number of output rows before cross joining large tables.

### 5 · `310ac5a9-b73e-4236-adfe-61d1e1ceae3e`

Q: Two systems each have a list of product IDs. You need only products found in both systems. Which join fits?

A. Left join the first list to the second and keep all first-list rows.
B. Inner join the lists on product_id.
C. Full join the lists and keep missing matches.
D. Right join the lists and keep all second-list rows.

Answer: B. An inner join keeps matching IDs from both lists.

Remember: System A has `{1, 2}` and B has `{2, 3}`. An inner join returns only ID `2`.

Pro tip: If IDs repeat in a source, the join can repeat products. Deduplicate only when the report needs one row per product.

### 6 · `d887750b-0bd9-434f-8108-0ee5ac9a432a`

Q: In an employee table, manager_id stores the employee_id of that person's manager. Which join condition finds the manager's row?

A. employee.employee_id = manager.manager_id
B. employee.manager_id = manager.manager_id
C. employee.employee_id = manager.employee_id
D. employee.manager_id = manager.employee_id

Answer: D. The employee's manager_id points to the manager's employee_id.

Remember: Alice has `manager_id = 5`; Bob has `employee_id = 5`. Joining those values puts Bob's name beside Alice.

Pro tip: Decide separately whether employees without managers should remain; that choice determines inner versus left join.

### 7 · `dbe040e5-8c3c-4ed6-a1d6-a9a5d98edec4`

Q: A report must show every customer and the total from their completed orders. Customers with none must show 0. Which plan works?

A. Left join completed orders using ON, group by customer, then use COALESCE on the sum.
B. Left join all orders, filter completed orders in WHERE, group by customer, then use COALESCE.
C. Inner join completed orders, group by customer, then use COALESCE on the sum.
D. Left join completed orders using ON, group by customer, then use the sum without COALESCE.

Answer: A. The left join keeps everyone, ON limits matching orders, and COALESCE turns a missing total into 0.

Remember: Ana has a completed order of 20; Ben has none. The report shows `Ana = 20`, `Ben = 0`.

Pro tip: Check these three parts separately: who stays, which orders match, and how missing totals appear.

### 8 · `c532f777-ee67-49a4-a94d-47f27ebc02bd`

Q: Your stock list has product IDs. A shipping list may be missing some products. How do you find stock products absent from the shipping list?

A. Inner join the lists and keep rows with a shipping product ID.
B. Left join stock to shipping and keep rows with a shipping product ID.
C. Left join stock to shipping and keep rows without a shipping product ID.
D. Right join stock to shipping and keep rows without a stock product ID.

Answer: C. Keep the full stock list, then find rows without a shipping match.

Remember: Stock has `{A, B}`; shipping has `{A}`. A left join gives B a NULL shipping ID, so B is missing.

Pro tip: `NOT EXISTS` is another clear way to ask whether a product has no shipping record.

### 9 · `54d646e2-23f6-4fc8-90e3-43134242d028`

Q: Some registered devices have sent many events; others have sent none. You need each device with no event, once. Which test is clearest?

A. EXISTS an event for the device.
B. NOT EXISTS an event for the device.
C. Inner join devices to events and select DISTINCT devices.
D. Left join devices to events and keep matched event IDs.

Answer: B. NOT EXISTS asks exactly whether a matching event is absent and does not create duplicate device rows.

Remember: Devices `{D1, D2}`; events contain only `D1`. `NOT EXISTS` is true for `D2`.

Pro tip: Check the event table's access path for device_id when the event history is very large.

### 10 · `29a6e139-ac49-4cb9-8141-5f2026c1aa0a`

Q: In `appointments RIGHT JOIN departments`, what happens to a department with no appointment?

A. It is removed because appointments comes first.
B. It appears with NULL appointment columns.
C. It is repeated for appointments in other departments.
D. It appears only if appointment_id is not NULL.

Answer: B. RIGHT JOIN keeps the table on the right: departments.

Remember: Appointments contain only Dept A; departments contain A and B. The RIGHT JOIN still shows B with NULL appointment columns.

Pro tip: Swapping the table order and using LEFT JOIN is often easier to read.

### 11 · `c30f6471-5886-49b3-98cb-89b02bebe3c7`

Q: Show every product and its number of sales, including products with zero sales. After `products LEFT JOIN sales`, what should you group and count?

A. Group by product ID; use COUNT(*).
B. Group by sale-side product ID; use COUNT(*).
C. Group by sale-side product ID; use COUNT(sale_id).
D. Group by product ID; use COUNT(sale_id).

Answer: D. Group by the kept product row and count real sale IDs; COUNT(*) counts the empty joined row too.

Remember: Product B has no sale. Its left-joined row exists, so `COUNT(*) = 1`, but `COUNT(sale_id) = 0`.

Pro tip: Count a sale key that cannot be NULL for a real sale.

### 12 · `d98cc183-1ef6-49c5-b691-c4b0dfed3244`

Q: A query starts with `customers LEFT JOIN orders` and then adds `WHERE orders.status = 'COMPLETED'`. What happens to customers without an order?

A. They stay because LEFT JOIN always keeps them through later filters.
B. They stay because their missing status becomes COMPLETED.
C. They are removed because NULL status does not pass the WHERE test.
D. They are removed only if another customer has a completed order.

Answer: C. The left join first keeps them, but the WHERE filter removes their NULL-status rows.

Remember: Ben has no order, so `orders.status` is NULL. `WHERE status = 'COMPLETED'` removes Ben's row.

Pro tip: Put the order-status test in ON if customers without completed orders must stay.

### 13 · `9da04e1b-0826-4206-820b-8e03a886d14d`

Q: A report needs orders only when a matching customer record exists. Which join from orders to customers fits?

A. Inner join on customer_id.
B. Left join on customer_id and retain unmatched orders.
C. Full join on customer_id and retain unmatched customers.
D. Cross join and then filter by customer name.

Answer: A. The report asks for matched orders only.

Remember: Orders `{O1→C1, O2→C9}`; customers contain only `C1`. An inner join returns `O1`, not `O2`.

Pro tip: If missing customer records are a data-quality concern, count them separately instead of silently ignoring them.

### 14 · `c54bcaca-5299-407d-ac0b-ee8ed057183a`

Q: Course A has 12 students; Course B has none. What does an inner join of courses to enrollments return for these courses?

A. One row for A and one for B.
B. Twelve rows for A and one for B.
C. Twelve rows for A and none for B.
D. One row for A and none for B.

Answer: C. The join returns one row for each matching enrollment and drops the unmatched course.

Remember: Course A has students 1 and 2; Course B has none. An inner join returns two A rows and no B row.

Pro tip: Check one-to-many row growth before summing course-level numbers after the join.

### 15 · `6ccda634-22d6-4dc5-a7d2-a21fa6dc8914`

Q: A customer may place many orders. You need each customer who ordered at least once, but only one row per customer. Which join-based plan works?

A. Inner join and select customer columns without removing repeats.
B. Left join and keep rows where order_id is NULL.
C. Inner join and select DISTINCT customer columns.
D. Full join and select every joined row.

Answer: C. The join finds customers with orders; DISTINCT removes repeats caused by multiple orders.

Remember: Ana has orders O1 and O2. The inner join gives two Ana rows; selecting DISTINCT customer columns gives one.

Pro tip: If you do not need order columns, EXISTS can express the same requirement more directly.

### 16 · `b3601994-c01e-4476-a864-9d595d7b35dd`

Q: Show sales for every store in every week of a 12-week period, using 0 for weeks with no sales. What should you build first?

A. Weekly totals from the sales rows that exist.
B. Every store-week pair, then left join weekly totals.
C. Every store, then left join sales without a week list.
D. Every store-week pair, then inner join weekly totals.

Answer: B. The store-week list creates missing weeks before optional sales are attached.

Remember: Stores `{A, B}` and weeks `{1, 2}` make four store-week rows before sales are joined, even if B has no sales.

Pro tip: Keep the calendar limited to the reporting period so the grid does not grow unnecessarily.

### 17 · `e578cdfc-6c67-4b89-b3da-db7ba7508c71`

Q: Two stores each send a product list. You need products in both lists and products in only one list. Which join keeps everything needed?

A. Inner join the lists.
B. Left join the first list to the second.
C. Right join the first list to the second.
D. Full outer join the lists.

Answer: D. A full outer join keeps matches and missing products from either store.

Remember: Store A has `{1, 2}`; Store B has `{2, 3}`. A full outer join keeps keys `1`, `2`, and `3`.

Pro tip: Check for duplicate product IDs in each source before reconciling.

### 18 · `ca940f3c-60d4-465e-a62f-61d3ee1d0743`

Q: You full-join two product lists. A product may appear on only the left or only the right. Which expression gives one product ID in the output for every result row?

A. left.product_id
B. right.product_id
C. COALESCE(left.product_id, right.product_id)
D. NULLIF(left.product_id, right.product_id)

Answer: C. COALESCE takes the ID from whichever side is present.

Remember: A right-only product has `left.product_id = NULL` and `right.product_id = 3`; `COALESCE` returns `3`.

Pro tip: Keep separate left/right presence flags so you can still tell which list held the product.

### 19 · `59046e6d-99d4-4f02-8879-7831be508039`

Q: You cross join 8 shirt designs with 5 colors. How many rows do you get before filtering?

A. 8 rows.
B. 13 rows.
C. 40 rows.
D. At most 5 rows.

Answer: C. Every design pairs with every color: 8 × 5.

Remember: Designs `{A, B}` and colors `{red, blue}` make four rows after CROSS JOIN: each design with each color.

Pro tip: Multiply input row counts before running a large cross join.

### 20 · `a7a583ee-ece0-474d-987d-176c94a90ae8`

Q: A vehicle list is left-joined to trips. Before any WHERE filter, what happens to a vehicle with no trip?

A. It stays, with NULL trip columns.
B. It disappears because there is no trip.
C. It pairs with every unrelated trip.
D. It appears once for each trip of another vehicle.

Answer: A. LEFT JOIN keeps the vehicle side even without a matching trip.

Remember: Vehicles `{V1, V2}`; trips contain only V1. A left join still shows V2 with NULL trip columns.

Pro tip: A later WHERE condition on trip columns can still remove those vehicles.

### 21 · `a8d1b420-3a1c-404a-b7d4-f590ff849eaa`

Q: Which join gives the same rows as `trips RIGHT JOIN vehicles ON vehicle_id`, assuming you select the same columns?

A. `vehicles INNER JOIN trips ON vehicle_id`
B. `vehicles LEFT JOIN trips ON vehicle_id`
C. `vehicles RIGHT JOIN trips ON vehicle_id`
D. `vehicles CROSS JOIN trips`

Answer: B. Swap table order and preserve vehicles with LEFT JOIN.

Remember: `trips RIGHT JOIN vehicles` and `vehicles LEFT JOIN trips` both keep V2 even when V2 has no trip.

Pro tip: Use explicit table aliases and key names in real SQL so the ON condition remains unambiguous.

### 22 · `73f2a739-58f4-4801-a7d0-106161f05f74`

Q: List A has IDs {1,2}; List B has {2,3}. Each ID appears once per list. How many rows does a full outer join on ID return?

A. One, for ID 2.
B. Two, for IDs 1 and 2.
C. Two, for IDs 2 and 3.
D. Three, for IDs 1, 2, and 3.

Answer: D. It keeps the shared ID and each unmatched ID.

Remember: A has `{1, 2}` and B has `{2, 3}`. A full outer join gives three keys: A-only `1`, both `2`, B-only `3`.

Pro tip: If either list has repeated IDs, the row count can be higher than the count of unique IDs.

### 23 · `b3fcf6b9-8f89-444b-ad7d-827658d06d36`

Q: List A has IDs {10,11,12}; List B has {11,12,13}. Which IDs appear after an inner join on ID?

A. {10,11,12,13}
B. {11,12}
C. {10,11,12}
D. {11,12,13}

Answer: B. Only IDs present in both lists survive.

Remember: A has `{10, 11}` and B has `{11, 12}`. An inner join keeps only `11`.

Pro tip: An inner join returns matching *rows*; duplicate keys can create more rows than this distinct-ID example.

### 24 · `b4ad7f20-0613-4872-ae7f-cbea60b30813`

Q: A tasks table has task_id and parent_task_id. Which condition joins a task to its parent task?

A. child.task_id = parent.parent_task_id
B. child.parent_task_id = parent.parent_task_id
C. child.parent_task_id = parent.task_id
D. child.task_id = parent.task_id

Answer: C. The child's parent_task_id points to the parent's task_id.

Remember: Task 9 has `parent_task_id = 3`; Task 3 has `task_id = 3`. The self join attaches Task 3 as Task 9's parent.

Pro tip: Use a left join if tasks without parents should remain.

### 25 · `b01bd86b-e7e0-43e1-9043-72b4342b5b87`

Q: A project is left-joined to deployments, but Project A has no deployment. What value appears in the deployment_id column for Project A?

A. NULL.
B. 0.
C. Project A's project_id.
D. The deployment table's default ID.

Answer: A. No deployment row exists, so the joined deployment columns are NULL.

Remember: Project A has no deployment. Its left-joined row has `deployment_id = NULL`, not `0`.

Pro tip: Use COALESCE only if the business wants a display value in place of NULL.

## Middle

### 26 · `661a74bf-dc0a-41e5-baab-23df82ab6cd3`

Q: Two systems each have a parts list. You need one result that labels each part as in both systems, only the first, or only the second. Which join should you start with?

A. Inner join on part_id.
B. Left join the first list to the second.
C. Full outer join on part_id.
D. Right join the first list to the second.

Answer: C. A full outer join keeps matching and unmatched parts from both lists.

Remember: Source has `{P1, P2}`; target has `{P2, P3}`. The full join labels P1 source-only, P2 both, and P3 target-only.

Pro tip: Make sure part_id is unique in each source before counting differences.

### 27 · `b7105d09-aad3-42c0-acf5-b087e32d1091`

Q: An employee table has employee_id, name, and manager_id. Your org chart must include the CEO, who has no manager. Which join gives each employee's manager name?

A. Left join employee.manager_id to manager.employee_id.
B. Inner join employee.manager_id to manager.employee_id.
C. Left join employee.employee_id to manager.manager_id.
D. Left join employee.manager_id to manager.manager_id.

Answer: A. It follows the manager link and keeps employees without a manager.

Remember: Alice points to manager ID 5, so she gets Bob's name; the CEO has NULL manager_id and remains with NULL manager name.

Pro tip: Give each copy of the employee table a role-based alias so you do not reverse the keys.

### 28 · `a070db41-ee27-42ee-9c33-4c36c7f02ed0`

Q: A customer's membership plan changes over time. Each plan row has valid_from and valid_to. An order should use the plan active on its order_date. Which join condition is right?

A. Match customer_id and use the newest plan row.
B. Match customer_id and require order_date = valid_from.
C. Match customer_id and require order_date < valid_from.
D. Match customer_id and require order_date >= valid_from AND order_date < valid_to.

Answer: D. The order date must fall inside the plan's active period.

Remember: Plan A is valid Jan 1–Feb 1; Plan B starts Feb 1. A Jan 20 order joins A, while a Feb 1 order joins B.

Pro tip: Check that plan periods for one customer do not overlap.

### 29 · `54f76142-f4bd-41df-9e25-fed8422a0a6e`

Q: One price is valid from 9:00 until 10:00, and the next price starts at 10:00. A purchase happens exactly at 10:00. Which time test gives it only the new price?

A. purchase_time BETWEEN valid_from AND valid_to
B. purchase_time >= valid_from AND purchase_time < valid_to
C. purchase_time > valid_from AND purchase_time <= valid_to
D. purchase_time = valid_from OR purchase_time = valid_to

Answer: B. Include the start but exclude the end so adjacent price periods do not overlap.

Remember: Rate A covers `[09:00, 10:00)` and Rate B covers `[10:00, 11:00)`. A 10:00 purchase matches only B.

Pro tip: Use the same time zone and timestamp type on both sides of a time-based join.

### 30 · `522b1afa-1326-4cfe-a6b6-df2dc0b94f87`

Q: Find pairs of card payments made at different shops within 10 minutes. Return each pair once. Payment times are unique for each card. Which self-join rule works?

A. Same card, different shop, second time > first time, and at most 10 minutes later.
B. Same card, different shop, time difference at most 10 minutes, with no pair direction.
C. Same card, same shop, second time > first time, and at most 10 minutes later.
D. Same card, different shop, second time > first time, with no 10-minute limit.

Answer: A. The forward time rule avoids reversed duplicates; the time limit and different shop rule complete the test.

Remember: Same card pays at Shop A at 10:00 and Shop B at 10:07. Keep the pair `(10:00, 10:07)`, not its reverse.

Pro tip: If two payments can share a timestamp, add a unique payment-ID tie-breaker.

### 31 · `b3a46449-51b4-40b1-a6a5-18af38da4af4`

Q: Show every teacher and how many classes they taught, including teachers with zero classes. Which plan is right?

A. Left join teachers to classes; group by teacher ID; COUNT(*).
B. Inner join teachers to classes; group by teacher ID; COUNT(class ID).
C. Left join teachers to classes; group by class-side teacher ID; COUNT(class ID).
D. Left join teachers to classes; group by teacher ID; COUNT(class ID).

Answer: D. Keep teachers, group by their ID, and count real class rows.

Remember: Teachers `{Ana, Ben}`; classes contain only Ana's class C1. After LEFT JOIN, `COUNT(class_id)` gives Ana 1 and Ben 0.

Pro tip: COUNT(*) after a left join counts the kept teacher row as one.

### 32 · `21e07f4f-9a6b-465d-b3ba-27f25b6d4fb2`

Q: Find services with no **open** incident. A service with only closed incidents should still appear. Which plan works?

A. Left join all incidents and keep rows with no incident ID.
B. Left join only open incidents and keep rows with no incident ID.
C. Inner join only open incidents and keep rows with no incident ID.
D. Left join only open incidents and keep rows with an incident ID.

Answer: B. The absence test must apply to open incidents, not all incidents.

Remember: Service A has one CLOSED incident; Service B has one OPEN incident. The no-open-incident result includes A, not B.

Pro tip: `NOT EXISTS` with an open-status test expresses the same rule directly.

### 33 · `f66dd99e-ea58-4305-8330-7bd6c733c092`

Q: A pipeline can have many successful runs. You need one row per pipeline that has at least one successful run, but no run details. Which approach is simplest?

A. Inner join pipelines to successful runs and return pipeline columns.
B. Left join pipelines to successful runs and keep missing run IDs.
C. Use EXISTS to check for a successful run for each pipeline.
D. Full join pipelines and runs, then group by run ID.

Answer: C. EXISTS checks whether a run exists without repeating the pipeline.

Remember: Pipeline P has two successful runs. `EXISTS` returns P once; joining to runs would return P twice.

Pro tip: Put the successful-status condition inside the EXISTS test.

### 34 · `7b5bed0d-87a8-4c3a-b282-d20e7f194e09`

Q: One shipment has one shipping cost but several packages. After joining shipments to packages, total shipping cost is too high. What should you change?

A. Change the join type but keep summing shipping cost after the package join.
B. Add DISTINCT across all package columns before summing shipping cost.
C. Group by package ID and sum shipping cost once per package.
D. Calculate shipping cost at shipment level, separate from package-level rows.

Answer: D. The package join repeats each shipment's cost, so keep the cost calculation at shipment level.

Remember: Shipment S costs 10 and has 3 packages. The join shows 10 three times, but the shipment total is still 10, not 30.

Pro tip: Reduce package data to one row per shipment before combining it with shipment-level totals.

### 35 · `434d3c1b-1ac4-438e-91c7-20054ba7b81d`

Q: A customer report needs every customer, completed-order total, whether any order had a catalog product, and whether the customer never ordered. How do you avoid counting an order total once per item?

A. Total completed orders by customer first; check catalog products separately; left join results to customers; use NOT EXISTS for never ordered.
B. Join customers, orders, items, and products first; then sum order amounts by customer.
C. Join orders to items and products first; then sum order amounts and full join customers.
D. Join all tables and use SUM(DISTINCT order amount) to remove repeated amounts.

Answer: A. Separate the totals and yes/no checks before item rows can multiply order amounts.

Remember: Order O1 is 20 and has two items. Joining items makes two rows of 20; summing those rows gives the wrong 40.

Pro tip: SUM(DISTINCT amount) is unsafe: two different orders can have the same amount.

## Senior

### 36 · `c73d6467-e34e-40a6-84f6-1d6f81272c28`

Q: A query joins a huge sales table to a smaller region table. Only a few regions are needed, but the plan joins many rows before filtering regions. What should you test first?

A. Add workers without changing the rows entering the join.
B. Keep all regions until after the final totals are calculated.
C. Filter to the needed regions before the join and compare plans.
D. Add DISTINCT after the join to shrink only the final output.

Answer: C. Fewer rows entering a costly join may help; confirm whether the engine already moves the filter earlier.

Remember: A region table has 100 regions but the report needs only 2. Filtering to those 2 before the join may reduce matching work; check the plan.

Pro tip: Check the actual plan, not just where the WHERE clause appears in written SQL.

### 37 · `a9004b66-2b51-4815-b2a1-193aface5a7b`

Q: A rule compares each card payment only with that card's **previous** payment. It checks whether shops differ and times are within 10 minutes. The current self-join creates too many pairs. What can replace it?

A. Use LAG by card, ordered by time and a unique ID, to read the previous payment.
B. Use LAG by shop, ordered by card, to read the previous shop.
C. Keep the self-join and remove repeated pairs at the end with DISTINCT.
D. Join on card only, then check times after making all pairs.

Answer: A. LAG gives the previous row in each card's time order without building every pair.

Remember: A card pays at 10:00, 10:05, and 10:08. LAG compares 10:08 with 10:05, not with every earlier payment.

Pro tip: LAG is **not** a replacement if the business wants every pair within 10 minutes rather than only neighboring payments.

### 38 · `528b4edb-267a-4ae4-a6dc-d641a2f12984`

Q: A join was expected to make 12 million rows but actually made 900 million. The key values changed recently. What should you inspect first?

A. Force another join method before checking the row estimates.
B. Check key duplicates, value distribution, and table statistics against actual row counts.
C. Add DISTINCT to the final SELECT so the output looks smaller.
D. Give the join more memory before asking why the estimate was wrong.

Answer: B. First explain why the expected and actual row counts differ so much.

Remember: A key expected to match 1 row now matches 50. Check duplicate keys and statistics before forcing a different join method.

Pro tip: Compare estimated and actual rows at both join inputs and the join output.

### 39 · `0e264dc5-dbab-481e-a125-207c92b85682`

Q: Usage records and credit records both have many rows per account. Joining raw rows by account makes totals too large. What should you do?

A. Join all raw rows and sum both amounts at the end.
B. Remove exact duplicate raw rows, then join and sum.
C. Full join raw rows, then use COALESCE on account ID.
D. Total each table by account separately, then join the account totals.

Answer: D. One total per account from each table avoids multiplying usage rows by credit rows.

Remember: Account A has 2 usage rows and 3 credit rows. A raw join makes 6 pairs; totaling each side first leaves one row per side.

Pro tip: Choose an outer join between the totals if accounts with only usage or only credits must remain.

### 40 · `0510f872-d621-4f53-acf2-9a8d7e91615a`

Q: A join of orders to order items produces 30 times as many rows as orders. A later revenue total is slow. What is the first thing to check?

A. Tune the final total without examining the join.
B. Check whether each order's amount is repeated once for every item.
C. Switch to LEFT JOIN and expect one row per order.
D. Add DISTINCT across all item columns and expect one amount per order.

Answer: B. The order-to-item relationship can repeat an order-level amount many times.

Remember: Order O1 has 5 items. After the join, O1 appears 5 times; summing its order amount there counts it 5 times.

Pro tip: This is one-to-many row growth; calculate order-level money before or apart from the item join.

### 41 · `2f0b85b6-907a-4451-b050-51f245ad7915`

Q: A large table repeatedly reads the same tiny country-code lookup during a join. The plan shows those repeated reads are costly. What should you investigate?

A. Split the tiny lookup into more pieces for workers to read.
B. Run the lookup separately for every large-table row.
C. Check whether the engine can keep or share the tiny lookup in memory.
D. Sort the large table for every query without checking sort cost.

Answer: C. Reusing the tiny lookup may avoid repeated access, depending on the database engine.

Remember: A 100-row code list is read for each of 1,000 data chunks. Reusing one in-memory copy can avoid 1,000 lookup reads.

Pro tip: Confirm that caching or broadcast is supported and useful in the actual execution plan.

### 42 · `a84a6e4b-ba14-4a23-99dd-5fda462cf5a4`

Q: A plan spends most of its time sorting two big tables before joining them; the join itself is quick. Which change should you investigate first?

A. Check whether saved key order, clustering, or indexes can reduce sorting.
B. Add DISTINCT after the join so the earlier sorts disappear.
C. Give the join more memory without measuring sorting.
D. Copy all columns into one table before checking the sort cost.

Answer: A. The plan points to sorting as the cost to address.

Remember: A plan spends 40 seconds sorting inputs and 2 seconds joining them. Reducing the sort targets the measured cost.

Pro tip: Physical design depends on the database engine and has a maintenance cost; compare that cost with the query benefit.
