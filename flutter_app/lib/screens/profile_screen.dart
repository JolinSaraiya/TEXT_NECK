import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/posture_history_manager.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? 'No email provided';
    final AuthService authService = AuthService();

    return AnimatedBuilder(
      animation: PostureHistoryManager(),
      builder: (context, _) {
        final manager = PostureHistoryManager();
        final int streakVal = manager.streak;
        final int avgScoreVal = manager.averageScore.round();
        final int totalSessionsVal = manager.totalSessions;

        return Scaffold(
          backgroundColor: AppColors.background,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceLight, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.surfaceLight,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryAccent,
                                width: 3,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.surface,
                              child: Icon(
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Stats Panel
                  Row(
                    children: [
                      _buildStatBox('🔥', '$streakVal', 'Streak'),
                      const SizedBox(width: 12),
                      _buildStatBox('📊', '$avgScoreVal%', 'Avg Score'),
                      const SizedBox(width: 12),
                      _buildStatBox('✅', '$totalSessionsVal', 'Scans'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Settings Menu List
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Account Settings',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
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
                          color: AppColors.riskHigh.withOpacity(0.2),
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

  Widget _buildStatBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight, width: 1),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primaryAccent, size: 22),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
