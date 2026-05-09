import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordle/services/storage_service.dart';
import 'package:wordle/models/game_mode.dart';
import 'package:wordle/models/achievement.dart';
import 'package:wordle/models/world_model.dart';
import 'package:wordle/pages/wordle_screen.dart';
import 'package:wordle/pages/worlds_page.dart';
import 'package:wordle/core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  Key _refreshKey = UniqueKey();
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _refreshKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(painter: _ParticlePainter(_particleController.value, isDark));
            },
          ),
        ),
        
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            String username = user?.displayName ?? "Explorer";
            String? profilePictureUrl = user?.photoURL;
            Map<String, dynamic> stats = {};
            int xp = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              username = data['username'] ?? username;
              profilePictureUrl = data['profilePictureUrl'] ?? profilePictureUrl;
              stats = data['stats'] ?? {};
              xp = data['xp'] ?? 0;
            }

            final currentRank = UserRank.getRank(xp);
            final dailyStreak = stats['daily']?['currentStreak'] ?? 0;
            final currentLevel = stats['level']?['currentLevel'] ?? 1;

            return SingleChildScrollView(
              key: _refreshKey,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  _buildHeader(username, profilePictureUrl, currentRank, xp),
                  const SizedBox(height: 32),
                  _buildJourneyCard(context, currentLevel, xp, currentRank),
                  const SizedBox(height: 20),
                  _buildDailyCard(context, dailyStreak),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(String name, String? colorName, UserRank rank, int xp) {
    return Column(
      children: [
        const Text(
          "WORDLE",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        Text(rank.title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: rank.color, letterSpacing: 3)),
        const SizedBox(height: 16),
        _buildXPBar(xp, rank),
      ],
    );
  }

  Widget _buildXPBar(int xp, UserRank currentRank) {
    final nextRankIndex = UserRank.ranks.indexOf(currentRank) + 1;
    final nextRank = nextRankIndex < UserRank.ranks.length ? UserRank.ranks[nextRankIndex] : null;
    final double progress = nextRank != null ? (xp - currentRank.minXP) / (nextRank.minXP - currentRank.minXP) : 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('XP: $xp', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            if (nextRank != null)
              Text('NEXT: ${nextRank.title}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [currentRank.color, currentRank.color.withOpacity(0.5)]),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: currentRank.color.withOpacity(0.3), blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneyCard(BuildContext context, int level, int xp, UserRank currentRank) {
    WorldModel currentWorld = WorldModel.worlds[0];
    int currentWorldLevel = level;

    if (level > 60) { currentWorld = WorldModel.worlds[3]; currentWorldLevel = level - 60; }
    else if (level > 40) { currentWorld = WorldModel.worlds[2]; currentWorldLevel = level - 40; }
    else if (level > 20) { currentWorld = WorldModel.worlds[1]; currentWorldLevel = level - 20; }
    else { currentWorld = WorldModel.worlds[0]; currentWorldLevel = level; }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [AppColors.darkSurface, AppColors.darkBackground]
            : [Colors.white, Colors.grey.withOpacity(0.05)],
        ),
        border: Border.all(color: currentWorld.primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorldsPage()));
            _refresh();
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ADVENTURE MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: currentWorld.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(currentWorld.difficulty.name.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: currentWorld.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currentWorld.name, 
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : Colors.black87
                  )
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.map_rounded, color: currentWorld.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Current Level: $currentWorldLevel', 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: currentWorld.primaryColor
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCard(BuildContext context, int streak) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.2)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WordleScreen(mode: GameMode.daily)));
          _refresh();
        },
        leading: const Icon(Icons.wb_sunny_rounded, color: AppColors.primaryYellow),
        title: Text(
          'DAILY CHALLENGE', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            color: isDark ? Colors.white : Colors.black87
          )
        ),
        subtitle: Text(
          streak > 0 ? '$streak Day Streak! 🔥' : 'Maintain your streak', 
          style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12)
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey : Colors.black26),
      ),
    );
  }

  Color _getColorFromName(String? name) {
    switch (name) {
      case "blue": return Colors.blueAccent;
      case "purple": return Colors.purpleAccent;
      case "orange": return Colors.orangeAccent;
      case "pink": return Colors.pinkAccent;
      case "teal": return Colors.tealAccent;
      case "red": return Colors.redAccent;
      default: return AppColors.primaryGreen;
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final bool isDark;
  _ParticlePainter(this.t, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05);
    final random = Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final yOffset = random.nextDouble() * 100;
      final y = (size.height - ((t * 200 + yOffset) % size.height));
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
