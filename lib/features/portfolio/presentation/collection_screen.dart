import 'package:flutter/material.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../../core/widgets/icon_button_chip.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../../../core/widgets/sparkline.dart';
import '../data/mock_portfolio.dart';
import '../domain/card_models.dart';

enum _SortKey { value, change, name, rarity }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({required this.onCardTap, super.key});

  final ValueChanged<TcgCard> onCardTap;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final TextEditingController _search = TextEditingController();
  String _setFilter = Strings.filterAll;
  String _rarityFilter = Strings.filterAll;
  _SortKey _sort = _SortKey.value;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<TcgCard> get _filtered {
    var list = [...MockPortfolio.cards];
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.code.toLowerCase().contains(q))
          .toList();
    }
    if (_setFilter != Strings.filterAll) {
      list = list.where((c) => c.set == _setFilter).toList();
    }
    if (_rarityFilter != Strings.filterAll) {
      list = list.where((c) => c.rarity.label == _rarityFilter).toList();
    }
    list.sort((a, b) => switch (_sort) {
          _SortKey.value => b.value.compareTo(a.value),
          _SortKey.change => b.change24.compareTo(a.change24),
          _SortKey.name => a.name.compareTo(b.name),
          _SortKey.rarity => b.rarity.rank.compareTo(a.rarity.rank),
        });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalValue =
        filtered.fold<double>(0, (s, c) => s + c.value * c.qty);
    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      physics: const BouncingScrollPhysics(),
      children: [
        _Header(count: filtered.length, totalValue: totalValue),
        _SearchBar(
          controller: _search,
          onChanged: (_) => setState(() {}),
        ),
        _ChipsRow(
          items: MockPortfolio.sets,
          value: _setFilter,
          accent: AppColors.violet,
          onChange: (v) => setState(() => _setFilter = v),
        ),
        _ChipsRow(
          items: MockPortfolio.rarities,
          value: _rarityFilter,
          accent: AppColors.gold,
          onChange: (v) => setState(() => _rarityFilter = v),
        ),
        _SortBar(
          sort: _sort,
          onChange: (s) => setState(() => _sort = s),
        ),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 60, 24, 0),
            child: Text(
              Strings.collectionEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text2, fontSize: 13),
            ),
          )
        else
          for (var i = 0; i < filtered.length; i++)
            _CardRow(
              card: filtered[i],
              onTap: () => widget.onCardTap(filtered[i]),
            ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.totalValue});

  final int count;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Strings.collectionTitle,
                  style: AppTypography.inter(
                    size: 26,
                    weight: FontWeight.w700,
                    color: AppColors.text0,
                    letterSpacing: -0.025,
                  ),
                ),
              ),
              IconButtonChip(icon: Icons.more_horiz_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                Strings.collectionCount(count),
                style: AppTypography.inter(size: 12, color: AppColors.text2),
              ),
              const Text(' · ', style: TextStyle(color: AppColors.text3)),
              Text(
                '€${Format.intGrouped(totalValue.round())}.${(totalValue - totalValue.floor()).toStringAsFixed(2).substring(2)}',
                style: AppTypography.num(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.text1,
                ),
              ),
              const Text(' · ', style: TextStyle(color: AppColors.text3)),
              const DeltaBadge(value: 2.4, pct: 2.4, size: DeltaBadgeSize.sm),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: AppColors.text2),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AppTypography.inter(size: 14, color: AppColors.text0),
                decoration: InputDecoration.collapsed(
                  hintText: Strings.collectionSearchPlaceholder,
                  hintStyle: AppTypography.inter(
                    size: 14,
                    color: AppColors.text2,
                  ),
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0x14FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.close_rounded, size: 12, color: AppColors.text1),
                ),
              ),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: AppColors.line),
            const SizedBox(width: 10),
            const Icon(Icons.tune_rounded, size: 16, color: AppColors.text1),
          ],
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.items,
    required this.value,
    required this.onChange,
    required this.accent,
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
          final accentSoft =
              accent == AppColors.violet ? AppColors.violetSoft : AppColors.goldSoft;
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

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onChange});

  final _SortKey sort;
  final ValueChanged<_SortKey> onChange;

  @override
  Widget build(BuildContext context) {
    final opts = <(_SortKey, String)>[
      (_SortKey.value, Strings.sortValue),
      (_SortKey.change, Strings.sort24h),
      (_SortKey.name, Strings.sortName),
      (_SortKey.rarity, Strings.sortRarity),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Text(Strings.sortLabel, style: AppTypography.eyebrow(size: 11)),
          const Spacer(),
          for (var i = 0; i < opts.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            GestureDetector(
              onTap: () => onChange(opts[i].$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sort == opts[i].$1
                      ? const Color(0x12FFFFFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sort == opts[i].$1
                        ? AppColors.line2
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  opts[i].$2,
                  style: AppTypography.inter(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: sort == opts[i].$1 ? AppColors.text0 : AppColors.text2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.onTap});

  final TcgCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final up = card.change24 >= 0;
    final sparkPts = up
        ? <double>[10, 11, 10, 12, 13, 12, 14, 15, 14, 16, 17, 18]
        : <double>[18, 17, 18, 16, 15, 16, 14, 13, 14, 12, 11, 10];
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CardArtTile(card: card, width: 48, height: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: AppColors.text0,
                          ),
                        ),
                      ),
                      if (card.foil) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            Strings.foilTag,
                            style: AppTypography.inter(
                              size: 9,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                              letterSpacing: 0.06,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(card.code, style: AppTypography.mono(size: 11)),
                      const Text(' · ', style: TextStyle(color: AppColors.text3)),
                      Text(
                        '×${card.qty}',
                        style: AppTypography.inter(
                          size: 11,
                          color: AppColors.text2,
                        ),
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
                Sparkline(points: sparkPts, up: up, width: 50, height: 18),
                const SizedBox(height: 4),
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
    );
  }
}
