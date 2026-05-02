import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../../core/widgets/icon_button_chip.dart';
import '../../../core/widgets/line_chart_view.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/card_models.dart';
import 'portfolio_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    required this.onCardTap,
    required this.onAddPressed,
    required this.onSeeAllPressed,
    super.key,
  });

  final ValueChanged<String> onCardTap;
  final VoidCallback onAddPressed;
  final VoidCallback onSeeAllPressed;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _range = '1S';

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);

    return collectionAsync.when(
      loading: () => const _CenteredSpinner(),
      error: (e, _) => _ErrorBlock(message: e.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(onAdd: widget.onAddPressed);
        }
        return _DashboardContent(
          items: items,
          range: _range,
          onRangeChange: (r) => setState(() => _range = r),
          onCardTap: widget.onCardTap,
          onSeeAllPressed: widget.onSeeAllPressed,
        );
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.items,
    required this.range,
    required this.onRangeChange,
    required this.onCardTap,
    required this.onSeeAllPressed,
  });

  final List<CollectionItem> items;
  final String range;
  final ValueChanged<String> onRangeChange;
  final ValueChanged<String> onCardTap;
  final VoidCallback onSeeAllPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(portfolioStatsProvider).value ??
        PortfolioStats.empty;
    final chartAsync = ref.watch(portfolioChartProvider(range));

    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      physics: const BouncingScrollPhysics(),
      children: [
        const _GreetingRow(),
        _BalanceBlock(
          total: stats.totalValue,
          delta: stats.delta24h,
          deltaPct: stats.deltaPct24h,
        ),
        _ChartBlock(
          range: range,
          chartAsync: chartAsync,
          onRangeChange: onRangeChange,
        ),
        const SizedBox(height: 4),
        _StatsRow(stats: stats),
        _TopPerformers(
          items: items,
          onCardTap: onCardTap,
          onSeeAllPressed: onSeeAllPressed,
        ),
        const _MarketPulseRow(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Empty / loading / error states
// ─────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 140),
      physics: const BouncingScrollPhysics(),
      children: [
        const _GreetingRow(),
        const SizedBox(height: 80),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldSoft,
            border: Border.all(color: AppColors.gold.withAlpha(0x59)),
          ),
          child: const Icon(Icons.style_rounded, size: 44, color: AppColors.gold),
        ),
        const SizedBox(height: 24),
        Text(
          Strings.dashboardEmptyTitle,
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            size: 20,
            weight: FontWeight.w700,
            color: AppColors.text0,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            Strings.dashboardEmptyHint,
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              size: 14,
              color: AppColors.text2,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            height: 52,
            width: 240,
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
                  onTap: onAdd,
                  child: Center(
                    child: Text(
                      Strings.dashboardEmptyCta,
                      style: AppTypography.inter(
                        size: 15,
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
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.gold),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.inter(size: 13, color: AppColors.down),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sections
// ─────────────────────────────────────────────────────────────────────────

class _GreetingRow extends ConsumerWidget {
  const _GreetingRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider);
    final initials = _initialsFrom(email);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.welcomeBack,
                  style: AppTypography.inter(
                    size: 13,
                    color: AppColors.text2,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? Strings.userDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    size: 15,
                    color: AppColors.text1,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButtonChip(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            dotIndicator: true,
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A2BE2), Color(0xFF5B1AA3)],
              ),
              border: Border.all(color: const Color(0x29FFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withAlpha(0x73),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTypography.num(
                size: 14,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initialsFrom(String? email) {
  if (email == null || email.isEmpty) return 'NK';
  final letter = email.runes.first;
  return String.fromCharCode(letter).toUpperCase();
}

class _BalanceBlock extends StatelessWidget {
  const _BalanceBlock({
    required this.total,
    required this.delta,
    required this.deltaPct,
  });

  final double total;
  final double delta;
  final double deltaPct;

  @override
  Widget build(BuildContext context) {
    final intPart = Format.intGrouped(total.floor());
    final cents = (total - total.floor()).toStringAsFixed(2).substring(2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.portfolioValueLabel,
            style: AppTypography.eyebrow(size: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '€',
                style: AppTypography.num(
                  size: 46,
                  weight: FontWeight.w700,
                  color: AppColors.text2,
                  letterSpacing: -0.03,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                intPart,
                style: AppTypography.num(
                  size: 46,
                  weight: FontWeight.w700,
                  color: AppColors.text0,
                  letterSpacing: -0.03,
                  height: 1,
                ),
              ),
              Text(
                '.$cents',
                style: AppTypography.num(
                  size: 26,
                  weight: FontWeight.w600,
                  color: AppColors.text2,
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              DeltaBadge(value: delta, pct: deltaPct, size: DeltaBadgeSize.lg),
              const SizedBox(width: 10),
              Text(
                Strings.last24h,
                style: AppTypography.inter(
                  size: 12,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartBlock extends StatelessWidget {
  const _ChartBlock({
    required this.range,
    required this.chartAsync,
    required this.onRangeChange,
  });

  final String range;
  final AsyncValue<List<double>> chartAsync;
  final ValueChanged<String> onRangeChange;

  static List<String> get _tabs => Strings.rangeTabs;

  @override
  Widget build(BuildContext context) {
    final points = chartAsync.value ?? const <double>[];
    final hasChart = points.length >= 2;
    final up = hasChart ? points.last >= points.first : true;
    final hi = hasChart ? (points.length * 0.66).floor().clamp(0, points.length - 1) : 0;
    final hoverPrice = hasChart ? points[hi] : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: hasChart
              ? Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 0,
                      child: LineChartView(points: points, up: up),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 6,
                      child: Align(
                        alignment: const Alignment(0.2, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xDB141418),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.line2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Strings.hoverLabelFor(range).toUpperCase(),
                                style: AppTypography.eyebrow(size: 9.5),
                              ),
                              Text(
                                '€${Format.intGrouped(hoverPrice.round())}',
                                style: AppTypography.num(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: AppColors.text0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: chartAsync.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        )
                      : Text(
                          Strings.dashboardChartEmpty,
                          style: AppTypography.inter(
                            size: 12,
                            color: AppColors.text2,
                          ),
                        ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                for (final t in _tabs)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onRangeChange(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t == range
                              ? AppColors.gold.withAlpha(0x1A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t,
                          style: AppTypography.num(
                            size: 12,
                            weight: FontWeight.w600,
                            color: t == range ? AppColors.gold : AppColors.text2,
                            letterSpacing: 0.04,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final PortfolioStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      // IntrinsicHeight + hint partout pour que les 3 tuiles aient la même
      // hauteur (sinon "Variation" sans hint est plus courte).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatTile(
                label: Strings.statCards,
                value: '${stats.cardCount}',
                hint: Strings.statCardsHintWithCount(stats.uniqueSets),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: Strings.statSecretRare,
                value: '${stats.secretRareCount}',
                hint: Strings.statSecretRareHint,
                accent: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: Strings.statAllTime,
                value: Format.pct(stats.deltaPct24h),
                hint: Strings.statAllTimeHint,
                accent: stats.deltaPct24h >= 0 ? AppColors.up : AppColors.down,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPerformers extends StatelessWidget {
  const _TopPerformers({
    required this.items,
    required this.onCardTap,
    required this.onSeeAllPressed,
  });

  final List<CollectionItem> items;
  final ValueChanged<String> onCardTap;
  final VoidCallback onSeeAllPressed;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) => (b.change24h ?? 0).compareTo(a.change24h ?? 0));
    final top = sorted.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.bolt_rounded,
                    size: 13, color: AppColors.gold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Strings.topPerformersTitle,
                  style: AppTypography.inter(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.text0,
                  ),
                ),
              ),
              InkWell(
                onTap: onSeeAllPressed,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Strings.seeAll,
                        style: AppTypography.inter(
                          size: 12,
                          color: AppColors.text2,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 14, color: AppColors.text2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in top) ...[
            _TopPerformerRow(
              item: c,
              onTap: () => onCardTap(c.id),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TopPerformerRow extends StatelessWidget {
  const _TopPerformerRow({required this.item, required this.onTap});

  final CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = item.toDisplay();
    return Material(
      color: const Color(0x06FFFFFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
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
                      display.name,
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
                        Text(display.code, style: AppTypography.mono(size: 11)),
                        const Text(' · ', style: TextStyle(color: AppColors.text3)),
                        RarityPill(rarity: display.rarity),
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
                    Format.money(display.value),
                    style: AppTypography.num(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.text0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DeltaBadge(
                    value: display.change24,
                    pct: display.change24,
                    size: DeltaBadgeSize.sm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketPulseRow extends StatelessWidget {
  const _MarketPulseRow();

  // V1 : valeurs statiques (placeholder). Sera remplacé par des aggregates SQL
  // en V2 (ex : indice par set, top movers par rareté).
  static const _items = [
    (label: Strings.marketPulseMythicIndex, val: '+4,2 %', up: true, spark: <double>[10, 12, 11, 14, 13, 15, 17, 16, 19, 21]),
    (label: Strings.marketPulseAuroraSet, val: '+1,8 %', up: true, spark: <double>[10, 11, 10, 12, 11, 13, 14, 12, 15, 15]),
    (label: Strings.marketPulseEmbergate, val: '−0,7 %', up: false, spark: <double>[12, 13, 14, 12, 11, 12, 11, 10, 11, 10]),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              Strings.marketPulseTitle,
              style: AppTypography.inter(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.text0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 20),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final it = _items[i];
                return Container(
                  width: 148,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x06FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.label,
                        style: AppTypography.inter(
                          size: 11,
                          color: AppColors.text2,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            it.val,
                            style: AppTypography.num(
                              size: 16,
                              weight: FontWeight.w700,
                              color: it.up ? AppColors.up : AppColors.down,
                            ),
                          ),
                          Sparkline(
                            points: it.spark,
                            up: it.up,
                            width: 56,
                            height: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
