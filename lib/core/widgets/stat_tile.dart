import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tuile statistique réutilisée sur le Dashboard et la fiche carte.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.hint,
    this.accent,
    super.key,
  });

  final String label;
  final String value;
  final String? hint;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x06FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow(size: 10.5),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.num(
              size: 18,
              weight: FontWeight.w700,
              color: accent ?? AppColors.text0,
              letterSpacing: -0.02,
              height: 1,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: AppTypography.inter(
                size: 11,
                color: AppColors.text2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
