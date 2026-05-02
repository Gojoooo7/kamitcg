import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/strings.dart';
import '../../../core/supabase/supabase_init.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../portfolio/domain/card_models.dart';
import '../../portfolio/presentation/portfolio_providers.dart';
import 'profile_providers.dart';

/// Limite du palier gratuit (cf. CLAUDE.md). Dépassée → CTA Premium.
const int _freeTierLimit = 50;

/// Liens externes — à remplacer par les vraies URLs hébergées avant publication.
const String _privacyUrl = 'https://kamitcg.app/privacy';
const String _termsUrl = 'https://kamitcg.app/terms';
const String _appVersion = '1.0.0';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          Strings.profileTitle,
          style: AppTypography.inter(
            size: 26,
            weight: FontWeight.w700,
            color: AppColors.text0,
            letterSpacing: -0.025,
          ),
        ),
        const SizedBox(height: 20),
        const _IdentityCard(),
        const SizedBox(height: 24),
        const _PremiumSection(),
        const SizedBox(height: 24),
        const _StatsSection(),
        const SizedBox(height: 24),
        const _PrefsSection(),
        const SizedBox(height: 24),
        const _DataSection(),
        const SizedBox(height: 24),
        const _AccountSection(),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'KamiTCG · v$_appVersion',
            style: AppTypography.inter(size: 11, color: AppColors.text3),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1) Identité
// ─────────────────────────────────────────────────────────────────────────
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final email = session?.user.email;
    final created = _parseUserCreatedAt(session?.user.createdAt);
    return _Card(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A2BE2), Color(0xFF5B1AA3)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsOf(email),
              style: AppTypography.num(
                size: 22,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.userDisplayName,
                  style: AppTypography.inter(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.text0,
                  ),
                ),
                const SizedBox(height: 2),
                if (email != null)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(size: 12, color: AppColors.text2),
                  ),
                const SizedBox(height: 6),
                Text(
                  created == null
                      ? Strings.profileMemberSinceUnknown
                      : Strings.profileMemberSince(_formatFrDate(created)),
                  style: AppTypography.inter(
                    size: 12,
                    color: AppColors.text2,
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

String _initialsOf(String? email) {
  if (email == null || email.isEmpty) return 'NK';
  return String.fromCharCode(email.runes.first).toUpperCase();
}

DateTime? _parseUserCreatedAt(String? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

const _frenchMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatFrDate(DateTime d) {
  return '${d.day} ${_frenchMonths[d.month - 1]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────
// 2) Statut Premium (placeholder — wiring RevenueCat à venir)
// ─────────────────────────────────────────────────────────────────────────
class _PremiumSection extends ConsumerWidget {
  const _PremiumSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(portfolioStatsProvider).value ?? PortfolioStats.empty;
    final cardCount = stats.cardCount;
    // TODO(premium): brancher sur profiles.premium_until quand RevenueCat sera là.
    // ignore: prefer_const_declarations
    final bool isPremium = false;
    final progress = (cardCount / _freeTierLimit).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: Strings.premiumSectionTitle),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x33D4AF37),
                Color(0x14D4AF37),
              ],
            ),
            border: Border.all(color: AppColors.gold.withAlpha(0x59)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 22, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    // ignore: dead_code
                    isPremium ? Strings.premiumActiveLabel : Strings.premiumFreeLabel,
                    style: AppTypography.inter(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              if (!isPremium) ...[
                const SizedBox(height: 14),
                Text(
                  Strings.premiumProgress(cardCount, _freeTierLimit),
                  style: AppTypography.num(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.text0,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.bg3,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  Strings.premiumPerksHeader,
                  style: AppTypography.eyebrow(size: 11),
                ),
                const SizedBox(height: 8),
                const _Perk(text: Strings.premiumPerk1),
                const _Perk(text: Strings.premiumPerk2),
                const _Perk(text: Strings.premiumPerk3),
                const _Perk(text: Strings.premiumPerk4),
                const SizedBox(height: 14),
                const _PremiumCta(
                  label: Strings.premiumCta,
                  hint: Strings.premiumComingSoon,
                ),
                // ignore: dead_code
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  Strings.premiumExpires('—'),
                  style: AppTypography.inter(size: 12, color: AppColors.text2),
                ),
                const SizedBox(height: 14),
                const _PremiumCta(
                  label: Strings.premiumManage,
                  hint: Strings.premiumComingSoon,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 14, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.inter(
                size: 13,
                color: AppColors.text1,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCta extends StatelessWidget {
  const _PremiumCta({required this.label, required this.hint});
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                onTap: () {
                  // TODO(premium): déclencher le paywall RevenueCat
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppSnackBar.info(Strings.premiumComingSoon),
                  );
                },
                child: Center(
                  child: Text(
                    label,
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
        const SizedBox(height: 6),
        Center(
          child: Text(
            hint,
            style: AppTypography.inter(size: 11, color: AppColors.text2),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3) Mes statistiques
// ─────────────────────────────────────────────────────────────────────────
class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(portfolioStatsProvider).value ?? PortfolioStats.empty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: Strings.profileStatsTitle),
        const SizedBox(height: 10),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: Strings.profileStatCards,
                      value: '${stats.cardCount}',
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: Strings.profileStatValue,
                      value: Format.money(stats.totalValue),
                      accent: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: Strings.profileStatSets,
                      value: '${stats.uniqueSets}',
                    ),
                  ),
                  const Expanded(
                    child: _MiniStat(
                      label: Strings.profileStatPnl,
                      // V1 : pas de cost basis comprehensif → placeholder.
                      value: Strings.profileStatPnlNoBasis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.accent});
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(size: 10.5),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.num(
            size: 18,
            weight: FontWeight.w700,
            color: accent ?? AppColors.text0,
            letterSpacing: -0.02,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 4) Préférences
// ─────────────────────────────────────────────────────────────────────────
class _PrefsSection extends ConsumerWidget {
  const _PrefsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: Strings.profilePrefsTitle),
        const SizedBox(height: 10),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PrefRow(
                icon: Icons.euro_rounded,
                label: Strings.profilePrefCurrency,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prefs.currency,
                      style: AppTypography.num(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.text3),
                  ],
                ),
                hint: Strings.profilePrefCurrencySoon,
                onTap: null, // V1 : non interactif
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.notifications_none_rounded,
                label: Strings.profilePrefNotifications,
                hint: Strings.profilePrefNotificationsHint,
                trailing: Switch(
                  value: prefs.notificationsEnabled,
                  activeThumbColor: AppColors.gold,
                  onChanged: notifier.setNotificationsEnabled,
                ),
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.vibration_rounded,
                label: Strings.profilePrefHaptics,
                hint: Strings.profilePrefHapticsHint,
                trailing: Switch(
                  value: prefs.hapticsEnabled,
                  activeThumbColor: AppColors.gold,
                  onChanged: notifier.setHapticsEnabled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.hint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.text1),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.inter(
                        size: 14,
                        weight: FontWeight.w500,
                        color: AppColors.text0,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint!,
                        style: AppTypography.inter(
                          size: 11.5,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 5) Données (export CSV + vider collection)
// ─────────────────────────────────────────────────────────────────────────
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: Strings.profileDataTitle),
        const SizedBox(height: 10),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PrefRow(
                icon: Icons.file_download_outlined,
                label: Strings.profileExport,
                hint: Strings.profileExportHint,
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.text3),
                onTap: () => _exportCsv(context, ref),
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.delete_sweep_outlined,
                label: Strings.profileClearCollection,
                hint: Strings.profileClearCollectionHint,
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.text3),
                onTap: () => _clearCollection(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final items = ref.read(collectionProvider).value ?? const <CollectionItem>[];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(Strings.profileExportEmpty),
      );
      return;
    }
    final csv = _buildCsv(items);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.success(Strings.profileExportSuccess),
    );
  }

  Future<void> _clearCollection(BuildContext context, WidgetRef ref) async {
    final items = ref.read(collectionProvider).value ?? const <CollectionItem>[];
    if (items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(
          Strings.profileClearTitle,
          style: AppTypography.inter(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.text0,
          ),
        ),
        content: Text(
          Strings.profileClearMessage(items.length),
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
              Strings.profileClearConfirm,
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(collectionRepositoryProvider)
          .removeManyFromCollection(items.map((i) => i.id).toList());
      ref.invalidate(collectionProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success(Strings.profileClearedSuccess),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.collectionDeleteError),
      );
    }
  }
}

String _buildCsv(List<CollectionItem> items) {
  final buf = StringBuffer()
    ..writeln('code,name,set,rarity,quantity,variant,purchase_price,added_at');
  for (final i in items) {
    final variant = [
      if (i.variant.isFoil) 'Foil',
      if (i.variant.isAltArt) (i.variant.variantLabel ?? 'Alt Art'),
    ].join(' / ');
    final price = i.purchasePrice == null ? '' : i.purchasePrice!.toStringAsFixed(2);
    buf.writeln([
      _csvField(i.card.code),
      _csvField(i.card.name),
      _csvField(i.card.setCode),
      _csvField(i.card.rarity.code),
      i.quantity.toString(),
      _csvField(variant),
      price,
      i.createdAt.toIso8601String(),
    ].join(','));
  }
  return buf.toString();
}

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

// ─────────────────────────────────────────────────────────────────────────
// 6) Compte & Support
// ─────────────────────────────────────────────────────────────────────────
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: Strings.profileAccountTitle),
        const SizedBox(height: 10),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PrefRow(
                icon: Icons.shield_outlined,
                label: Strings.profilePrivacy,
                trailing: const Icon(Icons.open_in_new_rounded,
                    size: 16, color: AppColors.text3),
                onTap: () => _openUrl(context, _privacyUrl),
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.description_outlined,
                label: Strings.profileTerms,
                trailing: const Icon(Icons.open_in_new_rounded,
                    size: 16, color: AppColors.text3),
                onTap: () => _openUrl(context, _termsUrl),
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.info_outline_rounded,
                label: Strings.profileVersion,
                trailing: Text(
                  _appVersion,
                  style: AppTypography.mono(size: 12, color: AppColors.text2),
                ),
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.logout_rounded,
                label: Strings.profileSignOut,
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.text3),
                onTap: () => _confirmSignOut(context, ref),
              ),
              const _Divider(),
              _PrefRow(
                icon: Icons.delete_forever_rounded,
                label: Strings.profileDelete,
                hint: Strings.profileDeleteHint,
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.down),
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.profileLinkOpenError),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final email = ref.read(currentUserEmailProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(
          Strings.profileSignOut,
          style: AppTypography.inter(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.text0,
          ),
        ),
        content: Text(
          email == null ? '' : Strings.profileSignedInAs(email),
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
              Strings.profileSignOut,
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
    if (ok != true) return;
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(
          Strings.profileDeleteTitle,
          style: AppTypography.inter(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.down,
          ),
        ),
        content: Text(
          Strings.profileDeleteMessage,
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
              Strings.profileDeleteConfirm,
              style: AppTypography.inter(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.down,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await supabase.rpc<void>('delete_my_account');
      // Le token devient invalide côté serveur. On signe out localement pour
      // purger le secure storage et rebasculer sur LoginScreen.
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.profileDeleteError),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Reusable bricks
// ─────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: AppTypography.eyebrow(size: 11)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x06FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(padding: padding, child: child),
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
