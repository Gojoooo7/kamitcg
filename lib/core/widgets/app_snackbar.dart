import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// SnackBars KamiTCG — fond `bg3` (assez clair pour être visible sur `bg0`),
/// bordure colorée selon le contexte, icône leading.
class AppSnackBar {
  const AppSnackBar._();

  /// SnackBar de succès — bordure dorée + check.
  static SnackBar success(String message) => _build(
        message: message,
        icon: Icons.check_circle_outline_rounded,
        accent: AppColors.gold,
      );

  /// SnackBar d'erreur — bordure rouge + icône d'alerte.
  static SnackBar error(String message) => _build(
        message: message,
        icon: Icons.error_outline_rounded,
        accent: AppColors.down,
        duration: const Duration(seconds: 3),
      );

  /// SnackBar d'info — bordure neutre claire.
  static SnackBar info(String message) => _build(
        message: message,
        icon: Icons.info_outline_rounded,
        accent: AppColors.text1,
      );

  static SnackBar _build({
    required String message,
    required IconData icon,
    required Color accent,
    Duration duration = const Duration(seconds: 2),
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.inter(
                size: 14,
                weight: FontWeight.w500,
                color: AppColors.text0,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.bg3,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withAlpha(0x99)),
      ),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      duration: duration,
      elevation: 8,
    );
  }
}
