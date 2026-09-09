import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/posture_history_manager.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? 'No email provided';
    final AuthService authService = AuthService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([PostureHistoryManager(), ThemeController.instance]),
      builder: (context, _) {
        final manager = PostureHistoryManager();
        final int streakVal = manager.streak;
        final int avgScoreVal = manager.averageScore.round();
        final int totalSessionsVal = manager.totalSessions;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Title
                  Text(
                    'Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surf(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border(context), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.surfLight(context),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryAccent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.surf(context),
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.subtext(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Stats Panel
                  Row(
                    children: [
                      _buildStatBox(context, '🔥', '$streakVal', 'Streak'),
                      const SizedBox(width: 12),
                      _buildStatBox(context, '📊', '$avgScoreVal%', 'Avg Score'),
                      const SizedBox(width: 12),
                      _buildStatBox(context, '✅', '$totalSessionsVal', 'Scans'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Settings Menu List
                  Text(
                    'APPEARANCE & SETTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.subtext(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dark / Light Mode Switch Tile
                  _buildThemeToggleTile(context, isDark),

                  _buildSettingsTile(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    title: 'Account Settings',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // Sign Out Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.riskHigh.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.riskHigh,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // padding for the bottom nav bar
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox(BuildContext context, String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.subtext(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Material(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: AppColors.primaryAccent,
            size: 22,
          ),
          title: Text(
            'Theme Mode',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          subtitle: Text(
            isDark ? 'Dark Theme (Active)' : 'Light Theme (Active)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.subtext(context),
            ),
          ),
          trailing: Switch(
            value: isDark,
            activeTrackColor: AppColors.primaryAccent,
            onChanged: (val) {
              ThemeController.instance.toggleTheme();
            },
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Material(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primaryAccent, size: 22),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.subtext(context),
            size: 20,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
