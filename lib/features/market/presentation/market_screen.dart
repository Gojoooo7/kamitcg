import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../domain/market_models.dart';
import 'market_providers.dart';

/// Écran Marché — agrégats sur tout le catalogue (pas seulement la collection).
/// Top movers 24 h, indices par set, cartes les plus chères.
class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          Strings.marketTitle,
          style: AppTypography.inter(
            size: 26,
            weight: FontWeight.w700,
            color: AppColors.text0,
            letterSpacing: -0.025,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Strings.marketSyntheticDisclaimer,
          style: AppTypography.inter(size: 11, color: AppColors.text2),
        ),
        const SizedBox(height: 24),
        const _MoverList(direction: _MoverDirection.up),
        const SizedBox(height: 24),
        const _MoverList(direction: _MoverDirection.down),
        const SizedBox(height: 24),
        const _IndicesGrid(),
        const SizedBox(height: 24),
        const _ExpensiveList(),
      ],
    );
  }
}

enum _MoverDirection { up, down }

class _MoverList extends ConsumerWidget {
  const _MoverList({required this.direction});
  final _MoverDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = direction == _MoverDirection.up
        ? ref.watch(marketTopGainersProvider)
        : ref.watch(marketTopLosersProvider);
    final title = direction == _MoverDirection.up
        ? Strings.marketTopGainers
        : Strings.marketTopLosers;
    final isUp = direction == _MoverDirection.up;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: title, isUp: isUp),
        const SizedBox(height: 10),
        async.when(
          loading: () => const _LoadingTile(),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (cards) {
            if (cards.isEmpty) return const _EmptyTile();
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  _MarketRow(card: cards[i]),
                  if (i < cards.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.card});
  final MarketCard card;

  @override
  Widget build(BuildContext context) {
    final display = card.toDisplay();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x06FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CardArtTile(card: display, width: 42, height: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.text0,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(card.code, style: AppTypography.mono(size: 11)),
                    const Text(' · ', style: TextStyle(color: AppColors.text3)),
                    RarityPill(rarity: card.rarity),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Format.money(card.currentPrice),
                style: AppTypography.num(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.text0,
                ),
              ),
              if (card.changePct != null) ...[
                const SizedBox(height: 4),
                DeltaBadge(
                  value: card.changePct!,
                  pct: card.changePct,
                  size: DeltaBadgeSize.sm,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IndicesGrid extends ConsumerWidget {
  const _IndicesGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketSetIndicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: Strings.marketIndices),
        const SizedBox(height: 10),
        async.when(
          loading: () => const _LoadingTile(),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (indices) {
            if (indices.isEmpty) return const _EmptyTile();
            // Tri : meilleurs en haut.
            final sorted = [...indices]
              ..sort((a, b) => b.avgChangePct.compareTo(a.avgChangePct));
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final ix in sorted) _IndexChip(index: ix),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IndexChip extends StatelessWidget {
  const _IndexChip({required this.index});
  final MarketSetIndex index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x06FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.setCode,
            style: AppTypography.inter(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.text0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${index.variantCount} variants',
            style: AppTypography.inter(size: 10.5, color: AppColors.text2),
          ),
          const SizedBox(height: 8),
          DeltaBadge(
            value: index.avgChangePct,
            pct: index.avgChangePct,
            size: DeltaBadgeSize.sm,
          ),
          const SizedBox(height: 6),
          Text(
            'Moy. ${Format.money(index.avgPrice)}',
            style: AppTypography.num(
              size: 11,
              weight: FontWeight.w500,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensiveList extends ConsumerWidget {
  const _ExpensiveList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketTopExpensiveProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          label: Strings.marketTopExpensive,
          accent: AppColors.gold,
        ),
        const SizedBox(height: 10),
        async.when(
          loading: () => const _LoadingTile(),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (cards) {
            if (cards.isEmpty) return const _EmptyTile();
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  _MarketRow(card: cards[i]),
                  if (i < cards.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.accent, this.isUp});
  final String label;
  final Color? accent;
  final bool? isUp;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (isUp == true) {
      leading = const Icon(Icons.trending_up_rounded,
          size: 14, color: AppColors.up);
    } else if (isUp == false) {
      leading = const Icon(Icons.trending_down_rounded,
          size: 14, color: AppColors.down);
    } else if (accent != null) {
      leading = Icon(Icons.workspace_premium_rounded, size: 14, color: accent);
    } else {
      leading = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          leading,
          if (leading is! SizedBox) const SizedBox(width: 6),
          Text(label, style: AppTypography.eyebrow(size: 11)),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: AppTypography.inter(size: 12, color: AppColors.down),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        Strings.marketEmpty,
        style: AppTypography.inter(size: 12, color: AppColors.text2),
      ),
    );
  }
}
