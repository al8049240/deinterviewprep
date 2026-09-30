"""Turn the Joins export into a deduplicated Supabase update."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\lethi\.codex\attachments\48a34642-73af-4ccd-9b03-5b04b268d30e\Pasted text.txt")
TARGET = ROOT / "supabase/migrations/20260928120000_deduplicate_sql_joins.sql"

questions = json.loads(SOURCE.read_text(encoding="utf-8"))
assert len(questions) == 42
assert len({q["question_id"] for q in questions}) == 42
assert all(q["type"] == "mcq" and len(q["answers"]) == 4 for q in questions)
assert all(sum(a["is_correct"] for a in q["answers"]) == 1 for q in questions)
assert len({a["option_id"] for q in questions for a in q["answers"]}) == 168

# Remove questions that test the same core point as a clearer retained item.
# The numbers refer to the question order in the 42-row user export.
REMOVED = {
    2: "employee/manager self-join repeats 6 and 24",
    8: "left anti-join repeats 1",
    9: "left anti-join repeats 1",
    13: "inner-join matches repeat 5",
    15: "existence without duplicates repeats 33",
    17: "full reconciliation repeats 22 and 26",
    18: "full reconciliation repeats 22 and 26",
    19: "cross join repeats 4",
    21: "right join repeats 10",
    23: "inner-join matches repeat 5",
    27: "employee/manager self-join repeats 6 and 24",
    29: "point-in-time join repeats 28",
    31: "zero-count left join repeats 11",
    32: "left anti-join repeats 1",
    40: "join fan-out repeats 34",
}
removed = [(questions[number - 1]["question_id"], reason) for number, reason in REMOVED.items()]
assert len(removed) == 15 and len({question_id for question_id, _ in removed}) == 15
questions = [q for number, q in enumerate(questions, 1) if number not in REMOVED]
assert len(questions) == 27
payload = json.dumps(questions, ensure_ascii=False, indent=2)
assert "$joins_export$" not in payload
removed_values = ",\n".join(
    "  ('" + question_id + "', '" + reason.replace("'", "''") + "')"
    for question_id, reason in removed
)

sql = """-- Deduplicate the supplied 42 SQL / Joins questions: retain 27, delete 15.
-- Update surviving questions/options from the export without changing their wording.
-- Delete only the 15 explicit duplicate IDs and their quiz-answer options.
-- Historical quiz_user_answers remain, but their old question text will no longer be in quiz-question.
-- Validates IDs, classification, and option links before any persistent changes.
-- All changes are transactional and safe to rerun.
BEGIN;

CREATE TEMP TABLE joins_removed_ids (
  question_id text PRIMARY KEY, duplicate_reason text NOT NULL
) ON COMMIT DROP;
INSERT INTO joins_removed_ids VALUES
""" + removed_values + ";\n\n" + """CREATE TEMP TABLE joins_export_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO joins_export_payload VALUES ($joins_export$
""" + payload + """
$joins_export$::jsonb);

CREATE TEMP TABLE joins_export_questions ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id,
       q->>'difficulty' AS difficulty,
       q->>'type' AS type,
       q->>'question' AS question,
       q->>'explaination' AS explaination,
       q->>'interview_note' AS interview_note,
       q->>'pro_tips' AS pro_tips
FROM joins_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q;

CREATE TEMP TABLE joins_export_answers ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id,
       a.answer->>'option_id' AS option_id,
       a.answer->>'option_text' AS option_text,
       (a.answer->>'is_correct')::boolean AS is_correct,
       a.position::integer AS position
FROM joins_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q
CROSS JOIN LATERAL jsonb_array_elements(q->'answers') WITH ORDINALITY AS a(answer, position);

DO $preflight$
DECLARE v_topic bigint; v_subtopic bigint;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name = 'SQL';
  SELECT id INTO v_subtopic FROM de_mobile_app."subtopics-legacy"
    WHERE topic_id = v_topic AND name = 'Joins';
  IF v_topic IS NULL OR v_subtopic IS NULL THEN
    RAISE EXCEPTION 'SQL / Joins classification missing';
  END IF;
  IF (SELECT count(*) FROM joins_removed_ids) <> 15
     OR (SELECT count(*) FROM joins_export_questions) <> 27
     OR (SELECT count(DISTINCT question_id) FROM joins_export_questions) <> 27
     OR (SELECT count(*) FROM joins_export_answers) <> 108
     OR (SELECT count(DISTINCT option_id) FROM joins_export_answers) <> 108 THEN
    RAISE EXCEPTION 'Expected 15 duplicate IDs, 27 survivors, and 108 surviving options';
  END IF;
  IF EXISTS (
    SELECT 1 FROM joins_export_questions q
    JOIN joins_export_answers a ON a.question_id = q.question_id
    GROUP BY q.question_id
    HAVING count(*) <> 4 OR count(*) FILTER (WHERE a.is_correct) <> 1
  ) THEN
    RAISE EXCEPTION 'Every exported MCQ must have four options and one correct option';
  END IF;
  IF (SELECT count(*) FROM joins_export_questions e
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = e.question_id
      WHERE q.topic = v_topic AND q.sub_topics = v_subtopic) <> 27 THEN
    RAISE EXCEPTION 'One or more survivor question IDs are not in SQL / Joins';
  END IF;
  IF (SELECT count(*) FROM joins_export_answers e
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = e.option_id
      WHERE a.question_id::text = e.question_id) <> 108 THEN
    RAISE EXCEPTION 'One or more survivor option IDs or question links differ from the export';
  END IF;
  IF EXISTS (
    SELECT 1 FROM joins_export_questions e
    JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = e.question_id
    GROUP BY e.question_id
    HAVING count(*) <> 4
  ) THEN
    RAISE EXCEPTION 'A question has extra or missing database options';
  END IF;
  IF (SELECT count(*) FROM joins_removed_ids r
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id)
     NOT IN (0, 15) THEN
    RAISE EXCEPTION 'Only part of the duplicate set exists; inspect before deleting';
  END IF;
  IF EXISTS (
    SELECT 1 FROM joins_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A duplicate ID belongs to another topic/subtopic';
  END IF;
  IF (SELECT count(*) FROM joins_removed_ids r
      JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id)
     NOT IN (0, 60) THEN
    RAISE EXCEPTION 'Duplicate question options are incomplete or unexpected';
  END IF;
END
$preflight$;

DELETE FROM de_mobile_app."quiz-answer" a
WHERE a.question_id::text IN (SELECT question_id FROM joins_removed_ids);

DELETE FROM de_mobile_app."quiz-question" q
WHERE q.question_id::text IN (SELECT question_id FROM joins_removed_ids);

UPDATE de_mobile_app."quiz-question" q
SET difficulty = e.difficulty,
    type = e.type,
    question = e.question,
    explaination = e.explaination,
    interview_note = e.interview_note,
    interview_tips = e.interview_note,
    pro_tips = e.pro_tips
FROM joins_export_questions e
WHERE q.question_id::text = e.question_id;

UPDATE de_mobile_app."quiz-answer" a
SET option_text = e.option_text,
    is_correct = e.is_correct,
    "order" = e.position
FROM joins_export_answers e
WHERE a.option_id::text = e.option_id AND a.question_id::text = e.question_id;

DO $postcheck$
BEGIN
  IF (SELECT count(*) FROM joins_export_questions e
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = e.question_id
      WHERE q.question = e.question AND q.explaination = e.explaination
        AND q.interview_note = e.interview_note AND q.pro_tips = e.pro_tips
        AND q.type = e.type AND q.difficulty = e.difficulty) <> 27 THEN
    RAISE EXCEPTION 'Question update verification failed';
  END IF;
  IF (SELECT count(*) FROM joins_export_answers e
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = e.option_id
      WHERE a.question_id::text = e.question_id AND a.option_text = e.option_text
        AND a.is_correct = e.is_correct AND a."order" = e.position) <> 108 THEN
    RAISE EXCEPTION 'Option update verification failed';
  END IF;
  IF EXISTS (SELECT 1 FROM joins_removed_ids r
             JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id)
     OR EXISTS (SELECT 1 FROM joins_removed_ids r
                JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id) THEN
    RAISE EXCEPTION 'Duplicate deletion verification failed';
  END IF;
END
$postcheck$;

COMMIT;

-- Optional read-only check after running:
-- SELECT r.question_id, r.duplicate_reason FROM joins_removed_ids r; -- within transaction only
"""

TARGET.write_text(sql, encoding="utf-8")
print(f"Wrote {TARGET}: 27 questions, 108 options, 15 deletions")
