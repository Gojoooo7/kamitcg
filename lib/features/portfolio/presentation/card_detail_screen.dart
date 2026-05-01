import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../../core/widgets/icon_button_chip.dart';
import '../../../core/widgets/line_chart_view.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../../../core/widgets/stat_tile.dart';
import '../domain/card_models.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({required this.card, required this.onBack, super.key});

  final TcgCard card;
  final VoidCallback onBack;

  Color get _ringColor => switch (card.rarity) {
        CardRarity.mythic => AppColors.rarityMythicRing,
        CardRarity.legendary => AppColors.rarityLegendaryRing,
        CardRarity.rare => AppColors.rarityRareRing,
        CardRarity.common => AppColors.rarityCommonRing,
      };

  @override
  Widget build(BuildContext context) {
    // Coller la action bar au-dessus de la barre système avec un mini-coussin.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double bottomOffset = safeBottom > 0 ? safeBottom + 8 : 16;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: 84 + bottomOffset),
          physics: const BouncingScrollPhysics(),
          children: [
            _Header(onBack: onBack),
            _Hero(card: card, ringColor: _ringColor),
            _Meta(card: card),
            _History(card: card),
            _Stats(card: card),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomOffset,
          child: const _ActionBar(),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          IconButtonChip(icon: Icons.chevron_left_rounded, onTap: onBack),
          const Spacer(),
          IconButtonChip(icon: Icons.ios_share_rounded, onTap: () {}),
          const SizedBox(width: 10),
          IconButtonChip(icon: Icons.more_horiz_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.card, required this.ringColor});
  final TcgCard card;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 232,
              height: 308,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(
                  colors: [
                    ringColor.withAlpha(0x33),
                    ringColor.withAlpha(0x00),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 60,
                    offset: Offset(0, 24),
                  ),
                ],
                border: Border.all(
                  color: card.foil ? ringColor : const Color(0x14FFFFFF),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CardArtTile(card: card, width: 188, height: 264),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.card});
  final TcgCard card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(card.code, style: AppTypography.mono(size: 12)),
              const Text(' · ', style: TextStyle(color: AppColors.text3)),
              Text(
                Strings.detailSetSuffix(card.set),
                style: AppTypography.inter(size: 12, color: AppColors.text2),
              ),
              const Text(' · ', style: TextStyle(color: AppColors.text3)),
              RarityPill(rarity: card.rarity),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            card.name,
            style: AppTypography.inter(
              size: 26,
              weight: FontWeight.w700,
              color: AppColors.text0,
              letterSpacing: -0.025,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Format.money(card.value),
                style: AppTypography.num(
                  size: 36,
                  weight: FontWeight.w700,
                  color: AppColors.text0,
                  letterSpacing: -0.025,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              DeltaBadge(value: card.change24, pct: card.change24),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Strings.floorCeiling(
              Format.intGrouped(card.low.round()),
              Format.intGrouped(card.high.round()),
            ),
            style: AppTypography.inter(size: 12, color: AppColors.text2),
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.card});
  final TcgCard card;

  List<double> _series() {
    final base = card.value / (1 + card.change24 / 100);
    return List.generate(14, (i) {
      final t = i / 13;
      final noise = math.sin(i * 1.4 + card.value) * (card.value * 0.04);
      return base + (card.value - base) * t + noise;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pts = _series();
    final up = card.change24 >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  Strings.priceHistoryTitle,
                  style: AppTypography.eyebrow(size: 11),
                ),
                const Spacer(),
                Text(
                  Strings.detailHigh(
                    Format.intGrouped(pts.reduce(math.max).round()),
                  ),
                  style: AppTypography.inter(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LineChartView(points: pts, up: up, height: 120, animate: false),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.card});
  final TcgCard card;

  @override
  Widget build(BuildContext context) {
    final unrealized = card.value * card.qty * 0.38;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: Strings.detailQuantity,
                  value: '× ${card.qty}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: Strings.detailHolding,
                  value: card.hold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: Strings.detailCostBasis,
                  value: Format.money(card.value * 0.62),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: Strings.detailUnrealized,
                  value: Format.money(unrealized, sign: true),
                  accent: AppColors.up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 52,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x0AFFFFFF),
                  foregroundColor: AppColors.text0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.line2),
                  ),
                ),
                child: Text(
                  Strings.detailListForSale,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.text0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gold, AppColors.goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withAlpha(0x59),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {},
                    child: Center(
                      child: Text(
                        Strings.detailTrackPrice,
                        style: AppTypography.inter(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF191100),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
