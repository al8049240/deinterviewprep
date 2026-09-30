"""Build the Query Optimization review migration from the user's export."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\lethi\.codex\attachments\9fd621d3-7e26-4531-bd33-408ee251b5ed\Pasted text.txt")
TARGET = ROOT / "supabase/migrations/20260928160000_review_query_optimization_and_gaps.sql"
original = json.loads(SOURCE.read_text(encoding="utf-8"))
assert len(original) == 50 and len({q["question_id"] for q in original}) == 50

# Number -> clearer retained question number or reason.
REMOVED = {
    2: "general projection/filter advice overlaps 3 and 5",
    4: "select needed columns repeats 5",
    6: "select needed columns repeats 5",
    7: "full-history partition scan repeats 35",
    8: "pruning percentage misconception repeats 32",
    9: "post-pruning bottleneck repeats 31 and 38",
    11: "partitioning is not a guarantee repeats 10 and 35",
    12: "filter misses partition column repeats 40",
    13: "OR and missing date filters repeat 44 and 40",
    14: "pruning on selective date repeats 1",
    16: "transformed partition predicate repeats 10 and 47",
    17: "implicit cast diagnosis repeats 48",
    18: "HAVING is an aggregation concept, not a distinct optimization test",
    19: "filter required month before aggregation repeats 1 and 20",
    22: "materialized repeated metric design repeats 21",
    23: "materialized repeated metric design repeats 21",
    26: "partition by date and cluster by ID repeats 28",
    29: "partition by date and cluster by ID repeats 28",
    30: "affected partition range repeats 39",
    33: "inspect plan before infrastructure changes repeats 3",
    36: "OR branch scans many partitions repeats 44",
    37: "transformed date predicate repeats 10 and 47",
    41: "partition key mismatches access pattern repeats 40",
    42: "implicit conversion repeats 48",
    43: "broad OR branch repeats 44",
    46: "transformed partition predicate repeats 10 and 47",
    50: "OR and implicit conversion repeat 45 and 48",
}
removed_ids = [(original[n - 1]["question_id"], reason) for n, reason in REMOVED.items()]
retained = [dict(q, mode="existing") for n, q in enumerate(original, 1) if n not in REMOVED]
assert len(removed_ids) == 27 and len(retained) == 23

for q in retained:
    note = q["interview_note"].strip().removeprefix("Common Interview Mistake: ").strip()
    if note.startswith("Avoid saying"):
        note = "Don't claim a particular expression always causes a full scan without checking the execution plan."
    assert note.startswith("Don't "), (q["question_id"], note)
    q["interview_note"] = note
    q["difficulty"] = {"junior": "easy", "middle": "medium", "senior": "hard", "leader": "hard"}.get(q["difficulty"], q["difficulty"])

NEW = [
    {
        "difficulty": "easy", "type": "mcq",
        "question": "A BigQuery analyst runs SELECT * FROM a large unclustered table LIMIT 100 only to inspect sample rows. Which change is more likely to reduce bytes read?",
        "explaination": "On an unclustered table, LIMIT on SELECT * does not by itself reduce bytes read. Selecting only needed columns or using a qualifying partition filter can reduce scanned data. Increasing LIMIT or sorting first does not solve unnecessary scanning.",
        "interview_note": "Don't assume LIMIT makes a SELECT * scan cheap; verify bytes processed.",
        "pro_tips": "Use the table preview for exploration; for real dashboard queries, select required columns and filter relevant partitions, then compare dry-run bytes.",
        "answers": [("Select only required columns and apply a qualifying partition filter where possible.", True), ("Increase LIMIT to 1000 so the scan stops sooner.", False), ("Add ORDER BY before LIMIT so BigQuery reads fewer columns.", False), ("Wrap SELECT * in a CTE while keeping the same scan.", False)],
    },
    {
        "difficulty": "hard", "type": "mcma",
        "question": "An aggregation over partition-pruned events is slow because one customer key dominates a shuffle stage. Which investigations are reasonable? Select all that apply.",
        "explaination": "A hot key can leave one task with disproportionate work even after scan pruning. Inspect key frequency and stage-level row distribution, then test a semantics-preserving strategy such as partial aggregation or treating the hot key separately. Final DISTINCT cannot undo the expensive shuffle, and blindly increasing partitions may leave the same hot key concentrated.",
        "interview_note": "Don't assume a pruned scan means balanced downstream work; inspect key skew and shuffle stages.",
        "pro_tips": "For clickstream metrics, compare the largest customer or anonymous-user bucket with typical keys before considering hot-key isolation or partial aggregation.",
        "answers": [("Check key frequencies and per-stage input distribution to confirm the hot key.", True), ("Test a semantics-preserving partial aggregation or separate hot-key path, then compare plans.", True), ("Add DISTINCT only to the final output and assume the shuffle cost disappears.", False), ("Increase the number of date partitions without checking key distribution.", False)],
    },
    {
        "difficulty": "medium", "type": "mcq",
        "question": "A report must retain every product, including products without completed sales. Where should a completed-sale filter be applied when LEFT JOINing sales to products?",
        "explaination": "Put the sale-status condition in the JOIN ON clause, or prefilter the sales input before the LEFT JOIN. Filtering right-side status in WHERE removes NULL-extended products with no completed sale. Changing to INNER JOIN also removes them; DISTINCT cannot restore missing products.",
        "interview_note": "Don't push a right-table filter into WHERE without checking whether unmatched left rows must remain.",
        "pro_tips": "When tuning a zero-sales product report, compare result row counts and zero-valued products before and after moving filters; faster SQL is not an improvement if it changes the answer.",
        "answers": [("In the JOIN ON condition, or in a filtered sales subquery before the LEFT JOIN.", True), ("In WHERE after the LEFT JOIN, because unmatched products have NULL status.", False), ("Replace the LEFT JOIN with INNER JOIN and filter in WHERE.", False), ("Add DISTINCT after applying the WHERE filter.", False)],
    },
    {
        "difficulty": "hard", "type": "mcma",
        "question": "A query uses WHERE sale_date in August OR channel = 'ONLINE'. You test two branches with UNION ALL to improve pruning. What must you do to preserve the original result rows? Select all that apply.",
        "explaination": "Rows meeting both predicates would appear twice with plain UNION ALL. Exclude the August-matching rows from the ONLINE branch using the logical negation of the first predicate (including correct NULL handling), then validate row counts and values against the original query. UNION DISTINCT can change duplicate-row semantics, and LIMIT only hides extra output.",
        "interview_note": "Don't rewrite OR as plain UNION ALL without handling rows that satisfy both branches.",
        "pro_tips": "For a sales dashboard, compare counts for August-only, ONLINE-only, and overlapping August-ONLINE rows before and after any branch rewrite.",
        "answers": [("Make the branches mutually exclusive, including the original predicate's NULL behavior.", True), ("Compare output rows and duplicate counts with the original OR query.", True), ("Use plain UNION ALL and assume an overlapping row is returned once.", False), ("Add LIMIT to the combined result to remove duplicates.", False)],
    },
]
for n, q in enumerate(NEW, 1):
    q["question_id"] = f"sql_opt_gap_20260928_{n:02d}"
    q["mode"] = "new"
    q["answers"] = [
        {"option_id": f"{q['question_id']}_{chr(97 + i)}", "option_text": text, "is_correct": correct}
        for i, (text, correct) in enumerate(q["answers"])
    ]
    assert q["interview_note"].startswith("Don't ")
    assert sum(a["is_correct"] for a in q["answers"]) == (1 if q["type"] == "mcq" else 2)

payload = json.dumps(retained + NEW, ensure_ascii=False, indent=2)
assert "$opt_export$" not in payload
removed_values = ",\n".join(
    f"  ('{qid}', '{reason.replace(chr(39), chr(39) * 2)}')" for qid, reason in removed_ids
)
prior_notes = [
    "Don't use DISTINCT to conceal join fan-out; check the join keys and intended grain first.",
    "Don't join hundreds of millions of raw rows when only a customer-level count is needed downstream.",
    "Don't replace exact distinct counts with an approximation when correctness requirements demand exact results.",
    "Don't add compute before checking shuffle spill, grouping cardinality, and hot keys.",
    "Don't credit a SQL rewrite for a cached second run; compare bytes, cache status, and representative executions.",
    "Don't force a join method before checking actual row counts, key duplication, and estimate quality.",
]
prior_values = ",\n".join(
    f"  ('sql_opt_20260928_{i:02d}', '{'medium' if i in (1, 2, 3, 5) else 'hard'}', '{note.replace(chr(39), chr(39) * 2)}')"
    for i, note in enumerate(prior_notes, 1)
)
answer_count = sum(len(q["answers"]) for q in retained + NEW)
retained_answer_count = sum(len(q["answers"]) for q in retained)
removed_answer_count = sum(len(original[n - 1]["answers"]) for n in REMOVED)

sql = """-- Query Optimization review: retain 23 of 50 supplied questions, remove 27 close repeats,
-- add four gaps, and normalize six earlier interview notes to "Don't ...".
-- Survivor wording and options come from the export; difficulties use easy/medium/hard.
-- Historical quiz_user_answers rows remain for deleted IDs.
BEGIN;

CREATE TEMP TABLE opt_removed_ids (question_id text PRIMARY KEY, reason text NOT NULL) ON COMMIT DROP;
INSERT INTO opt_removed_ids VALUES
""" + removed_values + ";\n\n" + """CREATE TEMP TABLE opt_prior_notes (
  question_id text PRIMARY KEY, difficulty text NOT NULL, interview_note text NOT NULL
) ON COMMIT DROP;
INSERT INTO opt_prior_notes VALUES
""" + prior_values + ";\n\n" + """CREATE TEMP TABLE opt_export_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO opt_export_payload VALUES ($opt_export$
""" + payload + """
$opt_export$::jsonb);

CREATE TEMP TABLE opt_seed_questions ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id, q->>'mode' AS mode,
       q->>'difficulty' AS difficulty, q->>'type' AS type,
       q->>'question' AS question, q->>'explaination' AS explaination,
       q->>'interview_note' AS interview_note, q->>'pro_tips' AS pro_tips
FROM opt_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q;

CREATE TEMP TABLE opt_seed_answers ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id, q->>'mode' AS mode,
       a.answer->>'option_id' AS option_id,
       a.answer->>'option_text' AS option_text,
       (a.answer->>'is_correct')::boolean AS is_correct,
       a.position::integer AS position
FROM opt_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q
CROSS JOIN LATERAL jsonb_array_elements(q->'answers') WITH ORDINALITY AS a(answer, position);

DO $preflight$
DECLARE v_topic bigint; v_subtopic bigint; v_old_count integer; v_old_options integer;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name = 'SQL';
  SELECT id INTO v_subtopic FROM de_mobile_app."subtopics-legacy"
    WHERE topic_id = v_topic AND name = 'Query Optimization';
  IF v_topic IS NULL OR v_subtopic IS NULL THEN
    RAISE EXCEPTION 'SQL / Query Optimization classification missing';
  END IF;
  IF (SELECT count(*) FROM opt_removed_ids) <> 27
     OR (SELECT count(*) FROM opt_prior_notes) <> 6
     OR (SELECT count(*) FROM opt_seed_questions WHERE mode = 'existing') <> 23
     OR (SELECT count(*) FROM opt_seed_questions WHERE mode = 'new') <> 4
     OR (SELECT count(DISTINCT question_id) FROM opt_seed_questions) <> 27
     OR (SELECT count(*) FROM opt_seed_answers) <> """ + str(answer_count) + """
     OR (SELECT count(DISTINCT option_id) FROM opt_seed_answers) <> """ + str(answer_count) + """ THEN
    RAISE EXCEPTION 'Question or option seed counts differ';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_seed_questions q
    JOIN opt_seed_answers a ON a.question_id = q.question_id
    GROUP BY q.question_id, q.type
    HAVING count(*) NOT IN (4, 5)
       OR count(*) FILTER (WHERE a.is_correct) NOT IN (1, 2, 3)
       OR (q.type = 'mcq' AND count(*) FILTER (WHERE a.is_correct) <> 1)
       OR (q.type = 'mcma' AND count(*) FILTER (WHERE a.is_correct) NOT IN (2, 3))
  ) THEN
    RAISE EXCEPTION 'Option counts or correctness flags are inconsistent';
  END IF;
  IF EXISTS (SELECT 1 FROM opt_seed_questions WHERE interview_note NOT LIKE 'Don''t %') THEN
    RAISE EXCEPTION 'An interview note does not begin with Don''t';
  END IF;
  IF (SELECT count(*) FROM opt_seed_questions s
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
      WHERE s.mode = 'existing' AND q.topic = v_topic AND q.sub_topics = v_subtopic) <> 23 THEN
    RAISE EXCEPTION 'A retained question is missing or reclassified';
  END IF;
  IF (SELECT count(*) FROM opt_seed_answers s
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
      WHERE s.mode = 'existing' AND a.question_id::text = s.question_id) <> """ + str(retained_answer_count) + """ THEN
    RAISE EXCEPTION 'Retained option IDs or links differ';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_seed_questions s
    JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = s.question_id
    WHERE s.mode = 'existing'
    GROUP BY s.question_id
    HAVING count(*) NOT IN (4, 5)
  ) THEN
    RAISE EXCEPTION 'A retained question has extra or missing options';
  END IF;
  SELECT count(*) INTO v_old_count FROM opt_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id;
  SELECT count(*) INTO v_old_options FROM opt_removed_ids r
    JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id;
  IF NOT ((v_old_count = 0 AND v_old_options = 0)
       OR (v_old_count = 27 AND v_old_options = """ + str(removed_answer_count) + """)) THEN
    RAISE EXCEPTION 'Only part of the duplicate set exists';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A removal ID belongs to another classification';
  END IF;
  IF (SELECT count(*) FROM opt_prior_notes n
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = n.question_id)
     NOT IN (0, 6) THEN
    RAISE EXCEPTION 'Only part of the previously added set exists';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_prior_notes n
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = n.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A previously added question belongs to another classification';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_seed_questions s
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
    WHERE s.mode = 'new' AND (q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic)
  ) THEN
    RAISE EXCEPTION 'A new question ID belongs to another classification';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_seed_answers s
    JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
    WHERE s.mode = 'new' AND a.question_id::text IS DISTINCT FROM s.question_id
  ) THEN
    RAISE EXCEPTION 'A new option ID belongs to another question';
  END IF;
END
$preflight$;

DELETE FROM de_mobile_app."quiz-answer" a
WHERE a.question_id::text IN (SELECT question_id FROM opt_removed_ids);
DELETE FROM de_mobile_app."quiz-question" q
WHERE q.question_id::text IN (SELECT question_id FROM opt_removed_ids);

UPDATE de_mobile_app."quiz-question" q
SET difficulty = s.difficulty, question = s.question,
    explaination = s.explaination, interview_note = s.interview_note,
    interview_tips = s.interview_note, pro_tips = s.pro_tips
FROM opt_seed_questions s
WHERE s.mode = 'existing' AND q.question_id::text = s.question_id;

UPDATE de_mobile_app."quiz-answer" a
SET option_text = s.option_text, is_correct = s.is_correct, "order" = s.position
FROM opt_seed_answers s
WHERE s.mode = 'existing' AND a.option_id::text = s.option_id
  AND a.question_id::text = s.question_id;

UPDATE de_mobile_app."quiz-question" q
SET difficulty = n.difficulty,
    interview_note = n.interview_note,
    interview_tips = n.interview_note
FROM opt_prior_notes n WHERE q.question_id::text = n.question_id;

INSERT INTO de_mobile_app."quiz-question"
  (question_id, topic, sub_topics, type, difficulty, question,
   explaination, interview_note, interview_tips, pro_tips)
SELECT s.question_id, t.id, st.id, s.type, s.difficulty, s.question,
       s.explaination, s.interview_note, s.interview_note, s.pro_tips
FROM opt_seed_questions s
JOIN de_mobile_app."topics-legacy" t ON t.name = 'SQL'
JOIN de_mobile_app."subtopics-legacy" st
  ON st.topic_id = t.id AND st.name = 'Query Optimization'
WHERE s.mode = 'new'
ON CONFLICT (question_id) DO UPDATE SET
  type = EXCLUDED.type, difficulty = EXCLUDED.difficulty,
  question = EXCLUDED.question, explaination = EXCLUDED.explaination,
  interview_note = EXCLUDED.interview_note,
  interview_tips = EXCLUDED.interview_tips, pro_tips = EXCLUDED.pro_tips;

INSERT INTO de_mobile_app."quiz-answer"
  (option_id, question_id, option_text, is_correct, "order")
SELECT s.option_id, s.question_id, s.option_text, s.is_correct, s.position
FROM opt_seed_answers s WHERE s.mode = 'new'
ON CONFLICT (option_id) DO UPDATE SET
  option_text = EXCLUDED.option_text, is_correct = EXCLUDED.is_correct,
  "order" = EXCLUDED."order";

DO $postcheck$
BEGIN
  IF (SELECT count(*) FROM opt_seed_questions s
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
      WHERE q.question = s.question AND q.difficulty = s.difficulty
        AND q.interview_note = s.interview_note AND q.pro_tips = s.pro_tips) <> 27 THEN
    RAISE EXCEPTION 'Question verification failed';
  END IF;
  IF (SELECT count(*) FROM opt_seed_answers s
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
      WHERE a.question_id::text = s.question_id AND a.option_text = s.option_text
        AND a.is_correct = s.is_correct AND a."order" = s.position) <> """ + str(answer_count) + """ THEN
    RAISE EXCEPTION 'Option verification failed';
  END IF;
  IF EXISTS (
    SELECT 1 FROM opt_prior_notes n
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = n.question_id
    WHERE q.difficulty IS DISTINCT FROM n.difficulty
       OR q.interview_note IS DISTINCT FROM n.interview_note
  ) THEN
    RAISE EXCEPTION 'Previous interview notes were not normalized';
  END IF;
  IF EXISTS (SELECT 1 FROM opt_removed_ids r
             JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id)
     OR EXISTS (SELECT 1 FROM opt_removed_ids r
                JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id) THEN
    RAISE EXCEPTION 'Duplicate removal verification failed';
  END IF;
END
$postcheck$;

COMMIT;
"""

TARGET.write_text(sql, encoding="utf-8")
print(f"Wrote {TARGET}: 23 retained, 27 removed, 4 new, {answer_count} options")
