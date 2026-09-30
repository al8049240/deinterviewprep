"""Build the reviewed aggregation deduplication migration from the user's export."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\lethi\.codex\attachments\5a79725b-82e8-456c-b196-0f6938a51deb\Pasted text.txt")
TARGET = ROOT / "supabase/migrations/20260928130000_deduplicate_sql_aggregation.sql"

all_questions = json.loads(SOURCE.read_text(encoding="utf-8"))
assert len(all_questions) == 36
assert len({q["question_id"] for q in all_questions}) == 36
assert all(len(q["answers"]) == (4 if q["type"] == "mcq" else 5) for q in all_questions)
assert all(sum(a["is_correct"] for a in q["answers"]) == (1 if q["type"] == "mcq" else 3) for q in all_questions)
assert len({a["option_id"] for q in all_questions for a in q["answers"]}) == 149

# Question numbers in the supplied 36-row export; each reason points to the
# retained question that tests the same core idea more fully.
REMOVED = {
    7: "COUNT function alone repeats grouped COUNT in 6",
    11: "running SUM repeats the more precise year-to-date window in 30",
    12: "ROW_NUMBER deduplication repeats 10 and 28",
    15: "AVG function alone repeats category AVG in 14",
    17: "HAVING concept repeats applied HAVING in 4 and 18",
    20: "SUM function alone repeats grouped SUM in 19",
    21: "latest customer ROW_NUMBER deduplication repeats 28",
    33: "composite deduplication key repeats 10",
    34: "latest transaction ROW_NUMBER deduplication repeats 28",
    35: "deterministic ROW_NUMBER tie-breaker repeats 13",
    36: "latest order ROW_NUMBER deduplication repeats 28",
}
removed = [(all_questions[number - 1]["question_id"], reason) for number, reason in REMOVED.items()]
survivors = [q for number, q in enumerate(all_questions, 1) if number not in REMOVED]
assert len(removed) == 11 and len(survivors) == 25
assert sum(q["type"] == "mcq" for q in survivors) == 22
assert sum(q["type"] == "mcma" for q in survivors) == 3
payload = json.dumps(survivors, ensure_ascii=False, indent=2)
assert "$agg_export$" not in payload
removed_values = ",\n".join(
    "  ('" + qid + "', '" + reason.replace("'", "''") + "')"
    for qid, reason in removed
)

sql = """-- Deduplicate the supplied 36 SQL / Aggregation questions: retain 25, delete 11.
-- The eight separately added sql_agg_join_20260928_* questions are untouched.
-- Preserve survivor wording/options exactly as supplied; remove only explicit duplicate IDs.
-- Historical quiz_user_answers remain, but deleted questions will no longer have quiz-table text.
-- All changes are transactional and safe to rerun.
BEGIN;

CREATE TEMP TABLE agg_removed_ids (
  question_id text PRIMARY KEY, duplicate_reason text NOT NULL
) ON COMMIT DROP;
INSERT INTO agg_removed_ids VALUES
""" + removed_values + ";\n\n" + """CREATE TEMP TABLE agg_export_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO agg_export_payload VALUES ($agg_export$
""" + payload + """
$agg_export$::jsonb);

CREATE TEMP TABLE agg_survivor_questions ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id,
       q->>'difficulty' AS difficulty,
       q->>'type' AS type,
       q->>'question' AS question,
       q->>'explaination' AS explaination,
       q->>'interview_note' AS interview_note,
       q->>'pro_tips' AS pro_tips
FROM agg_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q;

CREATE TEMP TABLE agg_survivor_answers ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id,
       a.answer->>'option_id' AS option_id,
       a.answer->>'option_text' AS option_text,
       (a.answer->>'is_correct')::boolean AS is_correct,
       a.position::integer AS position
FROM agg_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q
CROSS JOIN LATERAL jsonb_array_elements(q->'answers') WITH ORDINALITY AS a(answer, position);

DO $preflight$
DECLARE v_topic bigint; v_subtopic bigint; v_old_count integer; v_old_option_count integer;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name = 'SQL';
  SELECT id INTO v_subtopic FROM de_mobile_app."subtopics-legacy"
    WHERE topic_id = v_topic AND name = 'Aggregation';
  IF v_topic IS NULL OR v_subtopic IS NULL THEN
    RAISE EXCEPTION 'SQL / Aggregation classification missing';
  END IF;
  IF (SELECT count(*) FROM agg_removed_ids) <> 11
     OR (SELECT count(*) FROM agg_survivor_questions) <> 25
     OR (SELECT count(DISTINCT question_id) FROM agg_survivor_questions) <> 25
     OR (SELECT count(*) FROM agg_survivor_answers) <> 103
     OR (SELECT count(DISTINCT option_id) FROM agg_survivor_answers) <> 103 THEN
    RAISE EXCEPTION 'Expected 11 duplicate IDs, 25 survivors and 103 options';
  END IF;
  IF EXISTS (
    SELECT 1 FROM agg_survivor_questions q
    JOIN agg_survivor_answers a ON a.question_id = q.question_id
    GROUP BY q.question_id, q.type
    HAVING count(*) <> CASE WHEN q.type = 'mcq' THEN 4 ELSE 5 END
       OR count(*) FILTER (WHERE a.is_correct) <> CASE WHEN q.type = 'mcq' THEN 1 ELSE 3 END
  ) THEN
    RAISE EXCEPTION 'Survivor option counts or correct flags are inconsistent';
  END IF;
  IF (SELECT count(*) FROM agg_survivor_questions e
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = e.question_id
      WHERE q.topic = v_topic AND q.sub_topics = v_subtopic) <> 25 THEN
    RAISE EXCEPTION 'One or more survivor IDs are not in SQL / Aggregation';
  END IF;
  IF (SELECT count(*) FROM agg_survivor_answers e
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = e.option_id
      WHERE a.question_id::text = e.question_id) <> 103 THEN
    RAISE EXCEPTION 'Survivor option IDs or question links differ from the export';
  END IF;
  IF EXISTS (
    SELECT 1 FROM agg_survivor_questions e
    JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = e.question_id
    GROUP BY e.question_id, e.type
    HAVING count(*) <> CASE WHEN e.type = 'mcq' THEN 4 ELSE 5 END
  ) THEN
    RAISE EXCEPTION 'A survivor has extra or missing database options';
  END IF;
  SELECT count(*) INTO v_old_count FROM agg_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id;
  SELECT count(*) INTO v_old_option_count FROM agg_removed_ids r
    JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id;
  IF v_old_count NOT IN (0, 11) OR v_old_option_count NOT IN (0, 46) THEN
    RAISE EXCEPTION 'Only part of the duplicate set exists; inspect before deleting';
  END IF;
  IF EXISTS (
    SELECT 1 FROM agg_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A duplicate ID belongs to another topic/subtopic';
  END IF;
END
$preflight$;

DELETE FROM de_mobile_app."quiz-answer" a
WHERE a.question_id::text IN (SELECT question_id FROM agg_removed_ids);

DELETE FROM de_mobile_app."quiz-question" q
WHERE q.question_id::text IN (SELECT question_id FROM agg_removed_ids);

UPDATE de_mobile_app."quiz-question" q
SET difficulty = e.difficulty,
    type = e.type,
    question = e.question,
    explaination = e.explaination,
    interview_note = e.interview_note,
    interview_tips = e.interview_note,
    pro_tips = e.pro_tips
FROM agg_survivor_questions e
WHERE q.question_id::text = e.question_id;

UPDATE de_mobile_app."quiz-answer" a
SET option_text = e.option_text,
    is_correct = e.is_correct,
    "order" = e.position
FROM agg_survivor_answers e
WHERE a.option_id::text = e.option_id AND a.question_id::text = e.question_id;

DO $postcheck$
BEGIN
  IF (SELECT count(*) FROM agg_survivor_questions e
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = e.question_id
      WHERE q.question = e.question AND q.explaination = e.explaination
        AND q.interview_note = e.interview_note AND q.pro_tips = e.pro_tips
        AND q.type = e.type AND q.difficulty = e.difficulty) <> 25 THEN
    RAISE EXCEPTION 'Survivor question verification failed';
  END IF;
  IF (SELECT count(*) FROM agg_survivor_answers e
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = e.option_id
      WHERE a.question_id::text = e.question_id AND a.option_text = e.option_text
        AND a.is_correct = e.is_correct AND a."order" = e.position) <> 103 THEN
    RAISE EXCEPTION 'Survivor option verification failed';
  END IF;
  IF EXISTS (SELECT 1 FROM agg_removed_ids r
             JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id)
     OR EXISTS (SELECT 1 FROM agg_removed_ids r
                JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id) THEN
    RAISE EXCEPTION 'Duplicate deletion verification failed';
  END IF;
END
$postcheck$;

COMMIT;
"""

TARGET.write_text(sql, encoding="utf-8")
print(f"Wrote {TARGET}: 25 survivors, 103 options, 11 deletions")
