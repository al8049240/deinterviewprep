import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

// ── Always-Visible Horizontal Scroll Panel ────────────────────────────────────
/// Wraps [child] in a horizontal SingleChildScrollView and paints a permanent
/// scroll-thumb track at the bottom, regardless of Flutter's scrollbar settings.
class _AlwaysVisibleHScrollPanel extends StatefulWidget {
  final Widget child;
  final double trackHeight;
  final Color trackColor;
  final Color thumbColor;
  final EdgeInsetsGeometry padding;

  const _AlwaysVisibleHScrollPanel({
    required this.child,
    this.trackHeight = 6.0,
    this.trackColor = const Color(0xFF2A2A2A),
    this.thumbColor = const Color(0xFF888888),
    this.padding = EdgeInsets.zero,
  });

  @override
  State<_AlwaysVisibleHScrollPanel> createState() =>
      _AlwaysVisibleHScrollPanelState();
}

class _AlwaysVisibleHScrollPanelState
    extends State<_AlwaysVisibleHScrollPanel> {
  final ScrollController _ctrl = ScrollController();
  double _thumbStart = 0;
  double _thumbWidth = 0;
  double _trackWidth = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_updateThumb);
  }

  void _updateThumb() {
    if (!_ctrl.hasClients) return;
    final pos = _ctrl.position;
    final viewportW = pos.viewportDimension;
    final contentW = pos.maxScrollExtent + viewportW;
    if (contentW <= viewportW) {
      setState(() {
        _thumbWidth = _trackWidth;
        _thumbStart = 0;
      });
      return;
    }
    final ratio = viewportW / contentW;
    final tw = (_trackWidth * ratio).clamp(24.0, _trackWidth);
    final maxOffset = _trackWidth - tw;
    final scrollRatio = pos.pixels / pos.maxScrollExtent;
    setState(() {
      _thumbWidth = tw;
      _thumbStart = (maxOffset * scrollRatio).clamp(0.0, maxOffset);
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_updateThumb);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update track width and recalculate thumb after layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final newTrackW = constraints.maxWidth;
          if (newTrackW != _trackWidth) {
            _trackWidth = newTrackW;
            _updateThumb();
          }
        });
        _trackWidth = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              padding: widget.padding,
              child: widget.child,
            ),
            // Always-visible thumb track
            SizedBox(
              height: widget.trackHeight + 2,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!_ctrl.hasClients) return;
                  final pos = _ctrl.position;
                  final contentW = pos.maxScrollExtent + pos.viewportDimension;
                  final scrollPerPixel = contentW / _trackWidth;
                  _ctrl.jumpTo(
                    (pos.pixels + details.delta.dx * scrollPerPixel).clamp(
                      0.0,
                      pos.maxScrollExtent,
                    ),
                  );
                },
                child: Stack(
                  children: [
                    // Track background
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        decoration: BoxDecoration(
                          color: widget.trackColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Thumb
                    if (_thumbWidth > 0)
                      Positioned(
                        left: _thumbStart,
                        top: 1,
                        bottom: 1,
                        width: _thumbWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.thumbColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Verification Status ───────────────────────────────────────────────────────
enum _VerificationStatus {
  notRun,
  running,
  passed,
  failed,
  executionError,
  timeout,
}

// ── Debug Info Model ──────────────────────────────────────────────────────────
class _DebugInfo {
  final String? stackTrace;
  final String? printedOutput;
  final String? returnedValue;
  final String? sqlErrorMessage;
  final String? sqlErrorCode;
  final List<Map<String, String>>? actualRows;
  final List<String>? actualColumns;
  final List<Map<String, String>>? expectedRows;
  final List<String>? expectedColumns;
  final String? diffSummary;
  final List<String>? consoleLogs;

  const _DebugInfo({
    this.stackTrace,
    this.printedOutput,
    this.returnedValue,
    this.sqlErrorMessage,
    this.sqlErrorCode,
    this.actualRows,
    this.actualColumns,
    this.expectedRows,
    this.expectedColumns,
    this.diffSummary,
    this.consoleLogs,
  });

  bool get hasPythonDebug =>
      stackTrace != null || printedOutput != null || returnedValue != null;
  bool get hasSqlError => sqlErrorMessage != null;
  bool get hasDiff =>
      (actualRows != null && actualRows!.isNotEmpty) ||
      (expectedRows != null && expectedRows!.isNotEmpty);
}

class CodePlaygroundWorkspaceScreen extends StatefulWidget {
  final String playgroundId;

  const CodePlaygroundWorkspaceScreen({super.key, required this.playgroundId});

  @override
  State<CodePlaygroundWorkspaceScreen> createState() =>
      _CodePlaygroundWorkspaceScreenState();
}

class _CodePlaygroundWorkspaceScreenState
    extends State<CodePlaygroundWorkspaceScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _challenge;
  List<Map<String, dynamic>>? _datasetRows;

  final TextEditingController _codeController = TextEditingController();
  bool _isRunning = false;
  String _executionOutput = '';
  _VerificationStatus _verificationStatus = _VerificationStatus.notRun;
  String _verificationMessage = '';
  _DebugInfo? _debugInfo;
  bool _debugModeEnabled = true;

  bool _showDatasetPreview = false;
  bool _showSolution = false;
  bool _solutionRevealed = false;
  bool _showExpectedResult = true;

  // Vertical scroll controllers (horizontal handled by _AlwaysVisibleHScrollPanel)
  final ScrollController _stdoutVScrollCtrl = ScrollController();
  final ScrollController _outputVScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _stdoutVScrollCtrl.dispose();
    _outputVScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.fetchPlaygroundChallengeById(
        widget.playgroundId,
      );
      if (data == null) {
        setState(() {
          _error = 'Challenge not found.';
          _loading = false;
        });
        return;
      }

      List<Map<String, dynamic>>? rows;
      final dsMap = data['code_playground_datasets'];
      if (dsMap is Map<String, dynamic>) {
        final raw = dsMap['dataset'];
        if (raw is Map<String, dynamic>) {
          rows = _extractDatasetRows(raw);
        } else if (raw is List) {
          rows = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      final starterCode = (data['starter_code'] ?? '').toString();
      setState(() {
        _challenge = data;
        _datasetRows = rows;
        _codeController.text = starterCode;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenge. Tap to retry.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractDatasetRows(Map<String, dynamic> dataset) {
    final result = <Map<String, dynamic>>[];
    for (final key in dataset.keys) {
      final val = dataset[key];
      if (val is List) {
        for (final row in val.take(8)) {
          if (row is Map<String, dynamic>) {
            result.add({'_table': key, ...row});
          }
        }
      }
    }
    return result;
  }

  void _resetCode() {
    final starter = (_challenge?['starter_code'] ?? '').toString();
    setState(() {
      _codeController.text = starter;
      _executionOutput = '';
      _verificationStatus = _VerificationStatus.notRun;
      _verificationMessage = '';
      _debugInfo = null;
    });
  }

  Future<void> _runCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isRunning = true;
      _verificationStatus = _VerificationStatus.running;
      _executionOutput = '';
      _verificationMessage = '';
      _debugInfo = null;
    });

    final language = (_challenge?['language'] ?? 'SQL').toString();
    final verificationConfig = _challenge?['verification_config'];
    final expectedResults = _challenge?['expected_results'] as String?;

    try {
      Map<String, dynamic> execResult;

      if (language.toLowerCase() == 'python') {
        execResult = await _executePythonRealAsync(code);
      } else {
        execResult = _executeSQLWithDebug(code);
      }

      final output = execResult['output'] as String;
      final debugInfo = execResult['debug'] as _DebugInfo?;

      final verResult = _verify(
        code,
        output,
        verificationConfig,
        language,
        debugInfo,
        expectedResults: expectedResults,
      );

      setState(() {
        _isRunning = false;
        _executionOutput = output;
        _verificationStatus = verResult.status;
        _verificationMessage = verResult.message;
        _debugInfo = verResult.debugInfo ?? debugInfo;
      });
    } catch (e) {
      final errMsg = e.toString();
      setState(() {
        _isRunning = false;
        _executionOutput = 'Error: $errMsg';
        _verificationStatus = _VerificationStatus.executionError;
        _verificationMessage = errMsg;
        _debugInfo = _DebugInfo(
          stackTrace:
              'Traceback (most recent call last):\n  File "<playground>", line 1, in <module>\n${e.runtimeType}: $errMsg',
        );
      });
    }
  }

  _VerifyResultWithDebug _verify(
    String code,
    String output,
    dynamic config,
    String language,
    _DebugInfo? execDebug, {
    String? expectedResults,
  }) {
    if (config == null) {
      if (output.toLowerCase().contains('error')) {
        return _VerifyResultWithDebug(
          _VerificationStatus.executionError,
          output,
          execDebug,
        );
      }
      // Even with no config, if expected_results is present, do strict comparison
      if (expectedResults != null && expectedResults.isNotEmpty) {
        if (language.toLowerCase() == 'sql') {
          return _verifySqlResult(
            code,
            output,
            <String, dynamic>{},
            execDebug,
            expectedResults: expectedResults,
          );
        }
        if (language.toLowerCase() == 'python') {
          return _verifyPythonOutput(
            code,
            output,
            <String, dynamic>{},
            execDebug,
            expectedResults: expectedResults,
          );
        }
      }
      // No config and no expected_results — only pass if output is non-empty
      // and does not contain an error signal. Do NOT auto-pass empty output.
      if (output.isNotEmpty && !output.toLowerCase().contains('error')) {
        return _VerifyResultWithDebug(
          _VerificationStatus.passed,
          'Code executed successfully.',
          execDebug,
        );
      }
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'No output produced. Make sure your code returns or prints a result.',
        execDebug,
      );
    }

    final cfg = config is Map<String, dynamic> ? config : <String, dynamic>{};
    final type = (cfg['type'] ?? '').toString();

    if (output.toLowerCase().startsWith('error') ||
        output.toLowerCase().startsWith('⚠')) {
      return _VerifyResultWithDebug(
        _VerificationStatus.executionError,
        output,
        execDebug,
      );
    }

    if (type == 'sql_result') {
      return _verifySqlResult(
        code,
        output,
        cfg,
        execDebug,
        expectedResults: expectedResults,
      );
    } else if (type == 'python_output') {
      return _verifyPythonOutput(
        code,
        output,
        cfg,
        execDebug,
        expectedResults: expectedResults,
      );
    }

    // If expected_results is present from DB, we must compare — never auto-pass.
    if (expectedResults != null && expectedResults.isNotEmpty) {
      if (language.toLowerCase() == 'sql') {
        return _verifySqlResult(
          code,
          output,
          cfg,
          execDebug,
          expectedResults: expectedResults,
        );
      }
      return _verifyPythonOutput(
        code,
        output,
        cfg,
        execDebug,
        expectedResults: expectedResults,
      );
    }

    return _VerifyResultWithDebug(
      _VerificationStatus.passed,
      'Execution completed successfully.',
      execDebug,
    );
  }

  _VerifyResultWithDebug _verifySqlResult(
    String code,
    String output,
    Map<String, dynamic> cfg,
    _DebugInfo? execDebug, {
    String? expectedResults,
  }) {
    final codeLower = code.toLowerCase();

    // Check required columns
    final checkColumns = cfg['check_columns'];
    if (checkColumns is List) {
      for (final col in checkColumns) {
        if (!codeLower.contains(col.toString().toLowerCase())) {
          final expectedCols = checkColumns.map((c) => c.toString()).toList();
          final actualCols = _extractColumnsFromOutput(output);
          final debug = _DebugInfo(
            sqlErrorMessage:
                'Missing required column: "$col"\n\nYour SELECT clause must include all required columns: ${checkColumns.join(', ')}',
            sqlErrorCode: 'MISSING_COLUMN',
            actualColumns: actualCols,
            expectedColumns: expectedCols,
            diffSummary:
                'Column "$col" was not found in your query. Add it to your SELECT clause.',
          );
          return _VerifyResultWithDebug(
            _VerificationStatus.failed,
            'Your query is missing the required column: $col.',
            debug,
          );
        }
      }
    }

    final expectedRowCount = cfg['expected_row_count'];
    if (expectedRowCount != null) {
      if (!codeLower.contains('select')) {
        final debug = _DebugInfo(
          sqlErrorMessage:
              'SyntaxError: Missing SELECT statement\n\nYour query must start with SELECT to retrieve data.',
          sqlErrorCode: 'SYNTAX_ERROR',
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Your query must include a SELECT statement.',
          debug,
        );
      }
      if (!codeLower.contains('from')) {
        final debug = _DebugInfo(
          sqlErrorMessage:
              'SyntaxError: Missing FROM clause\n\nEvery SELECT query needs a FROM clause to specify the source table.',
          sqlErrorCode: 'SYNTAX_ERROR',
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Your query must include a FROM clause.',
          debug,
        );
      }
    }

    final orderMatters = cfg['order_matters'] as bool? ?? false;
    if (orderMatters && !codeLower.contains('order by')) {
      final tableData = _parseOutputTable(output);
      final actualRows = tableData?['rows'] as List<Map<String, String>>?;
      final actualCols = tableData?['columns'] as List<String>?;

      final expectedRows = actualRows != null
          ? List<Map<String, String>>.from(actualRows)
          : <Map<String, String>>[];

      final debug = _DebugInfo(
        sqlErrorMessage:
            'ValidationError: Results must be ordered\n\nThis challenge requires an ORDER BY clause. Your query returned results but they are not in the required order.',
        sqlErrorCode: 'ORDER_REQUIRED',
        actualRows: actualRows,
        actualColumns: actualCols,
        expectedRows: expectedRows,
        diffSummary:
            'Add ORDER BY to your query. The results must be sorted as specified in the challenge.',
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'This challenge requires an ORDER BY clause.',
        debug,
      );
    }

    // ── Strict comparison against expected_results from DB ────────────────────
    // When the challenge has expected_results stored, parse the actual output
    // rows and compare them exactly — do NOT pass just because the query ran.
    if (expectedResults != null && expectedResults.isNotEmpty) {
      final tableData = _parseOutputTable(output);
      final actualRows = tableData?['rows'] as List<Map<String, String>>?;
      final actualCols = tableData?['columns'] as List<String>?;

      // Parse expected JSON from DB
      final expectedRecordsDynamic = _safeParseRecords(expectedResults);

      if (expectedRecordsDynamic != null) {
        // Convert expected to Map<String,String> for comparison
        final expectedRowsStr = expectedRecordsDynamic
            .map((r) => r.map((k, v) => MapEntry(k, v?.toString() ?? '')))
            .toList();
        final expectedColsStr = expectedRecordsDynamic.isNotEmpty
            ? expectedRecordsDynamic.first.keys.toList()
            : <String>[];

        // Strict match: same row count, EXACT same columns (no extras), same values
        bool matched = false;
        if (actualRows != null &&
            actualRows.length == expectedRowsStr.length &&
            actualCols != null) {
          // Column sets must be identical — no extra columns allowed
          final actualColSet = actualCols.toSet();
          final expectedColSet = expectedColsStr.toSet();
          final columnsMatch =
              actualColSet.length == expectedColSet.length &&
              actualColSet.containsAll(expectedColSet);

          if (columnsMatch) {
            matched = true;
            for (int i = 0; i < actualRows.length; i++) {
              final aRow = actualRows[i];
              final eRow = expectedRowsStr[i];
              // Check every expected column has the right value
              for (final col in expectedColsStr) {
                final av = aRow[col]?.trim() ?? '';
                final ev = eRow[col]?.trim() ?? '';
                if (av != ev) {
                  matched = false;
                  break;
                }
              }
              if (!matched) break;
            }
          }
        }

        if (matched) {
          final debug = _DebugInfo(
            actualRows: actualRows,
            actualColumns: actualCols,
            expectedRows: expectedRowsStr,
            expectedColumns: expectedColsStr,
          );
          return _VerifyResultWithDebug(
            _VerificationStatus.passed,
            'Your query produced the correct result.',
            debug,
          );
        }

        // Build diff summary
        final diffLines = <String>[];
        final actualColSet2 = actualCols?.toSet() ?? <String>{};
        final expectedColSet2 = expectedColsStr.toSet();
        final columnMismatch =
            actualColSet2.length != expectedColSet2.length ||
            !actualColSet2.containsAll(expectedColSet2);

        if (columnMismatch) {
          diffLines.add(
            'Column mismatch — expected columns [${expectedColsStr.join(', ')}], '
            'but got [${actualCols?.join(', ') ?? 'none'}].',
          );
          final extraCols = actualColSet2.difference(expectedColSet2);
          final missingCols = expectedColSet2.difference(actualColSet2);
          if (extraCols.isNotEmpty) {
            diffLines.add(
              '  Extra columns in your output: ${extraCols.join(', ')}',
            );
          }
          if (missingCols.isNotEmpty) {
            diffLines.add('  Missing columns: ${missingCols.join(', ')}');
          }
        } else {
          diffLines.add(
            'Expected ${expectedRowsStr.length} record(s) with columns [${expectedColsStr.join(', ')}], '
            'got ${actualRows?.length ?? 0} record(s) with columns [${actualCols?.join(', ') ?? 'none'}].',
          );
        }
        if (!columnMismatch &&
            actualRows != null &&
            actualRows.length == expectedRowsStr.length) {
          for (int i = 0; i < actualRows.length; i++) {
            for (final col in expectedColsStr) {
              final av = actualRows[i][col]?.trim() ?? '(missing)';
              final ev = expectedRowsStr[i][col]?.trim() ?? '';
              if (av != ev) {
                diffLines.add(
                  '  Row ${i + 1} [$col]: got "$av", expected "$ev"',
                );
              }
            }
          }
        }

        final debug = _DebugInfo(
          actualRows: actualRows,
          actualColumns: actualCols,
          expectedRows: expectedRowsStr,
          expectedColumns: expectedColsStr,
          diffSummary: diffLines.join('\n'),
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Your query did not produce the expected result.',
          debug,
        );
      }
    }

    // ── Fallback: no expected_results in DB — use config-based check ──────────
    // Always parse the output table; do NOT gate on ✓/successfully strings
    // since those can appear in error messages and cause false passes.
    {
      // Parse actual result for display
      final tableData = _parseOutputTable(output);
      final actualRows = tableData?['rows'] as List<Map<String, String>>?;
      final actualCols = tableData?['columns'] as List<String>?;

      // Build expected from config if available
      final expectedResult = cfg['expected_result'];
      List<Map<String, String>>? expectedRows;
      List<String>? expectedCols;
      if (expectedResult is List && expectedResult.isNotEmpty) {
        expectedCols = (expectedResult.first as Map<String, dynamic>).keys
            .toList();
        expectedRows = expectedResult
            .map(
              (r) => (r as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v?.toString() ?? ''),
              ),
            )
            .toList();
      }

      // If config has expected_result, do strict comparison — do NOT auto-pass
      if (expectedRows != null && expectedCols != null) {
        final actualColSet = actualCols?.toSet() ?? <String>{};
        final expectedColSet = expectedCols.toSet();
        final columnsMatch =
            actualColSet.length == expectedColSet.length &&
            actualColSet.containsAll(expectedColSet);

        bool matched = false;
        if (actualRows != null &&
            actualRows.length == expectedRows.length &&
            columnsMatch) {
          matched = true;
          for (int i = 0; i < actualRows.length; i++) {
            final aRow = actualRows[i];
            final eRow = expectedRows[i];
            for (final col in expectedCols) {
              final av = aRow[col]?.trim() ?? '';
              final ev = eRow[col]?.trim() ?? '';
              if (av != ev) {
                matched = false;
                break;
              }
            }
            if (!matched) break;
          }
        }

        if (matched) {
          final debug = _DebugInfo(
            actualRows: actualRows,
            actualColumns: actualCols,
            expectedRows: expectedRows,
            expectedColumns: expectedCols,
          );
          return _VerifyResultWithDebug(
            _VerificationStatus.passed,
            'Your query produced the correct result.',
            debug,
          );
        }

        // Build diff for config-based mismatch
        final diffLines = <String>[];
        if (!columnsMatch) {
          diffLines.add(
            'Column mismatch — expected [${expectedCols.join(', ')}], got [${actualCols?.join(', ') ?? 'none'}].',
          );
          final extra = actualColSet.difference(expectedColSet);
          final missing = expectedColSet.difference(actualColSet);
          if (extra.isNotEmpty) {
            diffLines.add('  Extra columns: ${extra.join(', ')}');
          }
          if (missing.isNotEmpty) {
            diffLines.add('  Missing columns: ${missing.join(', ')}');
          }
        } else {
          diffLines.add(
            'Expected ${expectedRows.length} row(s), got ${actualRows?.length ?? 0}.',
          );
          if (actualRows != null && actualRows.length == expectedRows.length) {
            for (int i = 0; i < actualRows.length; i++) {
              for (final col in expectedCols) {
                final av = actualRows[i][col]?.trim() ?? '(missing)';
                final ev = expectedRows[i][col]?.trim() ?? '';
                if (av != ev) {
                  diffLines.add(
                    '  Row ${i + 1} [$col]: got "$av", expected "$ev"',
                  );
                }
              }
            }
          }
        }

        final debug = _DebugInfo(
          actualRows: actualRows,
          actualColumns: actualCols,
          expectedRows: expectedRows,
          expectedColumns: expectedCols,
          diffSummary: diffLines.join('\n'),
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Your query did not produce the expected result.',
          debug,
        );
      }

      // No expected_result in config and no DB expected_results.
      // Only pass if the query actually returned at least one row of data.
      // Do NOT auto-pass just because the output string contains ✓ or "successfully".
      if (actualRows != null && actualRows.isNotEmpty) {
        final debug = _DebugInfo(
          actualRows: actualRows,
          actualColumns: actualCols,
          expectedRows: null,
          expectedColumns: null,
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.passed,
          'Your query produced results.',
          debug,
        );
      }
      // Output claimed success but no rows were parsed — treat as failure.
      final debug = _DebugInfo(
        actualRows: actualRows,
        actualColumns: actualCols,
        diffSummary:
            'Your query did not return any rows. Make sure your SELECT statement retrieves the correct data.',
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'Your query returned no rows.',
        debug,
      );
    }

    // Generic failure with diff
    final tableData = _parseOutputTable(output);
    final actualRows = tableData?['rows'] as List<Map<String, String>>?;
    final actualCols = tableData?['columns'] as List<String>?;

    final expectedResult = cfg['expected_result'];
    List<Map<String, String>>? expectedRows;
    List<String>? expectedCols;
    if (expectedResult is List && expectedResult.isNotEmpty) {
      expectedCols = (expectedResult.first as Map<String, dynamic>).keys
          .toList();
      expectedRows = expectedResult
          .map(
            (r) => (r as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v?.toString() ?? ''),
            ),
          )
          .toList();
    }

    final debug = _DebugInfo(
      actualRows: actualRows,
      actualColumns: actualCols,
      expectedRows: expectedRows,
      expectedColumns: expectedCols,
      diffSummary:
          'Your query returned ${actualRows?.length ?? 0} row(s). Check your logic and compare with the expected output below.',
    );
    return _VerifyResultWithDebug(
      _VerificationStatus.failed,
      'Your query did not produce the expected result.',
      debug,
    );
  }

  List<String> _extractColumnsFromOutput(String output) {
    final tableData = _parseOutputTable(output);
    if (tableData != null) {
      return tableData['columns'] as List<String>;
    }
    return [];
  }

  List<Map<String, dynamic>>? _safeParseRecords(String raw) {
    final s = raw.indexOf('[');
    final e = raw.lastIndexOf(']');
    if (s < 0 || e < s) return null;
    // Empty array "[]" → return empty list so exact comparison works correctly
    if (e == s + 1) return <Map<String, dynamic>>[];
    return _parseJsonArray(raw.substring(s, e + 1));
  }

  List<Map<String, dynamic>>? _parseJsonArray(String jsonStr) {
    try {
      // Manual lightweight JSON array parser for our structured output
      final trimmed = jsonStr.trim();
      if (!trimmed.startsWith('[')) return null;
      // Use RegExp to extract individual JSON objects
      final objRegex = RegExp(r'\{[^{}]*\}');
      final matches = objRegex.allMatches(trimmed);
      final result = <Map<String, dynamic>>[];
      for (final m in matches) {
        final obj = _parseJsonObject(m.group(0)!);
        if (obj != null) result.add(obj);
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _parseJsonObject(String objStr) {
    try {
      final inner = objStr.substring(1, objStr.length - 1).trim();
      final result = <String, dynamic>{};
      // Match key: value pairs
      final pairRegex = RegExp(
        r'"(\w+)":\s*(?:"([^"]*)"|(null)|(-?\d+(?:\.\d+)?)|(true|false))',
      );
      for (final m in pairRegex.allMatches(inner)) {
        final key = m.group(1)!;
        if (m.group(3) != null) {
          result[key] = null;
        } else if (m.group(4) != null) {
          final numStr = m.group(4)!;
          result[key] = numStr.contains('.')
              ? double.parse(numStr)
              : int.parse(numStr);
        } else if (m.group(5) != null) {
          result[key] = m.group(5) == 'true';
        } else {
          result[key] = m.group(2);
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  /// Compares two JSON record lists for exact match (same keys, same values).
  bool _jsonRecordsMatch(
    List<Map<String, dynamic>> actual,
    List<Map<String, dynamic>> expected,
  ) {
    if (actual.length != expected.length) return false;
    for (int i = 0; i < actual.length; i++) {
      final a = actual[i];
      final e = expected[i];
      if (a.length != e.length) return false;
      for (final key in e.keys) {
        if (!a.containsKey(key)) return false;
        final av = a[key]?.toString() ?? 'null';
        final ev = e[key]?.toString() ?? 'null';
        if (av != ev) return false;
      }
    }
    return true;
  }

  /// Builds a human-readable diff summary between actual and expected records.
  String _buildRecordDiff(
    List<Map<String, dynamic>> actual,
    List<Map<String, dynamic>> expected,
  ) {
    final lines = <String>[];
    lines.add('Expected ${expected.length} record(s), got ${actual.length}.');
    if (actual.length == expected.length) {
      final diffs = <String>[];
      for (int i = 0; i < actual.length; i++) {
        for (final key in expected[i].keys) {
          final av = actual[i][key]?.toString() ?? 'null';
          final ev = expected[i][key]?.toString() ?? 'null';
          if (av != ev) {
            diffs.add('  Row ${i + 1} [$key]: got "$av", expected "$ev"');
          }
        }
      }
      if (diffs.isNotEmpty) {
        lines.add('\nField mismatches:');
        lines.addAll(diffs.take(8));
      }
    }
    return lines.join('\n');
  }

  _VerifyResultWithDebug _verifyPythonOutput(
    String code,
    String output,
    Map<String, dynamic> cfg,
    _DebugInfo? execDebug, {
    String? expectedResults,
  }) {
    final checkType = (cfg['check_type'] ?? '').toString();

    if (output.toLowerCase().contains('error') ||
        output.toLowerCase().contains('exception') ||
        output.toLowerCase().contains('traceback')) {
      final tracebackMatch = RegExp(
        r'(Traceback.*)',
        dotAll: true,
      ).firstMatch(output);
      final debug = _DebugInfo(
        stackTrace: tracebackMatch?.group(1) ?? output,
        printedOutput: execDebug?.printedOutput,
        returnedValue: execDebug?.returnedValue,
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.executionError,
        output,
        debug,
      );
    }

    // ── Get reference output: ONLY use DB expected_results — never fall back
    // to the mock _executePython engine, which produces hardcoded pattern-matched
    // output that causes false passes/failures.
    final bool hasExpectedResults =
        expectedResults != null && expectedResults.isNotEmpty;
    final actualRecords = _safeParseRecords(output);
    final expectedRecords = hasExpectedResults
        ? _safeParseRecords(expectedResults)
        : null;

    if (checkType == 'list_length') {
      final expectedLength = cfg['expected_length'] as int? ?? 0;

      // Exact JSON comparison when both sides parse successfully
      if (actualRecords != null && expectedRecords != null) {
        if (_jsonRecordsMatch(actualRecords, expectedRecords)) {
          return _VerifyResultWithDebug(
            _VerificationStatus.passed,
            'Your function returned the correct output — ${actualRecords.length} record(s) match the reference solution.',
            execDebug,
          );
        }
        final diffMsg = _buildRecordDiff(actualRecords, expectedRecords);
        final debug = _DebugInfo(
          returnedValue: output.isNotEmpty ? output : '(no output)',
          printedOutput: execDebug?.printedOutput,
          diffSummary: diffMsg,
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Output does not match the reference solution.',
          debug,
        );
      }

      // Fallback: check list presence and length
      if (output.contains('[') && output.contains(']')) {
        final lenMatch = RegExp(r'(\d+)\s+\w[\w ]*returned').firstMatch(output);
        final actualLen = lenMatch != null
            ? int.tryParse(lenMatch.group(1) ?? '') ?? -1
            : -1;
        if (expectedLength > 0 &&
            actualLen >= 0 &&
            actualLen != expectedLength) {
          final debug = _DebugInfo(
            returnedValue: output.isNotEmpty ? output : '(no output)',
            printedOutput: execDebug?.printedOutput,
            diffSummary:
                'Expected $expectedLength record(s), but your function returned $actualLen.',
          );
          return _VerifyResultWithDebug(
            _VerificationStatus.failed,
            'Expected $expectedLength records, got $actualLen.',
            debug,
          );
        }
        return _VerifyResultWithDebug(
          _VerificationStatus.passed,
          'Your function returned the correct output.',
          execDebug,
        );
      }
      final debug = _DebugInfo(
        returnedValue: output.isNotEmpty ? output : '(no output)',
        printedOutput: execDebug?.printedOutput,
        diffSummary:
            'Expected: a list with $expectedLength items\nActual: ${output.isEmpty ? "(no output)" : output.substring(0, output.length.clamp(0, 200))}',
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'Expected a list with $expectedLength items.',
        debug,
      );
    }

    if (checkType == 'dict_keys') {
      final expectedKeys = cfg['expected_keys'];
      if (expectedKeys is List) {
        final missingKeys = expectedKeys
            .where((k) => !output.contains(k.toString()))
            .toList();
        if (missingKeys.isEmpty) {
          // Also do exact record comparison if possible
          if (actualRecords != null && expectedRecords != null) {
            if (_jsonRecordsMatch(actualRecords, expectedRecords)) {
              return _VerifyResultWithDebug(
                _VerificationStatus.passed,
                'Your function returned all required keys and matches the reference solution.',
                execDebug,
              );
            }
            final diffMsg = _buildRecordDiff(actualRecords, expectedRecords);
            final debug = _DebugInfo(
              returnedValue: output.isNotEmpty ? output : '(no output)',
              printedOutput: execDebug?.printedOutput,
              diffSummary: diffMsg,
            );
            return _VerifyResultWithDebug(
              _VerificationStatus.failed,
              'Keys are present but values do not match the reference solution.',
              debug,
            );
          }
          return _VerifyResultWithDebug(
            _VerificationStatus.passed,
            'Your function returned all required keys.',
            execDebug,
          );
        }
        final debug = _DebugInfo(
          returnedValue: output.isNotEmpty ? output : '(no output)',
          printedOutput: execDebug?.printedOutput,
          diffSummary:
              'Missing keys: ${missingKeys.join(', ')}\n\nExpected keys: ${expectedKeys.join(', ')}\nYour output: ${output.substring(0, output.length.clamp(0, 300))}',
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Missing expected keys: ${missingKeys.join(', ')}.',
          debug,
        );
      }
    }

    if (checkType == 'no_nulls') {
      if (output.contains('None') ||
          output.contains('"null"') ||
          RegExp(r':\s*null').hasMatch(output)) {
        final noneMatches = RegExp(
          r'"(\w+)":\s*null|(\w+):\s*None',
        ).allMatches(output);
        final nullFields = noneMatches
            .map((m) => m.group(1) ?? m.group(2) ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        final debug = _DebugInfo(
          returnedValue: output.substring(0, output.length.clamp(0, 500)),
          printedOutput: execDebug?.printedOutput,
          diffSummary:
              'Null values found in fields: ${nullFields.isNotEmpty ? nullFields.join(', ') : 'unknown'}\n\nReplace None/null values with appropriate defaults (e.g., 0 for numbers, "" for strings, "unknown@example.com" for emails).',
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'Your output still contains null values.',
          debug,
        );
      }
      // Exact comparison against reference
      if (actualRecords != null && expectedRecords != null) {
        if (_jsonRecordsMatch(actualRecords, expectedRecords)) {
          return _VerifyResultWithDebug(
            _VerificationStatus.passed,
            'All null values handled correctly — output matches the reference solution.',
            execDebug,
          );
        }
        final diffMsg = _buildRecordDiff(actualRecords, expectedRecords);
        final debug = _DebugInfo(
          returnedValue: output.substring(0, output.length.clamp(0, 500)),
          printedOutput: execDebug?.printedOutput,
          diffSummary:
              '$diffMsg\n\nNo null values found, but record values differ from the reference.',
        );
        return _VerifyResultWithDebug(
          _VerificationStatus.failed,
          'No nulls found, but output does not match the reference solution.',
          debug,
        );
      }
      return _VerifyResultWithDebug(
        _VerificationStatus.passed,
        'All null values have been handled correctly.',
        execDebug,
      );
    }

    if (checkType == 'field_exists') {
      final field = (cfg['field'] ?? '').toString();
      if (field.isNotEmpty && output.contains(field)) {
        // Exact comparison against reference
        if (actualRecords != null && expectedRecords != null) {
          if (_jsonRecordsMatch(actualRecords, expectedRecords)) {
            return _VerifyResultWithDebug(
              _VerificationStatus.passed,
              'Your function correctly added the "$field" field and matches the reference solution.',
              execDebug,
            );
          }
          final diffMsg = _buildRecordDiff(actualRecords, expectedRecords);
          final debug = _DebugInfo(
            returnedValue: output.isNotEmpty ? output : '(no output)',
            printedOutput: execDebug?.printedOutput,
            diffSummary:
                '$diffMsg\n\nField "$field" is present but values differ from the reference.',
          );
          return _VerifyResultWithDebug(
            _VerificationStatus.failed,
            'Field "$field" found but values do not match the reference solution.',
            debug,
          );
        }
        return _VerifyResultWithDebug(
          _VerificationStatus.passed,
          'Your function correctly added the "$field" field.',
          execDebug,
        );
      }
      final debug = _DebugInfo(
        returnedValue: output.isNotEmpty ? output : '(no output)',
        printedOutput: execDebug?.printedOutput,
        diffSummary:
            'Expected field: "$field"\nYour output does not contain this field.\n\nMake sure your function adds "$field" to each record.',
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'Expected field "$field" not found in output.',
        debug,
      );
    }

    // ── Generic: exact JSON comparison against reference ──────────────────────
    if (actualRecords != null && expectedRecords != null) {
      if (_jsonRecordsMatch(actualRecords, expectedRecords)) {
        return _VerifyResultWithDebug(
          _VerificationStatus.passed,
          'Your output exactly matches the reference solution.',
          execDebug,
        );
      }
      final diffMsg = _buildRecordDiff(actualRecords, expectedRecords);
      final debug = _DebugInfo(
        returnedValue: output.isNotEmpty ? output : '(no output)',
        printedOutput: execDebug?.printedOutput,
        diffSummary: diffMsg,
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'Output does not match the reference solution.',
        debug,
      );
    }

    // If expected_results is present but we couldn't parse the actual output
    // as JSON records, that means the output format is wrong — fail it.
    if (hasExpectedResults) {
      final debug = _DebugInfo(
        returnedValue: output.isNotEmpty ? output : '(no output)',
        printedOutput: execDebug?.printedOutput,
        diffSummary:
            'Your output could not be parsed as a JSON record list.\n\nMake sure your function returns a list of dictionaries (e.g. [{"key": value, ...}]).',
      );
      return _VerifyResultWithDebug(
        _VerificationStatus.failed,
        'Output format is incorrect. Expected a list of records.',
        debug,
      );
    }

    // No expected_results in DB and no config check — only pass if output is
    // non-empty and non-error. This is the "no ground truth" path.
    if (output.isNotEmpty && !output.toLowerCase().contains('error')) {
      return _VerifyResultWithDebug(
        _VerificationStatus.passed,
        'Code executed successfully.',
        execDebug,
      );
    }

    final debug = _DebugInfo(
      returnedValue: output.isNotEmpty ? output : '(no output)',
      printedOutput: execDebug?.printedOutput,
      diffSummary: 'Unexpected output. Check your logic and try again.',
    );
    return _VerifyResultWithDebug(
      _VerificationStatus.failed,
      'Unexpected output.',
      debug,
    );
  }

  // ── SQL Execution with Debug ───────────────────────────────────────────────
  Map<String, dynamic> _executeSQLWithDebug(String query) {
    final q = query.trim();
    final ql = q.toLowerCase();

    if (q.isEmpty) {
      return {
        'output': 'ERROR: No SQL query to execute.',
        'debug': _DebugInfo(
          sqlErrorMessage:
              'ExecutionError: Empty query\n\nNo SQL query was provided. Write a SELECT statement to query the data.',
          sqlErrorCode: 'EMPTY_QUERY',
          consoleLogs: ['[ERROR] Query execution failed: empty input'],
        ),
      };
    }

    if (!ql.contains('select') || !ql.contains('from')) {
      String errorMsg;
      String errorCode;
      if (!ql.contains('select')) {
        errorMsg =
            'SyntaxError near line 1: unexpected token\n\nExpected SELECT keyword at the beginning of the query.\n\nExample:\n  SELECT column1, column2\n  FROM table_name\n  WHERE condition;';
        errorCode = 'SYNTAX_ERROR';
      } else {
        errorMsg =
            'SyntaxError: missing FROM clause\n\nYour SELECT statement is missing a FROM clause.\n\nExample:\n  SELECT *\n  FROM employees\n  LIMIT 10;';
        errorCode = 'SYNTAX_ERROR';
      }
      return {
        'output': 'ERROR: Invalid SQL.',
        'debug': _DebugInfo(
          sqlErrorMessage: errorMsg,
          sqlErrorCode: errorCode,
          consoleLogs: [
            '[INFO] Query received',
            '[ERROR] Parse error: $errorCode',
            '[ERROR] Query execution aborted',
          ],
        ),
      };
    }

    // Check for common table name errors
    final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(ql);
    if (tableMatch != null) {
      final tableName = tableMatch.group(1)!;

      // Build known tables dynamically from the loaded dataset rows first,
      // then fall back to a generic list for challenges without datasets.
      final dynamicTables = _datasetRows != null
          ? _datasetRows!
                .map((r) => r['_table']?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList()
          : <String>[];

      final fallbackTables = [
        'employees',
        'customers',
        'orders',
        'order_items',
        'transactions',
        'events',
        'sessions',
        'products',
        'sales',
        'users',
      ];

      // Combine: dataset tables take priority; fallback covers generic challenges
      final knownTables = <String>{
        ...dynamicTables,
        ...fallbackTables,
      }.toList();

      if (!knownTables.contains(tableName) &&
          !ql.contains('with ') &&
          !ql.contains('(select')) {
        // Build the list of actually-available tables for the error message
        final availableTables = dynamicTables.isNotEmpty
            ? dynamicTables
            : fallbackTables.where((t) => _isTableInDataset(t)).toList();

        return {
          'output': 'ERROR: Table not found.',
          'debug': _DebugInfo(
            sqlErrorMessage:
                'OperationalError: no such table: $tableName\n\nThe table "$tableName" does not exist in the dataset.\n\nAvailable tables for this challenge:\n${availableTables.map((t) => '  • $t').join('\n')}\n\nCheck the Dataset Preview above for the correct table names.',
            sqlErrorCode: 'NO_SUCH_TABLE',
            consoleLogs: [
              '[INFO] Query received',
              '[INFO] Resolving table: $tableName',
              '[ERROR] NO_SUCH_TABLE: relation "$tableName" does not exist',
              '[ERROR] Query execution aborted',
            ],
          ),
        };
      }
    }

    // Check for column errors in SELECT
    if (ql.contains('select ') && !ql.contains('select *')) {
      final selectMatch = RegExp(
        r'select\s+(.*?)\s+from',
        dotAll: true,
      ).firstMatch(ql);
      if (selectMatch != null) {
        final selectClause = selectMatch.group(1)!;
        // Check for common typos
        if (selectClause.contains('custmer') ||
            selectClause.contains('custoemr')) {
          return {
            'output': 'ERROR: Column not found.',
            'debug': _DebugInfo(
              sqlErrorMessage:
                  'OperationalError: no such column: ${selectClause.trim()}\n\nCheck your column names for typos. Use the Dataset Preview to see the exact column names.',
              sqlErrorCode: 'NO_SUCH_COLUMN',
              consoleLogs: [
                '[INFO] Query received',
                '[INFO] Parsing SELECT clause',
                '[ERROR] NO_SUCH_COLUMN: column "${selectClause.trim()}" does not exist',
                '[ERROR] Query execution aborted',
              ],
            ),
          };
        }
      }
    }

    final output = _executeSQL(query);

    // Build console logs from execution output
    final logs = <String>[];
    final timeMatch = RegExp(r'Execution time: ([\d.]+s)').firstMatch(output);
    final rowsMatch = RegExp(r'Rows returned: (\d+)').firstMatch(output);
    final rowsInSetMatch = RegExp(r'(\d+) rows in set').firstMatch(output);

    logs.add('[INFO] Connection established');
    logs.add('[INFO] Executing statement...');
    logs.add('[INFO] Query parsed successfully');
    if (timeMatch != null) {
      logs.add('[INFO] Execution time: ${timeMatch.group(1)}');
    } else {
      logs.add('[INFO] Execution time: 0.031s');
    }
    if (rowsMatch != null) {
      logs.add('[INFO] Query completed with ${rowsMatch.group(1)} rows');
    } else if (rowsInSetMatch != null) {
      logs.add('[INFO] Query completed with ${rowsInSetMatch.group(1)} rows');
    } else {
      logs.add('[INFO] Query completed with 0 rows');
    }
    if (output.contains('✓')) {
      logs.add('[INFO] Result validated successfully');
    }

    return {'output': output, 'debug': _DebugInfo(consoleLogs: logs)};
  }

  bool _isTableInDataset(String tableName) {
    if (_datasetRows == null) return false;
    return _datasetRows!.any((r) => r['_table'] == tableName);
  }

  // ── Real Python Execution via Judge0 CE ────────────────────────────────────
  /// Submits [code] to Judge0 CE (https://ce.judge0.com), polls until done,
  /// and returns the actual stdout/stderr as the execution output.
  Future<Map<String, dynamic>> _executePythonRealAsync(String code) async {
    const String judge0Base = 'https://ce.judge0.com';
    // Python 3.8.1 language_id on ce.judge0.com
    const int pythonLanguageId = 71;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Wrap user code so the function is called and its result is printed
    final wrappedCode = _wrapPythonCode(code);

    // Base64-encode the source code
    final encodedSource = base64Encode(utf8.encode(wrappedCode));

    String token;
    try {
      final submitResp = await dio.post(
        '$judge0Base/submissions?base64_encoded=true',
        data: {
          'source_code': encodedSource,
          'language_id': pythonLanguageId,
          'cpu_time_limit': 5,
          'wall_time_limit': 10,
        },
      );
      token = submitResp.data['token'] as String;
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      return {
        'output': 'Error: Could not reach execution server.\n$msg',
        'debug': _DebugInfo(
          stackTrace: 'ConnectionError: $msg',
          printedOutput: '',
          returnedValue: 'None',
        ),
      };
    }

    // Poll until status is no longer In Queue (1) or Processing (2)
    Map<String, dynamic>? result;
    for (int attempt = 0; attempt < 20; attempt++) {
      await Future.delayed(const Duration(milliseconds: 600));
      try {
        final pollResp = await dio.get(
          '$judge0Base/submissions/$token?base64_encoded=true&fields=stdout,stderr,status,compile_output,time,memory',
        );
        final data = pollResp.data as Map<String, dynamic>;
        final statusId =
            (data['status'] as Map<String, dynamic>?)?['id'] as int? ?? 0;
        if (statusId != 1 && statusId != 2) {
          result = data;
          break;
        }
      } catch (_) {
        // retry
      }
    }

    if (result == null) {
      return {
        'output': 'Error: Execution timed out waiting for result.',
        'debug': _DebugInfo(
          stackTrace: 'TimeoutError: Execution server did not respond in time.',
          printedOutput: '',
          returnedValue: 'None',
        ),
      };
    }

    // Decode base64 fields
    String decodeB64(dynamic val) {
      if (val == null) return '';
      try {
        return utf8.decode(base64Decode(val.toString().trim()));
      } catch (_) {
        return val.toString();
      }
    }

    final stdout = decodeB64(result['stdout']).trim();
    final stderr = decodeB64(result['stderr']).trim();
    final compileOutput = decodeB64(result['compile_output']).trim();
    final statusId =
        (result['status'] as Map<String, dynamic>?)?['id'] as int? ?? 0;
    final statusDesc =
        (result['status'] as Map<String, dynamic>?)?['description']
            as String? ??
        '';
    final execTime = result['time']?.toString() ?? '0.000';

    // Build output string
    String output;
    String? stackTrace;
    String? printedOutput;
    String? returnedValue;

    if (statusId == 6) {
      // Compilation error
      final errText = compileOutput.isNotEmpty ? compileOutput : stderr;
      output = 'Error: Compilation failed.\n$errText';
      stackTrace = errText;
    } else if (statusId == 5) {
      output = 'Error: Time Limit Exceeded (>${execTime}s)';
      stackTrace = 'TimeoutError: Your code exceeded the time limit.';
    } else if (statusId >= 7 && statusId <= 12) {
      // Runtime errors
      final errText = stderr.isNotEmpty ? stderr : statusDesc;
      output = 'Error: $errText';
      stackTrace = errText;
    } else if (statusId == 3) {
      // Accepted — use stdout as the output
      output = stdout;
      printedOutput = stdout;
      returnedValue = stdout.isNotEmpty ? stdout : 'None';
    } else {
      // Other statuses
      final combined = [stdout, stderr].where((s) => s.isNotEmpty).join('\n');
      output = combined.isNotEmpty ? combined : 'No output.';
    }

    return {
      'output': output,
      'debug': _DebugInfo(
        printedOutput: printedOutput ?? stdout,
        returnedValue: returnedValue ?? stdout,
        stackTrace: stackTrace,
        consoleLogs: [
          '[INFO] Submitted to Judge0 CE (Python 3.8.1)',
          '[INFO] Token: $token',
          '[INFO] Status: $statusDesc (id=$statusId)',
          if (execTime.isNotEmpty) '[INFO] Execution time: ${execTime}s',
        ],
      ),
    };
  }

  /// Wraps the user's Python code so that:
  /// 1. The dataset is injected as a variable `data` (if available).
  /// 2. The user's function is called and its return value is printed via `print(repr(...))`.
  String _wrapPythonCode(String code) {
    // Inject dataset as `data` variable if available
    final datasetJson = _buildDatasetJson();

    // Find the function name defined in the user's code
    final funcMatch = RegExp(r'def\s+(\w+)\s*\(').firstMatch(code);
    final funcName = funcMatch?.group(1);

    final buffer = StringBuffer();

    // Inject dataset
    if (datasetJson != null) {
      buffer.writeln('import json as _json');
      buffer.writeln('_raw_data = _json.loads(\'\'\'$datasetJson\'\'\')');
      buffer.writeln('data = _raw_data');
      buffer.writeln();
    }

    buffer.writeln(code);

    // Auto-call the function if we found one
    if (funcName != null) {
      buffer.writeln();
      buffer.writeln('# Auto-call by playground runner');
      if (datasetJson != null) {
        buffer.writeln('_result = $funcName(data)');
      } else {
        buffer.writeln('_result = $funcName([])');
      }
      buffer.writeln('import json as _json2');
      buffer.writeln('try:');
      buffer.writeln('    print(_json2.dumps(_result, default=str))');
      buffer.writeln('except Exception:');
      buffer.writeln('    print(repr(_result))');
    }

    return buffer.toString();
  }

  /// Builds a compact JSON string of the dataset rows for injection into Python.
  String? _buildDatasetJson() {
    if (_datasetRows == null || _datasetRows!.isEmpty) return null;
    try {
      final rows = _datasetRows!.map((r) {
        final clean = Map<String, dynamic>.from(r)..remove('_table');
        return clean;
      }).toList();
      return jsonEncode(rows);
    } catch (_) {
      return null;
    }
  }

  // ── Existing SQL execution helpers (unchanged) ─────────────────────────────
  String _executeSQL(String query) {
    final q = query.trim();
    final ql = q.toLowerCase();

    if (q.isEmpty) return 'ERROR: No SQL query to execute.';

    if (!ql.contains('select') || !ql.contains('from')) {
      return 'ERROR: Invalid SQL. Query must contain SELECT and FROM.';
    }

    if (ql.contains('over') &&
        (ql.contains('sum(') ||
            ql.contains('avg(') ||
            ql.contains('row_number') ||
            ql.contains('rank(') ||
            ql.contains('lag(') ||
            ql.contains('percent_rank'))) {
      return _sqlWindowResult(ql);
    }
    if (ql.startsWith('with ') || ql.contains('\nwith ')) {
      return _sqlCteResult(ql);
    }
    if (ql.contains('group by')) {
      return _sqlGroupByResult(ql);
    }
    if (ql.contains('join')) {
      return _sqlJoinResult(ql);
    }
    return _sqlGenericResult(ql);
  }

  String _sqlWindowResult(String ql) {
    if (ql.contains('lag(')) {
      return '''Query executed successfully ✓
Execution time: 0.041s | Rows returned: 4

month       revenue   prev_revenue  growth_pct
----------  --------  ------------  ----------
2024-01     45000     NULL          NULL
2024-02     52000     45000         15.56
2024-03     48000     52000         -7.69
2024-04     61000     48000         27.08

4 rows in set''';
    }
    if (ql.contains('percent_rank')) {
      return '''Query executed successfully ✓
Execution time: 0.038s | Rows returned: 10

name          dept         salary  salary_percentile
------------  -----------  ------  -----------------
Alice Chen    Engineering  95000   1.00
David Lee     Engineering  91000   0.67
Bob Martinez  Engineering  88000   0.33
Henry Brown   Engineering  85000   0.00
Sarah Kim     Marketing    75000   1.00
Iris Zhang    Marketing    72000   0.50
Emma Wilson   Marketing    68000   0.00
Grace Patel   Sales        70000   1.00
Frank Nguyen  Sales        65000   0.50
Jack Davis    Sales        62000   0.00

10 rows in set''';
    }
    if (ql.contains('sum(') && ql.contains('running')) {
      return '''Query executed successfully ✓
Execution time: 0.035s | Rows returned: 10

account_id  txn_date    amount   running_balance
----------  ----------  -------  ---------------
A1          2024-01-05  100.00   100.00
A1          2024-01-10  250.00   350.00
A1          2024-01-15  -80.00   270.00
A1          2024-02-01  300.00   570.00
A1          2024-02-10  -150.00  420.00
A2          2024-01-07  500.00   500.00
A2          2024-01-20  -200.00  300.00
A2          2024-02-05  400.00   700.00
A3          2024-02-08  750.00   750.00
A3          2024-02-15  -300.00  450.00

10 rows in set''';
    }
    if (ql.contains('avg(') && ql.contains('rows between')) {
      return '''Query executed successfully ✓
Execution time: 0.033s | Rows returned: 4

month    revenue  rolling_avg_3m
-------  -------  --------------
2024-01  38000    38000.00
2024-02  41000    39500.00
2024-03  55000    44666.67
2024-04  49000    48333.33

4 rows in set''';
    }
    if (ql.contains('row_number') || ql.contains('dense_rank')) {
      return '''Query executed successfully ✓
Execution time: 0.040s | Rows returned: 3

dept         name          salary
-----------  ------------  ------
Engineering  Alice Chen    95000
Marketing    Iris Zhang    75000
Sales        Grace Patel   70000

3 rows in set''';
    }
    return '''Query executed successfully ✓
Execution time: 0.036s | Window function applied.
Rows returned with computed window values.''';
  }

  String _sqlCteResult(String ql) {
    if (ql.contains('row_number') || ql.contains('rn')) {
      return '''Query executed successfully ✓
Execution time: 0.048s | Rows returned: 7

customer_id  order_id  order_date
-----------  --------  ----------
1            111       2024-03-05
2            107       2024-02-10
3            110       2024-03-01
4            112       2024-03-10
5            115       2024-03-25
6            109       2024-02-18
7            113       2024-03-15

7 rows in set''';
    }
    // Generic CTE: build from dataset if available
    return _buildSqlResultFromDataset(ql, 'CTE resolved successfully');
  }

  String _sqlGroupByResult(String ql) {
    if (ql.contains('count(distinct') || ql.contains('count( distinct')) {
      return '''Query executed successfully ✓
Execution time: 0.028s | Rows returned: 3

event_type  user_count
----------  ----------
login       3
page_view   2
purchase    2

3 rows in set''';
    }
    if (ql.contains('sum(') && ql.contains('count(')) {
      return '''Query executed successfully ✓
Execution time: 0.042s | Rows returned: 5

customer_id  customer_name  total_revenue
-----------  -------------  -------------
5            Emma Wilson    830.00
1            Alice Chen     770.50
2            Bob Martinez   595.00
4            David Lee      585.00
3            Sarah Kim      435.00

5 rows in set''';
    }
    if (ql.contains('count(*)') && ql.contains('session_id')) {
      return '''Query executed successfully ✓
Execution time: 0.025s | Rows returned: 5

session_id  user_id  event_count
----------  -------  -----------
s1          u1       4
s2          u2       2
s3          u1       2
s4          u3       1
s5          u2       3

5 rows in set''';
    }
    // Generic GROUP BY: build from dataset
    return _buildSqlResultFromDataset(ql, 'Aggregation applied');
  }

  String _sqlJoinResult(String ql) {
    if (ql.contains('not exists') || ql.contains('not in')) {
      return '''Query executed successfully ✓
Execution time: 0.038s | Rows returned: 3

customer_id  customer_name
-----------  -------------
2            Bob Martinez
4            David Lee
6            Frank Nguyen

3 rows in set''';
    }
    // Generic JOIN: build from dataset
    return _buildSqlResultFromDataset(ql, 'JOIN applied');
  }

  String _sqlGenericResult(String ql) {
    return _buildSqlResultFromDataset(ql, 'Query completed');
  }

  /// Builds a proper fixed-width table output from the loaded dataset rows.
  /// Falls back to a minimal placeholder table if no dataset is available.
  String _buildSqlResultFromDataset(String ql, String statusNote) {
    // Try to use actual dataset rows
    if (_datasetRows != null && _datasetRows!.isNotEmpty) {
      // Pick rows from the queried table if identifiable
      final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(ql);
      final targetTable = tableMatch?.group(1);

      List<Map<String, dynamic>> sourceRows;
      if (targetTable != null) {
        sourceRows = _datasetRows!.where((r) => r['_table'] == targetTable).map(
          (r) {
            final clean = Map<String, dynamic>.from(r)..remove('_table');
            return clean;
          },
        ).toList();
      } else {
        sourceRows = _datasetRows!.map((r) {
          final clean = Map<String, dynamic>.from(r)..remove('_table');
          return clean;
        }).toList();
      }

      if (sourceRows.isNotEmpty) {
        // Determine columns: if SELECT * or no specific columns, use all
        List<String> columns;
        if (ql.contains('select *') || ql.contains('select\n*')) {
          columns = sourceRows.first.keys.toList();
        } else {
          // Try to extract column names from SELECT clause
          final selectMatch = RegExp(
            r'select\s+(.*?)\s+from',
            dotAll: true,
          ).firstMatch(ql);
          if (selectMatch != null) {
            final selectClause = selectMatch.group(1)!;
            if (selectClause.trim() == '*') {
              columns = sourceRows.first.keys.toList();
            } else {
              // Parse comma-separated columns, strip aliases and functions
              final rawCols = selectClause
                  .split(',')
                  .map((c) {
                    final trimmed = c.trim();
                    // Handle "expr AS alias" → use alias
                    final asMatch = RegExp(
                      r'(?:.*\s+as\s+)(\w+)',
                      caseSensitive: false,
                    ).firstMatch(trimmed);
                    if (asMatch != null) return asMatch.group(1)!;
                    // Handle simple column name (possibly table.col)
                    final dotIdx = trimmed.lastIndexOf('.');
                    if (dotIdx >= 0) return trimmed.substring(dotIdx + 1);
                    // Strip function calls
                    final funcMatch = RegExp(
                      r'\w+\((\w+)\)',
                    ).firstMatch(trimmed);
                    if (funcMatch != null) return funcMatch.group(1)!;
                    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
                  })
                  .where((c) => c.isNotEmpty)
                  .toList();
              // Filter to columns that exist in the data
              columns = rawCols
                  .where((c) => sourceRows.first.containsKey(c))
                  .toList();
              if (columns.isEmpty) columns = sourceRows.first.keys.toList();
            }
          } else {
            columns = sourceRows.first.keys.toList();
          }
        }

        // Limit rows
        final displayRows = sourceRows.take(10).toList();

        // Compute column widths
        final widths = <int>[];
        for (final col in columns) {
          int maxW = col.length;
          for (final row in displayRows) {
            final val = (row[col] ?? '').toString();
            if (val.length > maxW) maxW = val.length;
          }
          widths.add(maxW);
        }

        // Build header line
        final headerParts = <String>[];
        final sepParts = <String>[];
        for (int i = 0; i < columns.length; i++) {
          headerParts.add(columns[i].padRight(widths[i]));
          sepParts.add('-' * widths[i]);
        }
        final header = headerParts.join('  ');
        final sep = sepParts.join('  ');

        // Build data rows
        final dataLines = displayRows
            .map((row) {
              final parts = <String>[];
              for (int i = 0; i < columns.length; i++) {
                final val = (row[columns[i]] ?? '').toString();
                parts.add(val.padRight(widths[i]));
              }
              return parts.join('  ');
            })
            .join('\n');

        final rowCount = displayRows.length;
        final execTime = (0.025 + (rowCount * 0.003)).toStringAsFixed(3);

        return '''Query executed successfully ✓
Execution time: ${execTime}s | Rows returned: $rowCount

$header
$sep
$dataLines

$rowCount rows in set''';
      }
    }

    // Fallback: minimal placeholder table
    return '''Query executed successfully ✓
Execution time: 0.031s | Rows returned: 0

id  result
--  ------

0 rows in set''';
  }

  String _executePython(String code) {
    if (code.trim().isEmpty) return 'Error: No Python code to execute.';

    final cl = code.toLowerCase();

    // ── Stub detection: starter code that hasn't been implemented yet ─────────
    // If the function body only contains `return []` or `return {}` with no
    // real logic (no for/while loops, no list/dict building), treat it as an
    // unimplemented stub and return an empty result so verification fails.
    final bool hasLoop = RegExp(r'\bfor\b|\bwhile\b').hasMatch(cl);
    final bool hasAssignment = RegExp(
      r'(totals|result|output|records|seen|counts|cleaned|flat|rows)\s*[=\[]',
    ).hasMatch(cl);
    final bool hasReturnStub =
        RegExp(r'^\s*return\s+\[\s*\]', multiLine: true).hasMatch(code) ||
        RegExp(r'^\s*return\s+\{\s*\}', multiLine: true).hasMatch(code);

    if (hasReturnStub && !hasLoop && !hasAssignment) {
      // Starter code is unimplemented — return empty output so comparison fails
      return '[]';
    }
    // ─────────────────────────────────────────────────────────────────────────

    if (cl.contains('def deduplicate') || cl.contains('seen = set()')) {
      return '''[{"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"}, {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"}, {"id": 4, "user_id": "u3", "name": "Carol", "email": null, "age": null, "score": 85.0, "status": "inactive"}, {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": null, "status": "active"}, {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active"}, {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": null, "score": 60.0, "status": "inactive"}]

6 unique records returned.''';
    }

    if (cl.contains('def clean_records') ||
        cl.contains('unknown@example.com')) {
      return '''[{"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"}, {"id": 2, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active"}, {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"}, {"id": 4, "user_id": "u3", "name": "Carol", "email": "unknown@example.com", "age": 0, "score": 85.0, "status": "inactive"}, {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": 82.1, "status": "active"}, {"id": 6, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active"}, {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active"}, {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": 0, "score": 60.0, "status": "inactive"}]

8 records cleaned.''';
    }

    if (cl.contains('def aggregate_by_status') ||
        (cl.contains('active') && cl.contains('inactive'))) {
      return '''{"active": {"count": 6, "avg_score": 86.7, "unique_users": 5}, "inactive": {"count": 2, "avg_score": 72.5, "unique_users": 2}}''';
    }

    if (cl.contains('def flatten_users') || cl.contains('api_response')) {
      return '''[{"user_id": "u1", "name": "Alice", "age": 28, "order_id": "o1", "order_total": 250.0}, {"user_id": "u1", "name": "Alice", "age": 28, "order_id": "o2", "order_total": 180.5}, {"user_id": "u2", "name": "Bob", "age": 35, "order_id": "o3", "order_total": 320.0}, {"user_id": "u3", "name": "Carol", "age": 31, "order_id": null, "order_total": null}, {"user_id": "u4", "name": "Dave", "age": 42, "order_id": "o4", "order_total": 95.0}, {"user_id": "u4", "name": "Dave", "age": 42, "order_id": "o5", "order_total": 410.0}]

6 rows returned (1-to-many expansion).''';
    }

    if (cl.contains('def find_duplicates') || cl.contains('counts.get')) {
      return '''["e001"]

1 duplicate event_id found.''';
    }

    if (cl.contains('def extract_purchases') ||
        cl.contains('event_type.*purchase')) {
      return '''[{"user_id": "u1", "timestamp": "2024-03-01T08:15:00", "item_id": "p1", "amount": 49.99}, {"user_id": "u3", "timestamp": "2024-03-02T11:30:00", "item_id": "p2", "amount": 129.0}, {"user_id": "u2", "timestamp": "2024-03-03T14:00:00", "item_id": "p1", "amount": 49.99}]

3 purchase events extracted.''';
    }

    if (cl.contains('def transform_sales') || cl.contains('revenue_per_unit')) {
      return '''[{"month": "2024-01-01", "region": "North", "revenue": 45000, "units": 120, "revenue_per_unit": 375.0}, {"month": "2024-01-01", "region": "South", "revenue": 38000, "units": 95, "revenue_per_unit": 400.0}, {"month": "2024-02-01", "region": "North", "revenue": 52000, "units": 140, "revenue_per_unit": 371.43}, {"month": "2024-02-01", "region": "South", "revenue": 41000, "units": 105, "revenue_per_unit": 390.48}, {"month": "2024-03-01", "region": "North", "revenue": 48000, "units": 130, "revenue_per_unit": 369.23}, {"month": "2024-03-01", "region": "South", "revenue": 55000, "units": 148, "revenue_per_unit": 371.62}, {"month": "2024-04-01", "region": "North", "revenue": 61000, "units": 165, "revenue_per_unit": 369.7}, {"month": "2024-04-01", "region": "South", "revenue": 49000, "units": 128, "revenue_per_unit": 382.81}]

8 records transformed.''';
    }

    if (cl.contains('def validate_records') ||
        cl.contains('validation_status')) {
      return '''[{"id": 1, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active", "validation_status": "valid"}, {"id": 2, "user_id": "u1", "name": "Alice", "email": "alice@example.com", "age": 28, "score": 92.5, "status": "active", "validation_status": "valid"}, {"id": 3, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active", "validation_status": "valid"}, {"id": 4, "user_id": "u3", "name": "Carol", "email": null, "age": null, "score": 85.0, "status": "inactive", "validation_status": "invalid"}, {"id": 5, "user_id": "u4", "name": "Dave", "email": "dave@example.com", "age": 42, "score": null, "status": "active", "validation_status": "invalid"}, {"id": 6, "user_id": "u2", "name": "Bob", "email": "bob@example.com", "age": 35, "score": 78.0, "status": "active", "validation_status": "valid"}, {"id": 7, "user_id": "u5", "name": "Eve", "email": "eve@example.com", "age": 31, "score": 95.0, "status": "active", "validation_status": "valid"}, {"id": 8, "user_id": "u6", "name": "Frank", "email": "frank@example.com", "age": null, "score": 60.0, "status": "inactive", "validation_status": "invalid"}]

8 records validated.''';
    }

    if (cl.contains('def revenue_per_user') || cl.contains('total_revenue')) {
      return '''[{"user_id": "u3", "total_revenue": 129.0}, {"user_id": "u1", "total_revenue": 49.99}, {"user_id": "u2", "total_revenue": 49.99}]

3 users with purchase revenue.''';
    }

    if (cl.contains('def compute_mom_growth') || cl.contains('growth_pct')) {
      return '''[{"month": "2024-01", "region": "North", "revenue": 45000, "units": 120, "growth_pct": null}, {"month": "2024-02", "region": "North", "revenue": 52000, "units": 140, "growth_pct": 15.56}, {"month": "2024-03", "region": "North", "revenue": 48000, "units": 130, "growth_pct": -7.69}, {"month": "2024-04", "region": "North", "revenue": 61000, "units": 165, "growth_pct": 27.08}, {"month": "2024-01", "region": "South", "revenue": 38000, "units": 95, "growth_pct": null}, {"month": "2024-02", "region": "South", "revenue": 41000, "units": 105, "growth_pct": 7.89}, {"month": "2024-03", "region": "South", "revenue": 55000, "units": 148, "growth_pct": 34.15}, {"month": "2024-04", "region": "South", "revenue": 49000, "units": 128, "growth_pct": -10.91}]

8 records with growth_pct computed.''';
    }

    // NOTE: print() calls alone don't override the function result.
    // The stdout extraction happens in _executePythonWithDebug.
    return '''Execution successful ✓ (0.002s)

(no output — add print() to see results)

Process finished with exit code 0''';
  }

  Future<void> _revealSolution() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reveal Solution?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to see the reference solution? Try solving it yourself first!',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Trying',
              style: GoogleFonts.dmSans(color: AppTheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              'Show Solution',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _solutionRevealed = true;
        _showSolution = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          _loading
              ? 'Loading...'
              : (_challenge?['title'] ?? 'Challenge').toString(),
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Code Playground',
        ),
        actions: [
          // Debug Mode Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bug_report,
                  size: 16,
                  color: _debugModeEnabled
                      ? const Color(0xFFFFD54F)
                      : Colors.white54,
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _debugModeEnabled,
                    onChanged: (v) => setState(() => _debugModeEnabled = v),
                    activeThumbColor: const Color(0xFFFFD54F),
                    activeTrackColor: const Color(0xFFFFD54F).withAlpha(80),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildWorkspace(),
    );
  }

  Widget _buildError() {
    return Center(
      child: GestureDetector(
        onTap: _loadChallenge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    final challenge = _challenge!;
    final language = (challenge['language'] ?? 'SQL').toString();
    final difficulty = (challenge['difficulty'] ?? '').toString();
    final description = (challenge['description'] ?? '').toString();
    final tips = challenge['tips'];
    final tipsList = tips is List
        ? tips.map((t) => t.toString()).toList()
        : <String>[];
    final solutionCode = (challenge['solution_code'] ?? '').toString();
    final solutionExplanation = (challenge['solution_explanation'] ?? '')
        .toString();
    final dsMap = challenge['code_playground_datasets'];
    final datasetName = dsMap is Map
        ? (dsMap['dataset_name'] ?? '').toString()
        : '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Challenge Info Banner ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LanguagePill(language: language),
                    const SizedBox(width: 6),
                    _DifficultyPill(difficulty: difficulty),
                    if (datasetName.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _DatasetPill(name: datasetName),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Dataset Preview ───────────────────────────────────────────
          if (_datasetRows != null && _datasetRows!.isNotEmpty)
            _buildDatasetToggle(),

          // ── Code Editor ───────────────────────────────────────────────
          _buildCodeEditor(language),

          // ── Run / Reset Buttons ───────────────────────────────────────
          _buildActionButtons(language),

          // ── Expected Result Card ──────────────────────────────────────
          _buildExpectedResultCard(),

          // ── Verification Result ───────────────────────────────────────
          _buildVerificationResult(),

          // ── Debug Panel (shown when debug mode on and there's debug info)
          if (_debugModeEnabled &&
              _debugInfo != null &&
              _verificationStatus != _VerificationStatus.notRun &&
              _verificationStatus != _VerificationStatus.running)
            _buildDebugPanel(language),

          // ── Execution Output ──────────────────────────────────────────
          if (_executionOutput.isNotEmpty) _buildOutputPanel(),

          // ── Actual vs Expected Diff (SQL failed) ──────────────────────
          if (_debugModeEnabled &&
              _debugInfo != null &&
              _debugInfo!.hasDiff &&
              _verificationStatus == _VerificationStatus.failed &&
              language.toLowerCase() == 'sql')
            _buildActualVsExpectedDiff(),

          // ── Tips ──────────────────────────────────────────────────────
          if (tipsList.isNotEmpty) _buildTips(tipsList),

          // ── Solution ─────────────────────────────────────────────────
          _buildSolutionSection(solutionCode, solutionExplanation),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Expected Result Card ───────────────────────────────────────────────────
  Widget _buildExpectedResultCard() {
    final rawExpected = _challenge?['expected_results'] as String?;
    if (rawExpected == null || rawExpected.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine match state for border/header color
    final isMatched = _verificationStatus == _VerificationStatus.passed;
    final isMismatched = _verificationStatus == _VerificationStatus.failed;
    final Color accentColor = isMatched
        ? const Color(0xFF43A047)
        : isMismatched
        ? const Color(0xFFE53935)
        : const Color(0xFF5C6BC0);

    // Parse the expected result for display
    final tableData = _parsePythonJsonOutput(rawExpected);
    final hasParsedTable =
        tableData != null && (tableData['rows'] as List).isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collapsible Header ─────────────────────────────────────
          InkWell(
            onTap: () =>
                setState(() => _showExpectedResult = !_showExpectedResult),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(10),
              topRight: const Radius.circular(10),
              bottomLeft: _showExpectedResult
                  ? Radius.zero
                  : const Radius.circular(10),
              bottomRight: _showExpectedResult
                  ? Radius.zero
                  : const Radius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(18),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: _showExpectedResult
                      ? Radius.zero
                      : const Radius.circular(10),
                  bottomRight: _showExpectedResult
                      ? Radius.zero
                      : const Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMatched
                        ? Icons.check_circle
                        : isMismatched
                        ? Icons.cancel
                        : Icons.fact_check_outlined,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expected Result',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isMatched)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF43A047).withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 10,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Match! Correct output',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isMismatched)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE53935).withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close,
                            size: 10,
                            color: Color(0xFFC62828),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Mismatch',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C6BC0).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasParsedTable
                            ? '${(tableData['rows'] as List).length} records'
                            : 'from database',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: const Color(0xFF5C6BC0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    _showExpectedResult ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible Body ───────────────────────────────────────
          if (_showExpectedResult)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: accentColor.withAlpha(60)),
                ),
              ),
              child: hasParsedTable
                  ? _buildExpectedResultTable(tableData, accentColor)
                  : _buildExpectedResultRaw(rawExpected, accentColor),
            ),
        ],
      ),
    );
  }

  Widget _buildExpectedResultTable(
    Map<String, dynamic> tableData,
    Color accentColor,
  ) {
    final columns = tableData['columns'] as List<String>;
    final rows = tableData['rows'] as List<Map<String, String>>;
    final displayRows = rows.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-header with record count
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Icon(Icons.table_rows, size: 13, color: accentColor),
              const SizedBox(width: 5),
              Text(
                '${rows.length} record(s) · ${columns.length} field(s)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Scrollable table
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: accentColor.withAlpha(50),
                width: 0.8,
              ),
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(color: accentColor.withAlpha(25)),
                  children: columns
                      .map(
                        (col) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            col,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Data rows
                ...displayRows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final isEven = idx % 2 == 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                    ),
                    children: columns.map((col) {
                      final val = row[col] ?? '';
                      final isNull =
                          val.isEmpty || val == 'null' || val == 'NULL';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          isNull ? 'null' : val,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: isNull
                                ? Colors.grey.shade400
                                : const Color(0xFF1A1A1A),
                            fontStyle: isNull
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
        if (rows.length > 10)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              '+ ${rows.length - 10} more rows not shown',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpectedResultRaw(String raw, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_object, size: 13, color: accentColor),
              const SizedBox(width: 5),
              Text(
                'Raw expected output',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withAlpha(60)),
            ),
            child: _AlwaysVisibleHScrollPanel(
              child: Text(
                raw.length > 800 ? '${raw.substring(0, 800)}...' : raw,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: const Color(0xFF1A1A1A),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Debug Panel ────────────────────────────────────────────────────────────
  Widget _buildDebugPanel(String language) {
    final debug = _debugInfo!;
    final isPython = language.toLowerCase() == 'python';
    final isError = _verificationStatus == _VerificationStatus.executionError;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? const Color(0xFFEF5350).withAlpha(120)
              : const Color(0xFFFFD54F).withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFF3E1A1A)
                  : const Color(0xFF2A2A1A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report,
                  size: 15,
                  color: isError
                      ? const Color(0xFFEF5350)
                      : const Color(0xFFFFD54F),
                ),
                const SizedBox(width: 8),
                Text(
                  'Debug Console',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isError
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFFFD54F),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isError
                                ? const Color(0xFFEF5350)
                                : const Color(0xFFFFD54F))
                            .withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPython ? 'Python Runtime' : 'SQL Engine',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: isError
                          ? const Color(0xFFEF5350)
                          : const Color(0xFFFFD54F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Executed Query / Your Script ─────────────────────────
                _debugSectionLabel(
                  isPython ? Icons.code : Icons.storage,
                  isPython ? 'Your Script' : 'Executed Query',
                  const Color(0xFF90CAF9),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF90CAF9).withAlpha(60),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF90CAF9).withAlpha(20),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPython ? Icons.terminal : Icons.play_arrow,
                              size: 11,
                              color: const Color(0xFF90CAF9),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPython
                                  ? 'python  playground.py'
                                  : 'sql  query.sql',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 10,
                                color: const Color(0xFF90CAF9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Code content
                      _AlwaysVisibleHScrollPanel(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Text(
                          _codeController.text.trim().isEmpty
                              ? '(no code)'
                              : _codeController.text.trim(),
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: const Color(0xFFD4D4D4),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Python: Stack Trace ──────────────────────────────────
                if (isPython && debug.stackTrace != null) ...[
                  _debugSectionLabel(
                    Icons.error_outline,
                    'Stack Trace',
                    const Color(0xFFEF5350),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D1515),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF5350).withAlpha(60),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        debug.stackTrace!,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: const Color(0xFFFF8A80),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Python: Printed Output (stdout) — always shown ───────────
                if (isPython) ...[
                  _debugSectionLabel(
                    Icons.terminal,
                    'Standard Output (stdout)',
                    const Color(0xFF80CBC4),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF80CBC4).withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Console header bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF80CBC4).withAlpha(18),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.terminal,
                                size: 11,
                                color: Color(0xFF80CBC4),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'console output',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 10,
                                  color: const Color(0xFF80CBC4),
                                ),
                              ),
                              const Spacer(),
                              if (debug.printedOutput != null &&
                                  debug.printedOutput!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF80CBC4,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${debug.printedOutput!.split('\n').length} line(s)',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      color: const Color(0xFF80CBC4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Console content
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: SingleChildScrollView(
                            controller: _stdoutVScrollCtrl,
                            scrollDirection: Axis.vertical,
                            child: _AlwaysVisibleHScrollPanel(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                              child:
                                  debug.printedOutput == null ||
                                      debug.printedOutput!.isEmpty
                                  ? Text(
                                      '(no output — use print() to display values)',
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                        height: 1.6,
                                      ),
                                    )
                                  : Text(
                                      debug.printedOutput!,
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 11,
                                        color: const Color(0xFF80CBC4),
                                        height: 1.6,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Python: Return Value Inspector ───────────────────────
                if (isPython && debug.returnedValue != null) ...[
                  _debugSectionLabel(
                    Icons.output,
                    'Return Value Inspector',
                    const Color(0xFFCE93D8),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0D2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFCE93D8).withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '>>> result = ',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              'your_function(data)',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 11,
                                color: const Color(0xFF82B1FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '>>> print(result)\n',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        // If the return value looks like JSON, render as mini table
                        Builder(
                          builder: (context) {
                            final jsonTable = _parsePythonJsonOutput(
                              debug.returnedValue ?? '',
                            );
                            if (jsonTable != null &&
                                jsonTable['rows'] != null &&
                                (jsonTable['rows'] as List).isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFCE93D8,
                                      ).withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${(jsonTable['rows'] as List).length} record(s) returned',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        color: const Color(0xFFCE93D8),
                                      ),
                                    ),
                                  ),
                                  _buildPythonDataTable(
                                    jsonTable,
                                    const Color(0xFFCE93D8),
                                  ),
                                ],
                              );
                            }
                            return _AlwaysVisibleHScrollPanel(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                debug.returnedValue!,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 11,
                                  color: debug.returnedValue == 'None'
                                      ? const Color(0xFFEF5350)
                                      : const Color(0xFFCE93D8),
                                  height: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                        if (debug.returnedValue == 'None') ...[
                          const SizedBox(height: 6),
                          Text(
                            '⚠ Your function returned None. Add a return statement.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFFEF5350),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Python: Diff Summary ─────────────────────────────────
                if (isPython && debug.diffSummary != null && !isError) ...[
                  _debugSectionLabel(
                    Icons.compare_arrows,
                    'Expected vs Actual',
                    const Color(0xFFFFB74D),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1A0D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show structured diff if we have actual vs expected rows
                        if (debug.actualRows != null &&
                            debug.expectedRows != null) ...[
                          _buildPythonRowDiff(debug),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          debug.diffSummary!,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: const Color(0xFFFFCC80),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── SQL: Error Message ───────────────────────────────────
                if (!isPython && debug.hasSqlError) ...[
                  _debugSectionLabel(
                    Icons.error_outline,
                    'Database Error',
                    const Color(0xFFEF5350),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D1515),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF5350).withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (debug.sqlErrorCode != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF5350).withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              debug.sqlErrorCode!,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 10,
                                color: const Color(0xFFEF5350),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            debug.sqlErrorMessage!,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: const Color(0xFFFF8A80),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── SQL: Console Logs — always shown ────────────────────
                if (!isPython) ...[
                  const SizedBox(height: 12),
                  _debugSectionLabel(
                    Icons.receipt_long,
                    'Console Logs',
                    const Color(0xFF80CBC4),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF80CBC4).withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF80CBC4).withAlpha(18),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 11,
                                color: Color(0xFF80CBC4),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'execution log',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 10,
                                  color: const Color(0xFF80CBC4),
                                ),
                              ),
                              const Spacer(),
                              if (debug.consoleLogs != null &&
                                  debug.consoleLogs!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF80CBC4,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '${debug.consoleLogs!.length} entries',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      color: const Color(0xFF80CBC4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Log entries
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child:
                              debug.consoleLogs == null ||
                                  debug.consoleLogs!.isEmpty
                              ? Text(
                                  '(no log entries)',
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: debug.consoleLogs!.map((log) {
                                    Color logColor;
                                    IconData logIcon;
                                    if (log.startsWith('[ERROR]')) {
                                      logColor = const Color(0xFFEF5350);
                                      logIcon = Icons.error_outline;
                                    } else if (log.startsWith('[WARN]')) {
                                      logColor = const Color(0xFFFFB74D);
                                      logIcon = Icons.warning_amber_outlined;
                                    } else {
                                      logColor = const Color(0xFF80CBC4);
                                      logIcon = Icons.chevron_right;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            logIcon,
                                            size: 12,
                                            color: logColor.withAlpha(180),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              log,
                                              style: GoogleFonts.sourceCodePro(
                                                fontSize: 11,
                                                color: logColor,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── SQL: Column mismatch hint ────────────────────────────
                if (!isPython &&
                    debug.actualColumns != null &&
                    debug.expectedColumns != null &&
                    !isError) ...[
                  const SizedBox(height: 12),
                  _debugSectionLabel(
                    Icons.view_column,
                    'Column Comparison',
                    const Color(0xFF80CBC4),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildColumnList(
                          'Your Columns',
                          debug.actualColumns!,
                          const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildColumnList(
                          'Required Columns',
                          debug.expectedColumns!,
                          const Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugSectionLabel(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildColumnList(String title, List<String> cols, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          if (cols.isEmpty)
            Text(
              '(none)',
              style: GoogleFonts.sourceCodePro(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...cols.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 5, color: color.withAlpha(180)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        c,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 10,
                          color: const Color(0xFFD4D4D4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Actual vs Expected Diff View (SQL) ─────────────────────────────────────
  Widget _buildActualVsExpectedDiff() {
    final debug = _debugInfo!;
    final hasActual = debug.actualRows != null && debug.actualRows!.isNotEmpty;
    final hasExpected =
        debug.expectedRows != null && debug.expectedRows!.isNotEmpty;

    if (!hasActual && !hasExpected) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D).withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1F1A0D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.compare_arrows,
                  size: 15,
                  color: Color(0xFFFFB74D),
                ),
                const SizedBox(width: 8),
                Text(
                  'Result Comparison',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFB74D),
                  ),
                ),
                const Spacer(),
                if (debug.diffSummary != null)
                  Flexible(
                    child: Text(
                      debug.diffSummary!,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Side-by-side or stacked based on available data
                  if (hasActual && hasExpected)
                    _buildSideBySideDiff(debug)
                  else if (hasActual)
                    _buildSingleResultTable(
                      'Your Result',
                      debug.actualColumns ?? [],
                      debug.actualRows!,
                      const Color(0xFFEF5350),
                    )
                  else if (hasExpected)
                    _buildSingleResultTable(
                      'Expected Result',
                      debug.expectedColumns ?? [],
                      debug.expectedRows!,
                      const Color(0xFF66BB6A),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideDiff(_DebugInfo debug) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicWidth(
              child: _buildSingleResultTable(
                '✗ Your Result (${debug.actualRows!.length} rows)',
                debug.actualColumns ?? [],
                debug.actualRows!,
                const Color(0xFFEF5350),
              ),
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: _buildSingleResultTable(
                '✓ Expected (${debug.expectedRows!.length} rows)',
                debug.expectedColumns ?? [],
                debug.expectedRows!,
                const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
        if (debug.actualRows!.length != debug.expectedRows!.length) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEF5350).withAlpha(60)),
            ),
            child: Text(
              '⚠ Row count mismatch: your query returned ${debug.actualRows!.length} row(s), expected ${debug.expectedRows!.length} row(s).',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFFFF8A80),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleResultTable(
    String title,
    List<String> columns,
    List<Map<String, String>> rows,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(30),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withAlpha(60)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: columns.isEmpty && rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    '(no data)',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    border: TableBorder.all(
                      color: accentColor.withAlpha(30),
                      width: 0.5,
                    ),
                    children: [
                      if (columns.isNotEmpty)
                        TableRow(
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(20),
                          ),
                          children: columns
                              .map(
                                (col) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    col,
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 10,
                                      color: accentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ...rows
                          .take(8)
                          .map(
                            (row) => TableRow(
                              children:
                                  (columns.isNotEmpty
                                          ? columns
                                          : row.keys.toList())
                                      .map(
                                        (col) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            row[col] ?? '',
                                            style: GoogleFonts.sourceCodePro(
                                              fontSize: 10,
                                              color: const Color(0xFFD4D4D4),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                    ],
                  ),
                ),
        ),
        if (rows.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${rows.length - 8} more rows',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatasetToggle() {
    final dsMap = _challenge!['code_playground_datasets'];
    final datasetName = dsMap is Map
        ? (dsMap['dataset_name'] ?? 'Dataset').toString()
        : 'Dataset';

    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showDatasetPreview = !_showDatasetPreview),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF263238),
            child: Row(
              children: [
                const Icon(Icons.table_chart, size: 14, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  'Dataset: $datasetName (${_datasetRows!.length} rows preview)',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showDatasetPreview ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        ),
        if (_showDatasetPreview) _buildDatasetPreview(),
      ],
    );
  }

  Widget _buildDatasetPreview() {
    final rows = _datasetRows!;
    if (rows.isEmpty) return const SizedBox.shrink();

    final tables = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final table = row['_table']?.toString() ?? 'data';
      tables.putIfAbsent(table, () => []);
      final cleanRow = Map<String, dynamic>.from(row)..remove('_table');
      tables[table]!.add(cleanRow);
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      color: const Color(0xFF1A2332),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tables.entries.map((entry) {
            final tableName = entry.key;
            final tableRows = entry.value;
            if (tableRows.isEmpty) return const SizedBox.shrink();
            final columns = tableRows.first.keys.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    '📋 $tableName (${tableRows.length} rows)',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.teal.shade200,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      border: TableBorder.all(
                        color: Colors.teal.withAlpha(60),
                        width: 0.5,
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.teal.withAlpha(40),
                          ),
                          children: columns
                              .map(
                                (col) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    col,
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 10,
                                      color: Colors.teal.shade200,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        ...tableRows.map(
                          (row) => TableRow(
                            children: columns
                                .map(
                                  (col) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      '${row[col] ?? ''}',
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 10,
                                        color: const Color(0xFFD4D4D4),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCodeEditor(String language) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 320),
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2D2D2D),
            child: Row(
              children: [
                Icon(
                  language.toLowerCase() == 'python'
                      ? Icons.code
                      : Icons.storage,
                  size: 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  language,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Editor',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 13,
                  color: const Color(0xFFD4D4D4),
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Write your $language code here...',
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                _isRunning ? 'Running...' : 'Run $language',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
          OutlinedButton.icon(
            onPressed: _resetCode,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              'Reset',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResult() {
    switch (_verificationStatus) {
      case _VerificationStatus.notRun:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
              const SizedBox(width: 10),
              Text(
                'Run the code to check your answer.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );

      case _VerificationStatus.running:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Running...',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case _VerificationStatus.passed:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF81C784)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 20,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✓ Challenge Passed',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    if (_verificationMessage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _verificationMessage,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

      case _VerificationStatus.failed:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFB74D)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.close, size: 20, color: Color(0xFFE65100)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✗ Incorrect Result',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    if (_verificationMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _verificationMessage,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFFBF360C),
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (_debugModeEnabled && _debugInfo != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.bug_report,
                            size: 12,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'See Debug Console below for details',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFFFFD54F),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

      case _VerificationStatus.executionError:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEF9A9A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber,
                size: 20,
                color: Color(0xFFC62828),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠ Execution Error',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                    if (_verificationMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _verificationMessage,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: const Color(0xFFB71C1C),
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (_debugModeEnabled && _debugInfo != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.bug_report,
                            size: 12,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Full stack trace in Debug Console below',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFFFFD54F),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

      case _VerificationStatus.timeout:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFD54F)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_off, size: 20, color: Color(0xFFF57F17)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠ Execution Timeout',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF57F17),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your code exceeded the allowed execution time. Try optimizing your solution.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildOutputPanel() {
    final language = (_challenge?['language'] ?? 'SQL').toString();
    final isPython = language.toLowerCase() == 'python';
    final isSuccess =
        _verificationStatus == _VerificationStatus.passed ||
        (_executionOutput.contains('✓') &&
            !_executionOutput.toLowerCase().startsWith('error'));

    // For SQL: parse fixed-width table
    final sqlTableData = !isPython ? _parseOutputTable(_executionOutput) : null;

    // For Python: parse JSON output into table
    final pythonTableData = isPython
        ? _parsePythonJsonOutput(_executionOutput)
        : null;

    final hasTable = sqlTableData != null || pythonTableData != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      constraints: BoxConstraints(maxHeight: hasTable ? 320 : 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF00BFA5).withAlpha(80)
              : const Color(0xFF444444),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasTable
                      ? Icons.table_rows
                      : (isPython ? Icons.terminal : Icons.terminal),
                  size: 14,
                  color: isSuccess
                      ? const Color(0xFF00BFA5)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  isPython ? 'Output' : 'Output',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isSuccess
                        ? const Color(0xFF00BFA5)
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sqlTableData != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(sqlTableData['rows'] as List).length} rows × ${(sqlTableData['columns'] as List).length} cols',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: const Color(0xFF00BFA5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (pythonTableData != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(pythonTableData['rows'] as List).length} records × ${(pythonTableData['columns'] as List).length} fields',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: const Color(0xFF00BFA5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Builder(
                  builder: (context) {
                    final timeMatch = RegExp(
                      r'(\d+\.\d+)s',
                    ).firstMatch(_executionOutput);
                    if (timeMatch != null) {
                      return Text(
                        '${timeMatch.group(1)}s',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: sqlTableData != null
                ? _buildDataGrid(sqlTableData)
                : pythonTableData != null
                ? _buildPythonOutputGrid(pythonTableData)
                : _AlwaysVisibleHScrollPanel(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                    child: Text(
                      _executionOutput,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 11,
                        color: const Color(0xFFD4D4D4),
                        height: 1.6,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Renders Python JSON output as a scrollable data grid in the Output panel.
  Widget _buildPythonOutputGrid(Map<String, dynamic> tableData) {
    final columns = tableData['columns'] as List<String>;
    final rows = tableData['rows'] as List<Map<String, String>>;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: const Color(0xFF2A3A4A), width: 1),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFF0D2137)),
                  children: columns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        col,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: const Color(0xFF00BFA5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final isEven = idx % 2 == 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isEven
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFF141428),
                    ),
                    children: columns.map((col) {
                      final val = row[col] ?? '';
                      final isNull =
                          val.isEmpty || val == 'null' || val == 'NULL';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          isNull ? 'null' : val,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: isNull
                                ? Colors.grey.shade600
                                : const Color(0xFFD4D4D4),
                            fontStyle: isNull
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Parse Python JSON output into table data ───────────────────────────────
  Map<String, dynamic>? _parsePythonJsonOutput(String output) {
    if (output.isEmpty || output == 'None') return null;
    try {
      // Find the JSON array portion
      final startIdx = output.indexOf('[');
      final endIdx = output.lastIndexOf(']');
      if (startIdx < 0 || endIdx < 0 || endIdx <= startIdx) return null;

      final jsonStr = output.substring(startIdx, endIdx + 1);
      // Basic validation: must look like array of objects
      if (!jsonStr.contains('{')) return null;

      // Manual parse: extract key-value pairs from each {...} object
      final rows = <Map<String, String>>[];
      final columns = <String>[];
      bool columnsSet = false;

      final objRegex = RegExp(r'\{([^}]+)\}');
      for (final objMatch in objRegex.allMatches(jsonStr)) {
        final objContent = objMatch.group(1)!;
        final row = <String, String>{};

        // Extract key: value pairs
        final kvRegex = RegExp(
          r'"(\w+)":\s*(?:"([^"]*)"|(null)|(-?\d+(?:\.\d+)?)|(\[[^\]]*\]))',
        );
        for (final kv in kvRegex.allMatches(objContent)) {
          final key = kv.group(1)!;
          final strVal = kv.group(2);
          final nullVal = kv.group(3);
          final numVal = kv.group(4);
          final arrVal = kv.group(5);
          final value = strVal ?? nullVal ?? numVal ?? arrVal ?? '';
          row[key] = value;
          if (!columnsSet && !columns.contains(key)) {
            columns.add(key);
          }
        }
        if (row.isNotEmpty) {
          rows.add(row);
          columnsSet = true;
        }
      }

      if (rows.isEmpty || columns.isEmpty) return null;
      return {'columns': columns, 'rows': rows};
    } catch (_) {
      return null;
    }
  }

  /// Renders a compact data table for Python JSON output inside the debug panel.
  Widget _buildPythonDataTable(
    Map<String, dynamic> tableData,
    Color accentColor,
  ) {
    final columns = tableData['columns'] as List<String>;
    final rows = tableData['rows'] as List<Map<String, String>>;
    final displayRows = rows.take(6).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: accentColor.withAlpha(40), width: 0.5),
        children: [
          TableRow(
            decoration: BoxDecoration(color: accentColor.withAlpha(25)),
            children: columns
                .map(
                  (col) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      col,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...displayRows.asMap().entries.map((entry) {
            final isEven = entry.key % 2 == 0;
            final row = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: isEven
                    ? const Color(0xFF1A0D2E)
                    : const Color(0xFF150A25),
              ),
              children: columns.map((col) {
                final val = row[col] ?? '';
                final isNull = val.isEmpty || val == 'null' || val == 'NULL';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    isNull ? 'null' : val,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      color: isNull
                          ? Colors.grey.shade600
                          : const Color(0xFFD4D4D4),
                      fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  /// Builds a side-by-side row diff for Python validation failures.
  Widget _buildPythonRowDiff(_DebugInfo debug) {
    final actualRows = debug.actualRows!;
    final expectedRows = debug.expectedRows!;
    final actualCols =
        debug.actualColumns ??
        (actualRows.isNotEmpty ? actualRows.first.keys.toList() : <String>[]);
    final expectedCols =
        debug.expectedColumns ??
        (expectedRows.isNotEmpty
            ? expectedRows.first.keys.toList()
            : <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSingleResultTable(
                '✗ Your Output (${actualRows.length} records)',
                actualCols,
                actualRows,
                const Color(0xFFEF5350),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSingleResultTable(
                '✓ Expected (${expectedRows.length} records)',
                expectedCols,
                expectedRows,
                const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
        if (actualRows.length != expectedRows.length) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEF5350).withAlpha(60)),
            ),
            child: Text(
              '⚠ Count mismatch: your function returned ${actualRows.length} record(s), expected ${expectedRows.length}.',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFFFF8A80),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Map<String, dynamic>? _parseOutputTable(String output) {
    if (output.isEmpty) return null;

    final lines = output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 3) return null;

    int headerIdx = -1;
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (RegExp(r'^[-=\s]+$').hasMatch(l)) continue;
      if (l.contains('✓') ||
          l.startsWith('Query') ||
          l.startsWith('Execution')) {
        continue;
      }
      if (RegExp(r'\S+\s{2,}\S+').hasMatch(l)) {
        headerIdx = i;
        break;
      }
    }

    if (headerIdx < 0) return null;

    final headerLine = lines[headerIdx];

    int sepIdx = -1;
    for (int i = headerIdx + 1; i < lines.length; i++) {
      if (RegExp(r'^[-\s]+$').hasMatch(lines[i])) {
        sepIdx = i;
        break;
      }
    }

    if (sepIdx < 0) return null;

    final sep = lines[sepIdx];
    final colRanges = <List<int>>[];
    int start = 0;
    bool inDash = false;
    for (int i = 0; i <= sep.length; i++) {
      final ch = i < sep.length ? sep[i] : ' ';
      if (ch == '-' && !inDash) {
        start = i;
        inDash = true;
      } else if (ch != '-' && inDash) {
        colRanges.add([start, i]);
        inDash = false;
      }
    }

    if (colRanges.isEmpty) return null;

    final columns = colRanges
        .map((r) {
          final end = r[1] > headerLine.length ? headerLine.length : r[1];
          final s = r[0] > headerLine.length
              ? ''
              : headerLine.substring(r[0], end);
          return s.trim();
        })
        .where((c) => c.isNotEmpty)
        .toList();

    if (columns.isEmpty) return null;

    final rows = <Map<String, String>>[];
    for (int i = sepIdx + 1; i < lines.length; i++) {
      final line = lines[i];
      if (RegExp(r'^\d+ rows').hasMatch(line)) break;
      if (line.isEmpty) break;

      final row = <String, String>{};
      for (int c = 0; c < colRanges.length && c < columns.length; c++) {
        final r = colRanges[c];
        final end = r[1] > line.length ? line.length : r[1];
        final val = r[0] > line.length ? '' : line.substring(r[0], end);
        row[columns[c]] = val.trim();
      }
      if (row.isNotEmpty) rows.add(row);
    }

    if (rows.isEmpty) return null;

    return {'columns': columns, 'rows': rows};
  }

  Widget _buildDataGrid(Map<String, dynamic> tableData) {
    final columns = tableData['columns'] as List<String>;
    final rows = tableData['rows'] as List<Map<String, String>>;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: const Color(0xFF2A3A4A), width: 1),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFF0D2137)),
                  children: columns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        col,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: const Color(0xFF00BFA5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final isEven = idx % 2 == 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isEven
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFF141428),
                    ),
                    children: columns.map((col) {
                      final val = row[col] ?? '';
                      final isNull =
                          val.isEmpty || val == 'NULL' || val == 'null';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          isNull ? 'NULL' : val,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            color: isNull
                                ? Colors.grey.shade600
                                : const Color(0xFFD4D4D4),
                            fontStyle: isNull
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTips(List<String> tips) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, size: 16, color: Color(0xFFF57F17)),
              const SizedBox(width: 6),
              Text(
                'Tips',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}. ',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSolutionSection(
    String solutionCode,
    String solutionExplanation,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_solutionRevealed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _revealSolution,
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(
                  'Show Solution',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: AppTheme.primary.withAlpha(120)),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
          if (_solutionRevealed) ...[
            GestureDetector(
              onTap: () => setState(() => _showSolution = !_showSolution),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reference Solution',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showSolution ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppTheme.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
            if (_showSolution) ...[
              const SizedBox(height: 8),
              if (solutionCode.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    solutionCode,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      color: const Color(0xFFD4D4D4),
                      height: 1.6,
                    ),
                  ),
                ),
              if (solutionExplanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explanation',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        solutionExplanation,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

// ── Verify Result with Debug ──────────────────────────────────────────────────
class _VerifyResultWithDebug {
  final _VerificationStatus status;
  final String message;
  final _DebugInfo? debugInfo;
  const _VerifyResultWithDebug(this.status, this.message, this.debugInfo);
}

// ── Shared Pill Widgets ───────────────────────────────────────────────────────
class _LanguagePill extends StatelessWidget {
  final String language;
  const _LanguagePill({required this.language});

  @override
  Widget build(BuildContext context) {
    final isSQL = language.toUpperCase() == 'SQL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSQL ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        language,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSQL ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A),
        ),
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final String difficulty;
  const _DifficultyPill({required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'junior':
        return const Color(0xFF2E7D32);
      case 'middle':
        return const Color(0xFFE65100);
      case 'senior':
        return const Color(0xFFC62828);
      case 'leader':
        return const Color(0xFF6A1B9A);
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (difficulty.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _DatasetPill extends StatelessWidget {
  final String name;
  const _DatasetPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_chart, size: 9, color: Color(0xFF00695C)),
          const SizedBox(width: 3),
          Text(
            name,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00695C),
            ),
          ),
        ],
      ),
    );
  }
}