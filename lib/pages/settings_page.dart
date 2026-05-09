import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordle/controllers/theme_controller.dart';
import 'package:wordle/services/auth_service.dart';
import 'package:wordle/core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUDIO & HAPTICS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              _buildSwitchTile(
                title: 'Sound Effects',
                subtitle: themeController.isMuted ? 'Game is muted' : 'Audio is active',
                icon: themeController.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                value: !themeController.isMuted,
                onChanged: (_) => themeController.toggleMute(),
              ),
              const Divider(indent: 50),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: themeController.isVibrationEnabled ? 'Tactile feedback on' : 'Silent feedback',
                icon: themeController.isVibrationEnabled ? Icons.vibration_rounded : Icons.do_not_disturb_on_rounded,
                value: themeController.isVibrationEnabled,
                onChanged: (_) => themeController.toggleVibration(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'ACCOUNT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              _buildActionTile(
                title: 'Password Reset',
                subtitle: 'Send a link to ${user?.email}',
                icon: Icons.lock_reset_rounded,
                onTap: () async {
                  if (user?.email != null) {
                    await AuthService().sendPasswordResetEmail(user!.email!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset link sent!')),
                      );
                    }
                  }
                },
              ),
              const Divider(indent: 50),
              _buildActionTile(
                title: 'Sign Out',
                subtitle: 'Securely log out of your account',
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onTap: () => AuthService().signOut(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'MAINTENANCE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              _buildActionTile(
                title: 'Clear Cache',
                subtitle: 'Reset local data & force sync',
                icon: Icons.delete_sweep_rounded,
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Clear Cache?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "This will reset local settings. Your cloud progress will be restored on next sync.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cache Cleared. Restarting sync...")),
                );
              }
            },
            child: const Text("CLEAR", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: color ?? AppColors.primaryGreen),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }
}
