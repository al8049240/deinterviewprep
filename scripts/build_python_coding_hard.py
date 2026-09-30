"""Build ten original Hard Python data-engineering practice MCQs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIUM_SQL = ROOT / "supabase/migrations/20260929020000_seed_python_coding_practice_medium.sql"
OUT = ROOT / "supabase/migrations/20260929030000_seed_python_coding_practice_hard.sql"
items = []


def add(question, options, correct, why, code, wrong, note, tip):
    assert len(options) == len(set(options)) == 4 and 0 <= correct < 4
    assert note.startswith("Don't ")
    items.append({
        "id": f"python_coding_hard_20260929_{len(items)+1:02d}",
        "level": "hard",
        "question": question,
        "options": options,
        "correct": correct,
        "explaination": f"Reasoning: {why}\n\nPython solution:\n{code}\n\nWhy the other options fail: {wrong}",
        "interview_note": note,
        "pro_tips": tip,
    })


add(
    "A JSON-lines stream is sorted by event_id. Keep one row per event_id: greatest timestamp wins, then lexicographically greatest payload. The stream is larger than RAM. Which design uses O(1) auxiliary memory?",
    ["Index the best row for each event_id in a dict, then emit all retained values after consuming the stream.",
     "Group adjacent raw JSON strings, select max(raw_string) per group, and decode only each selected value.",
     "Retain the current event_id and best row, emitting on a key change and flushing once more after iteration.",
     "Compare each row with the preceding row, immediately emitting whichever has the greater timestamp and payload."], 2,
    "Sorting makes all duplicates adjacent, so only the current key and best candidate must be retained. The final group needs an explicit flush.",
    "def dedupe(rows):\n    key = best = None\n    for raw in rows:\n        row = json.loads(raw)\n        if row['event_id'] != key:\n            if best is not None: yield best\n            key, best = row['event_id'], row\n        elif (row['timestamp'], row['payload']) > (best['timestamp'], best['payload']):\n            best = row\n    if best is not None: yield best",
    "A grows with distinct keys. B groups by serialization rather than event_id. D can emit an earlier candidate before a later duplicate supersedes it.",
    "Don't claim constant-memory exact deduplication for an unsorted stream with arbitrarily distant duplicate keys.",
    "In production, document the upstream ordering guarantee and reject or monitor out-of-order keys."
)
add(
    "Unordered events must be sessionized per user. A new session starts only when the gap from the previous event is greater than 1,800 seconds. Which sequence is correct?",
    ["Sort globally by timestamp, then compare every event with the immediately preceding global event.",
     "Group by user, sort each user's events by timestamp, and start a session when current_ts - previous_ts > 1800.",
     "Group by user, preserve arrival order, and start a session when current_ts - session_start > 1800.",
     "Group by user, sort descending, and start a session when previous_ts - current_ts >= 1800."], 1,
    "Sessions depend on consecutive chronological events for the same user; a gap of exactly 1,800 seconds remains in the current session.",
    "by_user = defaultdict(list)\nfor e in events: by_user[e['user_id']].append(e)\nfor user, rows in by_user.items():\n    rows.sort(key=lambda e: e['timestamp'])\n    # split when rows[i]['timestamp'] - rows[i-1]['timestamp'] > 1800",
    "A lets other users affect the comparison. C uses unreliable arrival order and measures from the wrong event. D reverses time and changes the boundary to >=.",
    "Don't compare with the session start when the rule is an inactivity gap between consecutive events.",
    "Define deterministic handling for equal timestamps if event order within a session matters."
)
add(
    "An ETL row is valid only when id is a positive int but not bool, price is a finite positive float, and created_at exactly matches YYYY-MM-DD. Every bad row must be quarantined without stopping the batch. Which validation is strongest?",
    ["Use one batch-level try/except; apply strict casts and range checks, quarantining the row that ends the loop on failure.",
     "Use try/except per row; accept successful int, float, and strptime conversions, then apply positive range checks.",
     "Use try/except per row; reject falsey fields, require positive cast values, and preserve the supplied date after parsing.",
     "Use try/except per row; reject bool or noncanonical IDs, nonfinite or nonpositive prices, and dates that fail a format round-trip."], 3,
    "Per-row isolation keeps the pipeline moving, while explicit type, finiteness, range, and date-format checks close Python coercion edge cases such as True, NaN, and non-zero-padded dates.",
    "try:\n    if isinstance(row.get('id'), bool): raise ValueError('boolean id')\n    raw_id = row['id']; parsed_id = int(raw_id)\n    if str(raw_id).strip() != str(parsed_id) or parsed_id <= 0: raise ValueError('invalid id')\n    price = float(row['price'])\n    if not math.isfinite(price) or price <= 0: raise ValueError('invalid price')\n    date = datetime.strptime(row['created_at'], '%Y-%m-%d')\n    if date.strftime('%Y-%m-%d') != row['created_at']: raise ValueError('invalid date')\nexcept (KeyError, TypeError, ValueError) as exc:\n    quarantine.append({'raw_record': row, 'error_reason': str(exc)})",
    "A abandons later rows. B accepts bool as an int, non-finite prices, and potentially lenient date text. C confuses missing values with legitimate falsey representations and does not enforce types.",
    "Don't catch BaseException or silently discard the failing row and reason.",
    "Keep stable error codes alongside human-readable reasons so quarantine metrics remain aggregatable."
)
add(
    "Outages are (start, end, region). Overlapping or touching intervals in the same region must be merged before summing downtime. After grouping and sorting by start, what is the correct merge condition and update?",
    ["When start <= last_end, replace the tail with (last_start, max(last_end, end)); otherwise append the interval.",
     "When start < last_end, add end-start directly to the region total; otherwise append the interval for later summing.",
     "When start <= last_start, replace the tail with (min(last_start, start), end); otherwise append the interval.",
     "When start <= last_end, merge into the last interval encountered globally, then allocate its duration to both regions."], 0,
    "The <= comparison includes contiguous intervals, and max preserves a prior interval that extends beyond the new one.",
    "for start, end in sorted(intervals):\n    if merged and start <= merged[-1][1]:\n        merged[-1] = (merged[-1][0], max(merged[-1][1], end))\n    else:\n        merged.append((start, end))\ntotal = sum(end-start for start, end in merged)",
    "B fails to merge touching intervals and can double-count overlaps. C compares the wrong boundary and may shrink coverage. D combines unrelated regional outages.",
    "Don't sum raw durations before unioning intervals, or overlaps will be counted more than once.",
    "State whether intervals are closed, open, or half-open; duration arithmetic usually uses [start, end)."
)
add(
    "Trades arrive in nondecreasing timestamp order. For each trade at ts, compute the mean over the inclusive window [ts-60, ts] in O(n) total time. Which eviction rule is correct?",
    ["Evict while oldest_ts <= ts-60, subtract each evicted price from a running sum, then divide by deque length.",
     "Evict while oldest_ts < ts-60, subtract each evicted price from a running sum, then divide by deque length.",
     "Evict while oldest_ts < ts, subtract each evicted price from a running sum, then divide by deque length.",
     "Retain the most recent 60 deque entries, maintain their running sum, then divide by the retained entry count."], 1,
    "An event exactly at ts-60 belongs to the inclusive window. Each trade enters and leaves the deque once, and the running sum makes each output amortized O(1).",
    "window.append((ts, price)); running_sum += price\nwhile window and window[0][0] < ts - 60:\n    _, old_price = window.popleft(); running_sum -= old_price\naverage = running_sum / len(window)",
    "A excludes the left boundary and recomputing sums can become quadratic. C keeps only equal-timestamp trades. D implements a row-count window rather than a time window.",
    "Don't call this O(n) unless input ordering is guaranteed or established first.",
    "For monetary data, consider Decimal and an explicit rounding policy rather than binary float."
)
add(
    "Flatten nested dicts and lists into dot paths such as user.address.city and items.0.name. Which recursive design correctly handles both container types?",
    ["Append dict keys to the parent path, but serialize each complete list as the scalar value at its current path.",
     "Append dict keys or enumerated list indices to the parent path, and emit path-value pairs only for scalar leaves.",
     "Serialize each container, remove braces and brackets, then split the remaining text into path-value fragments.",
     "Flatten each child container with a fresh empty path, then merge its emitted path-value pairs into the result."], 1,
    "The recursion must carry a complete parent path and treat list indices as path components; only scalar leaves become output entries.",
    "def walk(value, path=''):\n    if isinstance(value, dict):\n        for key, child in value.items(): yield from walk(child, join(path, str(key)))\n    elif isinstance(value, list):\n        for i, child in enumerate(value): yield from walk(child, join(path, str(i)))\n    else:\n        yield path, value\nflat = dict(walk(data))",
    "A loses list structure. C manipulates serialization rather than the data model. D loses ancestry and creates key collisions.",
    "Don't ignore collisions when source keys may contain the chosen separator.",
    "Define representations for empty dicts and lists; a leaf-only scheme otherwise emits nothing for them."
)
add(
    "Profile updates must become SCD Type 2 rows per user. Assuming updated_at values are unique per user, which construction gives non-overlapping validity ranges and exactly one current row?",
    ["Sort all updates globally; close each row at the next update timestamp, and mark the final row for each user current.",
     "Sort updates per user; close each row at that user's next timestamp, and mark only the open-ended final row current.",
     "Sort updates per user; leave every end date open, but mark only the greatest timestamp for each user current.",
     "Sort updates per user by country; close each row at the preceding timestamp, and mark the first row current."], 1,
    "Validity boundaries are entity-specific and chronological; the next version closes the current one, while only the last version remains active.",
    "rows.sort(key=lambda r: r['updated_at'])\nfor i, row in enumerate(rows):\n    last = i == len(rows)-1\n    out.append({**row, 'effective_start': row['updated_at'],\n                'effective_end': '9999-12-31' if last else rows[i+1]['updated_at'],\n                'is_current': last})",
    "A lets another user's change close the row. C creates overlapping current versions. D orders by an attribute rather than effective time and points boundaries backward.",
    "Don't leave equal-timestamp updates unspecified; add a sequence tiebreaker or reject the ambiguity.",
    "Agree whether effective_end is exclusive; using [start, end) avoids double validity at the boundary."
)
add(
    "Received sequence IDs are unsorted and may contain duplicates. Return only missing ranges between the smallest and largest received IDs. Which algorithm is correct?",
    ["Sort the original list and report (a+1, b-1) whenever adjacent values satisfy b-a > 1.",
     "Convert to a set, sort it, and for each adjacent pair with curr-prev > 1 append (prev+1, curr-1).",
     "Iterate range(min(ids), max(ids)) and append one tuple for every missing individual ID.",
     "Compare each ID with its arrival-order predecessor and report any numerical difference."], 1,
    "Deduplication prevents repeated IDs from complicating adjacency, and gaps between consecutive sorted unique IDs define maximal missing ranges.",
    "ordered = sorted(set(ids))\ngaps = [(a+1, b-1) for a, b in zip(ordered, ordered[1:]) if b-a > 1]",
    "A can work despite duplicates but does unnecessary sorting and does not explicitly normalize the contract. C may use time and memory proportional to the ID span. D mistakes arrival order for sequence order.",
    "Don't infer missing IDs before the observed minimum or after the observed maximum without external expected bounds.",
    "For huge bounded domains, bitmap or external-sort approaches can avoid holding all distinct IDs in Python memory."
)
add(
    "Rows must be assigned reproducibly to N output buckets across Python processes and retries. Which calculation avoids Python's randomized built-in string hash?",
    ["Encode the canonical key, compute hash(key_bytes), convert it to a nonnegative integer, and take the result modulo N.",
     "Encode the canonical key, seed random from hash(key_bytes) for each row, draw one integer, and take the result modulo N.",
     "Encode the canonical key, compute a SHA-256 digest, convert the digest to an integer, and take the result modulo N.",
     "Encode the canonical key, sum all byte values into an integer, mix in the byte length, and take the result modulo N."], 2,
    "A cryptographic digest over a documented canonical byte encoding is stable across processes; modulo maps it to the configured bucket count.",
    "if num_buckets <= 0: raise ValueError('num_buckets must be positive')\nkey_bytes = str(row[bucket_key]).encode('utf-8')\ndigest = hashlib.sha256(key_bytes).digest()\nbucket = int.from_bytes(digest, 'big') % num_buckets",
    "A is intentionally randomized for bytes between interpreter processes. B inherits that randomized hash through its seed. D is deterministic but creates severe systematic skew.",
    "Don't use row.get(key, '') unless missing keys are intentionally assigned to the same bucket as empty strings.",
    "Persist the hash algorithm, key encoding, null policy, and bucket count as part of the dataset contract."
)
add(
    "Upsert an incoming batch into an existing in-memory table by primary key. Within the batch, the last occurrence of a key wins. Re-running the same batch must leave both values and output order unchanged. Which design satisfies this?",
    ["Concatenate both inputs, stringify each row into a set for deduplication, then decode the set entries back into rows.",
     "Index existing rows in insertion order, assign every batch row by primary key, then return the index values in order.",
     "Index existing rows in insertion order, append only batch rows with unseen keys, then return all retained values.",
     "Concatenate both inputs, sort rows by primary key, then retain the first row encountered for each adjacent key."], 1,
    "Dict assignment overwrites the value without moving an existing key; new keys take first-insertion positions. Repeating the same ordered assignments produces the same rows and order, and later batch duplicates win.",
    "index = {row[pk]: row.copy() for row in existing}\nfor row in batch:\n    index[row[pk]] = row.copy()\nresult = list(index.values())",
    "A stringifies records, loses reliable structure and order, and does not deduplicate by primary key. C is insert-only rather than upsert. D cannot generally order dicts and does not resolve duplicate keys.",
    "Don't mutate caller-owned dictionaries accidentally; copy rows if the returned table must be isolated.",
    "State ordering and duplicate-key semantics explicitly; idempotent values alone do not define deterministic output order."
)

assert len(items) == 10
assert sorted(x["correct"] for x in items) == [0, 1, 1, 1, 1, 1, 1, 2, 2, 3]
assert all(max(map(len, x["options"])) - min(map(len, x["options"])) <= 30 for x in items)
source = MEDIUM_SQL.read_text(encoding="utf-8")
prefix, old_payload, suffix = source.split("$python_medium$")
assert json.loads(old_payload) and "python_medium_questions" in suffix
prefix = prefix.replace("Medium quiz", "Hard quiz").replace("python_medium", "python_hard")
suffix = suffix.replace("python_medium", "python_hard")
suffix = suffix.replace("Expected one Medium subtopic", "Expected one Hard subtopic")
prefix = prefix.replace("'Medium'", "'Hard'").replace(
    "Python iteration, validation, sorting, parsing, and arithmetic",
    "Production Python streaming, ETL resilience, temporal processing, and idempotency",
)
suffix = suffix.replace("'Medium'", "'Hard'").replace("Python Medium", "Python Hard")
prefix = prefix.replace("$python_medium$", "$python_hard$")
suffix = suffix.replace("$python_medium$", "$python_hard$")
sql = prefix + "$python_hard$" + json.dumps(items, ensure_ascii=False, indent=2) + "$python_hard$" + suffix
assert "python_medium" not in sql and "'Medium'" not in sql
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: 10 Hard questions / 40 options")
