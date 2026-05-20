
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
