"""Reframe the 12 Medium challenges around thinking steps and BigQuery GoogleSQL."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OLD = ROOT / "supabase/migrations/20260928220000_replace_sql_coding_medium_with_12.sql"
OUT = ROOT / "supabase/migrations/20260928230000_replace_sql_coding_medium_bigquery_reasoning.sql"
old_sql = OLD.read_text(encoding="utf-8")
start = old_sql.index("$medium$") + len("$medium$")
end = old_sql.index("$medium$", start)
items = json.loads(old_sql[start:end])

# (thinking prompt, choices, correct index, complete GoogleSQL solution,
#  why the other reasoning paths fail, common mistake, practical use)
specs = [
    (
        "Before writing the pivot, how should you align names across roles?",
        ["Assign ROW_NUMBER across all members ordered by name, then group equal row numbers and pivot by role.",
         "Assign ROW_NUMBER within each role ordered by member_name, then group by role and select the first name.",
         "Assign ROW_NUMBER separately inside each role, then group equal row numbers and conditionally select each role's name.",
         "Assign ROW_NUMBER within each role ordered by member_name, then join roles using member_name rather than row number."], 2,
        """WITH ranked AS (
  SELECT member_name, role,
         ROW_NUMBER() OVER (PARTITION BY role ORDER BY member_name) AS rn
  FROM team_members
)
SELECT MAX(IF(role='Frontend',member_name,NULL)) AS frontend,
       MAX(IF(role='Backend',member_name,NULL)) AS backend,
       MAX(IF(role='DevOps',member_name,NULL)) AS devops,
       MAX(IF(role='QA',member_name,NULL)) AS qa
FROM ranked GROUP BY rn ORDER BY rn;""",
        "A ranks the combined list, so role positions do not align; B returns one row per role rather than parallel rows; D matches names instead of their positions.",
        "Don't rank all employees together; each role needs its own alphabetical sequence.",
        "Test roles with different headcounts; later rows for shorter roles should be NULL."
    ),
    (
        "What grain should you establish before joining the four child tables?",
        ["LEFT JOIN all four raw child tables, then COUNT each child ID at hub grain.",
         "Count distinct IDs in each child table at hub grain, then INNER JOIN the summaries to hubs.",
         "LEFT JOIN the four child tables and use SUM(IF(child_id IS NOT NULL,1,0)) for each level.",
         "Count distinct IDs in each child table at hub grain, then LEFT JOIN those small summaries to hubs."], 3,
        """WITH rl AS (SELECT hub_code, COUNT(DISTINCT lead_id) n FROM regional_leads GROUP BY hub_code),
am AS (SELECT hub_code, COUNT(DISTINCT area_id) n FROM area_managers GROUP BY hub_code),
bm AS (SELECT hub_code, COUNT(DISTINCT branch_id) n FROM branch_managers GROUP BY hub_code),
dr AS (SELECT hub_code, COUNT(DISTINCT driver_id) n FROM drivers GROUP BY hub_code)
SELECT h.hub_code,h.lead_manager,
       COALESCE(rl.n,0) AS regional_lead_count,
       COALESCE(am.n,0) AS area_manager_count,
       COALESCE(bm.n,0) AS branch_manager_count,
       COALESCE(dr.n,0) AS driver_count
FROM hubs h LEFT JOIN rl USING (hub_code) LEFT JOIN am USING (hub_code)
LEFT JOIN bm USING (hub_code) LEFT JOIN dr USING (hub_code)
ORDER BY h.hub_code;""",
        "A and C still count duplicate raw rows created by join fan-out; B loses hubs without a child in every table.",
        "Don't count joined raw hierarchy rows as though each child appears once.",
        "Create a hub with no drivers and verify it remains with a driver count of zero."
    ),
    (
        "Which checks should you apply, and in what order, to label each category?",
        ["Check parent_id IS NULL for Root, then use a correlated child-existence test for Inner, otherwise Leaf.",
         "Check for a child first and label such rows Inner; then label parent_id IS NULL rows Root; otherwise Leaf.",
         "Mark parent_id IS NULL rows Root, then use a LEFT JOIN to children and label a row Leaf when a child ID is present.",
         "Mark parent_id IS NULL rows Root, then label any category ID appearing in parent_id as Leaf; otherwise Inner."], 0,
        """SELECT c.category_id,
       CASE WHEN c.parent_id IS NULL THEN 'Root'
            WHEN EXISTS (SELECT 1 FROM ticket_categories child
                         WHERE child.parent_id=c.category_id) THEN 'Inner'
            ELSE 'Leaf' END AS category_type
FROM ticket_categories c ORDER BY c.category_id;""",
        "B labels roots that have children Inner because it checks children first; C reverses Inner and Leaf; D also reverses the child-existence labels.",
        "Don't decide Leaf from the presence of a parent; check whether the node has children.",
        "Test one root, one inner category, and one leaf before trusting the query."
    ),
    (
        "What exactly should one counted achievement represent?",
        ["A distinct high-difficulty assessment whose learner's best score reaches 100.",
         "A distinct high-difficulty assessment with at least one submission equal to its configured max_score.",
         "Each perfect submission on a high-difficulty assessment, counting repeat perfect attempts separately.",
         "A distinct assessment with a submission at its configured max_score, regardless of its difficulty level."], 1,
        """SELECT u.user_id,u.user_name
FROM users u JOIN submissions s ON s.user_id=u.user_id
JOIN assessments a ON a.assessment_id=s.assessment_id
JOIN difficulty d ON d.difficulty_level=a.difficulty_level
WHERE a.difficulty_level>=4 AND s.score=d.max_score
GROUP BY u.user_id,u.user_name
HAVING COUNT(DISTINCT a.assessment_id)>=2
ORDER BY COUNT(DISTINCT a.assessment_id) DESC,u.user_id;""",
        "A assumes a universal 100-point maximum; C counts repeat perfect attempts; D omits the high-difficulty filter.",
        "Don't count perfect retries to one assessment as separate accomplishments.",
        "Three perfect attempts on one assessment still represent one distinct completed assessment."
    ),
    (
        "What calculation do the two specified corner points require?",
        ["Add the absolute latitude difference and absolute longitude difference, then round.",
         "Add (MIN(latitude)-MAX(latitude)) and (MAX(longitude)-MIN(longitude)), then take one absolute value.",
         "Take MAX(latitude+longitude)-MIN(latitude+longitude).",
         "Take the square root of the sum of squared latitude and longitude differences."], 0,
        """SELECT ROUND(ABS(MAX(latitude)-MIN(latitude))
           + ABS(MAX(longitude)-MIN(longitude)),4) AS manhattan_distance
FROM warehouses;""",
        "B can cancel differences that point in opposite directions; C selects extrema of the sum, not each axis separately; D calculates straight-line (Euclidean) distance.",
        "Don't confuse Manhattan distance with straight-line distance.",
        "These latitude/longitude values are treated as planar coordinates in the exercise, not kilometres on Earth."
    ),
    (
        "How should you turn the two coordinate differences into straight-line distance?",
        ["Add the absolute coordinate differences before squaring the sum.",
         "Square both differences and add them, then round without taking a root.",
         "Take the square root of the squared latitude difference minus the squared longitude difference.",
         "Take the square root of the sum of squared latitude and longitude differences."], 3,
        """SELECT ROUND(SQRT(POW(CAST(MAX(latitude)-MIN(latitude) AS FLOAT64),2)
                + POW(CAST(MAX(longitude)-MIN(longitude) AS FLOAT64),2)),4)
       AS euclidean_distance
FROM warehouses;""",
        "A squares the whole sum and introduces an unwanted cross-term; B returns squared distance; C subtracts rather than adds the two squared components.",
        "Don't stop after summing the squares; Euclidean distance needs the square root.",
        "Use geospatial functions for real Earth-surface distance; this is planar interview math."
    ),
    (
        "How do you handle both odd and even row counts without treating the median as a mean?",
        ["AVG(latitude) over the middle two ordered values, even when the non-NULL row count is odd.",
         "Use APPROX_QUANTILES(latitude,2)[OFFSET(1)] and treat it as an exact median.",
         "Order non-NULL values and select the row at FLOOR(COUNT(*)/2) using a zero-based offset for every row count.",
         "Use BigQuery PERCENTILE_CONT(latitude,0.5) OVER(), then return one rounded value."], 3,
        """WITH med AS (
  SELECT PERCENTILE_CONT(latitude,0.5) OVER() AS median_value
  FROM warehouses WHERE latitude IS NOT NULL
)
SELECT ROUND(MAX(median_value),4) AS median_latitude FROM med;""",
        "A averages two positions even for odd counts; B is approximate; C returns only one middle value for even counts and can misindex odd counts.",
        "Don't use AVG of the whole column for a median or present an approximate quantile as exact.",
        "Test both [1,2,9] and [1,2,8,9]; their medians are 2 and 5."
    ),
    (
        "How can you identify campaign boundaries before pairing dates?",
        ["Sort tasks by start_date and merge tasks whenever the next starts within one day of the previous end.",
         "Find starts that are not any prior task end and ends that are not any later task start; sort and pair the two boundary lists.",
         "Find starts with no prior end, then pair each with the earliest later task end.",
         "Find starts with no prior end and ends with no later start, then pair each start with the latest later end."], 1,
        """WITH starts AS (
  SELECT s.start_date,ROW_NUMBER() OVER(ORDER BY s.start_date) rn
  FROM task_sprints s WHERE NOT EXISTS
    (SELECT 1 FROM task_sprints p WHERE p.end_date=s.start_date)
), ends AS (
  SELECT e.end_date,ROW_NUMBER() OVER(ORDER BY e.end_date) rn
  FROM task_sprints e WHERE NOT EXISTS
    (SELECT 1 FROM task_sprints n WHERE n.start_date=e.end_date)
)
SELECT s.start_date,e.end_date FROM starts s JOIN ends e USING(rn)
ORDER BY DATE_DIFF(e.end_date,s.start_date,DAY),s.start_date;""",
        "A merges merely adjacent dates rather than exactly linked endpoints; C stops at the first task's end; D can pair a start with an end from a different chain.",
        "Don't infer a campaign merely from calendar proximity; the task links equal end/start dates.",
        "This boundary-pair method assumes simple non-overlapping, non-branching chains."
    ),
    (
        "Which IDs should each salary-table join use before comparing pay?",
        ["Join salaries twice, but use the engineer's ID for both salary aliases.",
         "Join salaries on the two correct IDs, but retain mentors with salary equal to the engineer's.",
         "Join one salary alias to the engineer and another to mentor_id; compare mentor salary > engineer salary.",
         "Join each salary alias on the correct ID, but compare the engineer's salary to the mentor's using the reversed inequality."], 2,
        """SELECT e.name FROM engineers e
JOIN mentors m ON m.engineer_id=e.id
JOIN salaries own ON own.engineer_id=e.id
JOIN salaries mentor ON mentor.engineer_id=m.mentor_id
WHERE mentor.salary>own.salary
ORDER BY mentor.salary,e.id;""",
        "A compares the engineer's salary with itself; B incorrectly includes equal pay; D selects engineers paid more than their mentors.",
        "Don't reuse the junior's ID for the mentor salary alias.",
        "An equal-paid mentor must not qualify because the comparison is strictly greater."
    ),
    (
        "What extra condition prevents a route row from matching itself?",
        ["Join reversed coordinates, keep x<=y, and deduplicate, but do not require different route IDs.",
         "Join reversed coordinates, require distinct route IDs, keep x<=y, and deduplicate output.",
         "Join reversed coordinates with distinct route IDs and keep x<y before deduplicating.",
         "Join reversed coordinates with distinct route IDs, keep x<=y, but return every matching pair without deduplication."], 1,
        """SELECT DISTINCT a.x,a.y FROM route_points a JOIN route_points b
  ON a.x=b.y AND a.y=b.x AND a.route_id<>b.route_id
WHERE a.x<=a.y ORDER BY x,y;""",
        "A lets one (4,4) row match itself; C loses valid pairs such as two separate (4,4) rows; D repeats outputs when duplicate reciprocal rows exist.",
        "Don't let one self-symmetric row act as its own partner; require two different IDs.",
        "Test one (4,4), two (4,4), and reciprocal (2,5)/(5,2)."
    ),
    (
        "At which grain should you aggregate before calculating a student's total?",
        ["First keep the maximum score per student and assignment, then sum those maxima per student.",
         "Sum scores per student and assignment first, then add the assignment totals per student.",
         "Keep one maximum score per assignment across all students, then sum by student.",
         "Keep each student's latest attempt per assignment, then sum those latest scores."], 0,
        """WITH best AS (
  SELECT student_id,assignment_id,MAX(score) AS best_score
  FROM submissions GROUP BY student_id,assignment_id
)
SELECT s.student_id,s.name,SUM(b.best_score) AS total_score
FROM students s JOIN best b USING(student_id)
GROUP BY s.student_id,s.name HAVING SUM(b.best_score)>0
ORDER BY total_score DESC,s.student_id;""",
        "B double-counts retries before aggregation; C selects a global winner for each assignment rather than each student's best; D can replace a better earlier attempt with a weaker later one.",
        "Don't sum submission rows before collapsing retries to one best score per assignment.",
        "Scores 50 and 80 for one assignment contribute 80, not 130."
    ),
    (
        "What sequence of steps produces a correct, ordered BigQuery string?",
        ["Generate 2..100, exclude divisors in 2..n-1, then STRING_AGG numbers as text without ORDER BY.",
         "Generate 2..100, exclude divisors in 2..FLOOR(SQRT(n)), then STRING_AGG numbers as text ordered lexicographically.",
         "Generate 2..100, exclude n with a divisor in 2..FLOOR(SQRT(n)), then STRING_AGG numbers as text in numeric order.",
         "Generate 2..100, exclude n with a divisor in 2..FLOOR(SQRT(n)), then STRING_AGG numbers as text in descending numeric order."], 2,
        """WITH nums AS (
  SELECT n FROM UNNEST(GENERATE_ARRAY(2,100)) AS n
)
SELECT STRING_AGG(CAST(x.n AS STRING),'|' ORDER BY x.n) AS prime_sequence
FROM nums x
WHERE NOT EXISTS (
  SELECT 1
  FROM UNNEST(GENERATE_ARRAY(2,CAST(FLOOR(SQRT(x.n)) AS INT64))) AS d
  WHERE MOD(x.n,d)=0
);""",
        "A finds primes but leaves their concatenation order unspecified; B sorts text so 11 can precede 2; D produces the required primes in reverse order.",
        "Don't use GROUP_CONCAT in BigQuery or rely on unordered STRING_AGG output.",
        "Check that 2 is included, while 1, 9, 25, and 100 are excluded."
    ),
]
assert len(items) == len(specs) == 12
for item, spec in zip(items, specs):
    thinking, options, correct, solution, wrong, note, tip = spec
    base = item["question"].split("\n\nWhich approach gives the correct result?")[0]
    base = base.replace("In PostgreSQL,", "In BigQuery,")
    item["question"] = base + "\n\n" + thinking
    item["options"] = options
    item["correct"] = correct
    item["explaination"] = "Reasoning: " + options[correct] + "\n\nBigQuery GoogleSQL answer:\n" + solution.strip() + "\n\nWhy the other approaches fail: " + wrong
    item["interview_note"] = note
    item["pro_tips"] = tip
    assert len(options) == 4 and note.startswith("Don't ")
assert sorted(item["correct"] for item in items) == [0,0,0,1,1,1,2,2,2,3,3,3]

new_payload = json.dumps(items, ensure_ascii=False, indent=2)
assert "$medium$" not in new_payload
new_sql = old_sql[:start] + new_payload + old_sql[end:]
new_sql = new_sql.replace(
    "-- twelve original, PostgreSQL-correct practice MCQs based on supplied concepts.",
    "-- twelve reasoning-first, BigQuery GoogleSQL MCQs based on supplied concepts."
)
new_sql = new_sql.replace(
    "Pivoting, hierarchy queries, multi-table joins, geometry, medians, gaps and islands, and SQL generation",
    "BigQuery reasoning practice: pivots, hierarchies, joins, geometry, medians, gaps, and SQL generation"
)
OUT.write_text(new_sql, encoding="utf-8")
print(f"Wrote {OUT}: {len(items)} BigQuery reasoning-first Medium questions")
