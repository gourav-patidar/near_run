import 'package:flutter/material.dart';

/// All color tokens from the NearRun design system.
/// Based on Material You / M3 color scheme with teal as primary.
class AppColors {
  AppColors._();

  // ─── Primary (Teal) ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00675C);
  static const Color primaryDim = Color(0xFF005A50);
  static const Color primaryContainer = Color(0xFF5BF4DE);
  static const Color primaryFixed = Color(0xFF5BF4DE);
  static const Color primaryFixedDim = Color(0xFF48E5D0);
  static const Color onPrimary = Color(0xFFC1FFF2);
  static const Color onPrimaryContainer = Color(0xFF00594F);
  static const Color onPrimaryFixedVariant = Color(0xFF006358);
  static const Color inversePrimary = Color(0xFF65FDE6);

  // ─── Secondary (Blue) ──────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF005DA7);
  static const Color secondaryDim = Color(0xFF005192);
  static const Color secondaryContainer = Color(0xFFB7D3FF);
  static const Color secondaryFixed = Color(0xFFB7D3FF);
  static const Color secondaryFixedDim = Color(0xFF9FC6FF);
  static const Color onSecondary = Color(0xFFEEF3FF);
  static const Color onSecondaryContainer = Color(0xFF004884);
  static const Color onSecondaryFixed = Color(0xFF003563);
  static const Color onSecondaryFixedVariant = Color(0xFF005294);

  // ─── Tertiary (Pink/Red) ────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFA53046);
  static const Color tertiaryDim = Color(0xFF95233B);
  static const Color tertiaryContainer = Color(0xFFFF909D);
  static const Color tertiaryFixed = Color(0xFFFF909D);
  static const Color tertiaryFixedDim = Color(0xFFFF788B);
  static const Color onTertiary = Color(0xFFFFEFEF);
  static const Color onTertiaryContainer = Color(0xFF67001F);
  static const Color onTertiaryFixed = Color(0xFF39000D);
  static const Color onTertiaryFixedVariant = Color(0xFF760726);

  // ─── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFB31B25);
  static const Color errorDim = Color(0xFF9F0519);
  static const Color errorContainer = Color(0xFFFB5151);
  static const Color onError = Color(0xFFFFEFEE);
  static const Color onErrorContainer = Color(0xFF570008);

  // ─── Surface & Background ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7F9);
  static const Color surface = Color(0xFFF5F7F9);
  static const Color surfaceBright = Color(0xFFF5F7F9);
  static const Color surfaceDim = Color(0xFFD0D5D8);
  static const Color surfaceVariant = Color(0xFFD9DDE0);

  // Surface containers (lowest → highest elevation)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEEF1F3);
  static const Color surfaceContainer = Color(0xFFE5E9EB);
  static const Color surfaceContainerHigh = Color(0xFFDFE3E6);
  static const Color surfaceContainerHighest = Color(0xFFD9DDE0);

  // ─── On Surface ────────────────────────────────────────────────────────────
  static const Color onBackground = Color(0xFF2C2F31);
  static const Color onSurface = Color(0xFF2C2F31);
  static const Color onSurfaceVariant = Color(0xFF595C5E);
  static const Color inverseSurface = Color(0xFF0B0F10);
  static const Color inverseOnSurface = Color(0xFF9A9D9F);

  // ─── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF747779);
  static const Color outlineVariant = Color(0xFFABADAF);

  // ─── Tint ──────────────────────────────────────────────────────────────────
  static const Color surfaceTint = Color(0xFF00675C);

  // ─── Convenience Aliases (for readability in UI code) ─────────────────────
  /// Semi-transparent white for glass-morphism cards
  static const Color glassWhite = Color(0x99FFFFFF);

  /// Glow color used behind the Start Run button
  static Color primaryGlow = primary.withOpacity(0.25);

  /// Bottom nav active indicator background
  static Color navActiveBackground = primary.withOpacity(0.10);

  /// Card shadow
  static Color cardShadow = onSurface.withOpacity(0.06);
}
