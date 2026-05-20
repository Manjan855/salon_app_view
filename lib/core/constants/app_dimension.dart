// ============================================================
// 3. app_dimensions.dart
// ============================================================
import 'package:flutter/material.dart';

class AppDimensions {
  // Padding & Margin (4px base unit)
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;
  static const double paddingXXXL = 32.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 100.0;

  // Elevation / Shadow
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;
  static const double elevation8 = 8;
  static const double elevation16 = 16;

  // Icon Sizes
  static const double iconXS = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;

  // Avatar Sizes
  static const double avatarXS = 24.0;
  static const double avatarS = 32.0;
  static const double avatarM = 40.0;
  static const double avatarL = 56.0;
  static const double avatarXL = 80.0;
  static const double avatarXXL = 120.0;

  // Button Sizes
  static const double buttonMinHeight = 44.0;
  static const double buttonMaxWidth = double.infinity;
  static const double buttonBorderWidth = 1.5;

  // Input Field
  static const double inputHeight = 56.0;
  static const double inputBorderWidth = 1.0;
  static const double inputFocusBorderWidth = 2.0;

  // Divider
  static const double dividerThin = 0.5;
  static const double dividerNormal = 1.0;
  static const double dividerThick = 2.0;

  // Card
  static const double cardElevation = 2.0;
  static const double cardBorderWidth = 1.0;

  // Image
  static const double imageThumbnail = 60.0;
  static const double imageSmall = 120.0;
  static const double imageMedium = 200.0;
  static const double imageLarge = 300.0;

  // Grid & Spacing
  static const double gridSpacing = 16.0;
  static const double gridChildAspectRatio = 0.75;

  // Dialog
  static const double dialogMinWidth = 280.0;
  static const double dialogMaxWidth = 320.0;

  // Bar Sizes
  static const double appBarHeight = 56.0;
  static const double bottomNavBarHeight = 56.0;
  static const double tabBarHeight = 48.0;

  // Salon App Specific
  static const double serviceCardHeight = 120.0;
  static const double stylistCardHeight = 180.0;
  static const double timeSlotWidth = 70.0;
  static const double timeSlotHeight = 40.0;
  static const double ratingStarSize = 20.0;
}

// Responsive helper extension
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double responsiveWidth(double percent) => screenWidth * (percent / 100);
  double responsiveHeight(double percent) => screenHeight * (percent / 100);

  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;
  bool get isLargeScreen => screenWidth >= 1200;

  EdgeInsets get defaultPadding => const EdgeInsets.all(AppDimensions.paddingL);
  EdgeInsets get horizontalPadding =>
      const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL);
  EdgeInsets get verticalPadding =>
      const EdgeInsets.symmetric(vertical: AppDimensions.paddingL);
}
