import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordle/services/auth_service.dart';
import 'package:wordle/services/achievement_service.dart';
import 'package:wordle/models/achievement.dart';
import 'package:wordle/core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  
  final List<Map<String, dynamic>> _avatarOptions = [
    {'name': 'green', 'color': AppColors.primaryGreen},
    {'name': 'blue', 'color': Colors.blueAccent},
    {'name': 'purple', 'color': Colors.purpleAccent},
    {'name': 'orange', 'color': Colors.orangeAccent},
    {'name': 'pink', 'color': Colors.pinkAccent},
    {'name': 'teal', 'color': Colors.tealAccent},
    {'name': 'red', 'color': Colors.redAccent},
  ];

  Color _getColorFromName(String? name) {
    for (var option in _avatarOptions) {
      if (option['name'] == name) return option['color'];
    }
    return AppColors.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PROFILE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String username = user?.displayName ?? user?.email?.split('@')[0] ?? "Player";
          String? profilePictureUrl = user?.photoURL;
          int xp = 0;
          Map<String, dynamic> stats = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            username = userData['username'] ?? username;
            profilePictureUrl = userData['profilePictureUrl'] ?? profilePictureUrl;
            xp = userData['xp'] ?? 0;
            stats = userData['stats'] ?? {};
          }

          final rank = UserRank.getRank(xp);
          final badges = AchievementService.getUnlockedBadges(stats);
          final metrics = AchievementService.calculateLiveMetrics(stats);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              children: [
                _buildProfileHeader(username, profilePictureUrl, rank),
                const SizedBox(height: 32),
                _buildAchievementSection(context, isDark, badges),
                const SizedBox(height: 32),
                _buildStatsPreview(context, isDark, metrics),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () {
                    _authService.signOut();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? colorName, UserRank rank) {
    return Column(
      children: [
        Hero(
          tag: 'profile-avatar',
          child: CircleAvatar(
            radius: 50,
            backgroundColor: _getColorFromName(colorName),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        Text(rank.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showEditProfileDialog(name, colorName),
          icon: const Icon(Icons.edit_rounded, size: 14),
          label: const Text("EDIT PROFILE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColorFromName(colorName).withOpacity(0.1),
            foregroundColor: _getColorFromName(colorName),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(String currentName, String? currentColor) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    String selectedColor = currentColor ?? 'green';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 32, left: 24, right: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("EDIT IDENTITY", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text("PROFILE COLOR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    final option = _avatarOptions[index];
                    final isSelected = selectedColor == option['name'];
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = option['name']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 50,
                        decoration: BoxDecoration(
                          color: option['color'],
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await _authService.updateProfile(
                      username: nameController.text.trim(),
                      profilePictureUrl: selectedColor,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementSection(BuildContext context, bool isDark, List<BadgeModel> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ACHIEVEMENTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            return _buildBadgeCard(badges[index], isDark);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, bool isDark) {
    final double progressPct = (badge.currentProgress / badge.targetValue).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badge.isUnlocked ? badge.rarityColor.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: badge.isUnlocked ? [
          BoxShadow(color: badge.rarityColor.withOpacity(0.1), blurRadius: 10)
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: badge.isUnlocked ? 1.0 : 0.4,
            child: Text(badge.icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: badge.isUnlocked ? (isDark ? Colors.white : Colors.black) : Colors.grey,
            ),
          ),
          Text(
            badge.rarity.name.toUpperCase(),
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badge.isUnlocked ? badge.rarityColor : Colors.grey),
          ),
          if (!badge.isUnlocked) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPct,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(badge.rarityColor.withOpacity(0.5)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${badge.currentProgress.toInt()}/${badge.targetValue.toInt()}",
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsPreview(BuildContext context, bool isDark, Map<String, String> metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("WIN RATE", metrics['winRate']!),
          _buildStatItem("ACCURACY", metrics['accuracy']!),
          _buildStatItem("IQ SCORE", metrics['iq']!),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryGreen)),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey)),
      ],
    );
  }
}
