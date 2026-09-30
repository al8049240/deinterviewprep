"""Replace 10 SQL Coding Practice medium MCQs with 12 user-supplied concepts."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "supabase/migrations/20260928220000_replace_sql_coding_medium_with_12.sql"
items = []

def add(title, task, options, correct, solution, why_wrong, note, tip):
    assert len(options) == 4 and 0 <= correct < 4 and note.startswith("Don't ")
    i = len(items) + 1
    items.append({
        "id": f"sql_coding_medium_20260928_{i:02d}",
        "question": title + "\n\n" + task + "\n\nWhich approach gives the correct result?",
        "options": options, "correct": correct,
        "explaination": "Correct PostgreSQL solution:\n" + solution.strip() + "\n\nWhy the other options fail: " + why_wrong,
        "interview_note": note, "pro_tips": tip,
    })

add("Daily team role roster (pivot)",
    "team_members(member_name, role) contains Frontend, Backend, DevOps, and QA staff. Show one column per role, with names alphabetized down each column; missing cells should be NULL.",
    ["Number names globally, then group by role and apply MAX(member_name).",
     "GROUP BY role and use STRING_AGG to put all names in one cell per role.",
     "Join the four roles by member_name, matching identical names only.",
     "Rank names separately within each role, then group by rank and use conditional MAX for each role."], 3,
    """WITH ranked AS (
  SELECT member_name, role,
         ROW_NUMBER() OVER (PARTITION BY role ORDER BY member_name) AS rn
  FROM team_members
)
SELECT MAX(member_name) FILTER (WHERE role = 'Frontend') AS frontend,
       MAX(member_name) FILTER (WHERE role = 'Backend') AS backend,
       MAX(member_name) FILTER (WHERE role = 'DevOps') AS devops,
       MAX(member_name) FILTER (WHERE role = 'QA') AS qa
FROM ranked GROUP BY rn ORDER BY rn;""",
    "A does not align each role independently; B changes the required row layout; C loses different names.",
    "Don't order all employees together before pivoting; each role needs its own row numbers.",
    "Test unequal role sizes: the shorter role should show NULL in later rows.")

add("Distribution-hub hierarchy totals",
    "hubs(hub_code, lead_manager), regional_leads(lead_id, hub_code), area_managers(area_id, hub_code), branch_managers(branch_id, hub_code), and drivers(driver_id, hub_code) must yield one row per hub with counts at every level, including zero-count hubs.",
    ["LEFT JOIN all four child tables and COUNT(*) for each level.",
     "INNER JOIN each child table and COUNT(DISTINCT id).",
     "Aggregate each child table by hub_code, then LEFT JOIN those four counts to hubs and COALESCE missing counts to zero.",
     "CROSS JOIN the four child tables and count distinct IDs."], 2,
    """WITH rl AS (SELECT hub_code, COUNT(DISTINCT lead_id) n FROM regional_leads GROUP BY hub_code),
am AS (SELECT hub_code, COUNT(DISTINCT area_id) n FROM area_managers GROUP BY hub_code),
bm AS (SELECT hub_code, COUNT(DISTINCT branch_id) n FROM branch_managers GROUP BY hub_code),
dr AS (SELECT hub_code, COUNT(DISTINCT driver_id) n FROM drivers GROUP BY hub_code)
SELECT h.hub_code, h.lead_manager,
       COALESCE(rl.n,0) regional_leads, COALESCE(am.n,0) area_managers,
       COALESCE(bm.n,0) branch_managers, COALESCE(dr.n,0) drivers
FROM hubs h LEFT JOIN rl USING (hub_code) LEFT JOIN am USING (hub_code)
LEFT JOIN bm USING (hub_code) LEFT JOIN dr USING (hub_code)
ORDER BY h.hub_code;""",
    "A multiplies counts through join fan-out; B excludes hubs without a child at every level; D creates unrelated combinations.",
    "Don't count rows after several one-to-many joins without controlling fan-out.",
    "For an empty new hub, verify all four counts display zero rather than losing the hub.")

add("Service category node labels",
    "ticket_categories(category_id, parent_id) forms a tree. Label each category Root if parent_id is NULL, Leaf if it has a parent and no children, otherwise Inner. Return category_id order.",
    ["Test parent_id IS NULL first, then test child existence with EXISTS, otherwise label Leaf.",
     "Label every category with a parent as Inner.",
     "Label a category Leaf only when its category_id is NULL.",
     "Use MAX(parent_id) over the entire table to decide every label."], 0,
    """SELECT c.category_id,
       CASE WHEN c.parent_id IS NULL THEN 'Root'
            WHEN EXISTS (SELECT 1 FROM ticket_categories child
                         WHERE child.parent_id = c.category_id) THEN 'Inner'
            ELSE 'Leaf' END AS category_type
FROM ticket_categories c ORDER BY c.category_id;""",
    "B confuses having a parent with having children; C checks the wrong NULL; D cannot classify nodes individually.",
    "Don't call every non-root category a leaf; some are both children and parents.",
    "Test a root with children, an intermediate node, and a leaf.")

add("Multiple full-score assessments",
    "users(user_id, user_name), assessments(assessment_id, difficulty_level), difficulty(difficulty_level, max_score), and submissions(user_id, assessment_id, score) are available. High difficulty means level >= 4. Find users with full marks on at least two different high-difficulty assessments; order by qualifying assessment count descending, then user_id.",
    ["Count all full-score submissions, including retries to the same assessment.",
     "Count distinct assessment IDs after filtering level >= 4 and score = max_score.",
     "Count assessments created by each user, regardless of their submissions.",
     "Filter score = 100 without consulting each difficulty's max_score."], 1,
    """SELECT u.user_id, u.user_name
FROM users u JOIN submissions s ON s.user_id = u.user_id
JOIN assessments a ON a.assessment_id = s.assessment_id
JOIN difficulty d ON d.difficulty_level = a.difficulty_level
WHERE a.difficulty_level >= 4 AND s.score = d.max_score
GROUP BY u.user_id, u.user_name
HAVING COUNT(DISTINCT a.assessment_id) >= 2
ORDER BY COUNT(DISTINCT a.assessment_id) DESC, u.user_id;""",
    "A treats repeated submissions as different assessments; C counts creation, not achievement; D assumes all maximum scores equal 100.",
    "Don't count retries to the same assessment as separate full-score achievements.",
    "A learner with three perfect retries on one assessment has still completed only one distinct assessment.")

add("Warehouse Manhattan distance",
    "warehouses(latitude numeric, longitude numeric) defines corner A=(MIN(latitude),MIN(longitude)) and B=(MAX(latitude),MAX(longitude)). Compute their 2D Manhattan distance rounded to four decimals. Treat the coordinates as planar values, not Earth-surface distance.",
    ["ROUND(ABS(MAX(latitude)-MIN(latitude)) + ABS(MAX(longitude)-MIN(longitude)), 4)",
     "ROUND(SQRT(POWER(MAX(latitude)-MIN(latitude),2) + POWER(MAX(longitude)-MIN(longitude),2)), 4)",
     "ROUND(MAX(latitude+longitude)-MIN(latitude+longitude), 4)",
     "ROUND((MAX(latitude)-MIN(longitude)) + (MAX(longitude)-MIN(latitude)), 4)"], 0,
    """SELECT ROUND(ABS(MAX(latitude)-MIN(latitude))
           + ABS(MAX(longitude)-MIN(longitude)), 4) AS manhattan_distance
FROM warehouses;""",
    "B is Euclidean distance; C chooses extrema of sums rather than the specified coordinate corners; D mixes coordinate axes.",
    "Don't confuse Manhattan distance with straight-line Euclidean distance.",
    "For real geographic distance in kilometres, use an appropriate geospatial function rather than planar degree arithmetic.")

add("Warehouse Euclidean distance",
    "Using warehouse coordinate extrema as planar points A=(MIN(latitude),MIN(longitude)) and B=(MAX(latitude),MAX(longitude)), compute their straight-line 2D distance rounded to four decimals.",
    ["ROUND(ABS(MAX(latitude)-MIN(latitude)) + ABS(MAX(longitude)-MIN(longitude)), 4)",
     "ROUND(POWER(MAX(latitude)-MIN(latitude),2) + POWER(MAX(longitude)-MIN(longitude),2), 4)",
     "ROUND(SQRT(POWER(MAX(latitude)-MIN(longitude),2) + POWER(MAX(longitude)-MIN(latitude),2)), 4)",
     "ROUND(SQRT(POWER(MAX(latitude)-MIN(latitude),2) + POWER(MAX(longitude)-MIN(longitude),2)), 4)"], 3,
    """SELECT ROUND(SQRT(POWER(MAX(latitude)-MIN(latitude),2)
                       + POWER(MAX(longitude)-MIN(longitude),2)), 4)
       AS euclidean_distance FROM warehouses;""",
    "A is Manhattan distance; B forgets the square root; C subtracts values from different axes.",
    "Don't forget the square root after adding squared coordinate differences.",
    "This is planar math for an interview exercise, not a geodesic distance on Earth.")

add("Median warehouse latitude",
    "warehouses(latitude numeric) has an unknown number of non-NULL rows. Return the median latitude rounded to four decimals; for an even count average the two middle values.",
    ["ROUND(AVG(latitude),4)",
     "ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY latitude))::numeric,4)",
     "ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY latitude))::numeric,4)",
     "ROUND(MAX(latitude)-MIN(latitude),4)"], 1,
    """SELECT ROUND((PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY latitude))::numeric, 4) AS median_latitude
FROM warehouses WHERE latitude IS NOT NULL;""",
    "A is the arithmetic mean; C picks an observed value rather than interpolating between middle values for even counts; D is the range.",
    "Don't use AVG of every row when the task asks for a median.",
    "Test [1,2,9] (median 2) and [1,2,8,9] (median 5).")

add("Continuous sprint campaigns",
    "task_sprints(start_date DATE, end_date DATE) contains non-overlapping tasks in simple chains: a task continues the previous campaign exactly when its start_date equals the prior end_date. Find each campaign's first start and final end, ordered by duration then start.",
    ["Pair every start_date with every later end_date and take MIN duration.",
     "Group tasks by calendar month, ignoring exact endpoint links.",
     "Find starts that are not any task end and ends that are not any task start; number each sorted list and pair by row number.",
     "Use DATEDIFF(end_date,start_date) to group PostgreSQL DATE rows."], 2,
    """WITH starts AS (
  SELECT s.start_date, ROW_NUMBER() OVER (ORDER BY s.start_date) rn
  FROM task_sprints s WHERE NOT EXISTS
    (SELECT 1 FROM task_sprints p WHERE p.end_date=s.start_date)
), ends AS (
  SELECT e.end_date, ROW_NUMBER() OVER (ORDER BY e.end_date) rn
  FROM task_sprints e WHERE NOT EXISTS
    (SELECT 1 FROM task_sprints n WHERE n.start_date=e.end_date)
)
SELECT s.start_date, e.end_date FROM starts s JOIN ends e USING (rn)
ORDER BY e.end_date-s.start_date, s.start_date;""",
    "A forms unrelated pairs; B ignores the chaining rule; D uses a non-PostgreSQL DATEDIFF call and does not form campaigns.",
    "Don't assume adjacent calendar dates are linked; this task links exact end and start timestamps.",
    "The endpoint-pair method assumes non-overlapping, non-branching chains; more complex schedules need interval logic.")

add("Mentor salary comparison",
    "engineers(id,name), mentors(engineer_id,mentor_id), and salaries(engineer_id,salary) hold one salary per engineer. Return engineers whose assigned mentor earns more, ordered by mentor salary and engineer ID.",
    ["Join salaries once using the junior engineer ID and compare that salary with itself.",
     "Join engineers to mentors, then join salaries twice: once for engineer_id and once for mentor_id; compare mentor > engineer.",
     "Compare mentor_id > engineer_id as a salary proxy.",
     "Use a CROSS JOIN between engineers and salaries, then sort by salary."], 1,
    """SELECT e.name FROM engineers e
JOIN mentors m ON m.engineer_id=e.id
JOIN salaries own ON own.engineer_id=e.id
JOIN salaries mentor ON mentor.engineer_id=m.mentor_id
WHERE mentor.salary>own.salary
ORDER BY mentor.salary,e.id;""",
    "A compares the same salary, C compares IDs rather than pay, and D creates unrelated combinations.",
    "Don't join the salary table twice without using distinct aliases and the correct keys.",
    "For mentor analytics, test a mentor who earns exactly the same salary; that engineer should not qualify.")

add("Reciprocal route coordinates",
    "route_points(route_id,x,y) has unique route_id. Return unique pairs (x,y) where a different row contains (y,x), outputting only x<=y. A pair (4,4) qualifies only if at least two distinct (4,4) rows exist.",
    ["Self-join on a.x=b.y and a.y=b.x, require a.route_id<>b.route_id, then select DISTINCT a.x,a.y with a.x<=a.y.",
     "Select any row with x=y, even when it is the only row.",
     "Self-join only on a.x=b.x, without comparing reciprocal coordinates.",
     "Use DISTINCT(x,y) without checking for a reversed row."], 0,
    """SELECT DISTINCT a.x,a.y FROM route_points a JOIN route_points b
  ON a.x=b.y AND a.y=b.x AND a.route_id<>b.route_id
WHERE a.x<=a.y ORDER BY a.x,a.y;""",
    "B fails the two-row requirement for equal coordinates; C matches same-direction values; D does not prove reciprocity.",
    "Don't let a single self-symmetric row match itself; require different row IDs.",
    "Test one (4,4), two (4,4), and the pair (2,5)/(5,2).")

add("Student assignment leaderboard",
    "students(student_id,name) and submissions(student_id,assignment_id,score) allow retries. Each assignment contributes only its student's highest score. Sum these maxima, drop zero-total students, order by total descending and student_id ascending.",
    ["SUM every submission score by student.",
     "Use MAX(score) once per student across all assignments.",
     "First MAX(score) per student and assignment, then SUM those maxima per student and filter total > 0.",
     "Keep only each student's latest submission and sum it."], 2,
    """WITH best AS (
  SELECT student_id,assignment_id,MAX(score) AS best_score
  FROM submissions GROUP BY student_id,assignment_id
)
SELECT s.student_id,s.name,SUM(b.best_score) AS total_score
FROM students s JOIN best b USING (student_id)
GROUP BY s.student_id,s.name HAVING SUM(b.best_score)>0
ORDER BY total_score DESC,s.student_id;""",
    "A double-counts retries; B keeps only one assignment; D may discard a better earlier attempt or other assignments.",
    "Don't sum all attempts when only each assignment's best score contributes.",
    "A student with scores 50 and 80 on one assignment contributes 80, not 130.")

add("Prime numbers as a pipe-separated string",
    "In PostgreSQL, generate every prime from 2 through 100 and return one ordered string such as 2|3|5|7|... . Which approach is correct?",
    ["Use GROUP_CONCAT(n SEPARATOR '|') over generate_series; PostgreSQL supports this syntax.",
     "Use STRING_AGG on all values from 2 to 100 without divisor testing.",
     "Keep odd numbers only, then concatenate them in unspecified order.",
     "Use STRING_AGG(n::text,'|' ORDER BY n) after excluding numbers with any proper divisor."], 3,
    """SELECT STRING_AGG(n::text,'|' ORDER BY n) AS primes
FROM generate_series(2,100) AS g(n)
WHERE NOT EXISTS (
  SELECT 1 FROM generate_series(2,FLOOR(SQRT(n::numeric))::int) AS d(k)
  WHERE n % k=0
);""",
    "A uses MySQL-only GROUP_CONCAT syntax; B includes composite numbers; C includes odd composites and has no deterministic ordering.",
    "Don't carry MySQL's GROUP_CONCAT into PostgreSQL; use STRING_AGG with ORDER BY.",
    "Verify 2 is included and 9, 25, and 100 are excluded.")

assert len(items) == 12
assert len({x["id"] for x in items}) == 12
payload = json.dumps(items, ensure_ascii=False, indent=2)
assert "$medium$" not in payload

sql = """-- Replace only the ten original SQL Coding Practice / Medium questions with
-- twelve original, PostgreSQL-correct practice MCQs based on supplied concepts.
-- Easy and Hard are untouched. Historical quiz_user_answers snapshots remain.
BEGIN;
CREATE TEMP TABLE old_medium_ids (question_id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO old_medium_ids
SELECT 'sql_coding_20260928_' || lpad(i::text,2,'0')
FROM generate_series(11,20) AS i;
CREATE TEMP TABLE medium_payload (data jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO medium_payload VALUES ($medium$""" + payload + """$medium$::jsonb);
CREATE TEMP TABLE medium_questions ON COMMIT DROP AS
SELECT x->>'id' AS question_id, x->>'question' AS question,
       x->>'explaination' AS explaination, x->>'interview_note' AS interview_note,
       x->>'pro_tips' AS pro_tips
FROM medium_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x;
CREATE TEMP TABLE medium_answers ON COMMIT DROP AS
SELECT x->>'id' AS question_id, x->>'id' || '_' || chr(96+a.position::integer) AS option_id,
       a.answer #>> '{}' AS option_text,
       (a.position::integer-1)=(x->>'correct')::integer AS is_correct,
       a.position::integer AS position
FROM medium_payload p CROSS JOIN LATERAL jsonb_array_elements(p.data) AS x
CROSS JOIN LATERAL jsonb_array_elements(x->'options') WITH ORDINALITY AS a(answer,position);

DO $preflight$
DECLARE v_topic bigint; v_medium bigint; v_old integer; v_old_options integer;
BEGIN
 SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='SQL Coding Practice';
 SELECT id INTO v_medium FROM de_mobile_app."subtopics-legacy" WHERE topic_id=v_topic AND name='Medium';
 IF v_topic IS NULL OR v_medium IS NULL THEN RAISE EXCEPTION 'SQL Coding Practice / Medium classification missing'; END IF;
 IF (SELECT count(*) FROM medium_questions)<>12 OR (SELECT count(*) FROM medium_answers)<>48
    OR (SELECT count(DISTINCT question_id) FROM medium_questions)<>12
    OR (SELECT count(DISTINCT option_id) FROM medium_answers)<>48 THEN
   RAISE EXCEPTION 'Twelve-question seed mismatch'; END IF;
 IF EXISTS (SELECT 1 FROM medium_questions q LEFT JOIN medium_answers a USING (question_id)
            GROUP BY q.question_id HAVING count(a.option_id)<>4 OR count(*) FILTER (WHERE a.is_correct)<>1) THEN
   RAISE EXCEPTION 'Each MCQ needs four options and one answer'; END IF;
 SELECT count(*) INTO v_old FROM old_medium_ids o JOIN de_mobile_app."quiz-question" q ON q.question_id::text=o.question_id;
 SELECT count(*) INTO v_old_options FROM old_medium_ids o JOIN de_mobile_app."quiz-answer" a ON a.question_id::text=o.question_id;
 IF NOT ((v_old=10 AND v_old_options=40) OR (v_old=0 AND v_old_options=0)) THEN
   RAISE EXCEPTION 'Only part of the original Medium set exists'; END IF;
 IF EXISTS (SELECT 1 FROM old_medium_ids o JOIN de_mobile_app."quiz-question" q ON q.question_id::text=o.question_id
            WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_medium)
    OR EXISTS (SELECT 1 FROM medium_questions s JOIN de_mobile_app."quiz-question" q ON q.question_id::text=s.question_id
               WHERE q.topic IS DISTINCT FROM v_topic OR q.sub_topics IS DISTINCT FROM v_medium)
    OR EXISTS (SELECT 1 FROM medium_answers s JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=s.option_id
               WHERE a.question_id::text IS DISTINCT FROM s.question_id) THEN
   RAISE EXCEPTION 'A target ID belongs to another question or classification'; END IF;
END $preflight$;

DELETE FROM de_mobile_app."quiz-answer" a WHERE a.question_id::text IN (SELECT question_id FROM old_medium_ids);
DELETE FROM de_mobile_app."quiz-question" q WHERE q.question_id::text IN (SELECT question_id FROM old_medium_ids);
UPDATE de_mobile_app."subtopics-legacy" s
SET description='Pivoting, hierarchy queries, multi-table joins, geometry, medians, gaps and islands, and SQL generation'
FROM de_mobile_app."topics-legacy" t
WHERE s.topic_id=t.id AND t.name='SQL Coding Practice' AND s.name='Medium';
INSERT INTO de_mobile_app."quiz-question"
 (question_id,topic,sub_topics,type,difficulty,question,explaination,interview_note,interview_tips,pro_tips)
SELECT m.question_id,t.id,s.id,'mcq','medium',m.question,m.explaination,m.interview_note,m.interview_note,m.pro_tips
FROM medium_questions m JOIN de_mobile_app."topics-legacy" t ON t.name='SQL Coding Practice'
JOIN de_mobile_app."subtopics-legacy" s ON s.topic_id=t.id AND s.name='Medium'
WHERE true
ON CONFLICT (question_id) DO UPDATE SET type=EXCLUDED.type,difficulty=EXCLUDED.difficulty,
 question=EXCLUDED.question,explaination=EXCLUDED.explaination,
 interview_note=EXCLUDED.interview_note,interview_tips=EXCLUDED.interview_tips,pro_tips=EXCLUDED.pro_tips;
INSERT INTO de_mobile_app."quiz-answer" (option_id,question_id,"order",option_text,is_correct)
SELECT option_id,question_id,position,option_text,is_correct FROM medium_answers
ON CONFLICT (option_id) DO UPDATE SET "order"=EXCLUDED."order",option_text=EXCLUDED.option_text,is_correct=EXCLUDED.is_correct;

DO $postcheck$
DECLARE v_topic bigint; v_medium bigint;
BEGIN
 SELECT id INTO v_topic FROM de_mobile_app."topics-legacy" WHERE name='SQL Coding Practice';
 SELECT id INTO v_medium FROM de_mobile_app."subtopics-legacy" WHERE topic_id=v_topic AND name='Medium';
 IF (SELECT count(*) FROM de_mobile_app."quiz-question" q WHERE q.topic=v_topic AND q.sub_topics=v_medium)<>12
    OR (SELECT count(*) FROM medium_answers m JOIN de_mobile_app."quiz-answer" a ON a.option_id::text=m.option_id
        WHERE a.question_id::text=m.question_id AND a.option_text=m.option_text
          AND a.is_correct=m.is_correct AND a."order"=m.position)<>48
    OR EXISTS (SELECT 1 FROM old_medium_ids o JOIN de_mobile_app."quiz-question" q ON q.question_id::text=o.question_id) THEN
   RAISE EXCEPTION 'Medium replacement verification failed'; END IF;
END $postcheck$;
COMMIT;
"""
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: replaced 10 with {len(items)} Medium questions")
