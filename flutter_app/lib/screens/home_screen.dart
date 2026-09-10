import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'dashboard_view.dart';
import 'analysis_results_screen.dart';
import 'exercise_screen.dart';
import 'profile_screen.dart'; // From team member's code

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default to Home Dashboard

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardView(onProfileTap: () => _onItemTapped(3)),
      const AnalysisResultsScreen(),
      const ExerciseScreen(),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // The current screen
          screens[_selectedIndex],
          
          // Floating Pill Navigation Bar
          Positioned(
            bottom: 30,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: AppColors.border(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.grid_view_rounded, 'Home', context),
          _buildNavItem(1, Icons.analytics_rounded, 'Results', context),
          _buildNavItem(2, Icons.fitness_center_rounded, 'Exercise', context),
          _buildNavItem(3, Icons.person_rounded, 'Profile', context),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, BuildContext context) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.black
                  : AppColors.subtext(context),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

