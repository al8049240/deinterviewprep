import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final ProService _proService = ProService();
  bool _isLoading = false;
  bool _isRestoring = false;

  Future<void> _unlockPro() async {
    setState(() => _isLoading = true);
    // Simulate IAP purchase flow
    await Future.delayed(const Duration(milliseconds: 800));
    await _proService.unlockPro();
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Serious Mode unlocked! Enjoy lifetime access.',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    final restored = await _proService.restorePurchases();
    if (mounted) {
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restored ? '✅ Purchase restored!' : 'No previous purchase found.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: restored ? AppTheme.primary : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock Serious Mode 🗿',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Pay Once, Own Forever',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recurring subscriptions. Prepare for your Data Engineering interviews at your own pace.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Comparison Table
                  _ComparisonTable(),
                  const SizedBox(height: 28),

                  // Price CTA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFFF57F17)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '\$19.99',
                          style: GoogleFonts.dmSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'One-time payment • Lifetime access',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Unlock Button — orange/gold gradient
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8C00), Color(0xFFFFB300)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00).withAlpha(80),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _unlockPro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '\$19.99 — One-time payment • Lifetime access',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Restore Button
                  TextButton(
                    onPressed: _isRestoring ? null : _restorePurchases,
                    child: _isRestoring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Restore Purchases',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure payment • Instant unlock',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
}

class _ComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Feature', 'Chill', 'Serious'],
      ['Core Flashcards', '10', '150+'],
      ['Interview Questions', '2 free', '150+'],
      ["Developer's Real Experiences 🗿", '✗', '✓'],
      ['Code Playground', '✗', '✓'],
      ['SQL/Python Practice', '✗', '✓'],
      ['Cheatsheets & Guides', '✗', '✓'],
      ['Offline Mode', '✗', '✓'],
      ['All Difficulty Levels', '✗', '✓'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isHeader = i == 0;
          return Container(
            decoration: BoxDecoration(
              color: isHeader ? AppTheme.primaryContainer : Colors.transparent,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : i == rows.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : null,
              border: i > 0
                  ? Border(top: BorderSide(color: Colors.grey.shade100))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    row[0],
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                      color: isHeader
                          ? AppTheme.primaryDark
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      row[1],
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: isHeader
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isHeader
                            ? AppTheme.primaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      row[2],
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isHeader
                            ? AppTheme.primaryDark
                            : row[2] == '✓'
                            ? AppTheme.primary
                            : row[2] == '✗'
                            ? Colors.red.shade400
                            : AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
