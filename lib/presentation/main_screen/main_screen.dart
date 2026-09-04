import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';
import '../dashboard_screen/dashboard_screen.dart';
import '../bookmarks_screen/bookmarks_screen.dart';
import '../performance_trends_screen/performance_trends_screen.dart';
import '../statistics_screen/statistics_screen.dart';
import '../paywall_screen/paywall_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final ProService _proService = ProService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _proService.addListener(_onProChanged);
    _proService.init();
  }

  @override
  void dispose() {
    _proService.removeListener(_onProChanged);
    super.dispose();
  }

  void _onProChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationTap(int index) {
    if (index == 2 && !_proService.isProUnlocked) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PaywallScreen(),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    _HomeTab(),
    _BookmarksTab(),
    _StatisticsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavigationTap,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _proService.isProUnlocked
                    ? Icons.bar_chart_rounded
                    : Icons.lock_rounded,
              ),
              label: 'Stats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wrapper widgets that embed each screen inside the shared AppBar ────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    return const BookmarksScreen();
  }
}

class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context) {
    return const StatisticsScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const PerformanceTrendsScreen();
  }
}
