import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographies du design KamiTCG :
/// - **Inter** : texte général (400 → 800)
/// - **Space Grotesk** : valeurs numériques (prix, %), avec chiffres tabular
/// - **JetBrains Mono** : codes carte (KMI-014)
class AppTypography {
  const AppTypography._();

  static TextStyle inter({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text0,
    double letterSpacing = -0.005,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Pour les valeurs numériques. Active les chiffres tabular (alignement vertical).
  static TextStyle num({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.text0,
    double letterSpacing = -0.01,
    double? height,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.liningFigures(),
        ],
      );

  /// Pour les codes de carte / identifiants techniques.
  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text2,
    double letterSpacing = 0.04,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Texte en majuscules avec letter-spacing large (labels Section / Tags).
  static TextStyle eyebrow({
    double size = 11,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.text2,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.08,
      );
}
