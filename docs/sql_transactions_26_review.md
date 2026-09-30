# SQL Transactions — 26 rewrites + 6 new questions

Review draft only. The first 26 IDs, types, option counts, and correct-answer counts match the export; answer letters are draft positions, not stored option IDs. The six additional questions cover missing practical transaction skills. CAP/replica-consistency items are retained under their current IDs but would fit better in a Distributed Systems subtopic.

## Junior

### 1 · `899508a6-4e69-4d8b-bba6-ba981cabcf23`

Q: A balance update is confirmed, and a read routed to another replica must immediately return the new balance. What read behavior is required?

A. A read may return either balance for several seconds.
B. A read always returns the last acknowledged balance.
C. A read returns the oldest stored balance first.
D. A read waits for every past transaction to be archived.

Answer: B. The application requires a strongly consistent read of the acknowledged write. A describes a possible stale read under asynchronous replication.

Remember: Balance changes 1000 → 800 and the write succeeds. The next read must show 800, not 1000.

Pro tip: Confirm the actual database's consistency guarantee and read routing; a strongly consistent primary does not make every asynchronous replica current.

### 2 · `0061b757-3b91-45d5-913d-0a10a2af2e35` · Select two

Q: A transfer subtracts 100 from one account and adds 100 to another, with a rule forbidding negative balances. Which two ACID properties are directly illustrated?

A. Atomicity: both balance changes commit or neither does.
B. Consistency: committed states satisfy the balance rules.
C. Durability: either balance is allowed to disappear after commit.
D. Isolation: the two accounts must be stored on one server.

Answer: A, B. Atomicity prevents half a transfer; consistency concerns the stated rule. D is not what isolation means.

Remember: A=200 and B=50 become A=100 and B=150 together; a failed transfer leaves 200 and 50.

Pro tip: A database constraint or validated conditional update must actually enforce the business rule; ACID alone does not invent it.

### 3 · `be2b19e8-b56b-4895-99e5-0c59c958e064` · Select two

Q: A network partition separates replicas. Payment balances must avoid conflicting accepted writes, while reaction counts can temporarily differ. Which two choices are defensible?

A. Pause some balance writes when the required agreement is unavailable.
B. Keep reaction counts available and reconcile differences later.
C. Accept conflicting balance writes and claim they are immediately identical.
D. Block every reaction read until all replicas are identical.

Answer: A, B. During a partition, the services can choose different availability/consistency trade-offs. C promises incompatible outcomes.

Remember: Two regions disagree for 5 seconds. Payments may reject a write; reaction counters may show 10 and 11 until syncing.

Pro tip: CAP consistency means a single-copy/linearizable behavior, not the ACID rule-validity meaning of “consistency.”

### 4 · `642dca7c-5c42-4cae-997a-df11fb0cd012` · Select two

Q: A platform stores payment balances and video-view counts. Which two consistency requirements are reasonable?

A. Require reads after confirmed balance writes to see the accepted value.
B. Permit a view count to lag briefly if the product accepts it.
C. Treat a stale payment balance as harmless because it is eventually fixed.
D. Require every view-count replica to agree before any view is shown.

Answer: A, B. Financial decisions may need current balances, while a temporary count lag can be acceptable. C ignores financial risk.

Remember: Payment balance 80 must not be read as 100 after confirmation; view counts 1000 and 1002 may converge shortly.

Pro tip: State the user-visible freshness requirement per data type rather than applying one rule to the whole platform.

### 5 · `87785910-dcaa-4f9d-bb34-8b2e2b2feff8`

Q: An address update succeeds, but a read from one replica returns the old address and then the new address ten seconds later. What likely happened?

A. The first read saw an uncommitted write.
B. The address update was rolled back.
C. Replication to that replica lagged behind the confirmed write.
D. The address field was automatically renamed.

Answer: C. An asynchronously updated replica can briefly serve stale data. A would involve uncommitted visibility, not this observed progression.

Remember: Address A → B is accepted at 10:00; a replica says A at 10:01 and B at 10:10.

Pro tip: If read-your-writes is required, route subsequent reads to a source that guarantees it or wait for replication progress.

### 6 · `22e2f0cd-1ac3-4837-808f-76d4de64ffc6`

Q: Replicas can acknowledge a write only after coordination, or acknowledge first and replicate later. What trade-off should the team expect?

A. Coordination may add latency or reject requests during failures; async propagation can allow temporary stale reads.
B. Coordination makes every write free, while async propagation always loses data.
C. Async propagation guarantees all replicas return the new value before acknowledgment.
D. Both designs have identical failure and latency behavior.

Answer: A. Coordination and asynchronous propagation offer different latency, availability, and freshness behavior. C reverses the async guarantee.

Remember: A coordinated write waits for required peers; an async write returns now while another replica may still show old value.

Pro tip: “Strong” and “eventual” labels are broad; verify exact acknowledgment, failover, and read guarantees of the chosen system.

### 7 · `a52da8f9-7130-4c9c-94ea-d80a5b165d2f` · Select two

Q: Two replica groups cannot communicate during a network failure. Which two statements describe the failure and a design choice it creates?

A. Partition tolerance: messages between groups are lost or delayed.
B. Availability: whether every request can still receive a response.
C. Durability: whether a committed disk page survives power loss.
D. Normalization: whether tables have duplicate columns.

Answer: A, B. The partition is the failure, and the design must decide how much service remains available. C is an ACID concern, not the CAP choice being tested.

Remember: Region A cannot reach B; serving a write in both regions keeps responses available but may threaten one agreed value.

Pro tip: State what “available” means for the operation and what happens to requests on the minority side.

### 8 · `af339265-832a-49ff-ae85-7d0f4b43d537` · Select two

Q: During a replica network partition, a payment service refuses writes it cannot safely agree on. Which two descriptions fit?

A. It may delay or reject some requests until agreement is possible.
B. It favors one agreed balance over full write availability during the partition.
C. It guarantees every isolated replica can accept the same write independently.
D. It treats temporary conflicting balances as always harmless.

Answer: A, B. The service sacrifices some availability to avoid incompatible accepted balances. C would need reconciliation and a different contract.

Remember: With A and B disconnected, A accepts a transfer only if it can meet the service's agreement rule; otherwise it says retry.

Pro tip: Distinguish rejecting a write from serving a stale read; systems can choose different policies per operation.

### 9 · `2bca3a3c-825f-41d9-8746-22895c40152d` · Select two

Q: A catalog accepts that new product descriptions may take a few seconds to reach every region. What two benefits can async replication provide?

A. Regions can continue serving some requests during communication delays.
B. Writes may respond without waiting for every replica to update.
C. Every replica is guaranteed to show the new description immediately.
D. Conflicting edits are automatically resolved according to business meaning.

Answer: A, B. Async propagation can support responsiveness and availability with temporary staleness. C denies that trade-off.

Remember: Region A publishes “blue”; B still displays “navy” for 3 seconds, then changes to “blue.”

Pro tip: Define conflict-resolution rules if more than one region can edit the same product concurrently.

### 10 · `7f636b7d-3059-4a6d-a1c2-c79be6cdd6cb`

Q: Under the standard SQL isolation-level names, which weakest level rules out dirty reads?

A. READ UNCOMMITTED
B. READ COMMITTED
C. REPEATABLE READ
D. SERIALIZABLE

Answer: B. READ COMMITTED does not expose another transaction's uncommitted writes. Stronger levels can also prevent dirty reads but are not the weakest standard level.

Remember: T1 changes 10 → 20 but has not committed. T2 at READ COMMITTED still reads 10; after T1 commits, a new T2 statement may read 20.

Pro tip: PostgreSQL treats READ UNCOMMITTED as READ COMMITTED in practice, so distinguish standard names from engine behavior.

### 11 · `24709cab-1027-4e4e-ba7d-a97edd54827e`

Q: After a profile update, one replica shows the new name and another shows the old name briefly; later they agree. What does this demonstrate?

A. Serial execution of all reads.
B. Guaranteed read-your-writes on every replica.
C. Eventual consistency across replicas.
D. A database deadlock.

Answer: C. Replicas converge after temporary disagreement. B would not allow the stale replica read described.

Remember: Name Ana → Anya; region A shows Anya now, region B shows Ana until it catches up.

Pro tip: Eventual convergence assumes replication succeeds and conflicts have a resolution policy.

### 12 · `5efb39e7-0fd9-4c1e-8911-4cbbd2f49e34` · Choose the incorrect statement

Q: A feed remains available during replica delays and may briefly show old posts. Which statement is incorrect?

A. A read can temporarily return an older post version.
B. Replicas can converge after communication resumes.
C. Availability can be favored for some operations during a partition.
D. Every replica must immediately return the same latest value during the partition.

Answer: D. The scenario permits stale reads, so immediate identical results are not guaranteed. A is expected behavior.

Remember: Replica A has version 2 while B still has version 1; D says this cannot happen, contradicting the example.

Pro tip: “Available” does not mean “fresh”; interview answers should name both properties separately.

### 13 · `211c31da-3b2f-4ffe-838f-b4d5b7da18bb`

Q: A transaction changes an order to PAID, then fails to insert its payment record. The whole transaction rolls back. Which ACID property is illustrated?

A. Durability
B. Atomicity
C. Isolation
D. Replication

Answer: B. Atomicity means the business action's writes commit together or not at all. Durability concerns writes after commit.

Remember: Status NEW plus no payment becomes PAID plus payment, or remains NEW plus no payment—never PAID with no payment.

Pro tip: Keep all database writes for one invariant in the same transaction when they share a transactional database.

### 14 · `6ab1a01b-3ee3-43ec-ad06-ee3cdc839e46`

Q: T1 holds row A and waits for row B; T2 holds B and waits for A. What has occurred?

A. Dirty read
B. Lost update
C. Deadlock
D. Phantom read

Answer: C. Each transaction waits for a lock held by the other, so neither can proceed without intervention.

Remember: T1 has A → wants B; T2 has B → wants A. The wait arrows form a cycle.

Pro tip: Acquire shared resources in a consistent order and be prepared to retry the transaction chosen as the deadlock victim.

### 15 · `6c181ebe-dc82-47b4-9e96-7f10a4990248`

Q: Within T1, a row reads balance 1000. T2 commits a change to 800. T1 reads the same row again and sees 800. Which anomaly is this?

A. Dirty read
B. Non-repeatable read
C. Deadlock
D. Write skew

Answer: B. A repeated read of the same row changes because another transaction committed between reads. It is not dirty because the update committed.

Remember: T1 reads 1000, T2 commits 800, T1 reads 800.

Pro tip: In PostgreSQL READ COMMITTED, separate statements can see different committed snapshots.

### 16 · `0fc23709-5ef4-43b0-904e-df238947cacc`

Q: T1 changes a row to 800 but has not committed. T2 reads 800. T1 then rolls back. What did T2 do?

A. Read uncommitted data (dirty read).
B. Read a committed new version.
C. Encounter a deadlock.
D. See a phantom row.

Answer: A. T2 observed data that never became committed. B is impossible after the stated rollback.

Remember: Database value starts 1000; T1 writes 800 then rolls back; T2 briefly saw 800 anyway.

Pro tip: PostgreSQL's ordinary READ COMMITTED queries do not permit this scenario; treat it as a general isolation anomaly.

### 17 · `c72ea00e-3388-44f6-8fcc-e141b33ff3d6` · Choose the incorrect statement

Q: Which statement about partition tolerance in a replicated service is incorrect?

A. A partition can prevent two groups of nodes from exchanging messages.
B. The service needs a policy for requests arriving while groups are disconnected.
C. Partition tolerance alone guarantees every read returns the latest value immediately.
D. A service may trade some write availability for stronger agreement during a partition.

Answer: C. Tolerating a communication failure does not automatically give fresh reads. D is one possible policy.

Remember: If A cannot reach B, A cannot know B's latest write without an additional coordination guarantee.

Pro tip: Avoid the shorthand “pick any two”; discuss the specific operation during a network partition.

### 18 · `cce4ff55-ba17-40b2-852e-d2b44bf4b4f1` · Choose the incorrect statement

Q: Which statement misstates the CAP trade-off for a replicated service during a network partition?

A. The service can choose to reject requests it cannot answer consistently.
B. The service can answer some requests while accepting temporary disagreement.
C. A partition makes communication between some nodes fail or stall.
D. Every operation can always retain linearizable consistency and full availability despite the partition.

Answer: D. Under the CAP model, a partition prevents the service from guaranteeing both properties for every operation. A and B describe alternative policies.

Remember: Two disconnected regions both accept conflicting writes: they stayed available, but cannot both promise one immediate agreed value.

Pro tip: CAP is about partitions and distributed operations; do not confuse it with ACID transaction consistency.

## Middle

### 19 · `fec72830-039b-4be9-94b1-da3e1d890672`

Q: A transfer updates an account balance and inserts a ledger record. Why put both writes in one database transaction?

A. It makes the ledger record visible before the balance update.
B. It guarantees replicas in every region are current.
C. It commits both writes or rolls both back.
D. It removes the need for balance rules.

Answer: C. A single transaction prevents a committed balance without its ledger record. B is a replication guarantee, not a transaction guarantee.

Remember: A=500 and no ledger record becomes A=400 with a -100 ledger entry, or stays unchanged after failure.

Pro tip: If the ledger and balance are in different services, a single local database transaction cannot atomically cover both.

### 20 · `92fd2796-7e1d-4066-8676-f4d604b861cf` · Select two

Q: A transfer debits one account and credits another, while a rule forbids negative balances. Which two ACID concerns are central?

A. Atomicity keeps debit and credit together.
B. Consistency requires the committed result to satisfy the balance rule.
C. Durability allows a committed debit to vanish after a crash.
D. Isolation means all transfers must run on one client computer.

Answer: A, B. The two changes must be all-or-nothing, and the invariant must hold at commit. D does not describe isolation.

Remember: A has 50, B has 20, and transfer is 100. The transaction must not commit A=-50 or credit B without debit.

Pro tip: Use a conditional debit or constraint so concurrent transactions cannot both pass a stale balance check.

### 21 · `89b554ea-ca9e-4531-aa41-e38615db912e`

Q: A server crashes after debiting one account but before crediting another. On recovery, neither change remains. Which property explains this?

A. Atomicity
B. Durability
C. Eventual consistency
D. Partition tolerance

Answer: A. The partial action was not committed, so it rolled back as a unit. Durability protects completed commits instead.

Remember: A=1000, B=1000; a 500 transfer crashes halfway. After rollback, both remain 1000.

Pro tip: Distinguish a crash before commit from one after commit; they test atomicity and durability differently.

### 22 · `d1c31a55-3280-4026-b68b-e9bf18714396` · Select two

Q: A loan payment updates balance, inserts a payment-history row, and may mark the loan CLOSED. Why use one transaction?

A. These writes represent one business action that should succeed or fail together.
B. It prevents a CLOSED loan from lacking its successful payment record.
C. It guarantees all read replicas update at the same instant.
D. It makes every individual write irreversible before commit.

Answer: A, B. Both address a consistent committed state. C exceeds what one local transaction promises.

Remember: Paying the last 20 changes balance 20 → 0, adds a payment row, and marks CLOSED together.

Pro tip: Make the closing rule conditional on the new balance and enforce it inside the transaction.

### 23 · `a173a470-647d-453c-92dd-aa0bab61cd3e`

Q: A payment commits successfully, then the database server crashes. After restart, the committed payment still exists. Which ACID property is shown?

A. Isolation
B. Atomicity
C. Durability
D. Read-your-writes

Answer: C. Durability means a successful commit survives the crash according to the database's configured guarantees.

Remember: Payment P1 is committed at 10:00; after restart at 10:02, P1 is still stored.

Pro tip: Check acknowledgment and storage configuration; an asynchronous replica may lag even when the primary commit is durable.

### 24 · `eaf43bf2-1086-4dd1-bf7a-e99932e3a7c9`

Q: Two buyers try to reserve the last 10 units of stock at once. Which mechanism directly helps prevent both from claiming the same units?

A. A final ORDER BY on reservations.
B. A plain read with no write condition.
C. A scheduled daily reconciliation only.
D. A lock or atomic conditional update on the stock row.

Answer: D. Coordinating the shared stock row lets one update win or causes the other to wait/recheck. A only sorts output.

Remember: Stock=10; two buyers each ask for 10. One reservation reduces stock to 0; the second must fail or retry.

Pro tip: Use a predicate such as `WHERE quantity >= 10` in an atomic update and check whether a row was updated.

### 25 · `7e9c5808-8701-45e3-982a-267edfb3776b` · Select two

Q: A client retries a payment after a timeout, but the first attempt may have committed. Which two controls help avoid duplicate charges and partial local records?

A. Use a unique idempotency key for the business payment request.
B. Apply related local database writes in one transaction.
C. Create a new payment ID on every retry and charge again.
D. Assume a timeout proves the first attempt rolled back.

Answer: A, B. A stable key identifies a retry of the same request; a transaction keeps local changes together. D confuses unknown outcome with failure.

Remember: Request K times out after charging 50. A retry with K finds the prior result rather than charging another 50.

Pro tip: A database transaction alone cannot roll back an already completed external card charge; coordinate with the payment provider's idempotency contract.

### 26 · `f95cd0f6-f8e0-4a97-89a7-3b242af9b5b2`

Q: Two withdrawals each read balance 1000 and try to take 800 and 700. What ACID property addresses interference between these concurrent transactions?

A. Atomicity
B. Durability
C. Isolation
D. Eventual consistency

Answer: C. Isolation and appropriate concurrency control prevent both transactions from committing based on an unsafe shared view. Atomicity alone only makes each individual withdrawal all-or-nothing.

Remember: If the 800 withdrawal commits first, the second must see/recheck that only 200 remains and reject 700.

Pro tip: The chosen isolation level and update pattern matter; a plain read-then-write at READ COMMITTED may still need locking or a conditional update.

## Six new practical questions

### 27 · `sql_tx_20260928_01`

Q: A batch processes 100 files in one transaction. File 37 is invalid, but the team wants to keep work from files 1–36 and continue. What PostgreSQL feature supports this within the open transaction?

A. Roll back the whole transaction and replay files 1–36 before file 38.
B. Create a SAVEPOINT before each file and ROLLBACK TO the failed file's savepoint.
C. Create the savepoint only after file 37 has failed.
D. COMMIT files 1–36 and start a new transaction for file 38.

Answer: B. A savepoint allows a partial rollback inside a still-open transaction. It does not commit earlier work by itself.

Remember: Files 1–36 are staged; file 37 fails. Roll back to the file-37 savepoint, then process file 38 before final COMMIT.

Pro tip: Use a clear policy for logging skipped files; an external API side effect cannot be rolled back by a database savepoint.

### 28 · `sql_tx_20260928_02`

Q: Several PostgreSQL workers claim pending jobs from one table. Worker A has locked job J1; Worker B should claim another job without waiting for J1. Which pattern fits?

A. Read a pending job without a lock, then update it later.
B. Use `SELECT ... FOR UPDATE` and wait for J1 to unlock.
C. Use `SELECT ... FOR UPDATE SKIP LOCKED` inside the claim transaction.
D. Use `SELECT ... FOR UPDATE NOWAIT` and treat an error as a claimed job.

Answer: C. SKIP LOCKED lets B bypass J1 and claim another unlocked job. A can let two workers select the same job.

Remember: A locks J1; B skips J1 and locks J2, so both can work on different jobs.

Pro tip: SKIP LOCKED is useful for queue-like work, not a general way to obtain a consistent report of all pending jobs.

### 29 · `sql_tx_20260928_03`

Q: A worker writes an order to PostgreSQL and must publish an event. A crash can happen between the database commit and the message send. Which pattern reduces lost events?

A. Publish the event first, then commit the order separately.
B. Store an outbox event with the order in one transaction, then publish it asynchronously.
C. Commit the order first, then publish directly with no durable retry record.
D. Store the order and outbox event in separate database transactions.

Answer: B. The order and publish intent commit together; a worker can retry delivering the outbox row after a crash.

Remember: Order O1 and outbox event E1 commit together. If the publisher crashes, E1 remains for retry.

Pro tip: Consumers still need idempotency because an outbox publisher can send the same event more than once.

### 30 · `sql_tx_20260928_04`

Q: A PostgreSQL transaction at READ COMMITTED counts open tickets twice. Another transaction commits a new open ticket between the counts, so the second count is larger. What changed?

A. A dirty read exposed an uncommitted ticket.
B. A newly matching row appeared between statement snapshots.
C. A lost update overwrote the first count.
D. The first transaction changed the same ticket row twice.

Answer: B. The second statement sees a later committed snapshot; a new matching row changes the predicate result. This is a phantom-style change.

Remember: First count=4. Another user commits one open ticket. Second count=5.

Pro tip: If a decision requires a stable set of rows, choose a suitable isolation/concurrency strategy instead of assuming repeated READ COMMITTED queries match.

### 31 · `sql_tx_20260928_05`

Q: An API retries an inventory reservation with the same request ID after a timeout. What database constraint best supports one successful reservation per request?

A. A unique constraint on the stable request ID.
B. A unique constraint on product ID for all reservations.
C. A CHECK constraint requiring requested quantity to be positive.
D. A foreign key from request ID to a request-log table without uniqueness.

Answer: A. A stable unique key lets retries recognize the same business action and prevents two reservation rows for that request.

Remember: Request R7 is sent twice; both attempts target the same unique R7, leaving one reservation.

Pro tip: Pair the unique key with an atomic stock update; deduplicating requests alone does not prevent overselling across different requests.

### 32 · `sql_tx_20260928_06`

Q: A long-running report begins a transaction and leaves it open while a user reviews a page. Why is this risky in PostgreSQL?

A. READ COMMITTED guarantees all locks and snapshots are released while the transaction is idle.
B. Open transactions can retain old row versions and hold locks, increasing bloat or blocking work.
C. The transaction makes all concurrent reads wait until the user closes the page.
D. The transaction automatically retries every statement while idle.

Answer: B. Long-lived transactions can delay cleanup and keep locks longer than needed. The report should not hold a transaction open during user think time.

Remember: A page stays open for an hour; an old snapshot may force the database to retain row versions from that hour.

Pro tip: Set appropriate idle-in-transaction timeouts and keep transactional work short.
