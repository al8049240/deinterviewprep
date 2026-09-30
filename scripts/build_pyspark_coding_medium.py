"""Build ten original Medium PySpark coding-practice MCQs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EASY_SQL = ROOT / "supabase/migrations/20260929040000_seed_pyspark_coding_practice_easy.sql"
OUT = ROOT / "supabase/migrations/20260929050000_seed_pyspark_coding_practice_medium.sql"
items = []


def add(question, options, correct, why, code, wrong, note, tip):
    assert len(options) == len(set(options)) == 4 and 0 <= correct < 4
    assert note.startswith("Don't ")
    items.append({
        "id": f"pyspark_coding_medium_20260929_{len(items)+1:02d}",
        "level": "medium",
        "question": question,
        "options": options,
        "correct": correct,
        "explaination": f"Reasoning: {why}\n\nPySpark solution:\n{code}\n\nWhy the other options fail: {wrong}",
        "interview_note": note,
        "pro_tips": tip,
    })


add(
    "Return exactly one highest-paid employee per department; ties go to the alphabetically earliest emp_name. Which window logic is deterministic for the stated rules?",
    ["Partition by department_id, order salary descending and emp_name ascending, assign row_number, and retain row 1.",
     "Partition by department_id, order salary descending, assign dense_rank, and retain every row with rank 1.",
     "Partition by emp_name, order salary descending and department_id ascending, assign row_number, and retain row 1.",
     "Order the full DataFrame by salary descending and emp_name ascending, then call dropDuplicates on department_id."], 0,
    "The partition resets ranking per department, the two sort keys encode the complete tie rule, and row_number selects one row.",
    "w = Window.partitionBy('department_id').orderBy(\n    F.col('salary').desc(), F.col('emp_name').asc()\n)\nresult = (df.withColumn('_rn', F.row_number().over(w))\n            .filter(F.col('_rn') == 1).drop('_rn'))",
    "B keeps all tied top salaries because dense_rank gives them the same rank. C partitions by the wrong entity. D does not make dropDuplicates retention deterministic.",
    "Don't use rank or dense_rank when the requirement demands exactly one row after applying a tiebreaker.",
    "Add a unique final ordering column if duplicate employee names can still tie."
)
add(
    "For each user event, calculate seconds since that user's previous event; the first event should have a null delta. Which transformation is correct?",
    ["Use lead(event_time) over a user/time window, then subtract event_time from the lead timestamp after casting both to long.",
     "Use lag(event_time) over a user/time window, then subtract the lag timestamp from event_time after casting both to long.",
     "Use lag(event_time) over a global time window, then subtract the lag timestamp from event_time after casting both to date.",
     "Use first(event_time) over a user partition, then subtract it from every event timestamp after casting both to long."], 1,
    "lag retrieves the preceding row inside each user's chronological partition; timestamp-to-long subtraction yields seconds and naturally leaves the first delta null.",
    "w = Window.partitionBy('user_id').orderBy('event_time')\nresult = (df.withColumn('_prev', F.lag('event_time').over(w))\n            .withColumn('seconds_since_previous',\n                F.col('event_time').cast('long') - F.col('_prev').cast('long')))",
    "A calculates time until the next event. C mixes users and DateType loses time-of-day precision. D measures from the first event rather than the immediately previous one.",
    "Don't omit a deterministic tiebreaker when multiple events for one user can share a timestamp.",
    "Confirm timestamp parsing and session timezone before interpreting epoch-second differences."
)
add(
    "Compute cumulative sales from the first row through the current row in date order. Multiple rows on one date must accumulate one by one using a stable row_id tiebreaker. Which window fits?",
    ["Window.orderBy('date', 'row_id').rowsBetween(Window.unboundedPreceding, Window.currentRow)",
     "Window.orderBy('date', 'row_id').rowsBetween(Window.currentRow, Window.unboundedFollowing)",
     "Window.partitionBy('date').rowsBetween(Window.unboundedPreceding, Window.currentRow)",
     "Window.orderBy('date', 'row_id').rangeBetween(Window.unboundedPreceding, Window.currentRow)"], 0,
    "A row-based frame ordered by date and a stable tiebreaker contains every physical row from the beginning through the current row.",
    "w = (Window.orderBy('date', 'row_id')\n           .rowsBetween(Window.unboundedPreceding, Window.currentRow))\nresult = df.withColumn('cumulative_sales', F.sum('amount').over(w))",
    "B sums forward from the current row. C resets for each date. D uses a value-based range frame and is not the requested one-row-at-a-time frame; range frames also restrict multi-expression numeric offsets.",
    "Don't rely on orderBy(date) alone when same-date rows require reproducible row-by-row results.",
    "A global unpartitioned window may move data to one partition; cumulative totals per business key scale better."
)
add(
    "Create one row per order item while retaining orders whose items array is null or empty as a row with null item_name. Which function matches?",
    ["Use F.explode('items') as item_name, because ordinary explode emits a null row for empty and null arrays.",
     "Use F.explode_outer('items') as item_name, because the outer form preserves null and empty arrays.",
     "Use F.flatten('items') as item_name, because flatten converts each array element into a separate DataFrame row.",
     "Use F.array_join('items', ',') as item_name, because joining preserves one output row for every array element."], 1,
    "explode_outer expands elements like explode but also emits a null element row when the input collection is null or empty.",
    "result = df.select(\n    'order_id', F.explode_outer('items').alias('item_name')\n)",
    "A drops null and empty arrays. C flattens an array of arrays into one array rather than rows. D creates one delimited string and preserves one row per order, not per item.",
    "Don't choose explode_outer unless preserving empty-parent records is part of the required row semantics.",
    "Exploding several arrays independently can create a Cartesian multiplication; use arrays_zip for positional pairing."
)
add(
    "Create one row per year with Q1, Q2, Q3, and Q4 columns containing total revenue. Which expression both aggregates correctly and fixes the output quarter set?",
    ["df.groupBy('year').pivot('quarter', ['Q1','Q2','Q3','Q4']).agg(F.sum('revenue'))",
     "df.groupBy('quarter').pivot('year', ['Q1','Q2','Q3','Q4']).agg(F.sum('revenue'))",
     "df.pivot('quarter', ['Q1','Q2','Q3','Q4']).groupBy('year').agg(F.sum('revenue'))",
     "df.groupBy('year', 'quarter').agg(F.sum('revenue')).withColumnRenamed('quarter', 'Q1')"], 0,
    "Grouping by year defines output rows, pivoting quarter defines output columns, and sum combines repeated revenue records in each cell.",
    "result = (df.groupBy('year')\n    .pivot('quarter', ['Q1', 'Q2', 'Q3', 'Q4'])\n    .agg(F.sum('revenue')))",
    "B swaps row and column dimensions and supplies quarter labels as year values. C calls pivot without a grouped-data object. D remains long-format and merely renames one column.",
    "Don't omit explicit pivot values when the allowed categories are known; Spark otherwise runs a discovery job.",
    "Expect null cells for missing quarter-year combinations unless downstream requirements specify a zero fill."
)
add(
    "A DataFrame contains user_id and an address struct with street, city, and zipcode. How can all current struct fields be promoted without listing each one?",
    ["Select user_id and the column expression address.*, which expands each child field into a top-level column.",
     "Select user_id and explode(address), which emits one row for every child field stored inside the struct.",
     "Select user_id and flatten(address), which converts the struct into an array of its top-level field values.",
     "Select user_id and address, then call drop('address') after Spark automatically copies its fields upward."], 0,
    "Spark's struct wildcard projection expands the immediate child fields while retaining separately selected columns such as user_id.",
    "result = df.select('user_id', 'address.*')",
    "B explode supports arrays and maps, not structs in this manner. C expects nested arrays, not a struct. D drops the struct without creating child columns.",
    "Don't use address.* blindly if child names can collide with existing top-level column names.",
    "This expands one struct level; nested child structs require additional projections or recursive schema traversal."
)
add(
    "Join a very large transaction DataFrame to a small country lookup while preserving every transaction. Which plan explicitly requests a broadcast hash join for the lookup side?",
    ["Broadcast lookup, left join it to large on country_code = code, then remove the duplicate code column.",
     "Broadcast large, left join lookup on country_code = code, then remove the duplicate code column.",
     "Repartition both inputs by their join keys, then perform a left join on country_code = code.",
     "Cross join large and lookup, filter where country_code = code, then select the transaction columns."], 0,
    "Broadcasting the small lookup copies it to executors so the large side need not be shuffled, while a left join preserves unmatched transactions.",
    "result = (large.join(\n    F.broadcast(lookup),\n    large.country_code == lookup.code,\n    'left'\n).drop(lookup.code))",
    "B attempts to broadcast the large side. C explicitly repartitions both inputs and can cause shuffles. D constructs a Cartesian product before filtering and also behaves like an inner join.",
    "Don't force a broadcast without confirming the lookup is small enough for executor memory and configured limits.",
    "Inspect the physical plan with explain() because adaptive execution or unsupported join conditions can affect strategy."
)
add(
    "For each customer, produce an alphabetically sorted array of distinct non-null product_id values. Which aggregation expresses all three requirements?",
    ["F.sort_array(F.collect_set('product_id')).alias('unique_products')",
     "F.collect_list(F.sort_array('product_id')).alias('unique_products')",
     "F.array_distinct(F.collect_list('product_id')).alias('unique_products')",
     "F.sort_array(F.collect_list('product_id')).alias('unique_products')"], 0,
    "collect_set removes duplicates during aggregation and excludes nulls; sort_array makes the otherwise unordered set result deterministic.",
    "result = df.groupBy('customer_id').agg(\n    F.sort_array(F.collect_set('product_id')).alias('unique_products')\n)",
    "B applies an array function to a scalar before aggregation and does not deduplicate. C deduplicates but does not sort. D sorts but preserves duplicate products.",
    "Don't depend on collect_set iteration order; explicitly sort when deterministic arrays are required.",
    "Large per-key arrays can create memory pressure and oversized rows even when duplicate values are removed."
)
add(
    "Within each account ordered by seq_no, flag a row when at least one integer is missing before the next observed sequence number. Duplicate seq_no values should not count as a gap. Which predicate is correct?",
    ["F.col('next_seq_no') != F.col('seq_no') + 1",
     "F.col('next_seq_no') > F.col('seq_no') + 1",
     "F.col('next_seq_no') >= F.col('seq_no') + 1",
     "F.col('next_seq_no') == F.col('seq_no') + 1"], 1,
    "After lead over an account partition, a strict greater-than-one jump identifies missing integers; an equal duplicate does not satisfy the predicate.",
    "w = Window.partitionBy('account_id').orderBy('seq_no')\nresult = (df.withColumn('next_seq_no', F.lead('seq_no').over(w))\n    .withColumn('is_gap',\n        F.coalesce(F.col('next_seq_no') > F.col('seq_no') + 1, F.lit(False))))",
    "A incorrectly flags duplicate or decreasing values. C flags every normal consecutive pair. D identifies continuity rather than a gap.",
    "Don't use != for missing-sequence detection when duplicate values may be present.",
    "Use next_seq_no - seq_no - 1 to calculate the missing count, and add one to each boundary for a missing range."
)
add(
    "Map error_code to a description from a small Python dictionary without a Python UDF, returning Unknown for unmapped or null codes. Which expression works?",
    ["Build F.create_map from alternating literal keys and values, index it by error_code, then coalesce the result with F.lit('Unknown').",
     "Pass the Python dict directly to F.lit, call it with error_code as a function, then fill null outputs with the string Unknown.",
     "Build F.array from dictionary values, index it by the string error_code, then coalesce missing array positions with Unknown.",
     "Use F.when(error_code.isNotNull(), mapping_dict[error_code]).otherwise('Unknown') with the Column as a Python dict key."], 0,
    "create_map produces a native Spark map expression, bracket lookup uses the row's code, and coalesce supplies the fallback entirely in Catalyst expressions.",
    "pairs = [F.lit(x) for kv in mapping.items() for x in kv]\nlookup = F.create_map(*pairs)\nresult = df.withColumn(\n    'error_message', F.coalesce(lookup[F.col('error_code')], F.lit('Unknown'))\n)",
    "B treats a Column like a Python callable. C arrays require integer indices and discard keys. D tries to resolve a distributed Column against a driver-side dict during plan construction.",
    "Don't reach for a Python UDF when built-in map expressions can keep execution optimized and code-generated.",
    "For a large or frequently changing mapping, store it as a reference DataFrame and use a broadcast join instead."
)

assert len(items) == 10
assert sorted(x["correct"] for x in items) == [0, 0, 0, 0, 0, 0, 0, 1, 1, 1]
assert all(max(map(len, x["options"])) - min(map(len, x["options"])) <= 30 for x in items)

source = EASY_SQL.read_text(encoding="utf-8")
prefix, old_payload, suffix = source.split("$pyspark_easy$")
assert json.loads(old_payload) and "pyspark_easy_questions" in suffix
prefix = prefix.replace("Easy quiz", "Medium quiz").replace("pyspark_easy", "pyspark_medium")
suffix = suffix.replace("pyspark_easy", "pyspark_medium")
suffix = suffix.replace("Expected one Easy subtopic", "Expected one Medium subtopic")
prefix = prefix.replace("'Easy'", "'Medium'").replace(
    "PySpark DataFrame schemas, columns, filters, aggregations, joins, and data quality",
    "PySpark windows, complex types, pivots, broadcast joins, and collection expressions",
)
suffix = suffix.replace("'Easy'", "'Medium'").replace("PySpark Easy", "PySpark Medium")
prefix = prefix.replace("$pyspark_easy$", "$pyspark_medium$")
suffix = suffix.replace("$pyspark_easy$", "$pyspark_medium$")
sql = prefix + "$pyspark_medium$" + json.dumps(items, ensure_ascii=False, indent=2) + "$pyspark_medium$" + suffix
assert "pyspark_easy" not in sql and "'Easy'" not in sql
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: 10 PySpark Medium questions / 40 options")
