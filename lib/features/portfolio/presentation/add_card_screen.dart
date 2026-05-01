import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/filter_chips_row.dart';
import '../../../core/widgets/icon_button_chip.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../domain/card_models.dart';
import 'portfolio_providers.dart';

/// Écran "Ajouter une carte" — browse du catalogue + variants. Tap = insert
/// dans `user_collection` puis ferme l'écran.
class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _searchCtl = TextEditingController();
  String _query = '';
  String _setFilter = Strings.filterAll;
  String _rarityFilter = Strings.filterAll;
  String? _addingVariantId;

  /// Sets disponibles dérivés du catalogue chargé (Strings.filterAll en tête).
  List<String> _availableSets(List<CatalogueEntry> entries) {
    final seen = <String>{};
    for (final e in entries) {
      seen.add(e.card.setCode);
    }
    final sorted = seen.toList()..sort();
    return [Strings.filterAll, ...sorted];
  }

  /// Raretés disponibles dérivées du catalogue chargé, triées par rareté
  /// décroissante (SEC en premier).
  List<String> _availableRarities(List<CatalogueEntry> entries) {
    final seen = <CardRarity>{};
    for (final e in entries) {
      seen.add(e.card.rarity);
    }
    final sorted = seen.toList()..sort((a, b) => b.rank.compareTo(a.rank));
    return [Strings.filterAll, for (final r in sorted) r.label];
  }

  bool _matches(CatalogueEntry e) {
    if (_query.isNotEmpty &&
        !e.card.name.toLowerCase().contains(_query) &&
        !e.card.code.toLowerCase().contains(_query)) {
      return false;
    }
    if (_setFilter != Strings.filterAll && e.card.setCode != _setFilter) {
      return false;
    }
    if (_rarityFilter != Strings.filterAll &&
        e.card.rarity.label != _rarityFilter) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _addVariant(CatalogueEntry entry) async {
    setState(() => _addingVariantId = entry.variant.id);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .addVariantToCollection(entry.variant.id);
      ref.invalidate(collectionProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.addCardAdded),
      );
      widget.onClose();
    } catch (_) {
      if (!mounted) return;
      setState(() => _addingVariantId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.addCardAddError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cataAsync = ref.watch(catalogueWithVariantsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  IconButtonChip(
                    icon: Icons.close_rounded,
                    onTap: widget.onClose,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      Strings.addCardTitle,
                      style: AppTypography.inter(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.text0,
                        letterSpacing: -0.02,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                    const Icon(Icons.search_rounded,
                        size: 18, color: AppColors.text2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtl,
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                        style: AppTypography.inter(
                          size: 14,
                          color: AppColors.text0,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: Strings.addCardSearchPlaceholder,
                          hintStyle: AppTypography.inter(
                            size: 14,
                            color: AppColors.text2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: cataAsync.when(
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
                      style: AppTypography.inter(
                        size: 13,
                        color: AppColors.down,
                      ),
                    ),
                  ),
                ),
                data: (entries) {
                  final filtered = entries.where(_matches).toList();
                  return Column(
                    children: [
                      FilterChipsRow(
                        items: _availableSets(entries),
                        value: _setFilter,
                        accent: AppColors.violet,
                        onChange: (v) => setState(() => _setFilter = v),
                      ),
                      FilterChipsRow(
                        items: _availableRarities(entries),
                        value: _rarityFilter,
                        accent: AppColors.gold,
                        onChange: (v) => setState(() => _rarityFilter = v),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    Strings.addCardEmpty,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.inter(
                                      size: 13,
                                      color: AppColors.text2,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _CatalogueRow(
                                  entry: filtered[i],
                                  isLoading: _addingVariantId ==
                                      filtered[i].variant.id,
                                  onTap: () => _addVariant(filtered[i]),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogueRow extends StatelessWidget {
  const _CatalogueRow({
    required this.entry,
    required this.isLoading,
    required this.onTap,
  });

  final CatalogueEntry entry;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = entry.toDisplay();
    final suffix = entry.variantSuffix;
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CardArtTile(card: display, width: 48, height: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: AppColors.text0,
                          ),
                        ),
                      ),
                      if (suffix.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            suffix.toUpperCase(),
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
                      Text(entry.card.code,
                          style: AppTypography.mono(size: 11)),
                      const Text(' · ',
                          style: TextStyle(color: AppColors.text3)),
                      RarityPill(rarity: entry.card.rarity),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  )
                : const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.gold,
                    size: 26,
                  ),
          ],
        ),
      ),
    );
  }
}
