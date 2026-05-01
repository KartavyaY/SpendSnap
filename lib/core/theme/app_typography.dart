import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayXl => GoogleFonts.instrumentSerif(
    fontSize: 56, fontWeight: FontWeight.w400,
    color: AppColors.ink, letterSpacing: -1.12, height: 1.0,
  );
  static TextStyle get displayL => GoogleFonts.instrumentSerif(
    fontSize: 40, fontWeight: FontWeight.w400,
    color: AppColors.ink, letterSpacing: -0.8, height: 1.05,
  );
  static TextStyle get displayM => GoogleFonts.instrumentSerif(
    fontSize: 32, fontWeight: FontWeight.w400,
    color: AppColors.ink, letterSpacing: -0.64, height: 1.1,
  );
  static TextStyle get headingLarge => GoogleFonts.instrumentSerif(
    fontSize: 24, fontWeight: FontWeight.w400,
    color: AppColors.ink, letterSpacing: -0.48, height: 1.2,
  );
  static const TextStyle headingMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.ink, letterSpacing: -0.16, height: 1.3,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.stone700, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.stone700, height: 1.45,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.stone600, height: 1.45,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.stone600, height: 1.4,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.stone600, letterSpacing: 1.32, height: 1.2,
    fontFamily: null,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.ink, letterSpacing: -0.13,
  );
  static const TextStyle numeric = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.ink, letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Legacy aliases for backward compatibility
  static TextStyle get displayLarge => displayM;

  static TextStyle moneyDisplay(double size, {Color? color}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size, fontWeight: FontWeight.w500,
      color: color ?? AppColors.ink,
      letterSpacing: size * -0.02,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  static TextStyle get moneyBody => GoogleFonts.jetBrainsMono(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.ink, letterSpacing: -0.3,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle get moneySmall => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.stone600, letterSpacing: -0.26,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
