import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand core
  static const Color ink        = Color(0xFF1B1B1B);
  static const Color paper      = Color(0xFFFAF7F2);
  static const Color orange     = Color(0xFFFF5C2B);
  static const Color orangeDeep = Color(0xFFE64516);

  // Neutrals (warm, paper-tinted)
  static const Color cream50  = Color(0xFFFDFBF7);
  static const Color cream100 = Color(0xFFFAF7F2);
  static const Color cream200 = Color(0xFFF2EDE3);
  static const Color cream300 = Color(0xFFE8E3DA);
  static const Color cream400 = Color(0xFFD4CEC2);
  static const Color stone500 = Color(0xFF8A857C);
  static const Color stone600 = Color(0xFF5C5852);
  static const Color stone700 = Color(0xFF3A3833);
  static const Color stone800 = Color(0xFF242320);

  // Semantic
  static const Color success   = Color(0xFF1F7A4D);
  static const Color successBg = Color(0xFFDDEFE2);
  static const Color warn      = Color(0xFFC97A0E);
  static const Color warnBg    = Color(0xFFF8E9CC);
  static const Color danger    = Color(0xFFB23A1F);
  static const Color dangerBg  = Color(0xFFF5D9CF);
  static const Color info      = Color(0xFF2A4D7A);
  static const Color infoBg    = Color(0xFFDCE5F0);

  // Category colors
  static const Color catFood    = Color(0xFFFF5C2B);
  static const Color catTransit = Color(0xFF2A4D7A);
  static const Color catCoffee  = Color(0xFF8B4513);
  static const Color catRent    = Color(0xFF1B1B1B);
  static const Color catFun     = Color(0xFFC97A0E);
  static const Color catHealth  = Color(0xFF1F7A4D);
  static const Color catShop    = Color(0xFFB23A1F);
  static const Color catBills   = Color(0xFF5C5852);

  // Borders
  static const Color borderHair = Color(0x141B1B1B);
  static const Color borderSoft = Color(0x241B1B1B);

  // Aliases for backward compat
  static const Color primary       = orange;
  static const Color primaryLight  = orangeDeep;
  static const Color accent        = orange;
  static const Color bgPrimary     = paper;
  static const Color surface       = cream50;
  static const Color border        = borderHair;
  static const Color textPrimary   = ink;
  static const Color textSecondary = stone600;
  static const Color textTertiary  = stone500;

  // Dark mode
  static const Color darkBgPrimary   = Color(0xFF1A1916);
  static const Color darkTextPrimary = paper;
}
