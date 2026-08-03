import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ── Mock leaderboard data model ───────────────────────────────────────────────
class _LeaderboardUser {
  final int rank;
  final String name;
  final String avatarEmoji;
  final int totalScore;
  final int sessionsCompleted;
  final double avgAccuracy;
  final int streak;
  final Map<String, double> topicAccuracy;
  final List<_SessionRecord> recentSessions;

  const _LeaderboardUser({
    required this.rank,
    required this.name,
    required this.avatarEmoji,
    required this.totalScore,
    required this.sessionsCompleted,
    required this.avgAccuracy,
    required this.streak,
    required this.topicAccuracy,
    required this.recentSessions,
  });
}

class _SessionRecord {
  final String topic;
  final int correct;
  final int total;
  final String timeAgo;

  const _SessionRecord({
    required this.topic,
    required this.correct,
    required this.total,
    required this.timeAgo,
  });
}

const List<_LeaderboardUser> _leaderboardData = [
  _LeaderboardUser(
    rank: 1,
    name: 'Alex Chen',
    avatarEmoji: '🏆',
    totalScore: 4820,
    sessionsCompleted: 48,
    avgAccuracy: 94.2,
    streak: 21,
    topicAccuracy: {'SQL': 97.0, 'Python': 92.0, 'Spark': 91.0, 'Kafka': 88.0},
    recentSessions: [
      _SessionRecord(topic: 'SQL', correct: 9, total: 10, timeAgo: '2h ago'),
      _SessionRecord(topic: 'Python', correct: 8, total: 10, timeAgo: '1d ago'),
      _SessionRecord(topic: 'Spark', correct: 7, total: 8, timeAgo: '2d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 2,
    name: 'Priya Sharma',
    avatarEmoji: '🥈',
    totalScore: 4310,
    sessionsCompleted: 41,
    avgAccuracy: 91.5,
    streak: 14,
    topicAccuracy: {'Python': 95.0, 'ETL': 90.0, 'Airflow': 88.0, 'dbt': 85.0},
    recentSessions: [
      _SessionRecord(
        topic: 'Python',
        correct: 10,
        total: 10,
        timeAgo: '3h ago',
      ),
      _SessionRecord(topic: 'ETL', correct: 9, total: 10, timeAgo: '1d ago'),
      _SessionRecord(topic: 'Airflow', correct: 7, total: 8, timeAgo: '3d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 3,
    name: 'Marcus Johnson',
    avatarEmoji: '🥉',
    totalScore: 3980,
    sessionsCompleted: 37,
    avgAccuracy: 88.7,
    streak: 9,
    topicAccuracy: {'SQL': 90.0, 'Cloud': 89.0, 'Docker': 86.0, 'NoSQL': 82.0},
    recentSessions: [
      _SessionRecord(topic: 'Cloud', correct: 8, total: 10, timeAgo: '5h ago'),
      _SessionRecord(topic: 'SQL', correct: 9, total: 10, timeAgo: '2d ago'),
      _SessionRecord(topic: 'Docker', correct: 6, total: 8, timeAgo: '4d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 4,
    name: 'Sofia Reyes',
    avatarEmoji: '🌟',
    totalScore: 3650,
    sessionsCompleted: 33,
    avgAccuracy: 86.4,
    streak: 7,
    topicAccuracy: {
      'dbt': 92.0,
      'Data Modeling': 88.0,
      'SQL': 84.0,
      'ETL': 80.0,
    },
    recentSessions: [
      _SessionRecord(topic: 'dbt', correct: 9, total: 10, timeAgo: '1h ago'),
      _SessionRecord(
        topic: 'Data Modeling',
        correct: 7,
        total: 8,
        timeAgo: '1d ago',
      ),
      _SessionRecord(topic: 'SQL', correct: 8, total: 10, timeAgo: '3d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 5,
    name: 'James Park',
    avatarEmoji: '⚡',
    totalScore: 3420,
    sessionsCompleted: 30,
    avgAccuracy: 84.0,
    streak: 5,
    topicAccuracy: {
      'Kafka': 88.0,
      'Spark': 85.0,
      'Python': 82.0,
      'DataOps': 78.0,
    },
    recentSessions: [
      _SessionRecord(topic: 'Kafka', correct: 8, total: 10, timeAgo: '4h ago'),
      _SessionRecord(topic: 'Spark', correct: 7, total: 9, timeAgo: '2d ago'),
      _SessionRecord(topic: 'Python', correct: 8, total: 10, timeAgo: '5d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 6,
    name: 'Aisha Okonkwo',
    avatarEmoji: '🔥',
    totalScore: 3180,
    sessionsCompleted: 28,
    avgAccuracy: 82.1,
    streak: 4,
    topicAccuracy: {
      'Cloud': 86.0,
      'Docker': 83.0,
      'NoSQL': 80.0,
      'DataOps': 76.0,
    },
    recentSessions: [
      _SessionRecord(topic: 'Cloud', correct: 7, total: 9, timeAgo: '6h ago'),
      _SessionRecord(topic: 'Docker', correct: 8, total: 10, timeAgo: '2d ago'),
      _SessionRecord(topic: 'NoSQL', correct: 6, total: 8, timeAgo: '4d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 7,
    name: 'Liam Torres',
    avatarEmoji: '💡',
    totalScore: 2940,
    sessionsCompleted: 25,
    avgAccuracy: 79.6,
    streak: 3,
    topicAccuracy: {'Airflow': 84.0, 'ETL': 80.0, 'SQL': 77.0, 'Python': 74.0},
    recentSessions: [
      _SessionRecord(
        topic: 'Airflow',
        correct: 8,
        total: 10,
        timeAgo: '8h ago',
      ),
      _SessionRecord(topic: 'ETL', correct: 7, total: 9, timeAgo: '3d ago'),
      _SessionRecord(topic: 'SQL', correct: 6, total: 8, timeAgo: '5d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 8,
    name: 'Emma Wilson',
    avatarEmoji: '🎯',
    totalScore: 2710,
    sessionsCompleted: 22,
    avgAccuracy: 77.3,
    streak: 2,
    topicAccuracy: {
      'Data Modeling': 82.0,
      'dbt': 79.0,
      'SQL': 75.0,
      'Cloud': 72.0,
    },
    recentSessions: [
      _SessionRecord(
        topic: 'Data Modeling',
        correct: 7,
        total: 9,
        timeAgo: '10h ago',
      ),
      _SessionRecord(topic: 'dbt', correct: 6, total: 8, timeAgo: '3d ago'),
      _SessionRecord(topic: 'SQL', correct: 7, total: 10, timeAgo: '6d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 9,
    name: 'Noah Kim',
    avatarEmoji: '🚀',
    totalScore: 2480,
    sessionsCompleted: 19,
    avgAccuracy: 74.8,
    streak: 1,
    topicAccuracy: {
      'Python': 78.0,
      'Spark': 76.0,
      'Kafka': 73.0,
      'Docker': 70.0,
    },
    recentSessions: [
      _SessionRecord(
        topic: 'Python',
        correct: 7,
        total: 10,
        timeAgo: '12h ago',
      ),
      _SessionRecord(topic: 'Spark', correct: 6, total: 8, timeAgo: '4d ago'),
      _SessionRecord(topic: 'Kafka', correct: 5, total: 7, timeAgo: '6d ago'),
    ],
  ),
  _LeaderboardUser(
    rank: 10,
    name: 'Zara Ahmed',
    avatarEmoji: '🌈',
    totalScore: 2250,
    sessionsCompleted: 17,
    avgAccuracy: 72.1,
    streak: 1,
    topicAccuracy: {'NoSQL': 76.0, 'DataOps': 74.0, 'Cloud': 71.0, 'ETL': 68.0},
    recentSessions: [
      _SessionRecord(topic: 'NoSQL', correct: 6, total: 8, timeAgo: '1d ago'),
      _SessionRecord(topic: 'DataOps', correct: 5, total: 7, timeAgo: '4d ago'),
      _SessionRecord(topic: 'Cloud', correct: 6, total: 9, timeAgo: '7d ago'),
    ],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Top 3 podium
          _buildPodium(),
          // Remaining entries
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _leaderboardData.length - 3,
              itemBuilder: (context, i) {
                final user = _leaderboardData[i + 3];
                return _LeaderboardRow(
                  user: user,
                  onTap: () => _showDetailSheet(context, user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _leaderboardData.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _PodiumItem(
            user: top3[1],
            height: 80.0,
            onTap: (ctx) => _showDetailSheet(ctx, top3[1]),
          ),
          // 1st place
          _PodiumItem(
            user: top3[0],
            height: 110.0,
            onTap: (ctx) => _showDetailSheet(ctx, top3[0]),
          ),
          // 3rd place
          _PodiumItem(
            user: top3[2],
            height: 65.0,
            onTap: (ctx) => _showDetailSheet(ctx, top3[2]),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, _LeaderboardUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user),
    );
  }
}

// ── Podium Item ───────────────────────────────────────────────────────────────
class _PodiumItem extends StatelessWidget {
  final _LeaderboardUser user;
  final double height;
  final void Function(BuildContext) onTap;

  const _PodiumItem({
    required this.user,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(user.avatarEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            user.name.split(' ').first,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${user.totalScore} pts',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 70,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(user.rank == 1 ? 50 : 30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${user.rank}',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard Row ───────────────────────────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  final _LeaderboardUser user;
  final VoidCallback onTap;

  const _LeaderboardRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  '#${user.rank}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              // Avatar emoji
              Text(user.avatarEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              // Name + streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '${user.streak} day streak',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Score + accuracy
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.totalScore} pts',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.avgAccuracy.toStringAsFixed(1)}% avg',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User Detail Bottom Sheet ──────────────────────────────────────────────────
class _UserDetailSheet extends StatelessWidget {
  final _LeaderboardUser user;

  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text(
                            user.avatarEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _RankBadge(rank: user.rank),
                                    const SizedBox(width: 8),
                                    Text(
                                      '🔥 ${user.streak} day streak',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      _buildSectionTitle('Session Breakdown'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatTile(
                            icon: Icons.edit_note_rounded,
                            label: 'Sessions',
                            value: '${user.sessionsCompleted}',
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          _StatTile(
                            icon: Icons.gps_fixed_rounded,
                            label: 'Avg Accuracy',
                            value: '${user.avgAccuracy.toStringAsFixed(1)}%',
                            color: const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 10),
                          _StatTile(
                            icon: Icons.star_rounded,
                            label: 'Total Score',
                            value: '${user.totalScore}',
                            color: const Color(0xFFE65100),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Topic accuracy
                      _buildSectionTitle('Accuracy by Topic'),
                      const SizedBox(height: 10),
                      ...user.topicAccuracy.entries.map((e) {
                        return _TopicAccuracyBar(
                          topic: e.key,
                          accuracy: e.value,
                        );
                      }),
                      const SizedBox(height: 20),

                      // Recent sessions
                      _buildSectionTitle('Recent Sessions'),
                      const SizedBox(height: 10),
                      ...user.recentSessions.map((s) {
                        return _RecentSessionTile(session: s);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}

// ── Rank Badge ────────────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  Color get _color {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        'Rank #$rank',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color == const Color(0xFFFFD700)
              ? const Color(0xFFB8860B)
              : _color,
        ),
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topic Accuracy Bar ────────────────────────────────────────────────────────
class _TopicAccuracyBar extends StatelessWidget {
  final String topic;
  final double accuracy;

  const _TopicAccuracyBar({required this.topic, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topic,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                accuracy >= 90
                    ? AppTheme.primary
                    : accuracy >= 75
                    ? const Color(0xFF1565C0)
                    : Colors.orange,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Session Tile ───────────────────────────────────────────────────────
class _RecentSessionTile extends StatelessWidget {
  final _SessionRecord session;

  const _RecentSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final accuracy = (session.correct / session.total * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.topic,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.correct}/${session.total} correct',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$accuracy%',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accuracy >= 80 ? AppTheme.primary : Colors.orange,
                ),
              ),
              Text(
                session.timeAgo,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
