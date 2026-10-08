import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light / Dark / AMOLED themes. AMOLED uses pure-black surfaces to save
/// battery on OLED screens; all three keep the emerald + gold brand.
class AppThemes {
  AppThemes._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      surface: AppColors.lightCard,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightScaffold,
        foregroundColor: AppColors.lightInk,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightCard,
        elevation: 1.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: AppColors.emerald,
        unselectedItemColor: AppColors.lightMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: AppColors.lightInk.withValues(alpha: 0.08),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.goldSoft,
      secondary: AppColors.gold,
      surface: AppColors.darkCard,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkScaffold,
        foregroundColor: AppColors.darkInk,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 1.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.goldSoft,
        unselectedItemColor: AppColors.darkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: AppColors.darkInk.withValues(alpha: 0.10),
    );
  }

  /// Pure-black variant of the dark theme for OLED battery saving.
  static ThemeData amoled() {
    final base = dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.amoledScaffold,
      cardTheme: base.cardTheme.copyWith(color: AppColors.amoledCard),
      appBarTheme:
          base.appBarTheme.copyWith(backgroundColor: AppColors.amoledScaffold),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme
          .copyWith(backgroundColor: AppColors.amoledCard),
      colorScheme:
          base.colorScheme.copyWith(surface: AppColors.amoledCard),
    );
  }
}
