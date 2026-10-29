/// PostureSense reusable UI components.
/// Import this file across all screens for consistent styling.
library ps_components;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Typography helpers
// ─────────────────────────────────────────────────────────────────────────────

class PSText {
  PSText._();

  static TextStyle headline(BuildContext c, {double size = 24}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: AppColors.text(c),
        height: 1.2,
      );

  static TextStyle title(BuildContext c, {double size = 17}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.text(c),
      );

  static TextStyle body(BuildContext c, {double size = 14}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: AppColors.text(c),
        height: 1.5,
      );

  static TextStyle caption(BuildContext c, {double size = 12}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: AppColors.subtext(c),
      );

  static TextStyle label(BuildContext c, {double size = 10}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.subtext(c),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PSCard — standard surface card
// ─────────────────────────────────────────────────────────────────────────────

class PSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;

  const PSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surf(context),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: border ?? Border.all(color: AppColors.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow(context),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSButton — primary CTA button
// ─────────────────────────────────────────────────────────────────────────────

class PSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final double height;

  const PSButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSTextField — styled text input
// ─────────────────────────────────────────────────────────────────────────────

class PSTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const PSTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 14, color: AppColors.subtext(context)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    size: 20, color: AppColors.subtext(context))
                : null,
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceLight
                : AppColors.lightSurfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.border(context), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.brandGreen, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSChip — small badge/pill
// ─────────────────────────────────────────────────────────────────────────────

class PSChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;
  final double fontSize;

  const PSChip({
    super.key,
    required this.label,
    this.color,
    this.bgColor,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandGreen;
    final bg = bgColor ?? c.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: fontSize, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSPageHeader — standard screen title + subtitle
// ─────────────────────────────────────────────────────────────────────────────

class PSPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PSPageHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PSText.headline(context)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: PSText.caption(context)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSStatCard — metric card (streak / avg / sessions)
// ─────────────────────────────────────────────────────────────────────────────

class PSStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final Color cardBg;

  const PSStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.border(context).withValues(alpha: 0.5),
              width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text(context))),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(unit,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.subtext(context))),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtext(context))),
                Icon(Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.subtext(context)
                        .withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSEmptyState — empty placeholder
// ─────────────────────────────────────────────────────────────────────────────

class PSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PSEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return PSCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon,
              size: 40,
              color: AppColors.subtext(context).withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(title, style: PSText.title(context, size: 15)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: PSText.caption(context),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSIconButton — small square icon action button
// ─────────────────────────────────────────────────────────────────────────────

class PSIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? bgColor;

  const PSIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.surf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Icon(icon,
            size: 20,
            color: iconColor ?? AppColors.text(context)),
      ),
    );
  }
}
