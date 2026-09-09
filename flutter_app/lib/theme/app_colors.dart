import 'package:flutter/material.dart';

class AppColors {
  // ── Dark Mode Palette (Current) ──
  static const Color darkBackground = Color(0xFF0A1128);
  static const Color darkSurface = Color(0xFF161F3D);
  static const Color darkSurfaceLight = Color(0xFF1F2A4A);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA0AAB2);

  // ── Light Mode Palette ──
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceLight = Color(0xFFE8EDF5);
  static const Color lightBorder = Color(0xFFDFE5EF);
  static const Color lightTextPrimary = Color(0xFF131C31);
  static const Color lightTextSecondary = Color(0xFF637286);

  // ── Backwards Compatible Defaults ──
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceLight = darkSurfaceLight;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;

  // ── Brand Accents & Clinical Tiers (Common) ──
  static const Color primaryAccent = Color(0xFF00C9A7);
  static const Color primaryAccentDim = Color(0x3300C9A7);
  static const Color riskHigh = Color(0xFFFF595E);
  static const Color riskModerate = Color(0xFFFFCA3A);
  static const Color riskLow = Color(0xFF00C9A7);

  // ── Chart Data Colors ──
  static const Color dataBlue = Color(0xFF3B82F6);
  static const Color dataPurple = Color(0xFF8B5CF6);

  // ── Dynamic Theme-Aware Helpers ──
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
  static Color surf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  static Color surfLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceLight : lightSurfaceLight;
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  static Color subtext(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceLight : lightBorder;
}
