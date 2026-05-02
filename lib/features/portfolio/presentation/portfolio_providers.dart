import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/card_repository.dart';
import '../data/collection_repository.dart';
import '../data/price_alerts_repository.dart';
import '../data/price_repository.dart';
import '../domain/card_models.dart';
import '../domain/price_alert.dart';

// ─────────────────────────────────────────────────────────────────────────
// Repositories (singletons)
// ─────────────────────────────────────────────────────────────────────────
final cardRepositoryProvider = Provider<CardRepository>((_) {
  return CardRepository();
});

final collectionRepositoryProvider = Provider<CollectionRepository>((_) {
  return CollectionRepository();
});

final priceRepositoryProvider = Provider<PriceRepository>((_) {
  return PriceRepository();
});

final priceAlertsRepositoryProvider = Provider<PriceAlertsRepository>((_) {
  return PriceAlertsRepository();
});

/// Liste des alertes de prix de l'utilisateur pour un variant donné.
/// Family key = variantId.
final priceAlertsForVariantProvider =
    FutureProvider.family<List<PriceAlert>, String>((ref, variantId) {
  return ref.watch(priceAlertsRepositoryProvider).listForVariant(variantId);
});

// ─────────────────────────────────────────────────────────────────────────
// Catalogue : toutes les cartes du jeu (lecture publique)
// ─────────────────────────────────────────────────────────────────────────
final catalogueProvider = FutureProvider<List<CatalogueCard>>((ref) {
  return ref.watch(cardRepositoryProvider).fetchAllCards();
});

/// Catalogue joint avec ses variants : une entrée par variant, prête à afficher
/// dans l'écran "Ajouter une carte".
class CatalogueEntry {
  const CatalogueEntry({required this.card, required this.variant});
  final CatalogueCard card;
  final CardVariant variant;

  /// Suffixe humain pour distinguer les variants ('Foil', 'Manga Art', etc.).
  String get variantSuffix {
    final parts = <String>[];
    if (variant.isFoil) parts.add('Foil');
    if (variant.isAltArt) parts.add(variant.variantLabel ?? 'Alt Art');
    if (parts.isEmpty && variant.variantLabel != null) {
      parts.add(variant.variantLabel!);
    }
    return parts.join(' · ');
  }

  /// Construit un [DisplayCard] pour réutiliser les widgets UI existants
  /// (CardArtTile, RarityPill). Pas de prix → 0.
  DisplayCard toDisplay() => DisplayCard(
        id: variant.id,
        name: card.name,
        code: card.code,
        set: card.setCode,
        rarity: card.rarity,
        art: card.artKey,
        value: 0,
        change24: 0,
        qty: 0,
        low: 0,
        high: 0,
        foil: variant.isFoil,
        hold: '',
        imageUrl: variant.imageUrl ?? card.imageUrl,
      );
}

final catalogueWithVariantsProvider =
    FutureProvider<List<CatalogueEntry>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  final cards = await repo.fetchAllCards();
  final variants = await repo.fetchAllVariants();
  final cardsById = {for (final c in cards) c.id: c};
  return variants
      .where((v) => cardsById.containsKey(v.cardId))
      .map((v) => CatalogueEntry(card: cardsById[v.cardId]!, variant: v))
      .toList()
    ..sort((a, b) {
      final cmp = a.card.setCode.compareTo(b.card.setCode);
      if (cmp != 0) return cmp;
      return a.card.cardNumber.compareTo(b.card.cardNumber);
    });
});

// ─────────────────────────────────────────────────────────────────────────
// Collection utilisateur : raw rows + prix → CollectionItem complets
// ─────────────────────────────────────────────────────────────────────────

/// Collection assemblée et enrichie en prix (current + change24h + low/high 30j).
final collectionProvider = FutureProvider<List<CollectionItem>>((ref) async {
  // Recompute à chaque event d'auth (sign-in, sign-out, refresh).
  ref.watch(authStateProvider);
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const <CollectionItem>[];

  final collectionRepo = ref.watch(collectionRepositoryProvider);
  final priceRepo = ref.watch(priceRepositoryProvider);

  final raw = await collectionRepo.fetchUserCollection();
  if (raw.isEmpty) return const <CollectionItem>[];

  final variantIds = raw.map((r) => r.variant.id).toList();
  final histories = await priceRepo.fetchHistoryForAll(variantIds);

  return raw.map((row) {
    final pts = histories[row.variant.id] ?? const [];
    final current = pts.isEmpty ? null : pts.last.price;
    final yesterday = _findPriceAround(
      pts,
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    final change24h = (current != null && yesterday != null && yesterday > 0)
        ? ((current - yesterday) / yesterday) * 100
        : null;
    final priceLow = pts.isEmpty
        ? null
        : pts.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final priceHigh = pts.isEmpty
        ? null
        : pts.map((p) => p.price).reduce((a, b) => a > b ? a : b);

    return row.toItemWith(
      currentPrice: current,
      change24h: change24h,
      priceLow30d: priceLow,
      priceHigh30d: priceHigh,
    );
  }).toList();
});

/// Cherche le point de prix le plus proche d'un instant cible.
/// Retourne null si aucune donnée à moins de 36h du target.
double? _findPriceAround(
  List<({DateTime at, double price})> points,
  DateTime target,
) {
  if (points.isEmpty) return null;
  ({DateTime at, double price})? best;
  Duration bestDelta = const Duration(days: 365);
  for (final p in points) {
    final delta = p.at.difference(target).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      best = p;
    }
  }
  if (bestDelta.inHours > 36) return null;
  return best?.price;
}

// ─────────────────────────────────────────────────────────────────────────
// Stats dérivées du portfolio
// ─────────────────────────────────────────────────────────────────────────

class PortfolioStats {
  const PortfolioStats({
    required this.totalValue,
    required this.delta24h,
    required this.deltaPct24h,
    required this.cardCount,
    required this.uniqueSets,
    required this.secretRareCount,
  });

  final double totalValue;
  final double delta24h;
  final double deltaPct24h;
  final int cardCount;
  final int uniqueSets;
  final int secretRareCount;

  static const empty = PortfolioStats(
    totalValue: 0,
    delta24h: 0,
    deltaPct24h: 0,
    cardCount: 0,
    uniqueSets: 0,
    secretRareCount: 0,
  );
}

/// Stats agrégées dérivées de la collection.
final portfolioStatsProvider = Provider<AsyncValue<PortfolioStats>>((ref) {
  return ref.watch(collectionProvider).whenData(_computeStats);
});

PortfolioStats _computeStats(List<CollectionItem> items) {
  if (items.isEmpty) return PortfolioStats.empty;

  var total = 0.0;
  var totalYesterday = 0.0;
  var cards = 0;
  final sets = <String>{};
  var secretRare = 0;

  for (final item in items) {
    final price = item.currentPrice ?? 0;
    final qty = item.quantity;
    total += price * qty;
    cards += qty;
    sets.add(item.card.setCode);
    if (item.card.rarity == CardRarity.secretRare) secretRare += qty;

    // Yesterday total : current / (1 + change24/100) ; fallback = current
    final change = item.change24h;
    if (change != null && change > -100) {
      totalYesterday += (price * qty) / (1 + change / 100);
    } else {
      totalYesterday += price * qty;
    }
  }

  final delta = total - totalYesterday;
  final pct = totalYesterday > 0 ? (delta / totalYesterday) * 100 : 0.0;

  return PortfolioStats(
    totalValue: total,
    delta24h: delta,
    deltaPct24h: pct,
    cardCount: cards,
    uniqueSets: sets.length,
    secretRareCount: secretRare,
  );
}

/// Top 3 performers (24h) — null si collection vide.
final topPerformersProvider = Provider<AsyncValue<List<CollectionItem>>>((ref) {
  return ref.watch(collectionProvider).whenData((items) {
    if (items.isEmpty) return const <CollectionItem>[];
    final sorted = [...items]..sort(
        (a, b) => (b.change24h ?? 0).compareTo(a.change24h ?? 0),
      );
    return sorted.take(3).toList();
  });
});

/// Series de prix agrégées sur le portfolio (somme pondérée des variants détenus).
/// Utilisée par le graphique du Dashboard. La family-key est un code parmi
/// `'1J' | '1S' | '1M' | '1A' | 'TOUT'` (cf. Strings.rangeTabs).
final portfolioChartProvider =
    FutureProvider.family<List<double>, String>((ref, rangeCode) async {
  final items = await ref.watch(collectionProvider.future);
  if (items.isEmpty) return const [];

  final priceRepo = ref.watch(priceRepositoryProvider);
  final days = switch (rangeCode) {
    '1J' => 1,
    '1S' => 7,
    '1M' => 30,
    '1A' => 365,
    _ => 30,
  };

  final variantIds = items.map((i) => i.variant.id).toList();
  final histories = await priceRepo.fetchHistoryForAll(variantIds, days: days);

  // Reconstruit une série temporelle agrégée : pour chaque jour distinct,
  // somme des (last_price_ce_jour × quantity).
  final qtyByVariant = {for (final i in items) i.variant.id: i.quantity};
  final allDays = <DateTime>{};
  for (final pts in histories.values) {
    for (final p in pts) {
      allDays.add(DateTime(p.at.year, p.at.month, p.at.day));
    }
  }
  final sortedDays = allDays.toList()..sort();
  if (sortedDays.isEmpty) return const [];

  final result = <double>[];
  for (final day in sortedDays) {
    var sum = 0.0;
    for (final entry in histories.entries) {
      final qty = qtyByVariant[entry.key] ?? 0;
      if (qty == 0) continue;
      // Dernier prix connu à <= ce jour
      double? priceForDay;
      for (final p in entry.value) {
        final pDay = DateTime(p.at.year, p.at.month, p.at.day);
        if (!pDay.isAfter(day)) {
          priceForDay = p.price;
        } else {
          break;
        }
      }
      sum += (priceForDay ?? 0) * qty;
    }
    result.add(sum);
  }
  return result;
});
