import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../../core/widgets/icon_button_chip.dart';
import '../../../core/widgets/line_chart_view.dart';
import '../../../core/widgets/rarity_pill.dart';
import '../../../core/widgets/stat_tile.dart';
import '../domain/card_models.dart';
import '../domain/price_alert.dart';
import 'portfolio_providers.dart';
import 'price_alert_sheet.dart';

/// Fiche carte d'une ligne de la collection. Watch live `collectionProvider`
/// pour refléter les éditions (quantité, prix d'achat) en temps réel et
/// auto-fermer si la ligne est supprimée.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    required this.collectionItemId,
    required this.onBack,
    super.key,
  });

  final String collectionItemId;
  final VoidCallback onBack;

  Color _ringColor(CardRarity rarity) => switch (rarity) {
        CardRarity.secretRare => AppColors.raritySecretRareRing,
        CardRarity.specialAlt => AppColors.raritySpecialAltRing,
        CardRarity.treasureRare => AppColors.rarityTreasureRareRing,
        CardRarity.superRare => AppColors.raritySuperRareRing,
        CardRarity.leader => AppColors.rarityLeaderRing,
        CardRarity.rare => AppColors.rarityRareRing,
        CardRarity.uncommon => AppColors.rarityUncommonRing,
        CardRarity.common => AppColors.rarityCommonRing,
        CardRarity.don => AppColors.rarityDonRing,
        CardRarity.promo => AppColors.rarityPromoRing,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);
    final item = collectionAsync.value
        ?.where((it) => it.id == collectionItemId)
        .firstOrNull;

    // Item supprimé / introuvable → ferme la fiche au prochain frame.
    if (collectionAsync.hasValue && item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onBack());
      return const SizedBox.shrink();
    }
    if (item == null) {
      return const _LoadingDetail();
    }

    final ring = _ringColor(item.card.rarity);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: 96 + safeBottom),
          physics: const BouncingScrollPhysics(),
          children: [
            _Header(onBack: onBack),
            _Hero(item: item, ringColor: ring),
            _Meta(item: item),
            _History(item: item),
            _Stats(item: item),
            const SizedBox(height: 16),
            _PositionEditor(item: item),
            const SizedBox(height: 24),
            _AlertsSection(item: item),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Section "ALERTES DE PRIX"
// ─────────────────────────────────────────────────────────────────────────
class _AlertsSection extends ConsumerWidget {
  const _AlertsSection({required this.item});
  final CollectionItem item;

  void _openSheet(BuildContext context) {
    PriceAlertSheet.show(
      context,
      card: item.card,
      variant: item.variant,
      currentPrice: item.currentPrice ?? 0,
    );
  }

  Future<void> _delete(WidgetRef ref, PriceAlert alert) async {
    await ref.read(priceAlertsRepositoryProvider).deleteAlert(alert.id);
    ref.invalidate(priceAlertsForVariantProvider(item.variant.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(priceAlertsForVariantProvider(item.variant.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              Strings.alertsSectionTitle,
              style: AppTypography.eyebrow(size: 11),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x06FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                alertsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                    ),
                  ),
                  error: (_, _) => Text(
                    Strings.alertsError,
                    style: AppTypography.inter(
                      size: 13,
                      color: AppColors.down,
                    ),
                  ),
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          Strings.alertsEmpty,
                          style: AppTypography.inter(
                            size: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final a in alerts)
                          _AlertChip(
                            alert: a,
                            onDelete: () => _delete(ref, a),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () => _openSheet(context),
                    icon: const Icon(Icons.notifications_active_rounded,
                        size: 18, color: AppColors.gold),
                    label: Text(
                      Strings.alertsAdd,
                      style: AppTypography.inter(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.goldSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.gold.withAlpha(0x66)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({required this.alert, required this.onDelete});
  final PriceAlert alert;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAbove = alert.direction == AlertDirection.above;
    final color = isAbove ? AppColors.up : AppColors.down;
    final dirLabel = isAbove
        ? Strings.alertsDirectionAbove
        : Strings.alertsDirectionBelow;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(0x29),
            ),
            alignment: Alignment.center,
            child: Text(
              alert.direction.arrow,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$dirLabel ${Format.money(alert.threshold)}',
              style: AppTypography.inter(
                size: 13.5,
                weight: FontWeight.w500,
                color: AppColors.text0,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.text2),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

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
  const _Hero({required this.item, required this.ringColor});
  final CollectionItem item;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final display = item.toDisplay();
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
                  color: display.foil ? ringColor : const Color(0x14FFFFFF),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CardArtTile(card: display, width: 188, height: 264),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.item});
  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final card = item.card;
    final display = item.toDisplay();
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
                Strings.detailSetSuffix(card.setCode),
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
                Format.money(display.value),
                style: AppTypography.num(
                  size: 36,
                  weight: FontWeight.w700,
                  color: AppColors.text0,
                  letterSpacing: -0.025,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              DeltaBadge(value: display.change24, pct: display.change24),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Strings.floorCeiling(
              Format.intGrouped(display.low.round()),
              Format.intGrouped(display.high.round()),
            ),
            style: AppTypography.inter(size: 12, color: AppColors.text2),
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.item});
  final CollectionItem item;

  List<double> _series() {
    final base = (item.currentPrice ?? 0) /
        (1 + (item.change24h ?? 0) / 100).clamp(0.1, double.infinity);
    return List.generate(14, (i) {
      final t = i / 13;
      final noise =
          math.sin(i * 1.4 + (item.currentPrice ?? 0)) * ((item.currentPrice ?? 0) * 0.04);
      return base + ((item.currentPrice ?? 0) - base) * t + noise;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pts = _series();
    final up = (item.change24h ?? 0) >= 0;
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
  const _Stats({required this.item});
  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity;
    final purchase = item.purchasePrice;
    final current = item.currentPrice ?? 0;
    final hasBasis = purchase != null;
    final costBasis = hasBasis ? purchase * qty : null;
    final unrealized = hasBasis ? (current - purchase) * qty : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: StatTile(label: 'Quantité', value: '× $qty')),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Détention',
                  value: _humanHold(item.createdAt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Prix de revient',
                  value: costBasis == null ? '—' : Format.money(costBasis),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Plus-value latente',
                  value: unrealized == null
                      ? '—'
                      : Format.money(unrealized, sign: true),
                  accent: unrealized == null
                      ? null
                      : (unrealized >= 0 ? AppColors.up : AppColors.down),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _humanHold(DateTime since) {
  final now = DateTime.now();
  final months = (now.year - since.year) * 12 + (now.month - since.month);
  if (months < 1) {
    final days = now.difference(since).inDays;
    if (days < 1) return 'aujourd’hui';
    return '${days}j';
  }
  if (months < 12) return '${months}m';
  final y = months ~/ 12;
  final m = months % 12;
  return m == 0 ? '${y}a' : '${y}a ${m}m';
}

// ─────────────────────────────────────────────────────────────────────────
// Section édition de position
// ─────────────────────────────────────────────────────────────────────────
class _PositionEditor extends ConsumerStatefulWidget {
  const _PositionEditor({required this.item});
  final CollectionItem item;

  @override
  ConsumerState<_PositionEditor> createState() => _PositionEditorState();
}

class _PositionEditorState extends ConsumerState<_PositionEditor> {
  late final TextEditingController _priceCtl;
  Timer? _qtyDebounce;
  int _pendingQty = 0;
  bool _qtyBusy = false;
  bool _priceBusy = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _pendingQty = widget.item.quantity;
    _priceCtl = TextEditingController(
      text: widget.item.purchasePrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PositionEditor old) {
    super.didUpdateWidget(old);
    // Sync local state if data changed externally (e.g. realtime update)
    if (widget.item.quantity != old.item.quantity && !_qtyBusy) {
      _pendingQty = widget.item.quantity;
    }
    if (widget.item.purchasePrice != old.item.purchasePrice && !_priceBusy) {
      _priceCtl.text = widget.item.purchasePrice?.toStringAsFixed(2) ?? '';
    }
  }

  @override
  void dispose() {
    _qtyDebounce?.cancel();
    _priceCtl.dispose();
    super.dispose();
  }

  void _changeQty(int delta) {
    final next = (_pendingQty + delta).clamp(0, 9999);
    setState(() => _pendingQty = next);
    HapticFeedback.selectionClick();
    _qtyDebounce?.cancel();
    _qtyDebounce = Timer(const Duration(milliseconds: 400), _flushQty);
  }

  Future<void> _flushQty() async {
    if (_pendingQty == widget.item.quantity) return;
    setState(() => _qtyBusy = true);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .updateQuantity(widget.item.id, _pendingQty);
      ref.invalidate(collectionProvider);
      if (!mounted) return;
      // Pas de snackbar : le badge qty se met à jour visuellement, suffisant.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.detailEditError),
      );
      setState(() => _pendingQty = widget.item.quantity);
    } finally {
      if (mounted) setState(() => _qtyBusy = false);
    }
  }

  Future<void> _savePrice() async {
    final raw = _priceCtl.text.trim().replaceAll(',', '.');
    double? value;
    if (raw.isNotEmpty) {
      final parsed = double.tryParse(raw);
      if (parsed == null || parsed < 0 || parsed > 1000000) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(Strings.detailEditPriceInvalid),
        );
        return;
      }
      value = parsed;
    }
    setState(() => _priceBusy = true);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .updatePurchasePrice(widget.item.id, value);
      ref.invalidate(collectionProvider);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.detailEditPriceSaved),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.detailEditError),
      );
    } finally {
      if (mounted) setState(() => _priceBusy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(
          Strings.detailEditDeleteTitle,
          style: AppTypography.inter(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.text0,
          ),
        ),
        content: Text(
          Strings.detailEditDeleteMessage,
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
          .removeFromCollection(widget.item.id);
      ref.invalidate(collectionProvider);
      // Le watch dans CardDetailScreen détectera la suppression et fermera
      // automatiquement. Snackbar de feedback.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.detailEditDeleted),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.detailEditError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              Strings.detailEditTitle,
              style: AppTypography.eyebrow(size: 11),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x06FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _QuantityRow(
                  value: _pendingQty,
                  busy: _qtyBusy,
                  onChange: _changeQty,
                ),
                const _Divider(),
                _PriceRow(
                  controller: _priceCtl,
                  busy: _priceBusy,
                  onSave: _savePrice,
                ),
                const _Divider(),
                _DeleteRow(
                  busy: _deleting,
                  onTap: _deleting ? null : _confirmDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.value,
    required this.busy,
    required this.onChange,
  });

  final int value;
  final bool busy;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 20, color: AppColors.text1),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              Strings.detailEditQuantity,
              style: AppTypography.inter(
                size: 14,
                weight: FontWeight.w500,
                color: AppColors.text0,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: !busy && value > 1,
            onTap: () => onChange(-1),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: Text(
                '$value',
                style: AppTypography.num(
                  size: 18,
                  weight: FontWeight.w700,
                  color: AppColors.text0,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: !busy && value < 9999,
            onTap: () => onChange(1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.goldSoft : const Color(0x06FFFFFF),
      shape: const CircleBorder(side: BorderSide(color: AppColors.line2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.gold : AppColors.text3,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.controller,
    required this.busy,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.euro_rounded, size: 20, color: AppColors.text1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.detailEditPurchasePrice,
                  style: AppTypography.inter(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.text0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Strings.detailEditPurchasePriceHint,
                  style: AppTypography.inter(
                    size: 11.5,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              enabled: !busy,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: AppTypography.num(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.text0,
              ),
              decoration: InputDecoration(
                hintText: '0,00',
                hintStyle: AppTypography.num(
                  size: 16,
                  weight: FontWeight.w500,
                  color: AppColors.text3,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: const Color(0x0AFFFFFF),
                suffixText: '€',
                suffixStyle: AppTypography.inter(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.text2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
              onSubmitted: (_) => onSave(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: busy ? null : onSave,
              child: SizedBox(
                width: 36,
                height: 36,
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF191100)),
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Color(0xFF191100),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteRow extends StatelessWidget {
  const _DeleteRow({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.down),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                Strings.detailEditDelete,
                style: AppTypography.inter(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.down,
                ),
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.down),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: AppColors.line, thickness: 0.5),
    );
  }
}
