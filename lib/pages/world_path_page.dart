import 'package:flutter/material.dart';
import 'package:wordle/models/world_model.dart';
import 'package:wordle/services/storage_service.dart';
import 'package:wordle/pages/wordle_screen.dart';
import 'package:wordle/models/game_mode.dart';
import 'package:wordle/core/theme/app_theme.dart';

class WorldPathPage extends StatelessWidget {
  final WorldModel world;

  const WorldPathPage({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.withOpacity(0.05),
      body: FutureBuilder<Map<String, dynamic>>(
        future: StorageService.getLocalStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};
          final levelData = stats['level'] ?? {};
          final int currentGlobalLevel = levelData['currentLevel'] ?? 1;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(context),
              _buildChapters(currentGlobalLevel),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          world.name,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5, color: isDark ? Colors.white : Colors.black87),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [world.primaryColor.withOpacity(0.15), isDark ? AppColors.darkBackground : Colors.white],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapters(int currentLevel) {
    final int totalChapters = (world.totalLevels / 10).ceil();
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final start = (index * 10) + 1;
          final end = (index + 1) * 10;
          return _ChapterGroup(
            chapter: index + 1,
            startLevel: start,
            endLevel: end,
            currentLevel: currentLevel,
            world: world,
          );
        },
        childCount: totalChapters,
      ),
    );
  }
}

class _ChapterGroup extends StatelessWidget {
  final int chapter;
  final int startLevel;
  final int endLevel;
  final int currentLevel;
  final WorldModel world;

  const _ChapterGroup({
    required this.chapter,
    required this.startLevel,
    required this.endLevel,
    required this.currentLevel,
    required this.world,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CHAPTER $chapter",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: world.primaryColor, letterSpacing: 2),
              ),
              Text(
                "${(currentLevel - startLevel).clamp(0, 10)}/10 Complete",
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              final levelNum = startLevel + index;
              final isUnlocked = levelNum <= currentLevel;
              final isCompleted = levelNum < currentLevel;
              final isCurrent = levelNum == currentLevel;
              final isBoss = levelNum % 10 == 0;

              return _LevelItem(
                level: levelNum,
                isUnlocked: isUnlocked,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isBoss: isBoss,
                world: world,
                onTap: () {
                  if (isUnlocked) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WordleScreen(mode: GameMode.level, level: levelNum))
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}

class _LevelItem extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBoss;
  final WorldModel world;
  final VoidCallback onTap;

  const _LevelItem({
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.isBoss,
    required this.world,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked 
              ? (isCurrent ? world.primaryColor : (isDark ? AppColors.darkSurface : Colors.white)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent 
                ? Colors.white 
                : (isUnlocked ? world.primaryColor.withOpacity(0.3) : (isDark ? Colors.white10 : Colors.black12)),
            width: isCurrent ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: isCompleted 
            ? Icon(Icons.check_rounded, color: world.primaryColor, size: 18)
            : isBoss
              ? Icon(Icons.stars_rounded, color: isUnlocked ? Colors.white : Colors.grey, size: 18)
              : Text(
                  "$level",
                  style: TextStyle(
                    color: isUnlocked 
                        ? (isCurrent ? Colors.white : (isDark ? Colors.white : Colors.black87)) 
                        : (isDark ? Colors.white12 : Colors.black12),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
      ),
    );
  }
}
