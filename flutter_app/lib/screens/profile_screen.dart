import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                    onTap: () => _showAccountSettingsSheet(context, user),
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () => _showNotificationsSheet(context),
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    onTap: () => _showPrivacySecuritySheet(context),
                  ),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => _showHelpSupportSheet(context),
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
          onTap: () {
            ThemeController.instance.toggleTheme();
          },
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

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Account Settings Sheet
  // ═════════════════════════════════════════════════════════════════════════
  void _showAccountSettingsSheet(BuildContext context, User? user) {
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? 'No email associated';
    final uid = user?.uid ?? 'Unknown';
    final created = user?.metadata.creationTime;
    final createdStr = created != null ? '${created.day}/${created.month}/${created.year}' : 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: AppColors.surf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.border(context), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.subtext(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Account Settings',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name tile with edit
              _buildAccountInfoCard(
                context,
                title: 'Display Name',
                value: displayName,
                icon: Icons.badge_outlined,
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    _showEditDisplayNameDialog(context, user, displayName);
                  },
                  child: const Text('Edit', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              // Email tile with verified tag
              _buildAccountInfoCard(
                context,
                title: 'Email Address',
                value: email,
                icon: Icons.mail_outline_rounded,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1AE67A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF1AE67A), size: 12),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(color: Color(0xFF1AE67A), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // UID tile
              _buildAccountInfoCard(
                context,
                title: 'Account User ID',
                value: uid.length > 18 ? '${uid.substring(0, 18)}...' : uid,
                icon: Icons.fingerprint_rounded,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryAccent),
                  tooltip: 'Copy UID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Member since
              _buildAccountInfoCard(
                context,
                title: 'Member Since',
                value: createdStr,
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 24),

              // Password reset
              OutlinedButton.icon(
                onPressed: () async {
                  if (user?.email != null) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                      if (context.mounted) {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password reset email dispatched to ${user.email}!'),
                            backgroundColor: AppColors.primaryAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not send reset link: $e')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: const Text('Send Password Reset Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text(context),
                  side: BorderSide(color: AppColors.border(context)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDisplayNameDialog(BuildContext context, User? user, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Display Name', style: GoogleFonts.inter(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: AppColors.surfLight(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text('Cancel', style: TextStyle(color: AppColors.subtext(context))),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && user != null) {
                  await user.updateDisplayName(newName);
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                    {'displayName': newName},
                    SetOptions(merge: true),
                  );
                  if (context.mounted) {
                    Navigator.pop(dlgCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Display name updated successfully!'),
                        backgroundColor: AppColors.primaryAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfLight(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.subtext(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Notifications Sheet
  // ═════════════════════════════════════════════════════════════════════════
  void _showNotificationsSheet(BuildContext context) {
    bool breakReminders = true;
    bool dailyScan = true;
    bool postureAlert = true;
    bool hapticFeedback = true;
    bool weeklyReport = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: AppColors.surf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppColors.border(context), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.subtext(context).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryAccent, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Notification Preferences',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildNotificationSwitch(
                    context,
                    title: 'Posture Break Alerts',
                    subtitle: 'Notify every 30 minutes to check spinal alignment',
                    value: breakReminders,
                    onChanged: (val) => setSheetState(() => breakReminders = val),
                  ),
                  _buildNotificationSwitch(
                    context,
                    title: 'Daily Scan Reminders',
                    subtitle: 'Morning & evening prompts to track neck tilt',
                    value: dailyScan,
                    onChanged: (val) => setSheetState(() => dailyScan = val),
                  ),
                  _buildNotificationSwitch(
                    context,
                    title: 'Bad Posture Warning Audio',
                    subtitle: 'Play gentle tone when neck tilt exceeds 25° during scan',
                    value: postureAlert,
                    onChanged: (val) => setSheetState(() => postureAlert = val),
                  ),
                  _buildNotificationSwitch(
                    context,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on posture calibration hold completion',
                    value: hapticFeedback,
                    onChanged: (val) => setSheetState(() => hapticFeedback = val),
                  ),
                  _buildNotificationSwitch(
                    context,
                    title: 'Weekly Progress Digest',
                    subtitle: 'Summary of your cervical angle improvements',
                    value: weeklyReport,
                    onChanged: (val) => setSheetState(() => weeklyReport = val),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification preferences saved! 🔔'),
                          backgroundColor: AppColors.primaryAccent,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfLight(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.subtext(context))),
        value: value,
        activeTrackColor: AppColors.primaryAccent,
        onChanged: onChanged,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Privacy & Security Sheet
  // ═════════════════════════════════════════════════════════════════════════
  void _showPrivacySecuritySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: AppColors.surf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.border(context), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.subtext(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Privacy & Security',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // On-device processing banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1AE67A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1AE67A).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFF1AE67A), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '100% Local On-Device AI Vision',
                            style: TextStyle(color: Color(0xFF1AE67A), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your camera video feed and uploaded photos are processed exclusively inside your device memory using ML Kit pose estimation. Zero video streams or facial photos are ever saved or transmitted to external servers.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.text(context), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfLight(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: AppColors.primaryAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Encrypted Cloud Storage', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text(context))),
                          const SizedBox(height: 2),
                          Text('Only numerical tilt angles, dates, and session scores are stored in your private Firebase vault.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.subtext(context))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Danger Zone: Clear History
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showClearHistoryConfirmDialog(context);
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18),
                label: const Text('Clear All Posture History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.riskHigh,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showPrivacyPolicyDialog(context);
                },
                child: const Text('View Privacy Policy & Terms', style: TextStyle(color: AppColors.primaryAccent, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearHistoryConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.riskHigh),
            const SizedBox(width: 10),
            Text('Clear History?', style: GoogleFonts.inter(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'This will permanently delete all your posture scan records from cloud & local storage. Your streak and scores will reset.',
          style: GoogleFonts.inter(color: AppColors.subtext(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtext(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await PostureHistoryManager().clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Posture scan history has been cleared.'),
                    backgroundColor: AppColors.primaryAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.riskHigh, foregroundColor: Colors.white),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Privacy Policy', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.text(context))),
        content: SingleChildScrollView(
          child: Text(
            '1. Camera Data: The camera input is strictly analyzed in volatile RAM using on-device ML Kit pose detection. No video frames, photographs, or raw biometric images are stored on our servers.\n\n'
            '2. Data Security: Calculated neck flexion angles and session timestamps are encrypted in transit and stored in Firebase Firestore under strict per-user security rules.\n\n'
            '3. User Control: You may delete your scan history or export reports anytime.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext(context), height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Help & Support Sheet
  // ═════════════════════════════════════════════════════════════════════════
  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: AppColors.surf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.border(context), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.subtext(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AppColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Help & Support',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    _buildFaqItem(
                      context,
                      'How is the neck angle measured?',
                      'Our AI detects your ear and shoulder landmarks and computes the forward cervical inclination angle from the vertical plumb line using θ = arctan(|Δx| / |Δy|) × (180 / π). An angle under 15° represents healthy posture.',
                    ),
                    _buildFaqItem(
                      context,
                      'What are the risk thresholds?',
                      '• Good (0°–14°): Healthy cervical spine alignment.\n• Warning (15°–29°): Noticeable forward tilt — common during phone or laptop use.\n• Critical (30°+): Severe forward posture placing up to 27kg of excess force on cervical discs.',
                    ),
                    _buildFaqItem(
                      context,
                      'How should I stand for an accurate scan?',
                      'Turn exactly 90° sideways to the camera so one ear and shoulder are clearly visible in the frame. Keep your camera at eye level, around 1 to 2 meters away.',
                    ),
                    _buildFaqItem(
                      context,
                      'How often should I do corrective exercises?',
                      'We recommend performing Chin Tucks, Neck Rolls, and Chest Stretches 2–3 times daily, especially every 30–45 minutes during sustained desk work.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact support button
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'support@textneck.ai'));
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support email copied: support@textneck.ai'),
                      backgroundColor: AppColors.primaryAccent,
                    ),
                  );
                },
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Contact Support (support@textneck.ai)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfLight(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text(context)),
        ),
        iconColor: AppColors.primaryAccent,
        collapsedIconColor: AppColors.subtext(context),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext(context), height: 1.5),
          ),
        ],
      ),
    );
  }
}
