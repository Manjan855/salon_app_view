import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Colors.deepPurple;
  static const Color primaryDark = Color(0xFF3700B3);
  static const Color primaryLight = Color(0xFFB39DDB);
  static const Color secondary = Colors.deepPurpleAccent;
  static const Color secondaryDark = Color(0xFF018786);
  static const Color secondaryLight = Color(0xFFB2EBF2);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textDisabledDark = Color(0xFF6C6C6C);

  // Accent Colors
  static const Color accentRed = Color(0xFFE53935);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentTeal = Color(0xFF009688);
  static const Color accentIndigo = Color(0xFF3F51B5);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color pending = Color(0xFFFF9800);
  static const Color cancelled = Color(0xFF9E9E9E);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFF6200EE)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentPurple, accentPink],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF2E7D32)],
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);
  static const Color borderFocus = primary;
  static const Color borderError = error;

  // Divider Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);
  static const Color cardShadow = Color(0x1A000000);

  // Overlay Colors
  static const Color overlayLight = Color(0x0A000000);
  static const Color overlayMedium = Color(0x1A000000);
  static const Color overlayDark = Color(0x33000000);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);

  // Social Media Colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color instagram = Color(0xFFE4405F);
  static const Color linkedin = Color(0xFF0077B5);
  static const Color youtube = Color(0xFFFF0000);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color telegram = Color(0xFF26A5E4);
  static const Color snapchat = Color(0xFFFFFC00);

  // Custom App-specific Colors
  static const Color ratingStar = Color(0xFFFFB900);
  static const Color onlineStatus = Color(0xFF4CAF50);
  static const Color offlineStatus = Color(0xFF9E9E9E);
  static const Color busyStatus = Color(0xFFE53935);

  // Chart Colors
  static const List<Color> chartColors = [
    accentBlue,
    accentRed,
    accentGreen,
    accentYellow,
    accentPurple,
    accentOrange,
    accentPink,
    accentTeal,
  ];

  // Material Color Swatches
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF673AB7, <int, Color>{
        50: Color(0xFFEDE7F6),
        100: Color(0xFFD1C4E9),
        200: Color(0xFFB39DDB),
        300: Color(0xFF9575CD),
        400: Color(0xFF7E57C2),
        500: Color(0xFF673AB7),
        600: Color(0xFF5E35B1),
        700: Color(0xFF512DA8),
        800: Color(0xFF4527A0),
        900: Color(0xFF311B92),
      });

  static const MaterialAccentColor secondarySwatch =
      MaterialAccentColor(0xFF7C4DFF, <int, Color>{
        100: Color(0xFFB388FF),
        200: Color(0xFF7C4DFF),
        400: Color(0xFF651FFF),
        700: Color(0xFF6200EA),
      });
}

// Extension for easy access to colors
extension AppColorExtension on BuildContext {
  AppColors get colors => AppColors();

  Color get primaryColor => AppColors.primary;
  Color get secondaryColor => AppColors.secondary;
  Color get backgroundColor => Theme.of(this).brightness == Brightness.light
      ? AppColors.background
      : AppColors.backgroundDark;
  Color get surfaceColor => Theme.of(this).brightness == Brightness.light
      ? AppColors.surface
      : AppColors.surfaceDark;
  Color get textPrimaryColor => Theme.of(this).brightness == Brightness.light
      ? AppColors.textPrimary
      : AppColors.textPrimaryDark;
  Color get textSecondaryColor => Theme.of(this).brightness == Brightness.light
      ? AppColors.textSecondary
      : AppColors.textSecondaryDark;
}
