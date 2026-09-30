"""Build ten original Medium Python coding-practice MCQs from reviewed concepts."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EASY_SQL = ROOT / "supabase/migrations/20260929010000_seed_python_coding_practice_easy.sql"
OUT = ROOT / "supabase/migrations/20260929020000_seed_python_coding_practice_medium.sql"
items = []

def add(question, options, correct, why, code, wrong, note, tip):
    assert len(options) == len(set(options)) == 4 and 0 <= correct < 4
    assert note.startswith("Don't ")
    items.append({
        "id": f"python_coding_medium_20260929_{len(items)+1:02d}",
        "level": "medium", "question": question, "options": options, "correct": correct,
        "explaination": f"Reasoning: {why}\n\nPython solution:\n{code}\n\nWhy the other options fail: {wrong}",
        "interview_note": note, "pro_tips": tip,
    })

add(
    "For '1222311', produce consecutive runs as (count, digit): (1,1), (3,2), (1,3), (2,1). Which approach preserves separate runs of the same digit?",
    ["Build Counter(s), then emit one count-and-digit tuple for every key retained by the counter.",
     "Iterate groupby(s), then emit one count-and-digit tuple before advancing beyond each adjacent group.",
     "Iterate groupby(sorted(s)), then emit one count-and-digit tuple for every resulting sorted group.",
     "Iterate dict.fromkeys(s), then emit each digit with the result of counting it across the original input."], 1,
    "groupby on the original sequence groups only adjacent equal keys, so the two runs of 1 stay separate.",
    "from itertools import groupby\nresult = [(sum(1 for _ in group), int(key)) for key, group in groupby(s)]",
    "A and D count global frequency, merging separated runs. C changes the sequence by sorting it, which also merges the two runs of 1.",
    "Don't sort or globally count data when run boundaries matter.",
    "For compressed event logs, a value that returns later begins a new run."
)
add(
    "From 'HACK', emit every length-2 unordered letter pair, including self-pairs such as AA, in lexicographic order. Which generator fits?",
    ["Use combinations_with_replacement(sorted(s), 2), then join each generated pair.",
     "Use combinations(sorted(s), 2), then add a second copy of every generated pair.",
     "Use permutations(sorted(s), 2), then retain pairs whose first letter is not greater.",
     "Use product(sorted(s), repeat=2), then retain pairs containing two different letters."], 0,
    "Combinations with replacement allow AA but omit the reversed duplicate CA when AC is present.",
    "from itertools import combinations_with_replacement\nresult = [''.join(pair) for pair in combinations_with_replacement(sorted(s), 2)]",
    "B excludes self-pairs. C excludes self-pairs and includes reversed orderings. D includes self-pairs but also includes both AC and CA.",
    "Don't use product when order should not distinguish a pair.",
    "For unordered feature pairs, decide explicitly whether pairing a feature with itself is allowed."
)
add(
    "A card ID must begin with 4, 5, or 6, contain exactly 16 ASCII digits, be either unhyphenated or four groups of four, and contain no run of four equal digits even across hyphens. Which validation sequence is correct?",
    ["Match four digit groups with optional hyphens, then search the unchanged input for a run of four equal digits.",
     "Remove all hyphens, require 16 valid digits, then reject four equal consecutive digits without checking layout.",
     "Match either 16 digits or exactly four hyphenated groups, then reject four equal digits in the cleaned value.",
     "Match exactly four hyphenated digit groups, then reject equal-digit runs by examining every group separately."], 2,
    "Validate the two permitted layouts as alternatives, then strip separators before checking repeated digits across group boundaries.",
    "import re\nlayout = re.fullmatch(r'(?:[456][0-9]{15}|[456][0-9]{3}(?:-[0-9]{4}){3})', card)\nvalid = bool(layout) and not re.search(r'([0-9])\\1{3}', card.replace('-', ''))",
    "A permits mixed use of hyphens and misses runs crossing them. B accepts misplaced hyphens. D rejects valid unhyphenated cards and misses cross-boundary runs.",
    "Don't let optional separators permit mixed formatting, or test repeats before removing separators.",
    "For real payments, use a payment provider; this validates only the exercise's string rules, not card authenticity."
)
add(
    "Sort a string's lowercase letters, uppercase letters, odd digits, then even digits; sort within each group. Input contains only ASCII letters and digits. Which key works?",
    ["Use key=lambda c: (c.isdigit(), c.isupper(), c), grouping letters before all digits.",
     "Use key=lambda c: (c.isdigit(), c.isdigit() and int(c)%2 == 1, c.isupper(), c).",
     "Use key=lambda c: (c.lower(), c.isdigit(), c.isupper()), grouping equal folded characters.",
     "Use key=lambda c: (c.isdigit(), c.isdigit() and int(c)%2 == 0, c.isupper(), c)."], 3,
    "Letters sort before digits; among letters, lowercase has isupper=False; among digits, odd has even-test=False.",
    "result = ''.join(sorted(s, key=lambda c: (c.isdigit(), c.isdigit() and int(c)%2 == 0, c.isupper(), c)))",
    "A sorts all digits together rather than odd before even. B places even before odd. C mixes case and digit categories by character value.",
    "Don't rely on ordinary lexicographic order when business rules define category priority.",
    "For a custom sort, test one value from each category and a tie within each category."
)
add(
    "Inside for i in range(1, N), print i repeated i times as a decimal number (1, 22, 333, ...), without converting to strings. Assume 1 <= i <= 9. Which expression works?",
    ["print(i * (10**i - 1) // 9)",
     "print((10**i - 1) // 9)",
     "print(i * 10**i)",
     "print(i * (10**i - 1) // 10)"], 0,
    "(10**i-1)//9 is a repunit with i ones; multiplying by a single digit i repeats that digit i times.",
    "for i in range(1, N):\n    print(i * (10**i - 1) // 9)",
    "B produces repeated 1s, not repeated i. C appends zeros. D divides by 10 instead of 9 and loses the repunit property.",
    "Don't apply this repeated-digit trick to i >= 10; carrying changes the result.",
    "This repunit identity is useful for understanding place value, not for general string formatting."
)
add(
    "For each position i in an uppercase word, count every substring that starts there. How many points should that position contribute to its vowel or consonant player?",
    ["Add i + 1, representing every possible starting position at or before the current index.",
     "Add len(s) - i, representing every valid ending position at or after the current index.",
     "Add len(s) - i - 1, representing every valid ending position strictly after the current index.",
     "Add len(s), representing the total number of possible endings for every starting index."], 1,
    "Each substring starting at i can end at i, i+1, ..., len(s)-1: exactly len(s)-i choices.",
    "scores = {'vowel': 0, 'consonant': 0}\nfor i, ch in enumerate(s):\n    group = 'vowel' if ch in 'AEIOU' else 'consonant'\n    scores[group] += len(s) - i",
    "A counts possible earlier starts, not endings. C omits the single-character substring. D overcounts later positions.",
    "Don't enumerate every substring when only its starting character matters.",
    "For BANANA, this count gives consonants 12 and vowels 9."
)
add(
    "Split 'AABCAAADA' into size-3 blocks and remove repeated characters separately within each block while preserving first appearance. Which method yields AB, CA, AD?",
    ["Deduplicate the entire string with dict.fromkeys, then divide the retained characters into size-k blocks.",
     "For every size-k block, join sorted(set(block)) so each character is emitted once in sorted order.",
     "For every size-k block, join dict.fromkeys(block) so each character is emitted at first occurrence.",
     "For every size-k block, join Counter(block).elements() so characters follow counter iteration order."], 2,
    "A new insertion-ordered dict per block keeps only each character's first appearance within that block.",
    "result = [''.join(dict.fromkeys(s[i:i+k])) for i in range(0, len(s), k)]",
    "A removes duplicates across blocks and changes boundaries. B sorts unique characters rather than keeping their first-seen order. D repeats characters according to frequency.",
    "Don't deduplicate globally when the rule resets at each chunk.",
    "For stream chunks, test a character that appears in more than one block."
)
add(
    "Every room number occurs K times except one, which occurs once; K > 1. Which O(n)-time arithmetic expression isolates the single room number?",
    ["(sum(rooms) - sum(set(rooms))) // (K - 1)",
     "(K * sum(set(rooms)) - sum(rooms)) // (K - 1)",
     "K * sum(set(rooms)) - sum(rooms)",
     "sum(set(rooms)) // K - sum(rooms)"], 1,
    "The difference between K copies of every distinct room and the actual list is (K-1) copies of the singleton room.",
    "single = (K * sum(set(rooms)) - sum(rooms)) // (K - 1)",
    "A uses the wrong subtraction and scale. C forgets to divide by K-1. D divides the distinct sum before subtracting and has no matching count identity.",
    "Don't use this formula unless exactly one value has count one and every other value has count K.",
    "For anomaly detection, validate the frequency assumption first; Counter is safer when counts may vary."
)
add(
    "A script needs start-tag and end-tag callbacks while reading HTML; start tags must expose parsed attribute pairs. Which standard-library approach is appropriate?",
    ["Use urllib.request.urlopen to parse tag events directly from response bytes.",
     "Use re.findall(r'<.*?>', html) and treat each match as a parsed tag with attributes.",
     "Subclass html.parser.HTMLParser and override handle_starttag and handle_endtag.",
     "Use xml.etree.ElementTree on arbitrary HTML and register handle_starttag callbacks."], 2,
    "HTMLParser provides event callbacks and passes a list of (name, value) attributes to handle_starttag.",
    "from html.parser import HTMLParser\nclass Tags(HTMLParser):\n    def handle_starttag(self, tag, attrs):\n        print('start', tag, attrs)\n    def handle_endtag(self, tag):\n        print('end', tag)\nparser = Tags()\nparser.feed(html)",
    "A fetches data but does not parse it. B cannot reliably handle HTML syntax or attributes with > inside quoted values. D is an XML parser and does not provide those HTMLParser callbacks.",
    "Don't parse arbitrary HTML tags with a single regex.",
    "For malformed web pages, consider a dedicated tolerant HTML parser; HTMLParser is suitable for this standard-library callback exercise."
)
add(
    "After reading a text matrix column by column, replace each run of non-ASCII-alphanumeric characters only when it lies between two ASCII-alphanumeric characters. Keep leading and trailing symbols. Which substitution works?",
    ["Replace r'[^A-Za-z0-9]+' globally, consuming every symbol run regardless of its position in the text.",
     "Replace r'(?<=\\w)[^\\w]+(?=\\w)', treating each regex word character as an alphanumeric boundary.",
     "Replace r'(?<=[A-Za-z0-9])[^A-Za-z0-9]+', requiring only an ASCII boundary on the left side.",
     "Replace r'(?<=[A-Za-z0-9])[^A-Za-z0-9]+(?=[A-Za-z0-9])', requiring ASCII boundaries on both sides."], 3,
    "Both lookarounds require an ASCII letter or digit immediately outside the replaced run; underscore counts as a symbol, unlike with \\w.",
    "import re\nclean = re.sub(r'(?<=[A-Za-z0-9])[^A-Za-z0-9]+(?=[A-Za-z0-9])', ' ', decoded_text)",
    "A changes leading and trailing noise. B treats underscore and Unicode word characters as alphanumeric. C also changes trailing noise because it lacks a right-side check.",
    "Don't use \\w when the requirement specifically says ASCII letters and digits.",
    "For text cleanup, test A_!B, !A, and B! to expose underscore and edge-boundary behavior."
)

assert len(items) == 10
assert sorted(x["correct"] for x in items) == [0,0,1,1,1,2,2,2,3,3]
assert all(max(map(len, x["options"])) - min(map(len, x["options"])) <= 25 for x in items)
source = EASY_SQL.read_text(encoding="utf-8")
prefix, old_payload, suffix = source.split("$python_easy$")
assert json.loads(old_payload) and "python_easy_questions" in suffix
prefix = prefix.replace("Easy quiz", "Medium quiz").replace("python_easy", "python_medium")
suffix = suffix.replace("python_easy", "python_medium")
suffix = suffix.replace("Expected one Easy subtopic", "Expected one Medium subtopic")
prefix = prefix.replace("'Easy'", "'Medium'").replace("Python data structures, strings, iteration, and built-ins", "Python iteration, validation, sorting, parsing, and arithmetic")
suffix = suffix.replace("'Easy'", "'Medium'").replace("Python Easy", "Python Medium")
prefix = prefix.replace("$python_easy$", "$python_medium$")
suffix = suffix.replace("$python_easy$", "$python_medium$")
sql = prefix + "$python_medium$" + json.dumps(items, ensure_ascii=False, indent=2) + "$python_medium$" + suffix
assert "python_easy" not in sql and "'Easy'" not in sql
OUT.write_text(sql, encoding="utf-8")
print(f"Wrote {OUT}: 10 Medium questions / 40 options")
