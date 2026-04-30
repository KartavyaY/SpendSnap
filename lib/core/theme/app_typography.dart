import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const _family = 'Inter';

  static const displayLarge = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const headingLarge = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const headingMedium = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const numeric = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
