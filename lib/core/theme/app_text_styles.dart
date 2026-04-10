import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// All typography styles for NearRun.
/// Uses [Plus Jakarta Sans] — matching the Figma design system exactly.
/// Organised by M3 type roles: Display → Headline → Title → Body → Label.
class AppTextStyles {
  AppTextStyles._();

  // ─── Base font ─────────────────────────────────────────────────────────────
  static TextStyle get _base => GoogleFonts.plusJakartaSans(
        color: AppColors.onSurface,
        height: 1.3,
      );

  // ─── Display ───────────────────────────────────────────────────────────────
  /// e.g. large hero numbers like "5.2 km"
  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => _base.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      );

  // ─── Headline ──────────────────────────────────────────────────────────────
  /// e.g. "Ready to run, Marcus?" — main screen greeting
  static TextStyle get headlineLarge => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headlineMedium => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get headlineSmall => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      );

  // ─── Title ─────────────────────────────────────────────────────────────────
  /// e.g. card titles like "Last Run Recap", "Pace yourself early."
  static TextStyle get titleLarge => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      );

  static TextStyle get titleMedium => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  static TextStyle get titleSmall => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  // ─── Body ──────────────────────────────────────────────────────────────────
  /// e.g. card descriptions, weather info
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.onSurfaceVariant,
      );

  // ─── Label ─────────────────────────────────────────────────────────────────
  /// e.g. "KM", "TIME", "PACE" — stat unit labels, nav bar labels
  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  /// Uppercase micro-labels e.g. "KM", "QUICK TIP"
  static TextStyle get labelSmall => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.onSurfaceVariant,
      );

  // ─── Convenience / Semantic Aliases ────────────────────────────────────────

  /// Top app bar brand name "NearRun"
  static TextStyle get brandTitle => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.primary,
      );

  /// Home screen greeting "Ready to run, Marcus?"
  static TextStyle get greeting => headlineLarge;

  /// Greeting subtitle line
  static TextStyle get greetingSubtitle => bodyLarge.copyWith(
        fontSize: 16,
        color: AppColors.onSurfaceVariant,
      );

  /// "START RUN" text inside the big button
  static TextStyle get startRunLabel => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
        color: AppColors.onPrimary,
      );

  /// Stat value inside recap cards e.g. "5.2", "28'", "5:24"
  static TextStyle get statValue => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: -0.5,
      );

  /// Stat unit label e.g. "KM", "TIME", "PACE"
  static TextStyle get statUnit => labelSmall.copyWith(
        color: AppColors.onSurfaceVariant,
      );

  /// Bottom nav bar tab label
  static TextStyle get navLabel => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );

  /// Section chip / tag e.g. "QUICK TIP"
  static TextStyle get chipLabel => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.onSurfaceVariant,
      );
}
