import 'package:flutter/material.dart';

/// PostureSense design-token palette.
/// All UI code should use these tokens — never hard-code colors.
class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color brandGreen     = Color(0xFF10B981);
  static const Color brandGreenDark = Color(0xFF059669);
  static const Color brandTeal      = Color(0xFF0D9488);

  // ── Light Mode ─────────────────────────────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF6FAF9);
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF0F7F4);
  static const Color lightBorder       = Color(0xFFE2EBE7);
  static const Color lightTextPrimary  = Color(0xFF0F172A);
  static const Color lightTextSecondary= Color(0xFF64748B);

  // ── Dark Mode ──────────────────────────────────────────────────────────────
  static const Color darkBackground    = Color(0xFF0D1117);
  static const Color darkSurface       = Color(0xFF161D2B);
  static const Color darkSurfaceLight  = Color(0xFF1F2A3D);
  static const Color darkBorder        = Color(0xFF243044);
  static const Color darkTextPrimary   = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ── Risk / Clinical ────────────────────────────────────────────────────────
  static const Color riskHigh     = Color(0xFFEF4444);
  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskLow      = Color(0xFF10B981);

  // ── Chart Data ─────────────────────────────────────────────────────────────
  static const Color dataBlue   = Color(0xFF3B82F6);
  static const Color dataPurple = Color(0xFF8B5CF6);

  // ── Stat Card Pastels (Light) ───────────────────────────────────────────────
  static const Color streakBgLight      = Color(0xFFFFF5F5);
  static const Color streakIconBgLight  = Color(0xFFFFE4E6);
  static const Color streakIconLight    = Color(0xFFF43F5E);

  static const Color avgBgLight         = Color(0xFFEFF6FF);
  static const Color avgIconBgLight     = Color(0xFFDBEAFE);
  static const Color avgIconLight       = Color(0xFF3B82F6);

  static const Color sessionBgLight     = Color(0xFFECFDF5);
  static const Color sessionIconBgLight = Color(0xFFD1FAE5);
  static const Color sessionIconLight   = Color(0xFF10B981);

  // ── Stat Card Pastels (Dark) ────────────────────────────────────────────────
  static const Color streakBgDark      = Color(0xFF201419);
  static const Color streakIconBgDark  = Color(0xFF321920);

  static const Color avgBgDark         = Color(0xFF131B2C);
  static const Color avgIconBgDark     = Color(0xFF1A2740);

  static const Color sessionBgDark     = Color(0xFF0E1E18);
  static const Color sessionIconBgDark = Color(0xFF122A21);

  // ── Backwards-compat aliases ────────────────────────────────────────────────
  static const Color background    = darkBackground;
  static const Color surface       = darkSurface;
  static const Color surfaceLight  = darkSurfaceLight;
  static const Color textPrimary   = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color primaryAccent = brandGreen;
  static const Color primaryAccentDim = Color(0x3310B981);

  // ── Dynamic context-aware helpers ──────────────────────────────────────────
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c) =>
      _dark(c) ? darkBackground : lightBackground;
  static Color surf(BuildContext c) =>
      _dark(c) ? darkSurface : lightSurface;
  static Color surfLight(BuildContext c) =>
      _dark(c) ? darkSurfaceLight : lightSurfaceLight;
  static Color text(BuildContext c) =>
      _dark(c) ? darkTextPrimary : lightTextPrimary;
  static Color subtext(BuildContext c) =>
      _dark(c) ? darkTextSecondary : lightTextSecondary;
  static Color border(BuildContext c) =>
      _dark(c) ? darkBorder : lightBorder;
  static Color cardShadow(BuildContext c) =>
      _dark(c)
          ? Colors.black.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.04);
}
