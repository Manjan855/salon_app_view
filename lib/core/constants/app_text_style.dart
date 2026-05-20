// ============================================================
// 1. app_textstyle.dart
// ============================================================
import 'package:flutter/material.dart';

class AppTextStyle {
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1.2,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 60,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const TextStyle headline3 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );
  static const TextStyle headline4 = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.2,
  );
  static const TextStyle headline5 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );
  static const TextStyle headline6 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.2,
  );

  // Subtitles
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // Body
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
  );

  // Buttons & Labels
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    height: 1.5,
  );

  // Salon App specific custom styles (adjust values as needed)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  static const TextStyle serviceName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const TextStyle servicePrice = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle stylistName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const TextStyle ratingText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle timeSlot = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}

// Extension for easy access from context
extension TextStyleExtension on BuildContext {
  AppTextStyle get textStyle => AppTextStyle();
}
