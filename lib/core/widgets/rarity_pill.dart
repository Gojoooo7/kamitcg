import 'package:flutter/material.dart';

import '../../features/portfolio/domain/card_models.dart';
import '../theme/app_colors.dart';

/// Pill rectangulaire montrant la rareté avec un point de couleur.
class RarityPill extends StatelessWidget {
  const RarityPill({required this.rarity, this.large = false, super.key});

  final CardRarity rarity;
  final bool large;

  static ({Color ring, Color text}) _palette(CardRarity r) => switch (r) {
        CardRarity.mythic =>
          (ring: AppColors.rarityMythicRing, text: AppColors.rarityMythicText),
        CardRarity.legendary => (
            ring: AppColors.rarityLegendaryRing,
            text: AppColors.rarityLegendaryText
          ),
        CardRarity.rare =>
          (ring: AppColors.rarityRareRing, text: AppColors.rarityRareText),
        CardRarity.common =>
          (ring: AppColors.rarityCommonRing, text: AppColors.rarityCommonText),
      };

  @override
  Widget build(BuildContext context) {
    final c = _palette(rarity);
    final padX = large ? 10.0 : 7.0;
    final padY = large ? 4.0 : 2.0;
    final fontSize = large ? 11.0 : 10.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.ring.withAlpha(0x33)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: c.ring, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            rarity.label.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: c.text,
              letterSpacing: 0.06 * fontSize / 10,
            ),
          ),
        ],
      ),
    );
  }
}
