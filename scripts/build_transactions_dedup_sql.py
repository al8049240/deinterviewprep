"""Build the scoped, rerunnable SQL Transactions review migration."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\lethi\.codex\attachments\0bd292c3-15c0-43a8-b82e-49936be5da74\Pasted text.txt")
OUT = ROOT / "supabase/migrations/20260928170000_review_sql_transactions_and_gaps.sql"
rows = json.loads(SOURCE.read_text(encoding="utf-8"))
assert len(rows) == 26
removed = {3: "CAP business choice repeats 7 and 9", 4: "balance-versus-counter example repeats 1 and 9",
           8: "partitioned balance service repeats 7", 11: "replica convergence repeats 5",
           12: "stale feed repeats 5 and 9", 17: "partition tolerance repeats 7",
           18: "CAP partition trade-off repeats 7", 20: "ACID transfer repeats 2",
           21: "partial transfer rollback repeats 13", 22: "multiwrite transaction repeats 19"}
keep = [x for i, x in enumerate(rows, 1) if i not in removed]
assert len(keep) == 16
def lit(s): return "'" + s.replace("'", "''") + "'"
removed_values = ",\n".join(f"  ({lit(rows[i-1]['question_id'])}, {lit(reason)})" for i, reason in removed.items())
retained_values = []
for r in keep:
    note = r["interview_note"].removeprefix("Common Interview Mistake: ").strip()
    if not note.startswith("Don't ") and r["question_id"] == "0fc23709-5ef4-43b0-904e-df238947cacc":
        note = "Don't call a read dirty after the other transaction has committed; dirty means the observed write was uncommitted."
    assert note.startswith("Don't "), (r["question_id"], note)
    level = {"junior":"easy", "middle":"medium", "senior":"hard", "leader":"hard"}[r["difficulty"]]
    retained_values.append(f"  ({lit(r['question_id'])}, {lit(level)}, {lit(note)})")
retained_sql = ",\n".join(retained_values)
old_answer_count = sum(len(rows[i-1]["answers"]) for i in removed)
prior = [
 ("medium", "Don't treat SAVEPOINT as a commit; work before it still rolls back if the outer transaction aborts."),
 ("medium", "Don't use SKIP LOCKED for a complete, consistent report; it deliberately skips locked rows."),
 ("hard", "Don't assume an outbox gives exactly-once delivery; make consumers idempotent."),
 ("medium", "Don't call a new committed matching row a dirty read; it is a phantom-style change."),
 ("medium", "Don't rely on a request ID in application code alone; enforce uniqueness in the database."),
 ("hard", "Don't leave a transaction open while waiting for a user; old snapshots and locks can hurt other work."),
]
prior_values = ",\n".join(f"  ('sql_tx_20260928_{i:02d}', {lit(level)}, {lit(note)})" for i,(level,note) in enumerate(prior,1))
new = [
 {"id":"sql_tx_gap_20260928_01", "level":"hard", "type":"mcq",
  "question":"Two on-call engineers each see that the other is available. Both then mark themselves off duty in separate transactions, leaving nobody on call. Which concurrency anomaly best describes this?",
  "explaination":"Write skew occurs when concurrent transactions read overlapping conditions but update different rows, so both can commit a result that violates a cross-row rule. A direct lost update would overwrite the same row; a dirty read would observe uncommitted data; a deadlock would involve waiting locks.",
  "interview_note":"Don't assume protecting each updated row separately protects a rule spanning several rows.",
  "pro_tips":"For an on-call roster, enforce the 'at least one person' rule using a suitable lock or SERIALIZABLE transaction, and retry serialization failures.",
  "answers":[("Write skew from concurrent decisions based on the same rule.",True),("A lost update because both transactions overwrote one identical row.",False),("A dirty read because each transaction saw uncommitted data.",False),("A deadlock because both transactions had to wait forever.",False)]},
 {"id":"sql_tx_gap_20260928_02", "level":"hard", "type":"mcq",
  "question":"PostgreSQL aborts a SERIALIZABLE checkout transaction with a serialization failure. What should the application retry?",
  "explaination":"Retry the complete transaction, including its reads and business decisions, using a fresh transaction. Retrying only the final UPDATE can reuse stale assumptions. Ignoring the failure loses the intended operation; changing to READ UNCOMMITTED is not a correct fix.",
  "interview_note":"Don't retry only the failed SQL statement after a serialization failure; the earlier reads may no longer be valid.",
  "pro_tips":"Keep checkout transactions short, make external effects idempotent, and use bounded whole-transaction retries with backoff.",
  "answers":[("Start a new transaction and rerun its reads, checks, and writes.",True),("Retry only the last UPDATE using values computed before the failure.",False),("Treat the aborted transaction as committed and acknowledge checkout.",False),("Switch to READ UNCOMMITTED for the failed statement.",False)]},
]
payload = []
for q in new:
    payload.append({**{k:v for k,v in q.items() if k!="answers"}, "answers":[{"id":q["id"]+"_"+chr(97+i),"text":t,"correct":c} for i,(t,c) in enumerate(q["answers"])]})
new_json = json.dumps(payload, ensure_ascii=False, indent=2)
sql = f"""-- Review 26 exported SQL / Transactions questions: retain 16, remove 10 overlapping items,
-- keep six prior practical additions, and add two missing concurrency concepts.
-- Original quiz_user_answers history is intentionally retained.
BEGIN;
CREATE TEMP TABLE tx_removed (question_id text PRIMARY KEY, reason text NOT NULL) ON COMMIT DROP;
INSERT INTO tx_removed VALUES
{removed_values};
CREATE TEMP TABLE tx_retained (question_id text PRIMARY KEY, difficulty text NOT NULL, interview_note text NOT NULL) ON COMMIT DROP;
INSERT INTO tx_retained VALUES
{retained_sql};
CREATE TEMP TABLE tx_prior (question_id text PRIMARY KEY, difficulty text NOT NULL, interview_note text NOT NULL) ON COMMIT DROP;
INSERT INTO tx_prior VALUES
{prior_values};
CREATE TEMP TABLE tx_new_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO tx_new_payload VALUES ($tx_payload${new_json}$tx_payload$::jsonb);
CREATE TEMP TABLE tx_new ON COMMIT DROP AS
SELECT x->>'id' AS question_id, x->>'level' AS difficulty, x->>'type' AS type,
       x->>'question' AS question, x->>'explaination' AS explaination,
       x->>'interview_note' AS interview_note, x->>'pro_tips' AS pro_tips
FROM tx_new_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x;
CREATE TEMP TABLE tx_new_answers ON COMMIT DROP AS
SELECT x->>'id' AS question_id, a.answer->>'id' AS option_id,
       a.answer->>'text' AS option_text, (a.answer->>'correct')::boolean AS is_correct,
       a.position::integer AS position
FROM tx_new_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x
CROSS JOIN LATERAL jsonb_array_elements(x->'answers') WITH ORDINALITY AS a(answer,position);
DO $preflight$
DECLARE v_topic bigint; v_subtopic bigint; v_removed integer; v_answers integer;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='SQL';
  SELECT id INTO v_subtopic FROM de_mobile_app."subtopics-legacy" WHERE topic_id=v_topic AND name='Transactions';
  IF v_topic IS NULL OR v_subtopic IS NULL THEN RAISE EXCEPTION 'SQL / Transactions classification missing'; END IF;
  IF (SELECT count(*) FROM tx_removed)<>10 OR (SELECT count(*) FROM tx_retained)<>16
     OR (SELECT count(*) FROM tx_prior)<>6 OR (SELECT count(*) FROM tx_new)<>2
     OR (SELECT count(*) FROM tx_new_answers)<>8 THEN RAISE EXCEPTION 'Transaction seed count differs'; END IF;
  IF (SELECT count(*) FROM tx_retained r JOIN de_mobile_app."quiz-question" q ON q.question_id::text=r.question_id
      WHERE q.topic=v_topic AND q.sub_topics=v_subtopic)<>16 THEN
    RAISE EXCEPTION 'Retained question missing or reclassified'; END IF;
  SELECT count(*) INTO v_removed FROM tx_removed r JOIN de_mobile_app."quiz-question" q ON q.question_id::text=r.question_id;
  SELECT count(*) INTO v_answers FROM tx_removed r JOIN de_mobile_app."quiz-answer" a ON a.question_id::text=r.question_id;
  IF NOT ((v_removed=10 AND v_answers={old_answer_count}) OR (v_removed=0 AND v_answers=0)) THEN
    RAISE EXCEPTION 'Only part of duplicate set exists'; END IF;
  IF EXISTS (SELECT 1 FROM tx_removed r JOIN de_mobile_app."quiz-question" q ON q.question_id::text=r.question_id
             WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic) THEN
    RAISE EXCEPTION 'Removal ID belongs to another classification'; END IF;
  IF (SELECT count(*) FROM tx_prior p JOIN de_mobile_app."quiz-question" q ON q.question_id::text=p.question_id) NOT IN (0,6) THEN
    RAISE EXCEPTION 'Only part of prior additions exists'; END IF;
  IF EXISTS (SELECT 1 FROM tx_prior p JOIN de_mobile_app."quiz-question" q ON q.question_id::text=p.question_id
             WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic) THEN
    RAISE EXCEPTION 'Prior addition belongs to another classification'; END IF;
  IF EXISTS (SELECT 1 FROM tx_new n JOIN de_mobile_app."quiz-question" q ON q.question_id::text=n.question_id
             WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic) THEN
    RAISE EXCEPTION 'New ID belongs to another classification'; END IF;
  IF EXISTS (SELECT 1 FROM tx_new_answers n JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=n.option_id
             WHERE a.question_id::text IS DISTINCT FROM n.question_id) THEN
    RAISE EXCEPTION 'New option ID belongs to another question'; END IF;
END $preflight$;
DELETE FROM de_mobile_app."quiz-answer" a WHERE a.question_id::text IN (SELECT question_id FROM tx_removed);
DELETE FROM de_mobile_app."quiz-question" q WHERE q.question_id::text IN (SELECT question_id FROM tx_removed);
UPDATE de_mobile_app."quiz-question" q
SET difficulty=r.difficulty, interview_note=r.interview_note, interview_tips=r.interview_note
FROM tx_retained r WHERE q.question_id::text=r.question_id;
UPDATE de_mobile_app."quiz-question" q
SET difficulty=p.difficulty, interview_note=p.interview_note, interview_tips=p.interview_note
FROM tx_prior p WHERE q.question_id::text=p.question_id;
INSERT INTO de_mobile_app."quiz-question"
  (question_id, topic, sub_topics, type, difficulty, question, explaination, interview_note, interview_tips, pro_tips)
SELECT n.question_id, t.id, st.id, n.type, n.difficulty, n.question, n.explaination,
       n.interview_note, n.interview_note, n.pro_tips
FROM tx_new n JOIN de_mobile_app."topics-legacy" t ON t.name='SQL'
JOIN de_mobile_app."subtopics-legacy" st ON st.topic_id=t.id AND st.name='Transactions'
WHERE true
ON CONFLICT (question_id) DO UPDATE SET type=EXCLUDED.type, difficulty=EXCLUDED.difficulty,
  question=EXCLUDED.question, explaination=EXCLUDED.explaination,
  interview_note=EXCLUDED.interview_note, interview_tips=EXCLUDED.interview_tips, pro_tips=EXCLUDED.pro_tips;
INSERT INTO de_mobile_app."quiz-answer" (option_id, question_id, option_text, is_correct, "order")
SELECT option_id, question_id, option_text, is_correct, position FROM tx_new_answers
ON CONFLICT (option_id) DO UPDATE SET option_text=EXCLUDED.option_text,
  is_correct=EXCLUDED.is_correct, "order"=EXCLUDED."order";
DO $postcheck$
BEGIN
  IF (SELECT count(*) FROM tx_new n JOIN de_mobile_app."quiz-question" q ON q.question_id::text=n.question_id
      WHERE q.question=n.question AND q.interview_note=n.interview_note AND q.difficulty=n.difficulty)<>2
     OR (SELECT count(*) FROM tx_new_answers n JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=n.option_id
         WHERE a.question_id::text=n.question_id AND a.option_text=n.option_text
           AND a.is_correct=n.is_correct AND a."order"=n.position)<>8 THEN
    RAISE EXCEPTION 'New transaction questions failed verification'; END IF;
  IF EXISTS (SELECT 1 FROM tx_removed r JOIN de_mobile_app."quiz-question" q ON q.question_id::text=r.question_id) THEN
    RAISE EXCEPTION 'Duplicate questions remain'; END IF;
END $postcheck$;
COMMIT;
"""
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: 16 retained, 10 removed, 2 added")
