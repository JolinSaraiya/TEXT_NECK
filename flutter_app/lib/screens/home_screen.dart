import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'dashboard_view.dart';
import 'analysis_results_screen.dart';
import 'exercise_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardView(
        onProfileTap: () => _onItemTapped(3),
        onExercisesTap: () => _onItemTapped(2),
      ),
      const AnalysisResultsScreen(),
      const ExerciseScreen(),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // Current Active Screen
          screens[_selectedIndex],

          // Floating Pill Navigation Bar (Matching Design Screenshots)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _buildFloatingNavBar(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2E) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? const Color(0xFF263246) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
          _buildNavItem(1, Icons.bar_chart_rounded, 'Stats', isDark),
          _buildNavItem(2, Icons.directions_run_rounded, 'Exercises', isDark),
          _buildNavItem(3, Icons.person_rounded, 'Profile', isDark),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;

    final activeBg = isDark ? const Color(0xFF143026) : const Color(0xFFE6F4EA);
    final activeFg = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    final inactiveFg = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeFg : inactiveFg,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeFg : inactiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
