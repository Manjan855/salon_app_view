
import 'package:flutter/material.dart';
import 'package:salon_app_view/core/constants/app_colors.dart';
import 'package:salon_app_view/core/constants/app_dimension.dart';
import 'package:salon_app_view/core/constants/app_text_style.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: AppColors.primarySwatch,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.cardBackground,
    dividerColor: AppColors.divider,

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: AppTextStyle.headline1,
      displayMedium: AppTextStyle.headline2,
      displaySmall: AppTextStyle.headline3,
      headlineMedium: AppTextStyle.headline4,
      headlineSmall: AppTextStyle.headline5,
      titleLarge: AppTextStyle.headline6,
      titleMedium: AppTextStyle.subtitle1,
      titleSmall: AppTextStyle.subtitle2,
      bodyLarge: AppTextStyle.bodyText1,
      bodyMedium: AppTextStyle.bodyText2,
      labelLarge: AppTextStyle.button,
      bodySmall: AppTextStyle.caption,
      labelSmall: AppTextStyle.overline,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: AppDimensions.elevation2,
      centerTitle: true,
      titleTextStyle: AppTextStyle.headline6,
      toolbarHeight: AppDimensions.appBarHeight,
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(
          AppDimensions.buttonMaxWidth,
          AppDimensions.buttonMinHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.inputFocusBorderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
    ),

    // // Card Theme
    // cardTheme: CardTheme(
    //   elevation: AppDimensions.cardElevation,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(AppDimensions.radiusM),
    //   ),
    //   margin: const EdgeInsets.all(AppDimensions.paddingS),
    // ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      thickness: AppDimensions.dividerNormal,
      space: AppDimensions.paddingL,
    ),

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: AppColors.primarySwatch,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.cardBackgroundDark,
    dividerColor: AppColors.dividerDark,

    // Text Theme for Dark Mode
    textTheme: TextTheme(
      displayLarge: AppTextStyle.headline1.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      displayMedium: AppTextStyle.headline2.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      displaySmall: AppTextStyle.headline3.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      headlineMedium: AppTextStyle.headline4.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      headlineSmall: AppTextStyle.headline5.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      titleLarge: AppTextStyle.headline6.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      titleMedium: AppTextStyle.subtitle1.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      titleSmall: AppTextStyle.subtitle2.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      bodyLarge: AppTextStyle.bodyText1.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: AppTextStyle.bodyText2.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      labelLarge: AppTextStyle.button.copyWith(color: Colors.white),
      bodySmall: AppTextStyle.caption.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      labelSmall: AppTextStyle.overline.copyWith(
        color: AppColors.textSecondaryDark,
      ),
    ),

    appBarTheme: const AppBarTheme(
      elevation: AppDimensions.elevation2,
      centerTitle: true,
      titleTextStyle: AppTextStyle.headline6,
      toolbarHeight: AppDimensions.appBarHeight,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(
          AppDimensions.buttonMaxWidth,
          AppDimensions.buttonMinHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.borderDark,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.borderDark,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.inputFocusBorderWidth,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
    ),

    // cardTheme: CardTheme(
    //   elevation: AppDimensions.cardElevation,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(AppDimensions.radiusM),
    //   ),
    //   margin: const EdgeInsets.all(AppDimensions.paddingS),
    // ),

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
    ),
  );
}

class AppThemeColors {
  final Color purpleDark;
  final Color purpleMid;
  final Color purpleAccent;
  final Color purpleLight;
  final Color white;
  final Color textMuted;
  final Color disabled;

  const AppThemeColors({
    required this.purpleDark,
    required this.purpleMid,
    required this.purpleAccent,
    required this.purpleLight,
    required this.white,
    required this.textMuted,
    required this.disabled,
  });

  static AppThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const AppThemeColors(
        purpleDark: Color(0xFF1A0A3B),
        purpleMid: Color(0xFF2D1B6B),
        purpleAccent: Color(0xFF7B2FBE),
        purpleLight: Color(0xFF9B6FD4),
        white: Color(0xFFFFFFFF),
        textMuted: Color(0xFFB8A9D9),
        disabled: Color(0xFF4A4A6A),
      );
    } else {
      return const AppThemeColors(
        purpleDark: Color(0xFFF6F3F9), // Light background
        purpleMid: Color(0xFFFFFFFF),  // White card surface
        purpleAccent: Color(0xFF673AB7), // Vibrant primary purple
        purpleLight: Color(0xFF9E77DC),  // Medium purple details
        white: Color(0xFF2D1B6B),      // Dark purple for text instead of white
        textMuted: Color(0xFF756F86),  // Muted gray-purple text
        disabled: Color(0xFFD6D3DF),   // Soft gray-purple disabled background
      );
    }
  }
}

extension AppThemeColorsExtension on BuildContext {
  AppThemeColors get themeColors => AppThemeColors.of(this);
}

