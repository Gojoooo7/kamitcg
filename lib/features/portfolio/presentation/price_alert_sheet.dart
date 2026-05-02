import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../domain/card_models.dart';
import '../domain/price_alert.dart';
import 'portfolio_providers.dart';

/// Bottom sheet pour gérer les alertes de prix d'un variant.
/// Présente les alertes actives + un formulaire pour créer une nouvelle.
class PriceAlertSheet extends ConsumerStatefulWidget {
  const PriceAlertSheet({
    required this.card,
    required this.variant,
    required this.currentPrice,
    super.key,
  });

  final CatalogueCard card;
  final CardVariant variant;
  final double currentPrice;

  static Future<void> show(
    BuildContext context, {
    required CatalogueCard card,
    required CardVariant variant,
    required double currentPrice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: PriceAlertSheet(
          card: card,
          variant: variant,
          currentPrice: currentPrice,
        ),
      ),
    );
  }

  @override
  ConsumerState<PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends ConsumerState<PriceAlertSheet> {
  late final TextEditingController _thresholdCtl;
  AlertDirection _direction = AlertDirection.above;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplit avec un seuil au-dessus du prix actuel (+10%) — helper UX.
    final suggested = (widget.currentPrice * 1.1).toStringAsFixed(2);
    _thresholdCtl = TextEditingController(text: suggested);
  }

  @override
  void dispose() {
    _thresholdCtl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final raw = _thresholdCtl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0 || value > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.alertsThresholdInvalid),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(priceAlertsRepositoryProvider).upsertAlert(
            variantId: widget.variant.id,
            threshold: value,
            direction: _direction,
          );
      ref.invalidate(priceAlertsForVariantProvider(widget.variant.id));
      if (!mounted) return;
      Haptics.light(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.alertsCreated),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.alertsError),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(PriceAlert alert) async {
    try {
      await ref.read(priceAlertsRepositoryProvider).deleteAlert(alert.id);
      ref.invalidate(priceAlertsForVariantProvider(widget.variant.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.alertsDeleted),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.alertsError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync =
        ref.watch(priceAlertsForVariantProvider(widget.variant.id));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.alertsSheetTitle,
                        style: AppTypography.inter(
                          size: 18,
                          weight: FontWeight.w700,
                          color: AppColors.text0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.card.name} · ${widget.card.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: 12,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.text1, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Strings.alertsSheetCurrent(Format.money(widget.currentPrice)),
              style: AppTypography.num(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 18),
            // Liste des alertes existantes
            alertsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
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
              error: (_, _) => const SizedBox.shrink(),
              data: (alerts) {
                if (alerts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.alertsActiveLabel,
                      style: AppTypography.eyebrow(size: 11),
                    ),
                    const SizedBox(height: 8),
                    for (final a in alerts) _AlertRow(alert: a, onDelete: _delete),
                    const SizedBox(height: 18),
                  ],
                );
              },
            ),
            // Formulaire nouvelle alerte
            Text(
              Strings.alertsNewLabel,
              style: AppTypography.eyebrow(size: 11),
            ),
            const SizedBox(height: 10),
            _DirectionToggle(
              value: _direction,
              onChange: (v) => setState(() => _direction = v),
            ),
            const SizedBox(height: 12),
            _ThresholdField(
              controller: _thresholdCtl,
              enabled: !_busy,
              onSubmit: _create,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
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
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _busy ? null : _create,
                    child: Center(
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF191100)),
                              ),
                            )
                          : Text(
                              Strings.alertsCreate,
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
            const SizedBox(height: 10),
            Text(
              Strings.alertsNotifsDisclaimer,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                size: 11,
                color: AppColors.text2,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onDelete});

  final PriceAlert alert;
  final ValueChanged<PriceAlert> onDelete;

  @override
  Widget build(BuildContext context) {
    final dirLabel = alert.direction == AlertDirection.above
        ? Strings.alertsDirectionAbove
        : Strings.alertsDirectionBelow;
    final color = alert.direction == AlertDirection.above
        ? AppColors.up
        : AppColors.down;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x06FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(0x29),
            ),
            alignment: Alignment.center,
            child: Text(
              alert.direction.arrow,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dirLabel ${Format.money(alert.threshold)}',
                  style: AppTypography.inter(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.text0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.text2),
            onPressed: () => onDelete(alert),
          ),
        ],
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({required this.value, required this.onChange});

  final AlertDirection value;
  final ValueChanged<AlertDirection> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DirectionChip(
            direction: AlertDirection.above,
            label: Strings.alertsDirectionAbove,
            color: AppColors.up,
            selected: value == AlertDirection.above,
            onTap: () => onChange(AlertDirection.above),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DirectionChip(
            direction: AlertDirection.below,
            label: Strings.alertsDirectionBelow,
            color: AppColors.down,
            selected: value == AlertDirection.below,
            onTap: () => onChange(AlertDirection.below),
          ),
        ),
      ],
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({
    required this.direction,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final AlertDirection direction;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(0x29) : const Color(0x08FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              direction.arrow,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.text2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.inter(
                size: 13,
                weight: FontWeight.w600,
                color: selected ? color : AppColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdField extends StatelessWidget {
  const _ThresholdField({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: AppTypography.num(
        size: 18,
        weight: FontWeight.w700,
        color: AppColors.text0,
      ),
      decoration: InputDecoration(
        labelText: Strings.alertsThresholdLabel,
        labelStyle: AppTypography.inter(size: 12, color: AppColors.text2),
        hintText: '0,00',
        suffixText: '€',
        suffixStyle: AppTypography.inter(
          size: 14,
          weight: FontWeight.w600,
          color: AppColors.text1,
        ),
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
      onSubmitted: (_) => onSubmit(),
    );
  }
}
