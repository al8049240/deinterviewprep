import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';
import '../../providers/bookmark_provider.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../paywall_screen/paywall_screen.dart';

// ── Playground tip/challenge model ───────────────────────────────────────────
class _PlaygroundItem {
  final String id;
  final String title;
  final String description;
  final String codeSnippet;
  final String language;

  const _PlaygroundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.codeSnippet,
    required this.language,
  });
}

const List<_PlaygroundItem> _sqlTips = [
  _PlaygroundItem(
    id: 'pg_sql_1',
    title: 'Window Function: Running Total',
    description:
        'Use SUM() OVER() to compute a running total without GROUP BY.',
    codeSnippet:
        'SELECT order_id, amount,\n  SUM(amount) OVER (ORDER BY order_date) AS running_total\nFROM orders;',
    language: 'SQL',
  ),
  _PlaygroundItem(
    id: 'pg_sql_2',
    title: 'CTE for Readable Queries',
    description:
        'Common Table Expressions (CTEs) make complex queries easier to read and debug.',
    codeSnippet:
        'WITH ranked AS (\n  SELECT *, ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn\n  FROM employees\n)\nSELECT * FROM ranked WHERE rn = 1;',
    language: 'SQL',
  ),
  _PlaygroundItem(
    id: 'pg_sql_3',
    title: 'LATERAL JOIN for Row-Level Subqueries',
    description:
        'LATERAL allows a subquery to reference columns from preceding tables.',
    codeSnippet:
        'SELECT u.user_id, recent.event_type\nFROM users u,\nLATERAL (\n  SELECT event_type FROM events e\n  WHERE e.user_id = u.user_id\n  ORDER BY event_time DESC LIMIT 1\n) recent;',
    language: 'SQL',
  ),
];

const List<_PlaygroundItem> _pythonTips = [
  _PlaygroundItem(
    id: 'pg_py_1',
    title: 'PySpark: GroupBy Aggregation',
    description: 'Aggregate data by key using PySpark DataFrame API.',
    codeSnippet:
        'from pyspark.sql import functions as F\n\nresult = df.groupBy("customer_id") \\\n  .agg(\n    F.sum("amount").alias("total"),\n    F.count("order_id").alias("orders")\n  ) \\\n  .orderBy(F.desc("total"))',
    language: 'Python',
  ),
  _PlaygroundItem(
    id: 'pg_py_2',
    title: 'Pandas: Efficient Merge',
    description:
        'Use merge() with explicit keys and how parameter for safe joins.',
    codeSnippet:
        'import pandas as pd\n\nresult = pd.merge(\n  orders_df,\n  customers_df,\n  on="customer_id",\n  how="left",\n  validate="many_to_one"\n)',
    language: 'Python',
  ),
  _PlaygroundItem(
    id: 'pg_py_3',
    title: 'List Comprehension for Transformations',
    description:
        'Pythonic way to filter and transform lists in a single expression.',
    codeSnippet:
        'completed = [\n  {"id": o["id"], "revenue": o["amount"] * 1.1}\n  for o in orders\n  if o["status"] == "completed" and o["amount"] > 100\n]',
    language: 'Python',
  ),
];

class CodePlaygroundScreen extends StatefulWidget {
  /// When set, the tips section scrolls to and highlights this specific tip (bookmark single-item view).
  final String? initialTipId;

  const CodePlaygroundScreen({super.key, this.initialTipId});

  @override
  State<CodePlaygroundScreen> createState() => _CodePlaygroundScreenState();
}

class _CodePlaygroundScreenState extends State<CodePlaygroundScreen>
    with SingleTickerProviderStateMixin {
  final ProService _proService = ProService();
  late TabController _tabController;
  final TextEditingController _sqlController = TextEditingController();
  final TextEditingController _pythonController = TextEditingController();
  final ScrollController _tipsScrollController = ScrollController();
  String _sqlOutput = '';
  String _pythonOutput = '';
  bool _isRunning = false;
  String _activeTab = 'SQL';
  String? _loadedTipId; // tracks which tip is currently loaded in the editor

  static const String _defaultSql = '''-- Sample: Query top customers by revenue
SELECT 
  customer_id,
  customer_name,
  SUM(order_amount) AS total_revenue,
  COUNT(order_id) AS order_count,
  AVG(order_amount) AS avg_order_value
FROM orders
JOIN customers USING (customer_id)
WHERE order_date >= '2024-01-01'
GROUP BY customer_id, customer_name
ORDER BY total_revenue DESC
LIMIT 10;''';

  static const String _defaultPython =
      '''# Sample: PySpark-style data transformation
import json

# Mock dataset
orders = [
    {"id": 1, "customer": "Alice", "amount": 250.0, "status": "completed"},
    {"id": 2, "customer": "Bob", "amount": 180.5, "status": "completed"},
    {"id": 3, "customer": "Alice", "amount": 320.0, "status": "pending"},
    {"id": 4, "customer": "Charlie", "amount": 95.0, "status": "completed"},
    {"id": 5, "customer": "Bob", "amount": 410.0, "status": "completed"},
]

# Group by customer, sum completed orders
result = {}
for order in orders:
    if order["status"] == "completed":
        c = order["customer"]
        result[c] = result.get(c, 0) + order["amount"]

# Sort by revenue descending
sorted_result = sorted(result.items(), key=lambda x: x[1], reverse=True)
for customer, revenue in sorted_result:
    print(f"{customer}: \${revenue:.2f}")
''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sqlController.text = _defaultSql;
    _pythonController.text = _defaultPython;
    _tabController.addListener(() {
      setState(() {
        _activeTab = _tabController.index == 0 ? 'SQL' : 'Python';
      });
    });

    // If opened from a bookmark, switch to the correct tab and load the tip's code
    if (widget.initialTipId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialTip();
      });
    }
  }

  void _loadInitialTip() {
    final tipId = widget.initialTipId;
    if (tipId == null) return;

    // Find the tip in SQL or Python lists
    final sqlMatch = _sqlTips.where((t) => t.id == tipId).toList();
    final pyMatch = _pythonTips.where((t) => t.id == tipId).toList();

    if (sqlMatch.isNotEmpty) {
      _tabController.animateTo(0);
      setState(() {
        _activeTab = 'SQL';
        _sqlController.text = sqlMatch.first.codeSnippet;
        _loadedTipId = tipId;
      });
    } else if (pyMatch.isNotEmpty) {
      _tabController.animateTo(1);
      setState(() {
        _activeTab = 'Python';
        _pythonController.text = pyMatch.first.codeSnippet;
        _loadedTipId = tipId;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sqlController.dispose();
    _pythonController.dispose();
    _tipsScrollController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    setState(() => _isRunning = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (_activeTab == 'SQL') {
      setState(() {
        _sqlOutput = _simulateSqlExecution(_sqlController.text);
        _isRunning = false;
      });
    } else {
      setState(() {
        _pythonOutput = _simulatePythonExecution(_pythonController.text);
        _isRunning = false;
      });
    }
  }

  String _simulateSqlExecution(String query) {
    final q = query.trim();
    final ql = q.toLowerCase();

    if (q.isEmpty) {
      return 'ERROR: No SQL query to execute. Please write a query first.';
    }

    // DDL statements
    if (ql.startsWith('create table') || ql.startsWith('create index')) {
      final nameMatch = RegExp(
        r'create\s+(?:table|index)\s+(\w+)',
        caseSensitive: false,
      ).firstMatch(q);
      final name = nameMatch?.group(1) ?? 'object';
      return 'DDL executed successfully ✓ (0.008s)\n\nTable/Index "$name" created.';
    }
    if (ql.startsWith('drop')) {
      return 'DDL executed successfully ✓ (0.005s)\n\nObject dropped.';
    }
    if (ql.startsWith('alter')) {
      return 'DDL executed successfully ✓ (0.006s)\n\nTable altered successfully.';
    }

    // DML statements
    if (ql.startsWith('insert')) {
      return 'Query OK, 1 row affected (0.012s)';
    }
    if (ql.startsWith('update')) {
      return 'Query OK, rows affected (0.015s)';
    }
    if (ql.startsWith('delete')) {
      return 'Query OK, rows deleted (0.010s)';
    }

    // SELECT queries — parse what columns/tables are referenced
    if (ql.contains('select') && ql.contains('from')) {
      // Detect window functions
      if (ql.contains('over') &&
          (ql.contains('sum(') ||
              ql.contains('row_number') ||
              ql.contains('rank(') ||
              ql.contains('count('))) {
        return _buildWindowFunctionResult(q);
      }
      // Detect CTEs
      if (ql.startsWith('with ') || ql.contains('\nwith ')) {
        return _buildCteResult(q);
      }
      // Detect GROUP BY aggregation
      if (ql.contains('group by')) {
        return _buildGroupByResult(q);
      }
      // Detect JOIN
      if (ql.contains('join')) {
        return _buildJoinResult(q);
      }
      // Detect LATERAL
      if (ql.contains('lateral')) {
        return _buildLateralResult(q);
      }
      // Generic SELECT
      return _buildGenericSelectResult(q);
    }

    return 'ERROR: Unrecognized SQL statement. Please check your syntax.';
  }

  String _buildWindowFunctionResult(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('sum(') && ql.contains('running')) {
      return '''Query executed successfully ✓
Execution time: 0.038s | Rows returned: 5

┌──────────┬──────────┬───────────────┐
│ order_id │  amount  │ running_total │
├──────────┼──────────┼───────────────┤
│ 1001     │ \$120.00 │ \$120.00      │
│ 1002     │ \$250.00 │ \$370.00      │
│ 1003     │ \$180.00 │ \$550.00      │
│ 1004     │ \$95.00  │ \$645.00      │
│ 1005     │ \$310.00 │ \$955.00      │
└──────────┴──────────┴───────────────┘

5 rows in set''';
    }
    if (ql.contains('row_number') || ql.contains('rank(')) {
      return '''Query executed successfully ✓
Execution time: 0.041s | Rows returned: 4

┌─────────────┬──────────┬────────┬────┐
│ employee_id │   name   │ salary │ rn │
├─────────────┼──────────┼────────┼────┤
│ E001        │ Alice    │ 95000  │ 1  │
│ E002        │ Bob      │ 88000  │ 1  │
│ E003        │ Carol    │ 82000  │ 1  │
│ E004        │ Dave     │ 79000  │ 1  │
└─────────────┴──────────┴────────┴────┘

4 rows in set (top-ranked per department)''';
    }
    return '''Query executed successfully ✓
Execution time: 0.035s | Rows returned: 5

Window function applied over partition.
5 rows returned with computed window values.''';
  }

  String _buildCteResult(String q) {
    return '''Query executed successfully ✓
Execution time: 0.052s | Rows returned: 3

CTE resolved successfully.

┌─────────────┬──────────────┬────────┬────┐
│ employee_id │     name     │ salary │ rn │
├─────────────┼──────────────┼────────┼────┤
│ E001        │ Alice Chen   │ 95000  │ 1  │
│ E005        │ Bob Martinez │ 88000  │ 1  │
│ E009        │ Sarah Kim    │ 91000  │ 1  │
└─────────────┴──────────────┴────────┴────┘

3 rows in set (highest-paid per department)''';
  }

  String _buildGroupByResult(String q) {
    final ql = q.toLowerCase();
    final hasSum = ql.contains('sum(');
    final hasCount = ql.contains('count(');
    final hasAvg = ql.contains('avg(');

    String header = '┌─────────────┬──────────────';
    String divider = '├─────────────┼──────────────';
    String footer = '└─────────────┴──────────────';
    String col2 = 'group_key    ';

    if (hasSum && hasCount) {
      return '''Query executed successfully ✓
Execution time: 0.042s | Rows returned: 5

┌─────────────┬──────────────┬───────────────┬─────────────┬─────────────────┐
│ customer_id │ customer_name│ total_revenue │ order_count │ avg_order_value │
├─────────────┼──────────────┼───────────────┼─────────────┼─────────────────┤
│ C001        │ Alice Chen   │ \$12,450.00   │ 48          │ \$259.38        │
│ C002        │ Bob Martinez │ \$9,820.50    │ 37          │ \$265.42        │
│ C003        │ Sarah Kim    │ \$8,340.00    │ 31          │ \$268.97        │
│ C004        │ David Lee    │ \$7,125.75    │ 29          │ \$245.72        │
│ C005        │ Emma Wilson  │ \$6,890.00    │ 26          │ \$265.00        │
└─────────────┴──────────────┴───────────────┴─────────────┴─────────────────┘

5 rows in set''';
    }
    if (hasCount) {
      return '''Query executed successfully ✓
Execution time: 0.028s | Rows returned: 4

┌──────────────┬───────┐
│    group     │ count │
├──────────────┼───────┤
│ Engineering  │ 24    │
│ Marketing    │ 18    │
│ Sales        │ 31    │
│ Operations   │ 12    │
└──────────────┴───────┘

4 rows in set''';
    }
    return '''Query executed successfully ✓
Execution time: 0.033s | Rows returned: 4

Aggregation applied. 4 groups returned.''';
  }

  String _buildJoinResult(String q) {
    final ql = q.toLowerCase();
    final isLeft = ql.contains('left join');
    final isRight = ql.contains('right join');
    final joinType = isLeft
        ? 'LEFT JOIN'
        : isRight
        ? 'RIGHT JOIN'
        : 'INNER JOIN';
    return '''Query executed successfully ✓
Execution time: 0.047s | Rows returned: 5

$joinType applied.

┌─────────┬──────────────┬───────────────┬────────────┐
│ user_id │  user_name   │  order_total  │ order_date │
├─────────┼──────────────┼───────────────┼────────────┤
│ U001    │ Alice Chen   │ \$1,240.00    │ 2024-03-15 │
│ U002    │ Bob Martinez │ \$890.50      │ 2024-03-14 │
│ U003    │ Sarah Kim    │ \$2,100.00    │ 2024-03-13 │
│ U004    │ David Lee    │ \$450.75      │ 2024-03-12 │
│ U005    │ Emma Wilson  │ \$3,200.00    │ 2024-03-11 │
└─────────┴──────────────┴───────────────┴────────────┘

5 rows in set''';
  }

  String _buildLateralResult(String q) {
    return '''Query executed successfully ✓
Execution time: 0.055s | Rows returned: 4

LATERAL subquery evaluated per row.

┌─────────┬────────────────────┐
│ user_id │    event_type      │
├─────────┼────────────────────┤
│ U001    │ purchase           │
│ U002    │ page_view          │
│ U003    │ add_to_cart        │
│ U004    │ checkout_complete  │
└─────────┴────────────────────┘

4 rows in set''';
  }

  String _buildGenericSelectResult(String q) {
    final ql = q.toLowerCase();
    // Try to detect LIMIT clause
    final limitMatch = RegExp(
      r'limit\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(q);
    final rowCount = limitMatch != null
        ? int.tryParse(limitMatch.group(1) ?? '5') ?? 5
        : 5;
    final displayRows = rowCount.clamp(1, 10);

    return '''Query executed successfully ✓
Execution time: 0.031s | Rows returned: $displayRows

┌────┬──────────────┬──────────────┬────────────┐
│ id │    name      │    value     │    date    │
├────┼──────────────┼──────────────┼────────────┤
${List.generate(displayRows, (i) => '│ ${(i + 1).toString().padRight(2)} │ Record ${(i + 1).toString().padRight(5)} │ \$${((i + 1) * 123.45).toStringAsFixed(2).padRight(12)} │ 2024-0${(i % 9) + 1}-${(i + 10).toString().padRight(2)} │').join('\n')}
└────┴──────────────┴──────────────┴────────────┘

$displayRows rows in set''';
  }

  String _simulatePythonExecution(String code) {
    if (code.trim().isEmpty) {
      return 'Error: No Python code to execute. Please write some code first.';
    }

    final lines = code.split('\n');
    final output = <String>[];

    // Simulate print statements
    for (final line in lines) {
      final trimmed = line.trim();
      // Match print("...") or print(f"...") or print(variable)
      final printMatch = RegExp(r'''print\\((.+)\\)''').firstMatch(trimmed);
      if (printMatch != null) {
        final arg = printMatch.group(1)!.trim();
        // f-string with customer/revenue pattern
        if (arg.contains('customer') && arg.contains('revenue')) {
          output.addAll([
            'Alice: \$570.00',
            'Bob: \$590.50',
            'Charlie: \$95.00',
          ]);
        } else if (arg.contains('f"') || arg.contains("f'")) {
          // Generic f-string — extract literal parts
          final literal = arg
              .replaceAll(RegExp(r'\{[^}]+\}'), '<value>')
              .replaceAll(RegExp(r'''[f"']'''), '');
          output.add(literal.isNotEmpty ? literal : '<computed value>');
        } else if (arg.startsWith('"') || arg.startsWith("'")) {
          // String literal
          output.add(arg.replaceAll(RegExp(r'''^['"]|['"]$'''), ''));
        } else {
          output.add('<$arg>');
        }
      }
    }

    // Detect PySpark patterns
    if (code.contains('pyspark') ||
        code.contains('SparkSession') ||
        code.contains('groupBy') ||
        code.contains('.agg(')) {
      return '''Execution successful ✓ (0.124s)

[PySpark simulation]
+─────────────┬──────────┬────────+
| customer_id | total    | orders |
+─────────────┼──────────┼────────+
| C001        | 12450.00 | 48     |
| C002        | 9820.50  | 37     |
| C003        | 8340.00  | 31     |
+─────────────┴──────────┴────────+

Process finished with exit code 0''';
    }

    // Detect pandas patterns
    if (code.contains('pandas') ||
        code.contains('pd.') ||
        code.contains('DataFrame') ||
        code.contains('merge(')) {
      return '''Execution successful ✓ (0.089s)

[Pandas simulation]
   customer_id  order_id  amount  customer_name
0         C001      1001  250.00    Alice Chen
1         C001      1002  180.50    Alice Chen
2         C002      1003  320.00    Bob Martinez
3         C003      1004   95.00    Sarah Kim

Shape: (4, 4)

Process finished with exit code 0''';
    }

    // Detect list comprehension / filter patterns
    if (code.contains('[') && code.contains('for') && code.contains('if')) {
      return '''Execution successful ✓ (0.002s)

[{'id': 1, 'revenue': 275.0}, {'id': 2, 'revenue': 198.55}, {'id': 5, 'revenue': 451.0}]

Process finished with exit code 0''';
    }

    // Detect sorting / dict patterns
    if (code.contains('sorted(') || code.contains('.items()')) {
      if (output.isEmpty) {
        output.addAll(['Alice: \$570.00', 'Bob: \$590.50', 'Charlie: \$95.00']);
      }
    }

    // Detect json patterns
    if (code.contains('json.') || code.contains('import json')) {
      if (output.isEmpty) {
        output.add('{"status": "ok", "count": 3, "data": [...]}');
      }
    }

    final execOutput = output.isNotEmpty ? output.join('\n') : '(no output)';

    return '''Execution successful ✓ (0.003s)

$execOutput

Process finished with exit code 0''';
  }

  void _togglePlaygroundBookmark(String id, String title) {
    final bookmarkProvider = context.read<BookmarkProvider>();
    final added = bookmarkProvider.togglePlaygroundBookmark(id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Code tip saved to Bookmarks' : 'Removed from Bookmarks',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: added ? const Color(0xFF2E7D32) : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _proService.isProUnlocked;

    if (!isPro) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(
            'Code Playground',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 40,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'PRO Feature',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock the Code Playground to practice SQL and Python with client-side execution.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const PaywallScreen(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Unlock Full Access (\$19.99)',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final output = _activeTab == 'SQL' ? _sqlOutput : _pythonOutput;
    // When opened from a bookmark, show only the specific tip; otherwise show all
    final allTips = _activeTab == 'SQL' ? _sqlTips : _pythonTips;
    final tips = widget.initialTipId != null
        ? allTips.where((t) => t.id == widget.initialTipId).toList()
        : allTips;

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(
              widget.initialTipId != null
                  ? 'Bookmarked Code Tip'
                  : 'Code Playground',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.secondary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: '🗄️ SQL'),
                Tab(text: '🐍 Python'),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookmarksScreen(
                      initialFilter: BookmarkFilter.playground,
                    ),
                  ),
                ),
                icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
                tooltip: 'View Bookmarks',
              ),
            ],
          ),
          body: Column(
            children: [
              // Mock dataset info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppTheme.primaryContainer,
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_chart,
                      size: 14,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mock dataset: orders, customers, products tables pre-loaded',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Code editor
              Expanded(
                flex: 3,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CodeEditor(
                      controller: _sqlController,
                      language: 'SQL',
                      hint: 'Write your SQL query here...',
                    ),
                    _CodeEditor(
                      controller: _pythonController,
                      language: 'Python',
                      hint: 'Write your Python code here...',
                    ),
                  ],
                ),
              ),

              // Run button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _runCode,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow, size: 20),
                        label: Text(
                          _isRunning ? 'Running...' : 'Run $_activeTab',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        if (_activeTab == 'SQL') {
                          _sqlController.text = _defaultSql;
                          setState(() => _sqlOutput = '');
                        } else {
                          _pythonController.text = _defaultPython;
                          setState(() => _pythonOutput = '');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Output panel
              if (output.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: const Color(0xFF2D2D2D),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.terminal,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Output',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              output,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 12,
                                color: const Color(0xFFD4D4D4),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tips & Challenges section — vertical scrollable list
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_activeTab Tips & Challenges',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  controller: _tipsScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: tips.length,
                  itemBuilder: (context, i) {
                    final tip = tips[i];
                    final isBookmarked = bookmarkProvider
                        .isPlaygroundBookmarked(tip.id);
                    final isHighlighted =
                        widget.initialTipId == tip.id || _loadedTipId == tip.id;
                    return _TipCard(
                      tip: tip,
                      isBookmarked: isBookmarked,
                      isHighlighted: isHighlighted,
                      onBookmark: () =>
                          _togglePlaygroundBookmark(tip.id, tip.title),
                      onTap: () {
                        final currentTab = _activeTab;
                        if (currentTab == 'SQL') {
                          _sqlController.text = tip.codeSnippet;
                        } else {
                          _pythonController.text = tip.codeSnippet;
                        }
                        setState(() {
                          _loadedTipId = tip.id;
                        });
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ "${tip.title}" loaded into editor',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tip Card ──────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final _PlaygroundItem tip;
  final bool isBookmarked;
  final bool isHighlighted;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  const _TipCard({
    required this.tip,
    required this.isBookmarked,
    this.isHighlighted = false,
    required this.onBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppTheme.primary.withAlpha(180)
              : Colors.grey.shade200,
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppTheme.primary.withAlpha(30)
                : Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + language badge + bookmark
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tip.language,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onBookmark,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description / explanation text
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              tip.description,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),

          // Code snippet block
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tip.codeSnippet,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  color: const Color(0xFFD4D4D4),
                  height: 1.6,
                ),
              ),
            ),
          ),

          // Load into editor button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.code_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Load into Editor',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Code Editor ───────────────────────────────────────────────────────────────
class _CodeEditor extends StatelessWidget {
  final TextEditingController controller;
  final String language;
  final String hint;

  const _CodeEditor({
    required this.controller,
    required this.language,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: null,
          style: GoogleFonts.sourceCodePro(
            fontSize: 13,
            color: const Color(0xFFD4D4D4),
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sourceCodePro(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          cursorColor: Colors.green,
        ),
      ),
    );
  }
}
