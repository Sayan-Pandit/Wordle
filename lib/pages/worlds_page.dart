import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordle/models/world_model.dart';
import 'package:wordle/pages/world_path_page.dart';
import 'package:wordle/core/theme/app_theme.dart';

class WorldsPage extends StatelessWidget {
  const WorldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "WORLD MAP", 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            letterSpacing: 2, 
            fontSize: 16, 
            color: isDark ? Colors.white : Colors.black87
          )
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          int currentGlobalLevel = 1;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final stats = data['stats'] ?? {};
            final levelData = stats['level'] ?? {};
            currentGlobalLevel = levelData['currentLevel'] ?? 1;
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: WorldModel.worlds.length,
            itemBuilder: (context, index) {
              return _buildRealWorldCard(context, index, currentGlobalLevel);
            },
          );
        },
      ),
    );
  }

  Widget _buildRealWorldCard(BuildContext context, int index, int currentGlobalLevel) {
    final world = WorldModel.worlds[index];
    
    // Level Range Logic
    int start = 1;
    if (index == 1) start = 21;
    if (index == 2) start = 51;
    if (index == 3) start = 101;

    final int totalInWorld = world.totalLevels;
    final int end = start + totalInWorld - 1;

    // COMPLETED Levels Logic (Current Level 2 means 1 is completed)
    int completed = 0;
    if (currentGlobalLevel > end) {
      completed = totalInWorld;
    } else if (currentGlobalLevel > start) {
      completed = currentGlobalLevel - start;
    }

    final double progressFactor = (completed / totalInWorld).clamp(0.0, 1.0);
    final int percent = (progressFactor * 100).toInt();

    // Unlock Logic
    bool isUnlocked = currentGlobalLevel >= start;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked 
            ? (isDark 
                ? [world.primaryColor.withOpacity(0.8), world.primaryColor.withOpacity(0.5)]
                : [world.primaryColor, world.primaryColor.withOpacity(0.9)])
            : (isDark ? [AppColors.darkSurface, AppColors.darkSurface] : [Colors.white, Colors.white]),
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(color: world.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorldPathPage(world: world))) : null,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(world.icon, color: Colors.white, size: 24),
                    ),
                    if (!isUnlocked)
                      const Icon(Icons.lock_rounded, color: Colors.white38, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                Text(world.name.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(world.difficulty.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
                const SizedBox(height: 24),
                Text(
                  index == 0 ? "Beginner friendly words to start your journey." : world.name, // Use placeholder if desc missing
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                
                // PROGRESS SECTION
                if (isUnlocked) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$percent% COMPLETED", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text("$completed/$totalInWorld LVLS", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("LOCKED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
                      Icon(Icons.lock_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 6, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressFactor,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
                      ),
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
}
