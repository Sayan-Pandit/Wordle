import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordle/services/storage_service.dart';
import 'package:wordle/core/theme/app_theme.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: FutureBuilder<Map<String, dynamic>>(
        future: StorageService.getLocalStats(),
        builder: (context, localSnapshot) {
          Map<String, dynamic> localData = localSnapshot.data ?? {
            'daily': {'currentStreak': 0, 'maxStreak': 0, 'wins': 0, 'totalGames': 0},
            'level': {'currentLevel': 1, 'wins': 0, 'totalGames': 0, 'guessDistribution': '{}'}
          };

          if (user == null) return _buildStatsBody(context, localData);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              Map<String, dynamic> data = localData;
              if (snapshot.hasData && snapshot.data!.exists) {
                final cloudData = snapshot.data!.data() as Map<String, dynamic>;
                if (cloudData.containsKey('stats')) data = cloudData['stats'];
              }
              return _buildStatsBody(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsBody(BuildContext context, Map<String, dynamic> data) {
    final daily = Map<String, dynamic>.from(data['daily'] ?? {});
    final level = Map<String, dynamic>.from(data['level'] ?? {});

    return Column(
      children: [
        _buildHighlightMetric(context, daily),
        const SizedBox(height: 24),
        _buildSectionCard(
          context,
          title: "GUESS DISTRIBUTION",
          icon: Icons.bar_chart_rounded,
          accentColor: AppColors.info,
          children: [_buildDistributionSection(context, data)],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context,
          title: "GLOBAL LEADERBOARD",
          icon: Icons.leaderboard_rounded,
          accentColor: Colors.amber,
          children: [_buildLeaderboardSection(context)],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHighlightMetric(BuildContext context, Map<String, dynamic> daily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGreenGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeroMetric("STREAK", (daily['currentStreak'] ?? 0).toString(), "Days"),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildHeroMetric("WINS", (daily['wins'] ?? 0).toString(), "Total"),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildHeroMetric("BEST", (daily['maxStreak'] ?? 0).toString(), "Streak"),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value, String sub) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
        Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }

  Widget _buildDistributionSection(BuildContext context, Map<String, dynamic> data) {
    Map<String, dynamic> dist = {};
    try {
      final rawDist = data['guessDistribution'];
      dist = jsonDecode(rawDist is String ? rawDist : '{}');
    } catch (e) {}
    
    int winCount = 0;
    dist.forEach((_, v) => winCount += (v as int));

    return Column(
      children: List.generate(6, (index) {
        final count = dist[(index + 1).toString()] ?? 0;
        final double pct = winCount > 0 ? count / winCount : 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct > 0 ? pct : 0.08,
                    child: Container(
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.primaryGreen : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: count > 0 ? [
                          BoxShadow(color: AppColors.primaryGreen.withOpacity(0.2), blurRadius: 4)
                        ] : [],
                      ),
                      padding: const EdgeInsets.only(right: 8),
                      alignment: Alignment.centerRight,
                      child: count > 0 ? Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)) : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLeaderboardSection(BuildContext context) {
    final now = DateTime.now();
    final monthKey = "${now.year}_${now.month}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('lastUpdateMonth', isEqualTo: monthKey)
          .orderBy('monthlyXP', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Error: ${snapshot.error}", style: const TextStyle(fontSize: 10, color: Colors.redAccent)),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
            ),
          );
        }

        final players = snapshot.data?.docs ?? [];
        if (players.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("SEASON JUST STARTED!", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.05), height: 1),
          itemBuilder: (context, index) {
            final player = players[index].data() as Map<String, dynamic>;
            final username = player['username'] ?? 'Anonymous';
            final monthlyXp = player['monthlyXP'] ?? 0;
            final pfp = player['profilePictureUrl'] ?? 'green';
            
            // Premium Ranking UI
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _buildRankPosition(index + 1),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getColorFromName(pfp),
                    child: Text(username[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text(
                          _getRankTitle(player['xp'] ?? 0),
                          style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  Text("$monthlyXp XP", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryGreen)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRankPosition(int rank) {
    if (rank == 1) return const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24);
    if (rank == 2) return const Icon(Icons.workspace_premium_rounded, color: Color(0xFFC0C0C0), size: 22);
    if (rank == 3) return const Icon(Icons.workspace_premium_rounded, color: Color(0xFFCD7F32), size: 20);
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          "$rank", 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey)
        ),
      ),
    );
  }

  String _getRankTitle(int xp) {
    if (xp >= 5000) return 'GRANDMASTER';
    if (xp >= 2500) return 'WORD MASTER';
    if (xp >= 1000) return 'LINGUIST';
    if (xp >= 500) return 'SCHOLAR';
    return 'WORD ROOKIE';
  }

  Color _getColorFromName(String? name) {
    switch (name) {
      case 'blue': return Colors.blueAccent;
      case 'purple': return Colors.purpleAccent;
      case 'orange': return Colors.orangeAccent;
      case 'pink': return Colors.pinkAccent;
      default: return AppColors.primaryGreen;
    }
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required IconData icon, required Color accentColor, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
