import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordle/pages/home_page.dart';
import 'package:wordle/pages/settings_page.dart';
import 'package:wordle/pages/statistics_page.dart';
import 'package:wordle/pages/profile_page.dart';
import 'package:wordle/core/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SettingsPage(),
    const StatisticsPage(),
  ];

  final List<String> _titles = [
    '',
    'SETTINGS',
    'TRACKER',
  ];

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.withOpacity(0.05),
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex], 
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              String username = user?.displayName ?? "P";
              String? profilePictureUrl = user?.photoURL;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                username = data['username'] ?? username;
                profilePictureUrl = data['profilePictureUrl'] ?? profilePictureUrl;
              }
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _getColorFromName(profilePictureUrl),
                      child: Text(username[0].toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildFloatingNavBar(isDark),
    );
  }

  Widget _buildFloatingNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.1), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, 'Hub'),
                _buildNavItem(1, Icons.tune_rounded, 'Config'),
                _buildNavItem(2, Icons.analytics_rounded, 'Stats'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGreen : Colors.grey, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w900, fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }
}
