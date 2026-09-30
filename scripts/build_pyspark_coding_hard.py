"""Build ten original Hard PySpark coding-practice MCQs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIUM_SQL = ROOT / "supabase/migrations/20260929050000_seed_pyspark_coding_practice_medium.sql"
OUT = ROOT / "supabase/migrations/20260929060000_seed_pyspark_coding_practice_hard.sql"
items = []


def add(question, options, correct, why, code, wrong, note, tip):
    assert len(options) == len(set(options)) == 4 and 0 <= correct < 4
    assert note.startswith("Don't ")
    items.append({
        "id": f"pyspark_coding_hard_20260929_{len(items)+1:02d}", "level": "hard",
        "question": question, "options": options, "correct": correct,
        "explaination": f"Reasoning: {why}\n\nPySpark solution:\n{code}\n\nWhy the other options fail: {wrong}",
        "interview_note": note, "pro_tips": tip,
    })


add(
    "A toppings DataFrame has unique topping_name values. Generate every unordered three-topping pizza exactly once. Which three-way PySpark join condition is sufficient?",
    ["Cross join aliases p1, p2, p3, then filter p1.name < p2.name and p2.name < p3.name.",
     "Cross join aliases p1, p2, p3, then filter that all three topping names are pairwise unequal.",
     "Join p1 to p2 on equal names, then join p3 where its name differs from the first two names.",
     "Cross join aliases p1, p2, p3, sort each resulting row by name, then call distinct on all columns."], 0,
    "A strict increasing chain chooses one canonical permutation of each three-element set and also prevents repeated toppings.",
    "p1, p2, p3 = (t.alias(x) for x in ('p1','p2','p3'))\ncombos = (p1.crossJoin(p2).crossJoin(p3)\n .filter((F.col('p1.topping_name') < F.col('p2.topping_name')) &\n         (F.col('p2.topping_name') < F.col('p3.topping_name'))))",
    "B retains six permutations per set. C requires two equal toppings. D is expensive and distinct cannot collapse permutations unless the three columns are first canonicalized into one value.",
    "Don't use a three-way Cartesian product without estimating n choose 3 output growth.",
    "For large catalogs, generate combinations outside Spark or use indexed range joins only when the output itself is manageable."
)
add(
    "After producing canonical aliases p1 < p2 < p3, create pizza as comma-separated names and sort total_cost descending, then pizza ascending. Which projection and order are correct?",
    ["Use concat(p1.name,p2.name,p3.name), sum costs, then orderBy(total_cost.asc(), pizza.desc()).",
     "Use concat_ws(',',p1.name,p2.name,p3.name), sum costs, then orderBy(total_cost.desc(), pizza.asc()).",
     "Use collect_list(name), average costs, then orderBy(pizza.asc(), total_cost.desc()).",
     "Use array_join(array(p3.name,p2.name,p1.name),','), sum costs, then orderBy(total_cost.desc())."], 1,
    "concat_ws inserts the delimiter, the canonical alias order is already alphabetical, and the two requested sort directions are explicit.",
    "result = combos.select(\n F.concat_ws(',', 'p1.topping_name','p2.topping_name','p3.topping_name').alias('pizza'),\n (F.col('p1.cost')+F.col('p2.cost')+F.col('p3.cost')).alias('total_cost')\n).orderBy(F.col('total_cost').desc(), F.col('pizza').asc())",
    "A omits separators and reverses both sort directions. C uses the wrong aggregation and ordering. D reverses the name order and omits the alphabetical tiebreaker.",
    "Don't assume an earlier DataFrame order survives a later transformation; specify the final orderBy explicitly.",
    "Use DecimalType for ingredient costs when exact currency totals are required."
)
add(
    "For each monthly signup cohort, calculate Month-1 retention as users whose end_date is null or on/after add_months(cohort_start,1), divided by cohort size. Which aggregation avoids integer truncation?",
    ["Sum the active Boolean cast to int, divide by count('*'), multiply by F.lit(100.0), and round to two decimals.",
     "Count end_date, divide by count('*') using integer literals, and round before multiplying by one hundred.",
     "Filter to active subscriptions first, count rows, and divide by the filtered count within each cohort.",
     "Count distinct end_date values, divide by cohort size, and multiply by one hundred after casting to date."], 0,
    "The conditional sum supplies the numerator while a floating literal preserves fractional division; the denominator must include the full cohort.",
    "active = F.when(F.col('end_date').isNull() |\n F.col('end_date').geq(F.add_months('cohort_start',1)), 1).otherwise(0)\nresult = base.groupBy('cohort_month').agg(\n F.count('*').alias('cohort_size'), F.sum(active).alias('m1_active')\n).withColumn('m1_pct', F.round(F.col('m1_active')*100.0/F.col('cohort_size'),2))",
    "B counts ended-date values rather than retained users. C destroys the original denominator. D counts date values, not users meeting the retention rule.",
    "Don't filter away non-retained members before computing a cohort-rate denominator.",
    "Clarify whether an end date exactly on the checkpoint counts as active; this implementation uses an inclusive boundary."
)
add(
    "Compute daily trip cancellation rate only when both client and driver are unbanned. Users contains one row per users_id. Which join plan enforces both roles correctly?",
    ["Join Users once where client_id equals users_id, then accept the row if either client or driver is unbanned.",
     "Alias Users as client and driver, inner join each role on its own ID with banned='No', then aggregate cancelled statuses.",
     "Left join Users twice, replace missing banned flags with 'No', then aggregate every trip in the requested dates.",
     "Join Users where users_id is in client_id or driver_id, group by trip ID, then keep trips with at least one match."], 1,
    "The two aliases represent independent foreign-key roles; inner joins with both unbanned predicates exclude any trip whose client or driver is banned or missing.",
    "c, d = users.alias('c'), users.alias('d')\neligible = (trips.alias('t')\n .join(c, (F.col('t.client_id')==F.col('c.users_id')) & (F.col('c.banned')=='No'))\n .join(d, (F.col('t.driver_id')==F.col('d.users_id')) & (F.col('d.banned')=='No')))\nresult = eligible.groupBy('request_at').agg(\n F.round(F.avg(F.col('status').startswith('cancelled').cast('double')),2).alias('rate'))",
    "A never validates the driver independently. C turns missing users into eligible users. D accepts a match for only one role and can duplicate trips.",
    "Don't join one user alias to two semantic roles and assume both role constraints were checked.",
    "Validate user-key uniqueness first, because duplicate dimension keys inflate both numerator and denominator."
)
add(
    "Identify users with activity on at least three consecutive calendar days, ignoring multiple events on the same day. Which PySpark gaps-and-islands method is correct?",
    ["Deduplicate user/date, set island_key=date_sub(date,row_number per user), group by user/island_key, and keep counts >=3.",
     "Order every raw event per user, compare its timestamp with lag(timestamp,2), and keep differences of at least two days.",
     "Group raw events by user, count all rows, and retain users with at least three events in any date range.",
     "Deduplicate dates globally, calculate row_number without partitioning by user, and retain groups containing three users."], 0,
    "For consecutive dates, subtracting a per-user row number from each distinct date yields a constant island key across uninterrupted runs.",
    "daily = df.select('user_id',F.to_date('login_date').alias('d')).distinct()\nw = Window.partitionBy('user_id').orderBy('d')\nislands = daily.withColumn('_k', F.date_sub('d',F.row_number().over(w)))\nresult = islands.groupBy('user_id','_k').count().filter('count >= 3').select('user_id').distinct()",
    "B keeps duplicate-day events and uses an imprecise at-least comparison. C does not test adjacency. D mixes different users into the same sequence.",
    "Don't count raw events when the streak definition is based on distinct calendar days.",
    "The island-key technique naturally supports streak lengths beyond three and exposes each streak's start and end."
)
add(
    "For each observed activity date, count distinct users active in [date-6,date]. Which method gives exact calendar-day semantics without using a row-count window?",
    ["For each date, use rowsBetween(-6,0) over activity rows and countDistinct user_id as a window aggregate.",
     "Create distinct current dates, range-join activity where activity_date is between date_sub(curr_date,6) and curr_date, then group.",
     "Group by activity date, count distinct users, then compute a seven-row moving sum over the daily counts.",
     "Convert dates to weekday numbers, partition by weekday, and count users in the current and six preceding partitions."], 1,
    "A non-equi range join evaluates the true seven-calendar-day interval and distinct-counts users once per current date.",
    "dates = activity.select(F.to_date('activity_date').alias('curr_date')).distinct()\na = activity.select('user_id',F.to_date('activity_date').alias('act_date'))\nresult = (dates.join(a, a.act_date.between(F.date_sub(dates.curr_date,6),dates.curr_date))\n .groupBy('curr_date').agg(F.countDistinct('user_id').alias('active_7d')))",
    "A counts rows rather than elapsed days and distinct window aggregates have limitations. C double-counts users active on several days. D confuses recurring weekdays with a trailing interval.",
    "Don't sum daily distinct counts to obtain multi-day distinct users; repeat users would be counted multiple times.",
    "For scale, consider expanding each distinct user-day into seven contribution dates and aggregating instead of a broad range join."
)
add(
    "Return every employee whose salary is among the top three distinct salaries in that employee's department, including ties. Which ranking is appropriate?",
    ["row_number over department ordered by salary descending, filtered to row_number <= 3.",
     "rank over department ordered by salary descending, filtered to rank <= 3.",
     "dense_rank over department ordered by salary descending, filtered to dense_rank <= 3.",
     "ntile(3) over department ordered by salary descending, filtered to tile = 1."], 2,
    "dense_rank gives equal salaries the same rank and advances by one for the next distinct salary, so exactly three distinct salary levels are included.",
    "w = Window.partitionBy('department_id').orderBy(F.col('salary').desc())\nresult = (employees.withColumn('_r',F.dense_rank().over(w))\n .filter(F.col('_r') <= 3).drop('_r'))",
    "A limits rows and can split ties. B leaves rank gaps after ties and may return fewer than three distinct levels. D divides rows into approximate buckets rather than salary levels.",
    "Don't use row_number for top-N distinct values when all ties must be retained.",
    "Null ordering should be stated explicitly if salary can be null."
)
add(
    "Calculate year-over-year GDP growth per country as (current-previous)/previous*100. Return null when there is no previous row or previous GDP is zero. Which expression is safe?",
    ["Use lag(gdp) by country/year, then always divide the difference by the lag value and replace infinities afterward.",
     "Use lead(gdp) by country/year, then divide the next-current difference by the current value for every row.",
     "Use lag(gdp) by country/year, then when lag is non-null and nonzero compute the percentage; otherwise return null.",
     "Use first(gdp) by country, then divide every year's difference from the first year by the current year's GDP."], 2,
    "lag supplies the prior observed value and an explicit zero guard prevents invalid division while retaining rows with a null result.",
    "w = Window.partitionBy('country_code').orderBy('year')\nbase = df.withColumn('_prev',F.lag('gdp_value').over(w))\nresult = base.withColumn('yoy_pct', F.when(\n F.col('_prev').isNotNull() & (F.col('_prev') != 0),\n F.round((F.col('gdp_value')-F.col('_prev'))/F.col('_prev')*100.0,2)))",
    "A performs unsafe division. B calculates forward change rather than year-over-year for the current row. D compares every year with the first and uses the wrong denominator.",
    "Don't assume the previous observed row is the previous calendar year when years can be missing.",
    "Add a year-gap check when YoY must require current_year = previous_year + 1."
)
add(
    "Measure exact Day-1 and Day-7 retention by signup date. Activity may contain many events per user per day. Which preprocessing prevents join multiplication from corrupting cohort metrics?",
    ["Keep all activity events, inner join on user_id, and use count(*) for both the cohort denominator and retained numerators.",
     "Deduplicate activity to user_id/activity_date, left join to signups by user_id, and count distinct user IDs conditionally.",
     "Aggregate activity only by date, join date totals to signup dates, and divide each activity total by total signup rows.",
     "Deduplicate signups by signup date only, cross join activity days, and filter differences equal to one or seven."], 1,
    "One user-day row limits join expansion, a left join preserves users without later activity, and distinct conditional counts protect the denominator and checkpoints.",
    "a = activity.select('user_id',F.to_date('activity_date').alias('act_dt')).distinct()\nj = signups.join(a,'user_id','left')\nresult = j.groupBy('signup_dt').agg(\n F.countDistinct('user_id').alias('cohort_size'),\n F.countDistinct(F.when(F.datediff('act_dt','signup_dt')==1,F.col('user_id'))).alias('d1'),\n F.countDistinct(F.when(F.datediff('act_dt','signup_dt')==7,F.col('user_id'))).alias('d7'))",
    "A drops non-returners and counts repeated events. C loses user-level cohort membership. D removes users sharing a signup date and creates a large Cartesian product.",
    "Don't use an inner join for retention when non-returning cohort members belong in the denominator.",
    "Define the timezone used to derive activity dates, especially when events arrive as UTC timestamps."
)
add(
    "A user can have several subscription rows, but cohort retention is defined per unique user signup. What must be established before calculating monthly percentages?",
    ["Choose one canonical cohort_start per user, create one user-level cohort row, then test retention against user-level activity or status.",
     "Keep every subscription row, count rows as cohort size, and divide retained subscription rows by that same row count.",
     "Choose the latest end_date per cohort without grouping by user, then apply that date to all users in the cohort.",
     "Remove every user with more than one subscription so each remaining cohort member contributes exactly one row."], 0,
    "The metric's grain is user, so cohort assignment and denominator must first be normalized to one canonical row per user.",
    "w = Window.partitionBy('user_id').orderBy(F.col('signup_date').asc())\nusers = (subscriptions.withColumn('_rn',F.row_number().over(w))\n .filter('_rn = 1').drop('_rn')\n .withColumn('cohort_start',F.trunc('signup_date','month'))) ",
    "B measures subscription retention rather than user retention. C applies one person's status to others. D biases the population by excluding valid multi-subscription users.",
    "Don't calculate a percentage until the numerator and denominator grain are explicitly identical.",
    "Canonical cohort rules—first signup, latest signup, or reactivation cohort—are business definitions, not implementation details."
)

assert len(items) == 10
assert sorted(x["correct"] for x in items) == [0,0,0,0,1,1,1,1,2,2]
assert all(max(map(len,x["options"])) - min(map(len,x["options"])) <= 30 for x in items)

source = MEDIUM_SQL.read_text(encoding="utf-8")
prefix, old_payload, suffix = source.split("$pyspark_medium$")
assert json.loads(old_payload) and "pyspark_medium_questions" in suffix
prefix = prefix.replace("Medium quiz", "Hard quiz").replace("pyspark_medium", "pyspark_hard")
suffix = suffix.replace("pyspark_medium", "pyspark_hard")
suffix = suffix.replace("Expected one Medium subtopic", "Expected one Hard subtopic")
prefix = prefix.replace("'Medium'", "'Hard'").replace(
    "PySpark windows, complex types, pivots, broadcast joins, and collection expressions",
    "Advanced PySpark cohorts, range joins, gaps and islands, multi-role joins, and ranking",
)
suffix = suffix.replace("'Medium'", "'Hard'").replace("PySpark Medium", "PySpark Hard")
prefix = prefix.replace("$pyspark_medium$", "$pyspark_hard$")
suffix = suffix.replace("$pyspark_medium$", "$pyspark_hard$")
sql = prefix + "$pyspark_hard$" + json.dumps(items,ensure_ascii=False,indent=2) + "$pyspark_hard$" + suffix
assert "pyspark_medium" not in sql and "'Medium'" not in sql
OUT.write_text(sql,encoding="utf-8")
print(f"Wrote {OUT}: 10 PySpark Hard questions / 40 options")
