import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Thème global de l'app — dark mode profond avec accent doré.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text0,
      displayColor: AppColors.text0,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg0,
      canvasColor: AppColors.bg0,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bg0,
        primary: AppColors.gold,
        onPrimary: Color(0xFF191100),
        secondary: AppColors.violet,
        onSecondary: Colors.white,
        error: AppColors.down,
        onError: Colors.white,
        outline: AppColors.line2,
      ),
      iconTheme: const IconThemeData(color: AppColors.text1, size: 22),
      dividerColor: AppColors.line,
      splashColor: const Color(0x14D4AF37),
      highlightColor: const Color(0x0AD4AF37),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.bg0,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}
