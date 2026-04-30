import 'package:flutter/material.dart';

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
import '../data/mock_portfolio.dart';
import '../domain/card_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.onCardTap, super.key});

  final ValueChanged<TcgCard> onCardTap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _range = '1W';

  @override
  Widget build(BuildContext context) {
    final points = MockPortfolio.chartSeries[_range]!;
    final up = points.last >= points.first;

    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      physics: const BouncingScrollPhysics(),
      children: [
        const _GreetingRow(),
        const _BalanceBlock(
          total: MockPortfolio.total,
          delta: MockPortfolio.delta,
          deltaPct: MockPortfolio.deltaPct,
        ),
        _ChartBlock(
          range: _range,
          points: points,
          up: up,
          onRangeChange: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: 4),
        const _StatsRow(),
        _TopPerformers(
          cards: MockPortfolio.cards,
          onCardTap: widget.onCardTap,
        ),
        const _MarketPulseRow(),
      ],
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: AppTypography.inter(
                    size: 13,
                    color: AppColors.text2,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nakama',
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
              'NK',
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
            'PORTFOLIO VALUE',
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
                'last 24h',
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
    required this.points,
    required this.up,
    required this.onRangeChange,
  });

  final String range;
  final List<double> points;
  final bool up;
  final ValueChanged<String> onRangeChange;

  static const _tabs = ['1D', '1W', '1M', '1Y', 'ALL'];

  String get _hoverLabel => switch (range) {
        '1D' => '14:00',
        '1W' => 'Wed',
        '1M' => 'Apr 14',
        _ => 'Aug 25',
      };

  @override
  Widget build(BuildContext context) {
    final hi = (points.length * 0.66).floor().clamp(0, points.length - 1);
    final hoverPrice = points[hi];
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          _hoverLabel.toUpperCase(),
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
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(child: StatTile(label: 'Cards', value: '38', hint: '6 sets')),
          SizedBox(width: 10),
          Expanded(
            child: StatTile(
              label: 'Mythics',
              value: '3',
              hint: 'rarest tier',
              accent: AppColors.gold,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatTile(
              label: 'All-time',
              value: '+187%',
              accent: AppColors.up,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPerformers extends StatelessWidget {
  const _TopPerformers({required this.cards, required this.onCardTap});

  final List<TcgCard> cards;
  final ValueChanged<TcgCard> onCardTap;

  @override
  Widget build(BuildContext context) {
    final top = [...cards]..sort((a, b) => b.change24.compareTo(a.change24));
    final topThree = top.take(3).toList();
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
                child: const Icon(Icons.bolt_rounded, size: 13, color: AppColors.gold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top performers · 24h',
                  style: AppTypography.inter(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.text0,
                  ),
                ),
              ),
              Text(
                'See all',
                style: AppTypography.inter(
                  size: 12,
                  color: AppColors.text2,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.text2),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in topThree) ...[
            _TopPerformerRow(card: c, onTap: () => onCardTap(c)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TopPerformerRow extends StatelessWidget {
  const _TopPerformerRow({required this.card, required this.onTap});

  final TcgCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              CardArtTile(card: card, width: 42, height: 60),
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
                        Text(
                          card.code,
                          style: AppTypography.mono(size: 11),
                        ),
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
                    Format.money(card.value),
                    style: AppTypography.num(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.text0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DeltaBadge(
                    value: card.change24,
                    pct: card.change24,
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

  static const _items = [
    (label: 'Mythic Index', val: '+4.2%', up: true, spark: <double>[10, 12, 11, 14, 13, 15, 17, 16, 19, 21]),
    (label: 'Aurora Set', val: '+1.8%', up: true, spark: <double>[10, 11, 10, 12, 11, 13, 14, 12, 15, 15]),
    (label: 'Embergate', val: '−0.7%', up: false, spark: <double>[12, 13, 14, 12, 11, 12, 11, 10, 11, 10]),
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
              'Market pulse',
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
