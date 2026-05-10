import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordle/controllers/theme_controller.dart';
import 'package:wordle/services/auth_service.dart';
import 'package:wordle/services/storage_service.dart';
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
          const SizedBox(height: 32),
          const Text(
            'SUPPORT & FEEDBACK',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              _buildActionTile(
                title: 'Report a Bug',
                subtitle: 'Help us improve the experience',
                icon: Icons.bug_report_rounded,
                onTap: () => _showFeedbackDialog(context, 'Report a Bug'),
              ),
              const Divider(indent: 50),
              _buildActionTile(
                title: 'Suggest a Feature',
                subtitle: 'Share your ideas with us',
                icon: Icons.lightbulb_rounded,
                onTap: () => _showFeedbackDialog(context, 'Suggest a Feature'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'ABOUT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              _buildActionTile(
                title: 'App Version',
                subtitle: 'v1.1.1 (Stable)',
                icon: Icons.info_outline_rounded,
                onTap: () => _showAboutDialog(context),
              ),
              const Divider(indent: 50),
              _buildActionTile(
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                icon: Icons.policy_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your feedback helps us make Wordle better for everyone.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter details here...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await StorageService.saveFeedback(
                  type: title,
                  message: controller.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thank you! Your feedback has been sent.")),
                  );
                }
              }
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.grid_4x4_rounded, color: Colors.amber, size: 40)),
            ),
            const SizedBox(height: 20),
            const Text("WORDLE PREMIUM", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const Text(
              "Version 1.1.1",
              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),
            const Text(
              "The ultimate Wordle experience, now secured and optimized. Built with passion for the global community of word lovers.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            const Text("© 2026 Wordle Studio", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ),
          ),
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
