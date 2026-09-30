import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/pro_service.dart';
import '../../theme/app_theme.dart';
import '../auth_screen/auth_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final ProService _proService = ProService();
  bool _isSigningIn = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _proService.addListener(_onPurchaseChanged);
    _proService.init();
  }

  @override
  void dispose() {
    _proService.removeListener(_onPurchaseChanged);
    super.dispose();
  }

  void _onPurchaseChanged() {
    if (!mounted) return;
    if (_proService.isProUnlocked) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {});
    }
  }

  Future<bool> _requireSignIn() async {
    setState(() => _authError = null);
    if (AuthService.instance.isSignedIn) return true;

    setState(() => _isSigningIn = true);
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (mounted) setState(() => _isSigningIn = false);
    if (signedIn == true && AuthService.instance.isSignedIn) {
      await _proService.refreshEntitlement();
      return true;
    }
    if (mounted) {
      setState(() =>
          _authError = 'Sign in or create an account to continue.');
    }
    return false;
  }

  Future<void> _purchaseWithSignIn() async {
    if (!await _requireSignIn()) return;
    await _proService.purchaseLifetime();
  }

  Future<void> _restoreWithSignIn() async {
    if (!await _requireSignIn()) return;
    await _proService.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSigningIn ||
        _proService.purchasePending ||
        _proService.restorePending;
    final price = _proService.displayPrice;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Unlock Serious Mode',
                      style: GoogleFonts.dmSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'One payment. Lifetime access. No subscription.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (ProService.isLaunchPromotion) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _launchOfferText(),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const _FeatureList(),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF9A825), Color(0xFFF57F17)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            price,
                            style: GoogleFonts.dmSans(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'one-time purchase • lifetime access',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.white.withAlpha(225),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_proService.purchaseError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _proService.purchaseError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                    if (_authError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _authError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: busy || _proService.isLoadingStore
                            ? null
                            : _purchaseWithSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: busy || _proService.isLoadingStore
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AuthService.instance.isSignedIn
                                    ? 'Unlock forever for $price'
                                    : 'Sign in to continue • $price',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _proService.restorePending
                          ? null
                          : _restoreWithSignIn,
                      child: Text(
                        _proService.restorePending
                            ? 'Restoring…'
                            : 'Restore purchase',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      'Payment is securely processed by Apple or Google.',
                      textAlign: TextAlign.center,
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
      ),
    );
  }

  String _launchOfferText() {
    final end = ProService.launchEndsAt;
    if (end == null) return 'LAUNCH OFFER • Regular price ${r'$10.00'}';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'LAUNCH OFFER • Ends ${months[end.month - 1]} ${end.day}, ${end.year}';
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const features = [
    ('Full flashcard library', 'Practical concepts across core DE topics'),
    (
      'Full quiz library',
      'All topics, difficulties, answers, and explanations',
    ),
    (
      'Full Real Case Scenario library',
      'Real-world architecture decisions, incidents, and trade-offs',
    ),
    ('Custom quiz builder', 'Create focused practice sessions by topic'),
    (
      'Offline mode coming soon',
      'Download quizzes for uninterrupted practice without internet',
    ),
    (
      'Monthly certification questions',
      'New Azure, Google Cloud, and AWS Data Engineer practice questions',
    ),
    (
      'New content coming soon',
      'Fresh interview topics, scenarios, and learning material are on the way',
    ),
    ('Data Dev Stories', 'Learn from production incidents and trade-offs'),
    (
      'Premium statistics and trends',
      'Track accuracy, streaks, topic performance, and recent attempts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primary,
                    size: 21,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$1,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF242424),
                          ),
                        ),
                        Text(
                          feature.$2,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
