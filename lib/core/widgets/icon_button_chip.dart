import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bouton-icône circulaire 36×36 (style "iconBtnStyle" du design).
class IconButtonChip extends StatelessWidget {
  const IconButtonChip({
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.dotIndicator = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool dotIndicator;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x0AFFFFFF),
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.text1),
              if (dotIndicator)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.gold, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
