"""Build ten original Easy PySpark coding-practice MCQs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PYTHON_EASY_SQL = ROOT / "supabase/migrations/20260929010000_seed_python_coding_practice_easy.sql"
OUT = ROOT / "supabase/migrations/20260929040000_seed_pyspark_coding_practice_easy.sql"
items = []


def add(question, options, correct, why, code, wrong, note, tip):
    assert len(options) == len(set(options)) == 4 and 0 <= correct < 4
    assert note.startswith("Don't ")
    items.append({
        "id": f"pyspark_coding_easy_20260929_{len(items)+1:02d}",
        "level": "easy",
        "question": question,
        "options": options,
        "correct": correct,
        "explaination": f"Reasoning: {why}\n\nPySpark solution:\n{code}\n\nWhy the other options fail: {wrong}",
        "interview_note": note,
        "pro_tips": tip,
    })


add(
    "Create an employee DataFrame where emp_id is integer, name is string, and salary is double. Which approach explicitly fixes those Spark SQL types?",
    ["Pass the three column names to createDataFrame and let Spark infer each field type from the local rows.",
     "Build a StructType containing IntegerType, StringType, and DoubleType fields, then pass it as the schema.",
     "Create the DataFrame without a schema, then rename its inferred _1, _2, and _3 columns to the target names.",
     "Convert every tuple value to text first, create the DataFrame, and rely on Spark to restore numeric types."], 1,
    "A StructType defines both field names and Spark SQL data types before DataFrame creation, avoiding inference surprises.",
    "schema = T.StructType([\n    T.StructField('emp_id', T.IntegerType()),\n    T.StructField('name', T.StringType()),\n    T.StructField('salary', T.DoubleType()),\n])\ndf = spark.createDataFrame(data, schema)",
    "A infers rather than explicitly defines types. C only renames columns and leaves inferred types unchanged. D deliberately creates strings and Spark will not restore the intended types automatically.",
    "Don't rely on inference when a pipeline has a published schema contract.",
    "Choose each field's nullable flag deliberately; the default True may be too permissive for identifiers."
)
add(
    "Add bonus as 10% of salary, but produce 0.0 when salary is null. Which column expression has the required null behavior?",
    ["df.withColumn('bonus', F.col('salary') * F.lit(0.10)), allowing null salary to produce a null bonus",
     "df.withColumn('bonus', F.coalesce(F.col('salary'), F.lit(0.0)) * F.lit(0.10))",
     "df.withColumn('bonus', F.when(F.col('salary').isNull(), F.lit(None)).otherwise(F.lit(0.0)))",
     "df.withColumn('bonus', F.coalesce(F.col('salary') * F.lit(0.10), F.col('salary')))"], 1,
    "coalesce replaces a null salary with zero before multiplication, so the derived value is a non-null numeric zero.",
    "result = df.withColumn(\n    'bonus', F.coalesce(F.col('salary'), F.lit(0.0)) * F.lit(0.10)\n)",
    "A propagates null through multiplication. C returns null for null salary and zero for non-null salary. D coalesces two expressions that are both null when salary is null.",
    "Don't expect ordinary arithmetic with null to produce zero in Spark SQL.",
    "Cast the fallback literal when decimal precision must match a DecimalType salary."
)
add(
    "Assign salary_tier as High for salary >= 80000, Medium for salary >= 50000, and Low otherwise. Which expression handles the boundaries correctly?",
    ["F.when(F.col('salary') >= 50000, 'Medium').when(F.col('salary') >= 80000, 'High').otherwise('Low')",
     "F.when(F.col('salary') > 80000, 'High').when(F.col('salary') > 50000, 'Medium').otherwise('Low')",
     "F.when(F.col('salary') >= 80000, 'High').when(F.col('salary') >= 50000, 'Medium').otherwise('Low')",
     "F.when(F.col('salary') < 50000, 'Low').when(F.col('salary') < 80000, 'High').otherwise('Medium')"], 2,
    "when clauses are evaluated in order, so the most selective high threshold comes first and both inclusive boundaries use >=.",
    "tiered = df.withColumn(\n    'salary_tier',\n    F.when(F.col('salary') >= 80000, 'High')\n     .when(F.col('salary') >= 50000, 'Medium')\n     .otherwise('Low')\n)",
    "A labels every salary at least 80000 as Medium before the High branch is reached. B misclassifies exact boundary values. D assigns the wrong labels to the middle and upper ranges.",
    "Don't place a broad matching condition before a narrower condition in a when chain.",
    "Decide explicitly how null salary should be classified; otherwise it falls into otherwise."
)
add(
    "For each region, calculate the sum of amount as total_revenue and the count of non-null amount values as transaction_count. Which aggregation matches?",
    ["df.groupBy('region').agg(F.sum('amount').alias('total_revenue'), F.count('amount').alias('transaction_count'))",
     "df.groupBy('region').agg(F.avg('amount').alias('total_revenue'), F.count('*').alias('transaction_count'))",
     "df.agg(F.sum('amount').alias('total_revenue'), F.count('amount').alias('transaction_count'))",
     "df.groupBy('amount').agg(F.sum('region').alias('total_revenue'), F.count('region').alias('transaction_count'))"], 0,
    "groupBy region creates one group per region; sum totals revenue and count(amount) counts only non-null amount values.",
    "summary = df.groupBy('region').agg(\n    F.sum('amount').alias('total_revenue'),\n    F.count('amount').alias('transaction_count'),\n)",
    "B computes an average and count(*) includes rows with null amount. C produces one result for the whole DataFrame. D groups by the wrong field and attempts to sum a string region.",
    "Don't treat count(column) and count('*') as identical when the column can be null.",
    "Use decimal amounts for exact currency arithmetic when floating-point rounding is unacceptable."
)
add(
    "Keep rows whose status is ACTIVE and whose non-null age is at least 21. Which PySpark filter is sufficient?",
    ["df.filter((F.col('status') == 'ACTIVE') | (F.col('age') >= 21))",
     "df.filter((F.col('status') == 'ACTIVE') & (F.col('age') >= 21))",
     "df.filter((F.col('status') != 'INACTIVE') & (F.col('age') > 21))",
     "df.filter(F.col('status') == 'ACTIVE').fillna({'age': 21})"], 1,
    "Spark's three-valued filter logic drops rows where the predicate is null, so the AND predicate already excludes null ages while keeping age 21.",
    "result = df.filter(\n    (F.col('status') == 'ACTIVE') & (F.col('age') >= 21)\n)",
    "A accepts rows satisfying only one requirement. C changes both the status and age rules. D converts missing ages into qualifying values rather than excluding them.",
    "Don't use Python and/or with Column expressions; use overloaded & and | with parentheses.",
    "An explicit isNotNull check can improve readability even though it is redundant for this comparison filter."
)
add(
    "Keep every employee, attach a matching department name, and use Unassigned when no department matches. Which transformation is correct?",
    ["emp.join(dept, 'dept_id', 'inner').fillna({'dept_name': 'Unassigned'})",
     "emp.join(dept, 'dept_id', 'right').fillna({'dept_name': 'Unassigned'})",
     "emp.join(dept, 'dept_id', 'left').fillna({'dept_name': 'Unassigned'})",
     "emp.crossJoin(dept).fillna({'dept_name': 'Unassigned'})"], 2,
    "A left join preserves every row from employees, and filling dept_name replaces only the missing matched value named in the mapping.",
    "result = (emp.join(dept, on='dept_id', how='left')\n             .fillna({'dept_name': 'Unassigned'}))",
    "A removes employees without a department match. B preserves departments instead of employees. D creates every employee-department combination and does not express key matching.",
    "Don't use a broad fillna value when only one nullable output column should receive the default.",
    "Check key uniqueness on the department side, or duplicate department keys can multiply employee rows."
)
add(
    "For each user_id, retain the row with the latest login_date; if dates tie, prefer device alphabetically. Which method is deterministic?",
    ["Call df.dropDuplicates(['user_id']) and rely on the first input row for each user being retained.",
     "Order the DataFrame globally by login_date descending, then call dropDuplicates(['user_id']).",
     "Use row_number over a window partitioned by user_id and ordered by login_date and device descending; keep row 1.",
     "Group by user_id and apply F.max to login_date and device independently, then place both maxima in one row."], 2,
    "A window expresses the complete per-user ordering before row_number selects exactly one coherent source row.",
    "w = Window.partitionBy('user_id').orderBy(\n    F.col('login_date').desc(), F.col('device').desc()\n)\nresult = (df.withColumn('_rn', F.row_number().over(w))\n            .filter(F.col('_rn') == 1).drop('_rn'))",
    "A does not guarantee which duplicate survives. B's global ordering is not a reliable retention contract for dropDuplicates. D can combine maxima taken from different source rows.",
    "Don't describe dropDuplicates as retaining the first row unless arbitrary retention is acceptable.",
    "Add a final unique tiebreaker when the stated ordering can still tie, especially for reproducible pipelines."
)
add(
    "Parse raw_date values such as 15-08-2025 into DateType and add their calendar year. Which transformation uses the matching Spark pattern?",
    ["df.withColumn('event_date', F.to_date('raw_date', 'dd-MM-yyyy')).withColumn('year', F.year('event_date'))",
     "df.withColumn('event_date', F.to_date('raw_date', 'MM-dd-yyyy')).withColumn('year', F.year('raw_date'))",
     "df.withColumn('event_date', F.date_format('raw_date', 'dd-MM-yyyy')).withColumn('year', F.year('event_date'))",
     "df.withColumn('event_date', F.to_timestamp('raw_date', 'dd-mm-yyyy')).withColumn('year', F.month('event_date'))"], 0,
    "to_date with dd-MM-yyyy matches day-month-year input and returns DateType; year then extracts the year from the parsed column.",
    "result = (df.withColumn('event_date', F.to_date('raw_date', 'dd-MM-yyyy'))\n            .withColumn('year', F.year('event_date')))",
    "B swaps day and month and extracts from the original string. C formats rather than parses the string into DateType. D uses minutes (mm) rather than months (MM) and extracts the month.",
    "Don't confuse MM for month with mm for minute in datetime patterns.",
    "Invalid input normally parses to null; monitor or quarantine those rows instead of silently losing them."
)
add(
    "Create clean_name by trimming the outside whitespace, lowercasing text, and replacing each run of internal whitespace with one underscore. Which expression matches?",
    ["F.regexp_replace(F.lower(F.trim('product_name')), r'\\s+', '_')",
     "F.lower(F.regexp_replace('product_name', r'\\s+', '')).alias('clean_name')",
     "F.trim(F.regexp_replace(F.lower('product_name'), r'_', ' '))",
     "F.regexp_replace(F.upper(F.trim('product_name')), r'\\s', '_')"], 0,
    "trim removes boundary spaces, lower normalizes case, and the \\s+ regex collapses one or more whitespace characters to a single underscore.",
    "result = df.withColumn(\n    'clean_name',\n    F.regexp_replace(F.lower(F.trim('product_name')), r'\\s+', '_')\n)",
    "B removes whitespace rather than inserting separators. C replaces underscores with spaces and never creates the requested separators. D uppercases and replaces each whitespace character separately.",
    "Don't use a literal single-space pattern when tabs or repeated whitespace must be normalized too.",
    "Define a Unicode and punctuation policy before treating this simple normalization as a production slug generator."
)
add(
    "Count unique non-null user_id values within each product category and name the result unique_user_count. Which aggregation is correct?",
    ["df.groupBy('category').agg(F.count('user_id').alias('unique_user_count'))",
     "df.groupBy('category').agg(F.countDistinct('user_id').alias('unique_user_count'))",
     "df.groupBy('user_id').agg(F.countDistinct('category').alias('unique_user_count'))",
     "df.select('category', 'user_id').distinct().agg(F.count('*').alias('unique_user_count'))"], 1,
    "countDistinct(user_id) removes repeated users inside each category and ignores null user IDs.",
    "result = df.groupBy('category').agg(\n    F.countDistinct('user_id').alias('unique_user_count')\n)",
    "A counts repeated purchases by the same user. C groups on the wrong dimension. D returns one global count after distinct rather than one count per category.",
    "Don't apply distinct to the entire DataFrame when uniqueness is defined by selected keys within groups.",
    "For very large cardinalities, approx_count_distinct can trade exactness for lower aggregation cost."
)

assert len(items) == 10
assert sorted(x["correct"] for x in items) == [0, 0, 0, 1, 1, 1, 1, 2, 2, 2]
assert all(max(map(len, x["options"])) - min(map(len, x["options"])) <= 30 for x in items)

source = PYTHON_EASY_SQL.read_text(encoding="utf-8")
prefix, old_payload, suffix = source.split("$python_easy$")
assert json.loads(old_payload) and "python_easy_questions" in suffix
prefix = prefix.replace("Python coding-practice Easy quiz", "PySpark coding-practice Easy quiz")
prefix = prefix.replace("python_easy", "pyspark_easy")
suffix = suffix.replace("python_easy", "pyspark_easy")
prefix = prefix.replace("Python Coding Practice", "PySpark Coding Practice")
suffix = suffix.replace("Python Coding Practice", "PySpark Coding Practice")
prefix = prefix.replace("Original Python coding and reasoning questions", "Original PySpark DataFrame coding and reasoning questions")
prefix = prefix.replace("Core Python data structures, strings, iteration, and built-ins", "PySpark DataFrame schemas, columns, filters, aggregations, joins, and data quality")
suffix = suffix.replace("Python Easy", "PySpark Easy")
prefix = prefix.replace("$python_easy$", "$pyspark_easy$")
suffix = suffix.replace("$python_easy$", "$pyspark_easy$")
sql = prefix + "$pyspark_easy$" + json.dumps(items, ensure_ascii=False, indent=2) + "$pyspark_easy$" + suffix
assert "python_easy" not in sql and "Python Coding Practice" not in sql
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: 10 PySpark Easy questions / 40 options")
