import 'package:flutter/material.dart';

/// SmartBank AI Design System
/// Extracted from Stitch designs
class AppColors {
  // Primary Colors
  static const background = Color(0xFF0A1628);
  static const surface = Color(0xFF162639);
  static const surfaceDark = Color(0xFF0D1B2D);
  static const primary = Color(0xFFFFC700);
  static const primaryDark = Color(0xFFB38F00);
  
  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B9AAD);
  static const textTertiary = Color(0xFF5A6B7F);
  
  // Semantic Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC700);
  static const error = Color(0xFFFF5252);
  static const info = Color(0xFF2196F3);
  
  // Accent Colors
  static const accentBlue = Color(0xFF1E3A5F);
  static const accentGold = Color(0xFFFFD54F);
  
  // Chart Colors
  static const chartGreen = Color(0xFF7CB342);
  static const chartYellow = Color(0xFFFFC700);
  static const chartRed = Color(0xFFFF5252);
  static const chartGray = Color(0xFF546E7A);
}

class AppTypography {
  static const fontFamily = 'Inter'; // or 'SF Pro Display' for iOS look
  
  // Display
  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );
  
  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // Headline
  static const headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  // Label
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );
  
  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );
}

class AppSizes {
  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
  static const paddingXLarge = 32.0;
  
  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;
  static const radiusXLarge = 20.0;
}
