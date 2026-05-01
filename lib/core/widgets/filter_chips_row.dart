import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Rangée de chips de filtre — utilisée dans la Collection et l'AddCardScreen.
///
/// L'`accent` détermine la couleur de fond/bordure de l'item actif.
/// Conventionnellement : violet pour les sets, doré pour les raretés.
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    required this.items,
    required this.value,
    required this.onChange,
    required this.accent,
    super.key,
  });

  final List<String> items;
  final String value;
  final ValueChanged<String> onChange;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          final active = it == value;
          final accentSoft = accent == AppColors.violet
              ? AppColors.violetSoft
              : AppColors.goldSoft;
          return GestureDetector(
            onTap: () => onChange(it),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? accentSoft : const Color(0x08FFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? accent.withAlpha(0x73) : AppColors.line,
                ),
              ),
              child: Text(
                it,
                style: AppTypography.inter(
                  size: 12,
                  weight: FontWeight.w600,
                  color: active ? accent : AppColors.text1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
