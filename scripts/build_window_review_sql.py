"""Build the Window Functions review migration from the user's export."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\lethi\.codex\attachments\2733114a-d892-4365-88c3-7bc828f7d0dd\Pasted text.txt")
TARGET = ROOT / "supabase/migrations/20260928150000_review_window_functions_and_gaps.sql"

original = json.loads(SOURCE.read_text(encoding="utf-8"))
assert len(original) == 19 and len({q["question_id"] for q in original}) == 19

REMOVED = {
    4: "top-one ROW_NUMBER repeats 17",
    5: "timestamp tie ordering repeats 7",
    6: "latest-record ROW_NUMBER repeats 7",
    10: "latest-per-customer ROW_NUMBER repeats 7",
    12: "RANK with skipped positions repeats 3",
    13: "LAG previous value repeats 1",
    16: "latest-status ROW_NUMBER repeats 7",
}
removed_ids = [original[number - 1]["question_id"] for number in REMOVED]
retained = [dict(q, mode="existing") for number, q in enumerate(original, 1) if number not in REMOVED]
assert len(retained) == 12

for q in retained:
    note = q["interview_note"].removeprefix("Common Interview Mistake: ").strip()
    assert note.startswith("Don't "), q["question_id"]
    q["interview_note"] = note
    q["difficulty"] = {"junior": "easy", "middle": "medium", "senior": "hard", "leader": "hard"}.get(
        q["difficulty"], q["difficulty"]
    )
    if q["question_id"] == original[7]["question_id"]:
        q["pro_tips"] += " This ROWS frame covers seven recorded rows; fill missing dates first if the requirement means seven calendar days."

NEW = [
    {
        "difficulty": "easy", "type": "mcq",
        "question": "Employees tied on revenue should share a rank, and the next rank should not skip a number. Which function fits?",
        "explaination": "DENSE_RANK gives ties the same rank without gaps. RANK leaves gaps after ties; ROW_NUMBER assigns a unique position; NTILE distributes rows into buckets. Example: revenues 100, 100, 80 receive dense ranks 1, 1, 2.",
        "interview_note": "Don't confuse DENSE_RANK with RANK; state whether ties should create gaps.",
        "pro_tips": "For a sales leaderboard, agree whether tied employees should both appear as rank 1 and whether the next employee should be rank 2 or 3.",
        "answers": [("RANK()", False), ("DENSE_RANK()", True), ("ROW_NUMBER()", False), ("NTILE(4)", False)],
    },
    {
        "difficulty": "medium", "type": "mcq",
        "question": "In BigQuery, you need the latest event per device using ROW_NUMBER(). Which clause can filter on the window result in the same SELECT?",
        "explaination": "QUALIFY filters rows after window functions are evaluated. WHERE runs too early to use the window result; HAVING filters groups, not the ROW_NUMBER result; global LIMIT 1 keeps only one device's row.",
        "interview_note": "Don't put a window-function condition in WHERE; use QUALIFY in BigQuery or an outer query.",
        "pro_tips": "In BigQuery event pipelines, QUALIFY ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY event_time DESC, event_id DESC) = 1 keeps one deterministic latest event per device.",
        "answers": [("QUALIFY ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY event_time DESC, event_id DESC) = 1", True), ("WHERE ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY event_time DESC) = 1", False), ("HAVING ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY event_time DESC) = 1", False), ("ORDER BY event_time DESC LIMIT 1", False)],
    },
    {
        "difficulty": "hard", "type": "mcq",
        "question": "For every monthly row, a report needs the final month's revenue in that customer's partition. Which LAST_VALUE frame makes the entire partition available?",
        "explaination": "LAST_VALUE returns the last value in its frame, not automatically the final partition row. UNBOUNDED FOLLOWING extends the frame to the partition end. A frame ending at CURRENT ROW can return the current value; FIRST_VALUE returns the first value; MAX returns the largest value, which need not be the final month's value.",
        "interview_note": "Don't assume LAST_VALUE means the last row of the whole partition; inspect the frame end.",
        "pro_tips": "For customer lifecycle reports, use an explicit frame through UNBOUNDED FOLLOWING and a deterministic month ordering when showing final observed revenue beside earlier months.",
        "answers": [("LAST_VALUE(revenue) OVER (PARTITION BY customer_id ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)", False), ("LAST_VALUE(revenue) OVER (PARTITION BY customer_id ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)", True), ("FIRST_VALUE(revenue) OVER (PARTITION BY customer_id ORDER BY month)", False), ("MAX(revenue) OVER (PARTITION BY customer_id)", False)],
    },
    {
        "difficulty": "hard", "type": "mcma",
        "question": "A store has one revenue row per recorded date, but some calendar dates are missing. The average should use observed values within the trailing seven calendar days. Which methods work in BigQuery? Select all that apply.",
        "explaination": "A complete store-date calendar with NULL revenue on missing dates plus a seven-row frame makes each row one calendar day; AVG ignores those NULLs. Alternatively, ordering by UNIX_DATE(sale_date) with RANGE BETWEEN 6 PRECEDING AND CURRENT ROW includes recorded dates in the seven-day date range. ROWS 6 PRECEDING on sparse data means seven observations, which may span more than seven days. A partition-only AVG ignores time.",
        "interview_note": "Don't call seven preceding rows seven calendar days when the date series has gaps.",
        "pro_tips": "For operations dashboards, decide whether missing dates mean zero revenue or no observation before filling a date spine; that decision changes the average.",
        "answers": [("Build a complete store-date calendar with NULL revenue for missing dates, then use ROWS BETWEEN 6 PRECEDING AND CURRENT ROW.", True), ("Use ORDER BY UNIX_DATE(sale_date) RANGE BETWEEN 6 PRECEDING AND CURRENT ROW on the one-row-per-recorded-date input.", True), ("Use ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW on the sparse input and call it seven calendar days.", False), ("Use AVG(revenue) OVER (PARTITION BY store_id) without ordering.", False)],
    },
    {
        "difficulty": "medium", "type": "mcma",
        "question": "A table has one revenue row per product per recorded month. You need month-over-month percentage change. Which steps are appropriate? Select all that apply.",
        "explaination": "LAG retrieves the previous recorded revenue within each product's ordered rows. Percentage change is (current - previous) / previous; SAFE_DIVIDE avoids division errors when the previous value is zero. LEAD reads a future row. MAX across a product is not the prior month. A missing month is not created by LAG.",
        "interview_note": "Don't divide by the current month's revenue or assume LAG creates missing calendar months.",
        "pro_tips": "For product dashboards, first decide whether comparisons should use the previous recorded month or the previous calendar month; add a month grid if gaps must appear.",
        "answers": [("Use LAG(revenue) OVER (PARTITION BY product_id ORDER BY month) to get the previous recorded value.", True), ("Use LEAD(revenue) to get the previous recorded value.", False), ("Calculate SAFE_DIVIDE(revenue - prior_revenue, prior_revenue) and define how to display NULL for the first row or a zero prior value.", True), ("Use MAX(revenue) OVER (PARTITION BY product_id) as the previous value.", False)],
    },
    {
        "difficulty": "medium", "type": "mcq",
        "question": "A store leaderboard should include every store tied at a top-three rank position. Which ranking filter fits?",
        "explaination": "RANK gives tied stores the same position; filtering rank <= 3 keeps every store whose rank is within the top three positions. ROW_NUMBER <= 3 keeps exactly three rows and may split a tie. DENSE_RANK <= 3 selects three distinct revenue levels, which can include a store whose RANK position is greater than 3. A global LIMIT is not per region.",
        "interview_note": "Don't use ROW_NUMBER when the business wants all ties at a top-N cutoff.",
        "pro_tips": "For awards or leaderboards, confirm whether top three means three rows, three rank positions, or three distinct scores before choosing ROW_NUMBER, RANK, or DENSE_RANK.",
        "answers": [("RANK() OVER (PARTITION BY region ORDER BY revenue DESC), then keep rank <= 3.", True), ("ROW_NUMBER() OVER (PARTITION BY region ORDER BY revenue DESC), then keep row number <= 3.", False), ("DENSE_RANK() OVER (PARTITION BY region ORDER BY revenue DESC), then keep dense rank <= 3.", False), ("ORDER BY revenue DESC LIMIT 3 for the whole table.", False)],
    },
]

for number, q in enumerate(NEW, 1):
    q["question_id"] = f"sql_window_gap_20260928_{number:02d}"
    q["mode"] = "new"
    q["answers"] = [
        {
            "option_id": f"{q['question_id']}_{chr(97 + i)}",
            "option_text": text,
            "is_correct": correct,
        }
        for i, (text, correct) in enumerate(q["answers"])
    ]
    assert q["interview_note"].startswith("Don't ")
    assert sum(a["is_correct"] for a in q["answers"]) == (1 if q["type"] == "mcq" else 2)

payload = json.dumps(retained + NEW, ensure_ascii=False, indent=2)
assert "$window_export$" not in payload
removed_values = ",\n".join(
    f"  ('{original[number - 1]['question_id']}', '{reason.replace(chr(39), chr(39) * 2)}')"
    for number, reason in REMOVED.items()
)
prior_notes = [
    "Don't rely on a peer-based default frame when a running total must advance once per row; order ties uniquely and use ROWS.",
    "Don't call the next recorded row the next calendar month; fill missing months if calendar adjacency matters.",
    "Don't filter to only visible dates before a rolling calculation; include the required lookback rows.",
    "Don't use a running total as the denominator for a region-wide share; use the full partition total.",
    "Don't assume NTILE(4) creates equal total spend; it divides ordered rows into near-equal-sized buckets.",
    "Don't rank raw sales when the business asks for store-month ranks; aggregate to store-month first.",
]
prior_values = ",\n".join(
    f"  ('sql_window_20260928_{i:02d}', '{'medium' if i <= 4 else 'hard'}', '{note.replace(chr(39), chr(39) * 2)}')"
    for i, note in enumerate(prior_notes, 1)
)

sql = """-- Review Window Functions: retain 12 of 19 supplied questions, remove seven repeats,
-- add six gap questions, and normalize the six previously added interview notes.
-- Existing survivor wording/options remain as supplied; difficulty uses easy/medium/hard.
-- Every interview note begins with a concrete "Don't ..." mistake to avoid.
-- Historical quiz_user_answers remain for removed question IDs.
BEGIN;

CREATE TEMP TABLE window_removed_ids (question_id text PRIMARY KEY, reason text NOT NULL) ON COMMIT DROP;
INSERT INTO window_removed_ids VALUES
""" + removed_values + ";\n\n" + """CREATE TEMP TABLE window_prior_notes (
  question_id text PRIMARY KEY, difficulty text NOT NULL, interview_note text NOT NULL
) ON COMMIT DROP;
INSERT INTO window_prior_notes VALUES
""" + prior_values + ";\n\n" + """CREATE TEMP TABLE window_export_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO window_export_payload VALUES ($window_export$
""" + payload + """
$window_export$::jsonb);

CREATE TEMP TABLE window_seed_questions ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id, q->>'mode' AS mode,
       q->>'difficulty' AS difficulty, q->>'type' AS type,
       q->>'question' AS question, q->>'explaination' AS explaination,
       q->>'interview_note' AS interview_note, q->>'pro_tips' AS pro_tips
FROM window_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q;

CREATE TEMP TABLE window_seed_answers ON COMMIT DROP AS
SELECT q->>'question_id' AS question_id, q->>'mode' AS mode,
       a.answer->>'option_id' AS option_id,
       a.answer->>'option_text' AS option_text,
       (a.answer->>'is_correct')::boolean AS is_correct,
       a.position::integer AS position
FROM window_export_payload p
CROSS JOIN LATERAL jsonb_array_elements(p.data) AS q
CROSS JOIN LATERAL jsonb_array_elements(q->'answers') WITH ORDINALITY AS a(answer, position);

DO $preflight$
DECLARE v_topic bigint; v_subtopic bigint; v_old_count integer;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name = 'SQL';
  SELECT id INTO v_subtopic FROM de_mobile_app."subtopics-legacy"
    WHERE topic_id = v_topic AND name = 'Window Functions';
  IF v_topic IS NULL OR v_subtopic IS NULL THEN
    RAISE EXCEPTION 'SQL / Window Functions classification missing';
  END IF;
  IF (SELECT count(*) FROM window_removed_ids) <> 7
     OR (SELECT count(*) FROM window_prior_notes) <> 6
     OR (SELECT count(*) FROM window_seed_questions WHERE mode = 'existing') <> 12
     OR (SELECT count(*) FROM window_seed_questions WHERE mode = 'new') <> 6
     OR (SELECT count(DISTINCT question_id) FROM window_seed_questions) <> 18
     OR (SELECT count(*) FROM window_seed_answers) <> 72
     OR (SELECT count(DISTINCT option_id) FROM window_seed_answers) <> 72 THEN
    RAISE EXCEPTION 'Seed counts differ from the reviewed set';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_seed_questions q
    JOIN window_seed_answers a ON a.question_id = q.question_id
    GROUP BY q.question_id, q.type
    HAVING count(*) <> 4 OR count(*) FILTER (WHERE a.is_correct)
      <> CASE WHEN q.type = 'mcq' THEN 1 ELSE 2 END
  ) THEN
    RAISE EXCEPTION 'Answer flags or option counts are inconsistent';
  END IF;
  IF EXISTS (SELECT 1 FROM window_seed_questions WHERE interview_note NOT LIKE 'Don''t %') THEN
    RAISE EXCEPTION 'An interview note does not begin with Don''t';
  END IF;
  IF (SELECT count(*) FROM window_seed_questions s
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
      WHERE s.mode = 'existing' AND q.topic = v_topic AND q.sub_topics = v_subtopic) <> 12 THEN
    RAISE EXCEPTION 'A retained export question is missing or reclassified';
  END IF;
  IF (SELECT count(*) FROM window_seed_answers s
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
      WHERE s.mode = 'existing' AND a.question_id::text = s.question_id) <> 48 THEN
    RAISE EXCEPTION 'Retained answer IDs or links differ';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_seed_questions s
    JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = s.question_id
    WHERE s.mode = 'existing'
    GROUP BY s.question_id HAVING count(*) <> 4
  ) THEN
    RAISE EXCEPTION 'A retained question has extra or missing options';
  END IF;
  SELECT count(*) INTO v_old_count FROM window_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id;
  IF v_old_count NOT IN (0, 7) THEN
    RAISE EXCEPTION 'Only part of the seven-question removal set exists';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_removed_ids r
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A removal ID belongs to another classification';
  END IF;
  IF (SELECT count(*) FROM window_prior_notes n
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = n.question_id)
     NOT IN (0, 6) THEN
    RAISE EXCEPTION 'Only part of the six previously added questions exists';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_prior_notes n
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = n.question_id
    WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic
  ) THEN
    RAISE EXCEPTION 'A previously added question belongs to another classification';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_seed_questions s
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
    WHERE s.mode = 'new' AND (q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_subtopic)
  ) THEN
    RAISE EXCEPTION 'A new question ID belongs to another classification';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_seed_answers s
    JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
    WHERE s.mode = 'new' AND a.question_id::text IS DISTINCT FROM s.question_id
  ) THEN
    RAISE EXCEPTION 'A new option ID belongs to another question';
  END IF;
END
$preflight$;

DELETE FROM de_mobile_app."quiz-answer" a
WHERE a.question_id::text IN (SELECT question_id FROM window_removed_ids);
DELETE FROM de_mobile_app."quiz-question" q
WHERE q.question_id::text IN (SELECT question_id FROM window_removed_ids);

UPDATE de_mobile_app."quiz-question" q
SET difficulty = s.difficulty, question = s.question,
    explaination = s.explaination, interview_note = s.interview_note,
    interview_tips = s.interview_note, pro_tips = s.pro_tips
FROM window_seed_questions s
WHERE s.mode = 'existing' AND q.question_id::text = s.question_id;

UPDATE de_mobile_app."quiz-answer" a
SET option_text = s.option_text, is_correct = s.is_correct, "order" = s.position
FROM window_seed_answers s
WHERE s.mode = 'existing' AND a.option_id::text = s.option_id
  AND a.question_id::text = s.question_id;

UPDATE de_mobile_app."quiz-question" q
SET difficulty = n.difficulty,
    interview_note = n.interview_note,
    interview_tips = n.interview_note
FROM window_prior_notes n WHERE q.question_id::text = n.question_id;

INSERT INTO de_mobile_app."quiz-question"
  (question_id, topic, sub_topics, type, difficulty, question,
   explaination, interview_note, interview_tips, pro_tips)
SELECT s.question_id, t.id, st.id, s.type, s.difficulty, s.question,
       s.explaination, s.interview_note, s.interview_note, s.pro_tips
FROM window_seed_questions s
JOIN de_mobile_app."topics-legacy" t ON t.name = 'SQL'
JOIN de_mobile_app."subtopics-legacy" st
  ON st.topic_id = t.id AND st.name = 'Window Functions'
WHERE s.mode = 'new'
ON CONFLICT (question_id) DO UPDATE SET
  type = EXCLUDED.type, difficulty = EXCLUDED.difficulty,
  question = EXCLUDED.question, explaination = EXCLUDED.explaination,
  interview_note = EXCLUDED.interview_note,
  interview_tips = EXCLUDED.interview_tips,
  pro_tips = EXCLUDED.pro_tips;

INSERT INTO de_mobile_app."quiz-answer"
  (option_id, question_id, option_text, is_correct, "order")
SELECT s.option_id, s.question_id, s.option_text, s.is_correct, s.position
FROM window_seed_answers s WHERE s.mode = 'new'
ON CONFLICT (option_id) DO UPDATE SET
  option_text = EXCLUDED.option_text, is_correct = EXCLUDED.is_correct,
  "order" = EXCLUDED."order";

DO $postcheck$
BEGIN
  IF (SELECT count(*) FROM window_seed_questions s
      JOIN de_mobile_app."quiz-question" q ON q.question_id::text = s.question_id
      WHERE q.question = s.question AND q.difficulty = s.difficulty
        AND q.interview_note = s.interview_note AND q.pro_tips = s.pro_tips) <> 18 THEN
    RAISE EXCEPTION 'Question verification failed';
  END IF;
  IF (SELECT count(*) FROM window_seed_answers s
      JOIN de_mobile_app."quiz-answer" a ON a.option_id::text = s.option_id
      WHERE a.question_id::text = s.question_id AND a.option_text = s.option_text
        AND a.is_correct = s.is_correct AND a."order" = s.position) <> 72 THEN
    RAISE EXCEPTION 'Option verification failed';
  END IF;
  IF EXISTS (
    SELECT 1 FROM window_prior_notes n
    JOIN de_mobile_app."quiz-question" q ON q.question_id::text = n.question_id
    WHERE q.difficulty IS DISTINCT FROM n.difficulty
       OR q.interview_note IS DISTINCT FROM n.interview_note
  ) THEN
    RAISE EXCEPTION 'Previously added interview notes were not normalized';
  END IF;
  IF EXISTS (SELECT 1 FROM window_removed_ids r
             JOIN de_mobile_app."quiz-question" q ON q.question_id::text = r.question_id)
     OR EXISTS (SELECT 1 FROM window_removed_ids r
                JOIN de_mobile_app."quiz-answer" a ON a.question_id::text = r.question_id) THEN
    RAISE EXCEPTION 'Duplicate removal verification failed';
  END IF;
END
$postcheck$;

COMMIT;
"""

TARGET.write_text(sql, encoding="utf-8")
print(f"Wrote {TARGET}: 12 retained, 7 removed, 6 new, 6 earlier notes normalized")
