import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../../core/widgets/filter_chips_row.dart';
import '../../../core/widgets/icon_button_chip.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../../../core/widgets/sparkline.dart';
import '../domain/card_models.dart';
import 'portfolio_providers.dart';

enum _SortKey { value, change, name, rarity }

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    required this.onCardTap,
    required this.onAddPressed,
    super.key,
  });

  final ValueChanged<String> onCardTap;
  final VoidCallback onAddPressed;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController _search = TextEditingController();
  String _setFilter = Strings.filterAll;
  String _rarityFilter = Strings.filterAll;
  _SortKey _sort = _SortKey.value;

  // Selection mode (long-press pour entrer, tap toggle, X pour sortir)
  final Set<String> _selectedIds = <String>{};
  bool _deleting = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedIds.contains(itemId)) {
        _selectedIds.remove(itemId);
      } else {
        _selectedIds.add(itemId);
      }
    });
  }

  void _exitSelection() => setState(_selectedIds.clear);

  Future<void> _confirmAndDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(
          Strings.collectionDeleteTitle,
          style: AppTypography.inter(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.text0,
          ),
        ),
        content: Text(
          Strings.collectionDeleteMessage(count),
          style: AppTypography.inter(size: 14, color: AppColors.text1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              Strings.collectionDeleteCancel,
              style: AppTypography.inter(size: 14, color: AppColors.text1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              Strings.collectionDeleteConfirm,
              style: AppTypography.inter(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.down,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .removeManyFromCollection(_selectedIds.toList());
      ref.invalidate(collectionProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.collectionDeletedSnack(count)),
      );
      setState(() {
        _selectedIds.clear();
        _deleting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.collectionDeleteError),
      );
    }
  }

  List<CollectionItem> _filtered(List<CollectionItem> items) {
    var list = [...items];
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.card.name.toLowerCase().contains(q) ||
              c.card.code.toLowerCase().contains(q))
          .toList();
    }
    if (_setFilter != Strings.filterAll) {
      list = list.where((c) => c.card.setCode == _setFilter).toList();
    }
    if (_rarityFilter != Strings.filterAll) {
      list = list.where((c) => c.card.rarity.label == _rarityFilter).toList();
    }
    list.sort((a, b) => switch (_sort) {
          _SortKey.value =>
            (b.currentPrice ?? 0).compareTo(a.currentPrice ?? 0),
          _SortKey.change =>
            (b.change24h ?? 0).compareTo(a.change24h ?? 0),
          _SortKey.name => a.card.name.compareTo(b.card.name),
          _SortKey.rarity =>
            b.card.rarity.rank.compareTo(a.card.rarity.rank),
        });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionProvider);
    return collectionAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            e.toString(),
            textAlign: TextAlign.center,
            style: AppTypography.inter(size: 13, color: AppColors.down),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _CollectionEmpty(onAdd: widget.onAddPressed);
        }
        final filtered = _filtered(items);
        final totalValue =
            filtered.fold<double>(0, (s, c) => s + (c.currentPrice ?? 0) * c.quantity);
        final sets = _availableSets(items);
        final rarities = _availableRarities(items);
        return ListView(
          padding: const EdgeInsets.only(bottom: 140),
          physics: const BouncingScrollPhysics(),
          children: [
            if (_selectionMode)
              _SelectionHeader(
                count: _selectedIds.length,
                deleting: _deleting,
                onCancel: _exitSelection,
                onDelete: _confirmAndDelete,
              )
            else
              _Header(count: filtered.length, totalValue: totalValue),
            _SearchBar(
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            FilterChipsRow(
              items: sets,
              value: _setFilter,
              accent: AppColors.violet,
              onChange: (v) => setState(() => _setFilter = v),
            ),
            FilterChipsRow(
              items: rarities,
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
              for (final item in filtered)
                _CardRow(
                  item: item,
                  selected: _selectedIds.contains(item.id),
                  selectionMode: _selectionMode,
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(item.id);
                    } else {
                      widget.onCardTap(item.id);
                    }
                  },
                  onLongPress: () => _toggleSelection(item.id),
                ),
          ],
        );
      },
    );
  }

  List<String> _availableSets(List<CollectionItem> items) {
    final seen = <String>{};
    for (final i in items) {
      seen.add(i.card.setCode);
    }
    final sorted = seen.toList()..sort();
    return [Strings.filterAll, ...sorted];
  }

  List<String> _availableRarities(List<CollectionItem> items) {
    final seen = <CardRarity>{};
    for (final i in items) {
      seen.add(i.card.rarity);
    }
    final sorted = seen.toList()..sort((a, b) => b.rank.compareTo(a.rank));
    return [Strings.filterAll, for (final r in sorted) r.label];
  }
}

class _CollectionEmpty extends StatelessWidget {
  const _CollectionEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 140),
      physics: const BouncingScrollPhysics(),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldSoft,
              border: Border.all(color: AppColors.gold.withAlpha(0x59)),
            ),
            child: const Icon(Icons.style_rounded, size: 44, color: AppColors.gold),
          ),
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
        Text(
          Strings.dashboardEmptyHint,
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            size: 14,
            color: AppColors.text2,
            height: 1.4,
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

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.count,
    required this.deleting,
    required this.onCancel,
    required this.onDelete,
  });

  final int count;
  final bool deleting;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          IconButtonChip(
            icon: Icons.close_rounded,
            onTap: deleting ? null : onCancel,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Strings.collectionSelected(count),
              style: AppTypography.inter(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.text0,
                letterSpacing: -0.02,
              ),
            ),
          ),
          deleting
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.down),
                      ),
                    ),
                  ),
                )
              : Material(
                  color: AppColors.down.withAlpha(0x1F),
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.line2),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDelete,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.down,
                      ),
                    ),
                  ),
                ),
        ],
      ),
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
                Format.money(totalValue),
                style: AppTypography.num(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.text1,
                ),
              ),
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
                  child: const Icon(Icons.close_rounded,
                      size: 12, color: AppColors.text1),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    color: sort == opts[i].$1
                        ? AppColors.text0
                        : AppColors.text2,
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
  const _CardRow({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final CollectionItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final display = item.toDisplay();
    final up = display.change24 >= 0;
    final sparkPts = up
        ? <double>[10, 11, 10, 12, 13, 12, 14, 15, 14, 16, 17, 18]
        : <double>[18, 17, 18, 16, 15, 16, 14, 13, 14, 12, 11, 10];
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(color: AppColors.line)),
          color: selected ? AppColors.goldSoft : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CardArtTile(card: display, width: 48, height: 68),
                if (selectionMode)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.gold : AppColors.bg2,
                        border: Border.all(
                          color: selected ? AppColors.gold : AppColors.line2,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Color(0xFF191100),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          display.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: AppColors.text0,
                          ),
                        ),
                      ),
                      if (display.foil) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
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
                      Text(display.code, style: AppTypography.mono(size: 11)),
                      const Text(' · ',
                          style: TextStyle(color: AppColors.text3)),
                      Text(
                        '×${display.qty}',
                        style: AppTypography.inter(
                          size: 11,
                          color: AppColors.text2,
                        ),
                      ),
                      const Text(' · ',
                          style: TextStyle(color: AppColors.text3)),
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
                Sparkline(points: sparkPts, up: up, width: 50, height: 18),
                const SizedBox(height: 4),
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
    );
  }
}
