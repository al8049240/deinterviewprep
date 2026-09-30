"""Replace the ten Hard SQL Coding Practice questions with reasoning-first BigQuery MCQs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIUM = ROOT / "supabase/migrations/20260928230000_replace_sql_coding_medium_bigquery_reasoning.sql"
OUT = ROOT / "supabase/migrations/20260929000000_replace_sql_coding_hard_bigquery_reasoning.sql"
items = []

def add(title, scenario, thinking, options, correct, solution, wrong, note, tip):
    assert len(options) == 4 and note.startswith("Don't ")
    n = len(items)+1
    items.append({
        "id": f"sql_coding_hard_20260929_{n:02d}",
        "question": title + "\n\n" + scenario + "\n\n" + thinking,
        "options": options, "correct": correct,
        "explaination": "Reasoning: " + options[correct] + "\n\nBigQuery GoogleSQL answer:\n" + solution.strip() + "\n\nWhy the other approaches fail: " + wrong,
        "interview_note": note, "pro_tips": tip,
    })

add("Campaign metrics without fan-out",
    "campaigns(campaign_id,campaign_name) has ad_groups(ad_group_id,campaign_id). Each ad group has many ad_clicks(clicks,unique_clicks) and order_conversions(conversions,conversion_value). Return summed campaign metrics, excluding campaigns with zero tracked metrics. Here unique_clicks is an additive count recorded per ad group, not distinct users across the whole campaign.",
    "What grain should each independent child table reach before the joins?",
    ["Aggregate clicks by campaign_id but conversions by ad_group_id, then join both summaries through ad_groups.",
     "Aggregate clicks and conversions separately at ad_group_id, LEFT JOIN both summaries, then roll up to campaign_id.",
     "Join the raw child tables, then use SUM(DISTINCT metric) to cancel duplicated metric values.",
     "Aggregate both child tables at ad_group_id, then INNER JOIN each summary to ad_groups."], 1,
    """WITH click_totals AS (
  SELECT ad_group_id,SUM(clicks) clicks,SUM(unique_clicks) unique_clicks
  FROM ad_clicks GROUP BY ad_group_id
), conversion_totals AS (
  SELECT ad_group_id,SUM(conversions) conversions,
         SUM(conversion_value) conversion_value
  FROM order_conversions GROUP BY ad_group_id
), campaign_totals AS (
  SELECT c.campaign_id,c.campaign_name,
         COALESCE(SUM(ct.clicks),0) total_clicks,
         COALESCE(SUM(ct.unique_clicks),0) total_unique_clicks,
         COALESCE(SUM(cv.conversions),0) total_conversions,
         COALESCE(SUM(cv.conversion_value),0) total_conversion_value
  FROM campaigns c LEFT JOIN ad_groups ag USING(campaign_id)
  LEFT JOIN click_totals ct USING(ad_group_id)
  LEFT JOIN conversion_totals cv USING(ad_group_id)
  GROUP BY c.campaign_id,c.campaign_name
)
SELECT * FROM campaign_totals
WHERE total_clicks+total_unique_clicks+total_conversions+total_conversion_value>0
ORDER BY campaign_id;""",
    "A repeats the campaign-level click total once per ad group; C collapses genuinely separate rows that share the same metric value; D loses ad groups that have only clicks or only conversions.",
    "Don't SUM metrics after joining two raw one-to-many tables to the same parent.",
    "If an ad group has 3 click rows and 2 conversion rows, a raw join produces 6 combined rows."
)

add("Daily login streaks and daily leaders",
    "For each date from 2026-03-01 through 2026-03-14, report (1) how many users logged in on every day since March 1 and (2) the day's most frequent user, breaking ties by lowest user_id. Tables: user_logins(login_id,user_id,login_date DATE), users(user_id,user_name).",
    "How do you separate continuous attendance from daily login frequency?",
    ["Count DISTINCT login dates up to each report date, including dates before March 1, and compare with elapsed sprint days.",
     "Count login rows since March 1 and compare with elapsed sprint days; rank the top user separately for each date.",
     "Generate report dates, deduplicate attendance within the sprint, compare attended dates with elapsed days, and separately rank login counts per date.",
     "Check only whether each user's immediately previous login was yesterday, then rank the daily leader."], 2,
    """WITH days AS (
  SELECT d AS log_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2026-03-01',DATE '2026-03-14')) d
), attendance AS (
  SELECT DISTINCT user_id,login_date FROM user_logins
  WHERE login_date BETWEEN DATE '2026-03-01' AND DATE '2026-03-14'
), candidate_days AS (
  SELECT d.log_date,u.user_id,COUNT(a.login_date) days_attended
  FROM days d CROSS JOIN (SELECT DISTINCT user_id FROM attendance) u
  LEFT JOIN attendance a ON a.user_id=u.user_id AND a.login_date<=d.log_date
  GROUP BY d.log_date,u.user_id
), streaks AS (
  SELECT log_date,COUNTIF(days_attended=DATE_DIFF(log_date,DATE '2026-03-01',DAY)+1)
         AS consecutive_users FROM candidate_days GROUP BY log_date
), daily_counts AS (
  SELECT login_date,user_id,COUNT(*) total_logins FROM user_logins
  WHERE login_date BETWEEN DATE '2026-03-01' AND DATE '2026-03-14'
  GROUP BY login_date,user_id
), daily_top AS (
  SELECT * FROM daily_counts
  QUALIFY ROW_NUMBER() OVER(PARTITION BY login_date ORDER BY total_logins DESC,user_id)=1
)
SELECT d.log_date,COALESCE(s.consecutive_users,0) consecutive_users,
       t.user_id,u.user_name
FROM days d LEFT JOIN streaks s USING(log_date)
LEFT JOIN daily_top t ON t.login_date=d.log_date
LEFT JOIN users u ON u.user_id=t.user_id
ORDER BY d.log_date;""",
    "A lets earlier history mask a missed sprint day; B lets repeated same-day logins mask a gap; D proves only a two-day link, not attendance every day since March 1.",
    "Don't count activity before March 1 or repeated logins as extra attended days.",
    "Test a user who logged twice on day one but missed day two; their streak must end on day two."
)

add("Unique three-item gift baskets",
    "inventory(item_id,item_name,price) has unique item_id. List every set of exactly three distinct items once, regardless of item order, with total price.",
    "Which ordering rule removes permutations without losing combinations?",
    ["Join three copies with i1.item_id<i2.item_id and i2.item_id<i3.item_id.",
     "Join with i1.item_id<i2.item_id and i2.item_id<>i3.item_id, then select distinct triples.",
     "Require all three IDs to differ, then SELECT DISTINCT the ordered item columns.",
     "Use item_name instead of item_id for the two strict ordering comparisons."], 0,
    """SELECT i1.item_id AS item_1,i2.item_id AS item_2,i3.item_id AS item_3,
       i1.price+i2.price+i3.price AS total_price
FROM inventory i1 JOIN inventory i2 ON i1.item_id<i2.item_id
JOIN inventory i3 ON i2.item_id<i3.item_id
ORDER BY total_price DESC,item_1,item_2,item_3;""",
    "B still allows i3=i1 or an alternative ordering; C keeps permutations because (A,B,C) and (C,B,A) are distinct ordered rows; D can drop valid baskets when two different items share a name.",
    "Don't order by a potentially duplicated item name when item_id is the unique identity.",
    "For four items there should be exactly four three-item baskets."
)

add("Potential rapid duplicate charges",
    "transactions(transaction_id,user_id,amount,transaction_timestamp TIMESTAMP) logs charges. Flag a charge when the previous charge by the same user for the same amount occurred within 10 minutes; break timestamp ties by transaction_id.",
    "What partition, order, and time comparison do you need?",
    ["LAG within user_id only, then compare only consecutive charges that also have the same amount.",
     "Group by user_id and amount, then accept the group only if MAX(timestamp)-MIN(timestamp)<=10 minutes.",
     "LAG within (user_id,amount), but accept TIMESTAMP_DIFF(current,previous,MINUTE)<=10.",
     "LAG within (user_id,amount), order by timestamp and ID, then test TIMESTAMP_DIFF in seconds <=600."], 3,
    """WITH ordered AS (
  SELECT transaction_id,user_id,amount,transaction_timestamp,
         LAG(transaction_timestamp) OVER(
           PARTITION BY user_id,amount
           ORDER BY transaction_timestamp,transaction_id) AS previous_timestamp
  FROM transactions
)
SELECT transaction_id,user_id,amount,transaction_timestamp
FROM ordered
WHERE previous_timestamp IS NOT NULL
  AND TIMESTAMP_DIFF(transaction_timestamp,previous_timestamp,SECOND)<=600;""",
    "A misses a same-amount pair separated by a different-amount charge; B misses a rapid pair when the group's total span is long; C can accept a gap of 10 minutes 59 seconds because MINUTE differences truncate partial minutes.",
    "Don't compare only the earliest and latest charge in a group; a rapid pair may occur in the middle.",
    "A 10-minute boundary means 600 seconds; test exactly 600 and 601 seconds."
)

add("Server uptime from status events",
    "server_logs(server_id,event_time TIMESTAMP,status) has unique event times per server and alternates start and stop. Sum complete start-to-next-stop intervals as hours; ignore an unmatched final start.",
    "When should you filter to start rows relative to applying LEAD?",
    ["Filter to starts before LEAD, then treat the next retained event as the stop.",
     "Apply LEAD to the complete per-server event stream, then sum starts whose immediate next event is stop.",
     "Use MAX(stop event_time)-MIN(start event_time) for each server.",
     "Join each start to every later stop for the same server, then sum all matched durations."], 1,
    """WITH sequenced AS (
  SELECT server_id,status,event_time,
         LEAD(status) OVER(PARTITION BY server_id ORDER BY event_time) next_status,
         LEAD(event_time) OVER(PARTITION BY server_id ORDER BY event_time) next_time
  FROM server_logs
)
SELECT server_id,
       ROUND(SUM(TIMESTAMP_DIFF(next_time,event_time,SECOND))/3600.0,2) AS uptime_hours
FROM sequenced WHERE status='start' AND next_status='stop'
GROUP BY server_id;""",
    "A removes the stop rows LEAD needs; C includes downtime between sessions; D counts several stop events for one start and inflates uptime.",
    "Don't filter out stop events before pairing each start with its next event.",
    "Two one-hour sessions separated by a day should total two hours, not a day."
)

add("Reactivated users in June",
    "user_activity(user_id,activity_date DATE) records visits. A reactivated user visited in June 2026, did not visit in May 2026, and visited at least once before May. Count distinct reactivated users.",
    "Which three period tests distinguish reactivation from a brand-new user?",
    ["Require June activity, no May activity, and at least one activity date before May.",
     "Require June activity and no May activity, without checking for earlier history.",
     "Require June activity and a pre-May visit, without checking May activity.",
     "Require at least two active months and June as the latest active month."], 0,
    """SELECT COUNT(DISTINCT cur.user_id) AS reactivated_users
FROM user_activity cur
WHERE cur.activity_date>=DATE '2026-06-01'
  AND cur.activity_date<DATE '2026-07-01'
  AND NOT EXISTS (
    SELECT 1 FROM user_activity prev WHERE prev.user_id=cur.user_id
      AND prev.activity_date>=DATE '2026-05-01'
      AND prev.activity_date<DATE '2026-06-01')
  AND EXISTS (
    SELECT 1 FROM user_activity hist WHERE hist.user_id=cur.user_id
      AND hist.activity_date<DATE '2026-05-01');""",
    "B includes first-time June users; C includes users active in May; D can include May-to-June continuously active users because it never requires May absence.",
    "Don't label a first-time June user as reactivated; prior history is required.",
    "A user active in April and June but not May qualifies; a user active in May and June does not."
)

add("Consecutive tax-filing years",
    "tax_submissions(user_id,tax_year INT64) can contain duplicate filings for a year. Find stretches of at least three consecutive years per user and return each stretch's first year, last year, and length.",
    "What key stays constant within one uninterrupted sequence?",
    ["Compute tax_year-ROW_NUMBER() on raw filings before removing duplicate user-year rows.",
     "After deduplicating years, test MAX(year)-MIN(year)=COUNT(*)-1 once for each user's entire history.",
     "After DISTINCT user-year, compute tax_year-ROW_NUMBER() ordered by year within user, then group by that key.",
     "After deduplicating years, count LAG(year)=year-1 matches per user without resetting at gaps."], 2,
    """WITH years AS (
  SELECT DISTINCT user_id,tax_year FROM tax_submissions
), numbered AS (
  SELECT user_id,tax_year,
         tax_year-ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY tax_year) AS island_key
  FROM years
)
SELECT user_id,MIN(tax_year) first_year,MAX(tax_year) last_year,
       COUNT(*) consecutive_years
FROM numbered GROUP BY user_id,island_key
HAVING COUNT(*)>=3 ORDER BY user_id,first_year;""",
    "A lets duplicate years change row numbers and split a real streak; B misses a three-year streak when another part of the user's history has a gap; D combines consecutive pairs from separate runs into a false long streak.",
    "Don't calculate streaks on duplicate user-year rows; deduplicate before ROW_NUMBER.",
    "Years 2022,2023,2024 share one island key; 2026 begins another."
)

add("Managers with indirect reports",
    "employees(employee_id,manager_id) forms an acyclic hierarchy. Identify managers with at least ten distinct direct-or-indirect reports. The hierarchy is shallow enough for BigQuery's recursive CTE limit.",
    "What traversal is needed beyond a direct manager_id GROUP BY?",
    ["Self-join employees twice from each manager, covering direct and second-level reports, then stop.",
     "Recursively seed every employee as their own root and count all visited IDs, including the root, against the threshold of ten.",
     "Recursively follow each employee upward to managers, then count ancestor IDs per employee.",
     "Seed direct manager-report pairs, recursively follow reports to their reports, then count distinct descendants per root manager."], 3,
    """WITH RECURSIVE chain AS (
  SELECT manager_id AS root_manager,employee_id,
         [manager_id,employee_id] AS visited
  FROM employees WHERE manager_id IS NOT NULL
  UNION ALL
  SELECT c.root_manager,e.employee_id,
         ARRAY_CONCAT(c.visited,[e.employee_id])
  FROM chain c JOIN employees e ON e.manager_id=c.employee_id
  WHERE e.employee_id NOT IN UNNEST(c.visited)
)
SELECT root_manager AS manager_id,
       COUNT(DISTINCT employee_id) AS total_reports
FROM chain GROUP BY root_manager
HAVING COUNT(DISTINCT employee_id)>=10
ORDER BY total_reports DESC,manager_id;""",
    "A misses reports deeper than two levels; B counts the manager as one of their own reports and has an off-by-one threshold; C counts ancestors of an employee rather than descendants of a manager.",
    "Don't equate ten direct reports with ten total descendants.",
    "If A manages B and B manages C, C is an indirect report of A."
)

add("Ticket surge against three prior months",
    "support_tickets(account_id,ticket_id,created_at TIMESTAMP) feeds a monthly report. Flag an account-month only if its ticket count is more than 1.5 times the average of the previous three calendar months. Missing months count as zero; require all three prior months in the reporting span.",
    "What must happen before a ROWS-based moving average is meaningful?",
    ["Aggregate only observed months, then average ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING.",
     "Fill a complete account-month calendar with zeros, average the prior three rows excluding the current month, and require three prior months.",
     "Fill missing months, then average ROWS BETWEEN 3 PRECEDING AND CURRENT ROW.",
     "Fill missing months and average the prior three rows, but allow the first or second month to qualify from a partial baseline."], 1,
    """WITH monthly AS (
  SELECT account_id,DATE_TRUNC(DATE(created_at),MONTH) month_start,
         COUNT(*) ticket_count
  FROM support_tickets GROUP BY account_id,month_start
), bounds AS (
  SELECT account_id,MIN(month_start) first_month,MAX(month_start) last_month
  FROM monthly GROUP BY account_id
), calendar AS (
  SELECT b.account_id,m AS month_start FROM bounds b,
       UNNEST(GENERATE_DATE_ARRAY(b.first_month,b.last_month,INTERVAL 1 MONTH)) m
), filled AS (
  SELECT c.account_id,c.month_start,COALESCE(m.ticket_count,0) ticket_count
  FROM calendar c LEFT JOIN monthly m USING(account_id,month_start)
), scored AS (
  SELECT *,
    AVG(ticket_count) OVER(PARTITION BY account_id ORDER BY month_start
      ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) prior_avg,
    COUNT(*) OVER(PARTITION BY account_id ORDER BY month_start
      ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) prior_months
  FROM filled
)
SELECT account_id,month_start,ticket_count,ROUND(prior_avg,2) prior_3m_avg
FROM scored WHERE prior_months=3 AND prior_avg>0
  AND ticket_count>1.5*prior_avg
ORDER BY month_start DESC,account_id;""",
    "A measures three observed months, which can span a longer calendar period; C includes the surge month in its own baseline; D violates the requirement for all three prior months.",
    "Don't call three observed rows three calendar months when the series has gaps.",
    "An account with zero tickets last month still needs a zero row in the baseline."
)

add("Three-day, three-channel engagement",
    "marketing_touches(user_id,interaction_date DATE,channel) may have duplicate records or multiple channels on a day. A qualifying user has three consecutive dates, exactly one distinct channel on each date, and three different channels across those dates.",
    "What should you normalize before using LAG to test the sequence?",
    ["SELECT DISTINCT user_id,date,channel, then LAG two rows by date without checking for multiple channels on one day.",
     "Pick ANY_VALUE(channel) per user-day even when several channels occurred that day, then test the three-day sequence.",
     "Keep only user-days with one distinct channel, then check both date gaps and all three pairwise channel differences.",
     "Keep one channel per day and consecutive dates, but compare only day 1 vs 2 and day 2 vs 3."], 2,
    """WITH daily AS (
  SELECT user_id,interaction_date,MAX(channel) AS channel,
         COUNT(DISTINCT channel) AS channels_that_day
  FROM marketing_touches GROUP BY user_id,interaction_date
), eligible AS (
  SELECT user_id,interaction_date,channel
  FROM daily WHERE channels_that_day=1
), seq AS (
  SELECT *,
    LAG(interaction_date,1) OVER(PARTITION BY user_id ORDER BY interaction_date) d1,
    LAG(interaction_date,2) OVER(PARTITION BY user_id ORDER BY interaction_date) d2,
    LAG(channel,1) OVER(PARTITION BY user_id ORDER BY interaction_date) c1,
    LAG(channel,2) OVER(PARTITION BY user_id ORDER BY interaction_date) c2
  FROM eligible
)
SELECT DISTINCT user_id FROM seq
WHERE DATE_DIFF(interaction_date,d1,DAY)=1
  AND DATE_DIFF(interaction_date,d2,DAY)=2
  AND channel<>c1 AND channel<>c2 AND c1<>c2;""",
    "A leaves multi-channel same-day rows that distort LAG positions; B chooses an arbitrary channel on an ambiguous day; D allows an Email-Ad-Email sequence.",
    "Don't test only neighbouring channels; all three must be pairwise distinct.",
    "Email, Ad, Email on three days does not qualify even though each adjacent pair differs."
)

assert len(items)==10
assert sorted(x["correct"] for x in items)==[0,0,1,1,1,2,2,2,3,3]
payload=json.dumps(items,ensure_ascii=False,indent=2)
assert "$medium$" not in payload

template=MEDIUM.read_text(encoding="utf-8")
start=template.index("$medium$")+len("$medium$")
end=template.index("$medium$",start)
template=template[:start]+payload+template[end:]
template=template.replace("old_medium_ids","old_hard_ids")
template=template.replace("v_medium","v_hard")
template=template.replace("medium_payload","hard_payload")
template=template.replace("medium_questions","hard_questions")
template=template.replace("medium_answers","hard_answers")
template=template.replace("generate_series(11,20)","generate_series(21,30)")
template=template.replace("name='Medium'","name='Hard'")
template=template.replace("$medium$","$hard$")
template=template.replace("'mcq','medium'","'mcq','hard'")
template=template.replace("<>12","<>10")
template=template.replace("<>48","<>40")
template=template.replace("Twelve-question seed mismatch","Ten-question seed mismatch")
template=template.replace("original Medium set","original Hard set")
template=template.replace("/ Medium classification missing","/ Hard classification missing")
template=template.replace("Medium replacement verification failed","Hard replacement verification failed")
template=template.replace("-- Replace only the ten original SQL Coding Practice / Medium questions with","-- Replace only the ten original SQL Coding Practice / Hard questions with")
template=template.replace("-- twelve reasoning-first, BigQuery GoogleSQL MCQs","-- ten reasoning-first, BigQuery GoogleSQL MCQs")
template=template.replace("-- Easy and Hard are untouched.","-- Easy and Medium are untouched.")
template=template.replace("BigQuery reasoning practice: pivots, hierarchies, joins, geometry, medians, gaps, and SQL generation",
                          "BigQuery reasoning practice: fan-out, streaks, time series, recursion, and sequence analysis")
OUT.write_text(template,encoding="utf-8")
print(f"Wrote {OUT}: replaced 10 Hard questions with {len(items)} BigQuery reasoning questions")
