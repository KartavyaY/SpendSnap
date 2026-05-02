import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: brightness,
      primary: AppColors.orange,
      secondary: AppColors.orange,
      surface: AppColors.cream50,
      error: AppColors.danger,
    ).copyWith(
      surface: isDark ? AppColors.darkBgPrimary : AppColors.cream50,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBgPrimary : AppColors.paper,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
        ),
        headlineLarge: AppTypography.headingLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
        ),
        headlineMedium: AppTypography.headingMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.stone700,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.stone700,
        ),
        labelSmall: AppTypography.caption.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.stone500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkBgPrimary : AppColors.cream50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderHair),
        ),
        color: isDark ? AppColors.darkBgPrimary : AppColors.cream50,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.paper,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orange,
          textStyle: AppTypography.label,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: AppTypography.headingMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderHair,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cream200,
        selectedColor: AppColors.ink,
        labelStyle: AppTypography.caption,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkBgPrimary : AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.borderHair,
          ),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
        ),
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
