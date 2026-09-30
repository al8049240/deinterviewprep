"""Build the reviewed, rerunnable Supabase seed from the 27-question Markdown draft."""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/sql_cte_view_function_27_mcq_mcma_review.md"
TARGET = ROOT / "supabase/migrations/20260928090000_seed_cvf_practical_mcq_mcma.sql"
OLD_MIGRATION = ROOT / "supabase/migrations/20260928080000_apply_sql_cte_view_function_review.sql"

# A short, specific reason for each wrong choice. Correct choices are explained
# by the answer paragraph in the draft.
WRONG = {
    1: {"B": "The CTE name ends with its first statement.", "C": "A subquery alias also ends with its statement.", "D": "A WITH clause cannot extend across a semicolon."},
    2: {"B": "Order 2 is open, so the CTE filters it out.", "D": "The name paid is scoped to this statement."},
    3: {"B": "A cross join does not define recursive steps.", "C": "Grouping and windows do not provide a recursive member.", "D": "A temporary table and index are not the recursive CTE structure."},
    4: {"C": "Sorting does not stop recursion.", "D": "Changing a name does not detect a cycle."},
    5: {"B": "A name prefix has no planner meaning.", "C": "A primary key does not decide CTE materialization.", "D": "Final ordering does not determine whether the CTE is evaluated once."},
    6: {"C": "MATERIALIZED is statement-scoped, not a permanent table.", "D": "Neither directive guarantees better performance."},
    7: {"B": "An inner join starting from sparse sales loses zero-sale dates.", "C": "Sorting cannot invent missing dates.", "D": "DISTINCT removes duplicates but cannot add missing dates."},
    8: {"C": "A CTE does not protect its rows from join fanout.", "D": "Sorting does not change duplicated totals."},
    9: {"B": "Joining all tag rows can duplicate the total.", "C": "A cross join multiplies rows even more.", "D": "Tag counts vary, so dividing by three is not a sound fix."},
    10: {"B": "A regular view is not refreshed like a materialized view.", "C": "Changing source rows does not invalidate this view.", "D": "The status update does not duplicate the row."},
    11: {"C": "A view definition does not revoke existing table grants.", "D": "A view does not encrypt the base table."},
    12: {"B": "A regular view still executes its query and needs measurement.", "C": "Ordering alone does not precompute the summary.", "D": "A CTE does not persist across dashboard requests."},
    13: {"C": "Materialized views do not require disabling permissions.", "D": "SELECT does not refresh a PostgreSQL materialized view."},
    14: {"B": "Ordering does not group rows by store.", "C": "LIMIT discards rows rather than producing each store total.", "D": "Changing the aggregate does not supply the missing grouping column."},
    15: {"C": "dbt SQL models run SQL in the data platform, not entirely in Python.", "D": "dbt supports multiple materializations, not only materialized views."},
    16: {"B": "A materialized view is not required for a simple view update.", "C": "An UPDATE changes data, not the saved view definition.", "D": "PostgreSQL supports automatically updatable simple views."},
    17: {"C": "Nesting alone does not prove a query is slow.", "D": "Views can still benefit from indexes on base tables."},
    18: {"B": "The new sale was committed after the last refresh.", "C": "The materialized view remains queryable.", "D": "ORDER BY does not refresh stored rows."},
    19: {"B": "Ordering cannot centralize a classification rule.", "C": "An index does not create the business labels by itself.", "D": "A CTE in another statement is not a shared rule."},
    20: {"C": "STRICT returns NULL for a NULL argument.", "D": "IMMUTABLE promises stable output; it does not authorize table changes."},
    21: {"B": "The date can differ on another day.", "C": "PARALLEL SAFE is not a volatility category.", "D": "STRICT controls NULL handling, not time dependence."},
    22: {"C": "Subtracting NULL yields NULL, not the gross amount.", "D": "STRICT skips the body and returns NULL when discount is NULL."},
    23: {"B": "PostgreSQL VOLATILE functions can have side effects.", "C": "Functions can accept input parameters.", "D": "IMMUTABLE functions must not modify tables."},
    24: {"C": "A scalar function does not universally disable indexes.", "D": "Inlining depends on function properties and the database engine."},
    25: {"B": "A regular view has no caller-supplied parameter list.", "C": "A materialized view is also not parameterized per call.", "D": "A column alias cannot accept arguments."},
    26: {"C": "The caller does not become a superuser.", "D": "An owner-privileged function is a security boundary that needs review."},
    27: {"B": "CREATE VIEW has no parameter declaration.", "C": "CREATE MATERIALIZED VIEW has no per-call parameter declaration.", "D": "A CTE is scoped to one statement, not all future statements."},
}


def sql_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


source = SOURCE.read_text(encoding="utf-8")
old_source = OLD_MIGRATION.read_text(encoding="utf-8")
old_ids = []
for marker, end_marker in (
    ("INSERT INTO cvf_review_questions VALUES", "CREATE TEMP TABLE cvf_review_answers"),
    ("INSERT INTO cvf_new VALUES", "DO $new_check$"),
):
    section = old_source.split(marker, 1)[1].split(end_marker, 1)[0]
    old_ids.extend(re.findall(r"(?m)^\s*\('([^']+)'", section))
assert len(old_ids) == 33 and len(set(old_ids)) == 33, "Expected 27 reviewed + 6 added old question IDs"
blocks = re.findall(r"(?ms)^### (\d+)\. \[(MCQ|MCMA)\] ([^\n]+)\n(.*?)(?=^### \d+\. |^## Editorial checks)", source)
assert len(blocks) == 27, f"Expected 27 questions; found {len(blocks)}"
question_rows = []
answer_rows = []
for number_text, kind, _title, body in blocks:
    number = int(number_text)
    option_matches = list(re.finditer(r"(?m)^([A-D])\. (.+?)(?:  )?$", body))
    assert len(option_matches) == 4, (number, len(option_matches))
    question = body[:option_matches[0].start()].strip()
    question = re.sub(r"^\*\*Question:\*\* ", "", question)
    question = question.replace("```sql\n", "").replace("```", "")
    question = re.sub(r"\*\*(.*?)\*\*", r"\1", question).strip()
    options = {m.group(1): m.group(2).strip().rstrip("  ") for m in option_matches}
    answer_match = re.search(r"\*\*Answers?: ([A-D](?:, [A-D])*)\.\*\* (.*?) \*\*pro_tips:\*\* (.+)", body, re.S)
    assert answer_match, number
    correct = set(answer_match.group(1).split(", "))
    assert len(correct) == (1 if kind == "MCQ" else 2), number
    explanation = answer_match.group(2).strip()
    explanation = re.sub(r"\s*\*\*Remember:\*\*.*", "", explanation)
    tips = answer_match.group(3).strip()
    wrong = WRONG[number]
    assert set(wrong) == set("ABCD") - correct, number
    explanation += "\n\nWhy other options are incorrect:\n" + "\n".join(
        f"{letter}. {wrong[letter]}" for letter in "ABCD" if letter in wrong
    )
    question_id = f"sql_cvf_practical_20260928_{number:02d}"
    category = "CTEs" if number <= 9 else "Views" if number <= 18 else "Functions"
    difficulty = "junior" if number in (1, 2, 3, 10, 11, 14, 19, 20, 21) else "senior" if number in (4, 5, 6, 8, 16, 17, 23, 24, 26) else "middle"
    question_rows.append(
        f"  ({sql_quote(question_id)}, {sql_quote(category)}, {sql_quote(kind.lower())}, {sql_quote(difficulty)}, "
        f"{sql_quote(question)}, {sql_quote(explanation)}, {sql_quote(tips)})"
    )
    for position, letter in enumerate("ABCD", 1):
        option_id = f"{question_id}_{letter.lower()}"
        answer_rows.append(
            f"  ({sql_quote(option_id)}, {sql_quote(question_id)}, {position}, {sql_quote(options[letter])}, "
            f"{'true' if letter in correct else 'false'})"
        )

sql = """-- Replace the prior 33 CTE / View / Function questions with 27 practical questions.
-- Deletes only IDs from the previous reviewed-set migration (27 existing + 6 added),
-- then inserts 15 MCQ and 12 MCMA questions and their options in one transaction.
-- Historical quiz_user_answers rows remain; they refer to deleted question IDs.
-- Rerunnable after successful replacement; fails if this subtopic contains unrecognized IDs.
-- Review the preflight checks and run in the Supabase SQL Editor. Transaction rolls back on failure.
BEGIN;

CREATE TEMP TABLE cvf_old_ids (question_id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO cvf_old_ids VALUES
""" + ",\n".join(f"  ({sql_quote(old_id)})" for old_id in old_ids) + ";\n\n" + """CREATE TEMP TABLE cvf_question_seed (
  question_id text PRIMARY KEY, category text NOT NULL, type text NOT NULL,
  difficulty text NOT NULL, question text NOT NULL,
  explaination text NOT NULL, pro_tips text NOT NULL
) ON COMMIT DROP;
INSERT INTO cvf_question_seed VALUES
""" + ",\n".join(question_rows) + ";\n\n" + """CREATE TEMP TABLE cvf_answer_seed (
  option_id text PRIMARY KEY, question_id text NOT NULL, position integer NOT NULL,
  option_text text NOT NULL, is_correct boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO cvf_answer_seed VALUES
""" + ",\n".join(answer_rows) + ";\n\n" + """DO $preflight$
DECLARE v_topic bigint; v_subtopic bigint;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name = 'SQL';
  SELECT id INTO v_subtopic FROM de_mobile_app."subtopics-legacy"
    WHERE topic_id = v_topic AND name = 'CTE & View & Function';
  IF v_topic IS NULL OR v_subtopic IS NULL THEN
    RAISE EXCEPTION 'SQL / CTE & View & Function classification missing';
  END IF;
  IF (SELECT count(*) FROM cvf_question_seed) <> 27
     OR (SELECT count(*) FROM cvf_answer_seed) <> 108
     OR (SELECT count(*) FROM cvf_old_ids) <> 33
     OR (SELECT count(*) FROM cvf_question_seed WHERE type = 'mcq') <> 15
     OR (SELECT count(*) FROM cvf_question_seed WHERE type = 'mcma') <> 12 THEN
    RAISE EXCEPTION 'Seed count mismatch';
  END IF;
  IF EXISTS (
    SELECT 1 FROM cvf_question_seed s
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A seed question ID belongs to another topic/subtopic';
  END IF;
  IF EXISTS (
    SELECT 1 FROM cvf_answer_seed s
    JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
    WHERE a.question_id::text IS DISTINCT FROM s.question_id
  ) THEN
    RAISE EXCEPTION 'A seed option ID belongs to another question';
  END IF;
  IF (SELECT count(*) FROM cvf_old_ids old
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = old.question_id)
     NOT IN (0, 33) THEN
    RAISE EXCEPTION 'Only part of the prior 33-question set exists; inspect before deleting';
  END IF;
  IF EXISTS (
    SELECT 1 FROM cvf_old_ids old
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = old.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A prior question ID belongs to another topic/subtopic';
  END IF;
  IF EXISTS (
    SELECT 1 FROM de_mobile_app."quiz-question" q
    WHERE q.topic = v_topic AND q.sub_topics = v_subtopic
      AND NOT EXISTS (SELECT 1 FROM cvf_old_ids old WHERE old.question_id = q.question_id::text)
      AND NOT EXISTS (SELECT 1 FROM cvf_question_seed s WHERE s.question_id = q.question_id::text)
  ) THEN
    RAISE EXCEPTION 'This subtopic has other question IDs; no deletion performed';
  END IF;
  IF EXISTS (
    SELECT 1 FROM cvf_question_seed q
    LEFT JOIN cvf_answer_seed a ON a.question_id = q.question_id
    GROUP BY q.question_id, q.type
    HAVING count(a.option_id) <> 4
       OR count(*) FILTER (WHERE a.is_correct) <> CASE WHEN q.type = 'mcq' THEN 1 ELSE 2 END
  ) THEN
    RAISE EXCEPTION 'Each MCQ needs one correct option; each MCMA needs two';
  END IF;
END
$preflight$;

-- Remove options first; old question rows only are then removed.
DELETE FROM de_mobile_app."quiz-answer" a
WHERE a.question_id::text IN (SELECT question_id FROM cvf_old_ids);

DELETE FROM de_mobile_app."quiz-question" q
WHERE q.question_id::text IN (SELECT question_id FROM cvf_old_ids);

INSERT INTO de_mobile_app."quiz-question"
  (question_id, topic, sub_topics, type, difficulty, question,
   explaination, interview_note, interview_tips, pro_tips)
SELECT s.question_id, t.id, st.id, s.type, s.difficulty, s.question,
       s.explaination, '', '', s.pro_tips
FROM cvf_question_seed s
JOIN de_mobile_app."topics-legacy" t ON t.name = 'SQL'
JOIN de_mobile_app."subtopics-legacy" st
  ON st.topic_id = t.id AND st.name = 'CTE & View & Function'
ON CONFLICT (question_id) DO UPDATE SET
  type = EXCLUDED.type,
  difficulty = EXCLUDED.difficulty,
  question = EXCLUDED.question,
  explaination = EXCLUDED.explaination,
  pro_tips = EXCLUDED.pro_tips;

INSERT INTO de_mobile_app."quiz-answer"
  (option_id, question_id, option_text, is_correct, "order")
SELECT option_id, question_id, option_text, is_correct, position
FROM cvf_answer_seed
ON CONFLICT (option_id) DO UPDATE SET
  option_text = EXCLUDED.option_text,
  is_correct = EXCLUDED.is_correct,
  "order" = EXCLUDED."order";

DO $verify$
BEGIN
  IF EXISTS (SELECT 1 FROM de_mobile_app."quiz-question" q
             JOIN cvf_old_ids old ON old.question_id = q.question_id::text) THEN
    RAISE EXCEPTION 'Old questions were not fully removed';
  END IF;
  IF EXISTS (SELECT 1 FROM de_mobile_app."quiz-answer" a
             JOIN cvf_old_ids old ON old.question_id = a.question_id::text) THEN
    RAISE EXCEPTION 'Old options were not fully removed';
  END IF;
  IF (SELECT count(*) FROM cvf_question_seed s
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
      WHERE q.type = s.type AND q.question = s.question AND q.explaination = s.explaination
        AND q.pro_tips = s.pro_tips) <> 27 THEN
    RAISE EXCEPTION 'Question verification failed';
  END IF;
  IF (SELECT count(*) FROM cvf_answer_seed s
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
      WHERE a.question_id::text = s.question_id AND a.option_text = s.option_text
        AND a.is_correct = s.is_correct AND a."order" = s.position) <> 108 THEN
    RAISE EXCEPTION 'Answer verification failed';
  END IF;
END
$verify$;

COMMIT;

-- Optional read-only verification after running:
-- SELECT q.type, count(*) FROM de_mobile_app."quiz-question" q
-- WHERE q.question_id::text LIKE 'sql_cvf_practical_20260928_%' GROUP BY q.type;
"""
TARGET.write_text(sql, encoding="utf-8")
print(f"Wrote {TARGET}: {len(question_rows)} questions, {len(answer_rows)} options")
