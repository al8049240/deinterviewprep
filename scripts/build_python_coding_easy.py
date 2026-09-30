"""Seed ten original Easy Python coding-practice MCQs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "supabase/migrations/20260929010000_seed_python_coding_practice_easy.sql"

def item(question, options, correct, reasoning, code, wrong, note, tip):
    number = len(items) + 1
    assert len(options) == len(set(options)) == 4
    items.append({
        "id": f"python_coding_easy_20260929_{number:02d}", "level": "easy",
        "question": question, "options": options, "correct": correct,
        "explaination": f"Reasoning: {reasoning}\n\nPython solution:\n{code}\n\nWhy the other options fail: {wrong}",
        "interview_note": note, "pro_tips": tip,
    })

items = []
item(
    "Students are [('Harry', 37.21), ('Berry', 37.21), ('Tina', 37.2), ('Akriti', 41)]. Return the names at the second distinct lowest score in alphabetical order. Which approach works?",
    ["Sort the records by score and take just the second record's name.",
     "Find the second value in sorted(set(scores)); select all names at that score; sort the names.",
     "Remove one record at the minimum score, then collect names at the new minimum.",
     "Sort names first, then return the first two names with scores above the minimum."], 1,
    "Rank distinct score values, then include every student tied at the second value. The answer is Berry, Harry.",
    "scores = sorted({score for _, score in students})\nif len(scores) < 2:\n    raise ValueError('Need at least two distinct scores')\nnames = sorted(name for name, score in students if score == scores[1])",
    "A selects one record, not all ties. C can leave another student tied at the minimum. D chooses names by alphabetical position rather than the second score.",
    "Don't rank records when the requirement ranks distinct score values.",
    "For student-score reports, test a tie at both the minimum and second-lowest grade."
)
item(
    "Generate every [i, j, k] for 0 <= i <= X, 0 <= j <= Y, 0 <= k <= Z, excluding points whose coordinates sum to N. Which expression preserves nested-loop order?",
    ["[[i,j,k] for i in range(X) for j in range(Y) for k in range(Z) if i+j+k != N]",
     "[[i,j,k] for i,j,k in zip(range(X+1),range(Y+1),range(Z+1)) if i+j+k != N]",
     "[[i,j,k] for i in range(X+1) for j in range(Y+1) for k in range(Z+1) if i+j+k == N]",
     "[[i,j,k] for i in range(X+1) for j in range(Y+1) for k in range(Z+1) if i+j+k != N]"], 3,
    "Each range includes its upper bound, three for-clauses form the Cartesian product, and the final if removes the excluded sum.",
    "coords = [[i,j,k] for i in range(X+1) for j in range(Y+1) for k in range(Z+1) if i+j+k != N]",
    "A omits upper-bound coordinates. B zips matching positions rather than generating every combination. C keeps precisely the forbidden points.",
    "Don't use zip when the task asks for a Cartesian product.",
    "For grid generation, test X=Y=Z=1 and compare against the eight possible points before filtering."
)
item(
    "Convert 'chris  gayle  12abc' to 'Chris  Gayle  12abc', keeping the exact spacing and leaving letters after digits lowercase. Which approach is safe?",
    ["Use s.title(), which treats digits as part of the same word.",
     "Use ' '.join(word.capitalize() for word in s.split()), which preserves every original space.",
     "Use ' '.join(part.capitalize() for part in s.split(' ')), preserving empty parts from repeated spaces.",
     "Use s.replace(word, word.capitalize()) for each token returned by s.split()."], 2,
    "Splitting on the literal space retains empty fields between consecutive spaces; capitalize changes only each token's first character.",
    "result = ' '.join(part.capitalize() for part in s.split(' '))",
    "A turns 12abc into 12Abc. B collapses repeated spaces because split() discards empty fields. D can replace matching text in unintended positions and mutates the whole string repeatedly.",
    "Don't use split() without a separator when whitespace must be preserved exactly.",
    "For user-facing names, check repeated spaces and tokens beginning with digits."
)
item(
    "Count overlapping appearances of 'CDC' in 'ABCDCDC'. Which approach returns 2? Assume the substring is nonempty.",
    ["Check each possible starting index and compare text[i:i+len(pattern)] with pattern.",
     "Use text.count(pattern), which counts overlapping matches by default.",
     "After a find() match, resume searching at match_start + len(pattern).",
     "Split on pattern and use len(parts) - 1."], 0,
    "A one-character sliding step allows a later occurrence to start inside an earlier one.",
    "count = sum(text[i:i+len(pattern)] == pattern for i in range(len(text)-len(pattern)+1))",
    "B and D count non-overlapping matches. C advances past the full match and skips overlapping starts.",
    "Don't advance by the pattern length when overlaps count.",
    "For log token detection, test ABCDCDC, where matches begin at indices 2 and 4."
)
item(
    "A={2,4,5,9} and B={2,4,11,12}. Return sorted IDs present in exactly one set. Which expression works?",
    ["sorted(A | B)", "sorted(A - B)", "sorted(A & B)", "sorted(A ^ B)"], 3,
    "Symmetric difference keeps members exclusive to either side, producing [5,9,11,12].",
    "result = sorted(A ^ B)",
    "A also keeps shared IDs. B loses B-only IDs. C keeps only shared IDs.",
    "Don't confuse either-set membership with exactly-one-set membership.",
    "For comparing two customer cohorts, symmetric difference identifies IDs exclusive to either cohort."
)
item(
    "Stock is [7,8,8,9,10]. Three orders request size 8 at $50 each. What code sells only available pairs and earns $100?",
    ["stock = Counter(sizes); for each order, add price then decrement stock[size].",
     "stock = Counter(sizes); for each order, if stock[size] > 0, add price and decrement stock[size].",
     "stock = set(sizes); for each order, if size in stock, add price.",
     "stock = Counter(sizes); for each order, if size in stock, add price without decrementing."], 1,
    "Counter tracks quantity by size; the availability guard prevents overselling and the decrement consumes one unit.",
    "from collections import Counter\nstock = Counter(sizes)\nearned = 0\nfor size, price in orders:\n    if stock[size] > 0:\n        earned += price\n        stock[size] -= 1",
    "A accepts a third order and can make stock negative. C discards quantity information. D never consumes stock, so all three orders are charged.",
    "Don't treat membership in inventory as proof that quantity remains positive.",
    "For warehouse allocation, test one more order than the available count."
)
item(
    "Transactions arrive as [('BANANA',10),('APPLE',15),('BANANA',10)]. Sum by item while reporting items in first-seen order. Which approach is correct in modern Python?",
    ["Use a plain dict and update totals[name] = totals.get(name, 0) + price; iterate its items.",
     "Use a set of names, then sum once per name in the set's iteration order.",
     "Sort transactions by item name before summing into a dict.",
     "Use a Counter on item names and read its counts as the price totals."], 0,
    "Python 3.7+ dict preserves insertion order; updating an existing key does not move it. Output is BANANA 20, then APPLE 15.",
    "totals = {}\nfor name, price in transactions:\n    totals[name] = totals.get(name, 0) + price\nfor name, total in totals.items():\n    print(name, total)",
    "B has no guaranteed first-seen order and drops amounts. C changes the requested order to alphabetical. D counts occurrences, not prices.",
    "Don't assume a set preserves insertion order; use a dict or OrderedDict for first-seen grouping.",
    "For event summaries, a plain dict is sufficient on Python 3.7+; OrderedDict remains useful for explicit reordering operations."
)
item(
    "For 'HACK', print combinations of lengths 1 through 2 in lexicographic order, without reusing a character position. Which approach fits?",
    ["Use permutations(sorted(S), 2) for all lengths.",
     "Use product(sorted(S), repeat=length) for lengths 1..2.",
     "For length in 1..2, use combinations(sorted(S), length) and join each tuple.",
     "Use combinations(S, 2) only, then sort the emitted pairs."], 2,
    "Sorted input plus combinations gives the needed order and lengths without replacement.",
    "from itertools import combinations\nfor length in range(1, K+1):\n    for group in combinations(sorted(S), length):\n        print(''.join(group))",
    "A creates ordered permutations and omits length 1. B permits repeated character positions. D omits length 1 and relies on unsorted input.",
    "Don't choose permutations when AB and BA should represent one combination.",
    "For feature-pair generation, consider whether duplicate letters are distinct positions; combinations does not deduplicate identical values."
)
item(
    "Scores are stored by subject: [[89,90,78],[92,88,80]]. How do you calculate one mean per student? Assume all rows have the same number of students.",
    ["Compute sum(row)/len(row) for each subject row.",
     "Flatten the matrix and split it into consecutive chunks of two values.",
     "Use zip(scores), then average each resulting tuple.",
     "Use zip(*scores) and average each tuple of scores at the same index."], 3,
    "Unpacking subject rows into zip groups values by student index, yielding means 90.5, 89.0, and 79.0.",
    "averages = [sum(student_scores)/len(student_scores) for student_scores in zip(*scores)]",
    "A gives one mean per subject. B groups adjacent flattened entries rather than matching student positions. C treats each entire row as a single zipped element.",
    "Don't average the wrong axis of a matrix.",
    "For batch score matrices, check whether rows represent subjects or students before transposing."
)
item(
    "Given nums, return True only if every value is positive and at least one value is a palindrome in decimal notation. Which expression is correct?",
    ["any(x > 0 for x in nums) and any(str(x) == str(x)[::-1] for x in nums)",
     "all(x > 0 for x in nums) and any(str(x) == str(x)[::-1] for x in nums)",
     "all(x > 0 and str(x) == str(x)[::-1] for x in nums)",
     "all(x > 0 for x in nums) or any(str(x) == str(x)[::-1] for x in nums)"], 1,
    "The two requirements use different quantifiers: all numbers must be positive, but only one must be palindromic.",
    "result = all(x > 0 for x in nums) and any(str(x) == str(x)[::-1] for x in nums)",
    "A allows nonpositive values. C requires every number to be palindromic. D accepts a list satisfying only one condition.",
    "Don't use all for an at-least-one requirement or any for a universal requirement.",
    "For validation rules, test [12,9,30] and [12,-9,30]; the latter must fail."
)

assert len(items) == 10
assert sorted(x["correct"] for x in items) == [0,0,1,1,1,2,2,3,3,3]
payload = json.dumps(items, ensure_ascii=False, indent=2)
assert "$python_easy$" not in payload

sql = """-- Original Python coding-practice Easy quiz. Rerunnable; does not alter SQL practice.
BEGIN;
INSERT INTO de_mobile_app."topics-legacy" (name, description, icon)
VALUES ('Python Coding Practice', 'Original Python coding and reasoning questions', 'code')
ON CONFLICT (name) DO NOTHING;

DO $topic_check$
BEGIN
  IF (SELECT count(*) FROM de_mobile_app."topics-legacy" WHERE name='Python Coding Practice')<>1 THEN
    RAISE EXCEPTION 'Python Coding Practice topic is missing or duplicated';
  END IF;
END $topic_check$;

INSERT INTO de_mobile_app."subtopics-legacy" (topic_id, name, description)
SELECT t.id, 'Easy', 'Core Python data structures, strings, iteration, and built-ins'
FROM de_mobile_app."topics-legacy" t
WHERE t.name='Python Coding Practice'
  AND NOT EXISTS (SELECT 1 FROM de_mobile_app."subtopics-legacy" s WHERE s.topic_id=t.id AND s.name='Easy');

CREATE TEMP TABLE python_easy_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO python_easy_payload VALUES ($python_easy$""" + payload + """$python_easy$::jsonb);
CREATE TEMP TABLE python_easy_questions ON COMMIT DROP AS
SELECT x->>'id' AS question_id, x->>'level' AS difficulty,
       x->>'question' AS question, x->>'explaination' AS explaination,
       x->>'interview_note' AS interview_note, x->>'pro_tips' AS pro_tips
FROM python_easy_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x;
CREATE TEMP TABLE python_easy_answers ON COMMIT DROP AS
SELECT x->>'id' AS question_id,
       x->>'id' || '_' || chr(96+a.position::integer) AS option_id,
       a.answer #>> '{}' AS option_text,
       (a.position::integer-1)=(x->>'correct')::integer AS is_correct,
       a.position::integer AS position
FROM python_easy_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x
CROSS JOIN LATERAL jsonb_array_elements(x->'options') WITH ORDINALITY AS a(answer,position);

DO $preflight$
DECLARE v_topic bigint;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='Python Coding Practice';
  IF (SELECT count(*) FROM de_mobile_app."subtopics-legacy" WHERE topic_id=v_topic AND name='Easy')<>1 THEN
    RAISE EXCEPTION 'Expected one Easy subtopic';
  END IF;
  IF (SELECT count(*) FROM python_easy_questions)<>10 OR (SELECT count(*) FROM python_easy_answers)<>40
     OR (SELECT count(DISTINCT question_id) FROM python_easy_questions)<>10
     OR (SELECT count(DISTINCT option_id) FROM python_easy_answers)<>40 THEN
    RAISE EXCEPTION 'Python Easy payload count mismatch';
  END IF;
  IF EXISTS (SELECT 1 FROM python_easy_questions q LEFT JOIN python_easy_answers a USING (question_id)
             GROUP BY q.question_id HAVING count(a.option_id)<>4
                OR count(*) FILTER (WHERE a.is_correct)<>1) THEN
    RAISE EXCEPTION 'Each question needs four options and one correct answer';
  END IF;
  IF EXISTS (SELECT 1 FROM python_easy_questions c JOIN de_mobile_app."quiz-question" q ON q.question_id::text=c.question_id
             WHERE q.topic IS DISTINCT FROM v_topic) THEN
    RAISE EXCEPTION 'Python Easy question ID belongs to another topic';
  END IF;
  IF EXISTS (SELECT 1 FROM python_easy_answers c JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=c.option_id
             WHERE a.question_id::text IS DISTINCT FROM c.question_id) THEN
    RAISE EXCEPTION 'Python Easy option ID belongs to another question';
  END IF;
END $preflight$;

INSERT INTO de_mobile_app."quiz-question"
  (question_id,topic,sub_topics,type,difficulty,question,explaination,interview_note,interview_tips,pro_tips)
SELECT c.question_id,t.id,s.id,'mcq',c.difficulty,c.question,c.explaination,
       c.interview_note,c.interview_note,c.pro_tips
FROM python_easy_questions c JOIN de_mobile_app."topics-legacy" t ON t.name='Python Coding Practice'
JOIN de_mobile_app."subtopics-legacy" s ON s.topic_id=t.id AND s.name='Easy'
ON CONFLICT (question_id) DO UPDATE SET type=EXCLUDED.type,difficulty=EXCLUDED.difficulty,
  question=EXCLUDED.question,explaination=EXCLUDED.explaination,
  interview_note=EXCLUDED.interview_note,interview_tips=EXCLUDED.interview_tips,
  pro_tips=EXCLUDED.pro_tips;
INSERT INTO de_mobile_app."quiz-answer" (option_id,question_id,"order",option_text,is_correct)
SELECT option_id,question_id,position,option_text,is_correct FROM python_easy_answers
ON CONFLICT (option_id) DO UPDATE SET "order"=EXCLUDED."order",
  option_text=EXCLUDED.option_text,is_correct=EXCLUDED.is_correct;

DO $postcheck$
DECLARE v_topic bigint;
BEGIN
  SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='Python Coding Practice';
  IF (SELECT count(*) FROM python_easy_questions c JOIN de_mobile_app."quiz-question" q ON q.question_id::text=c.question_id
      WHERE q.topic=v_topic AND q.question=c.question AND q.difficulty=c.difficulty)<>10
     OR (SELECT count(*) FROM python_easy_answers c JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=c.option_id
         WHERE a.question_id::text=c.question_id AND a.option_text=c.option_text
           AND a.is_correct=c.is_correct AND a."order"=c.position)<>40 THEN
    RAISE EXCEPTION 'Python coding practice Easy verification failed';
  END IF;
END $postcheck$;
COMMIT;
"""
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: {len(items)} questions / 40 options")
