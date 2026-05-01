/// Modèles du domaine portfolio.
///
/// - [CardRarity] : enum aligné sur les codes OPCG (`public.cards.rarity`).
/// - [CatalogueCard] : ligne de la table `public.cards` (catalogue maître).
/// - [CardVariant]  : ligne de la table `public.card_variants`.
/// - [CollectionItem] : `public.user_collection` + card + variant + dernier prix.
/// - [DisplayCard] : view-model utilisé par les widgets UI (consolidation de tout).
library;

/// Rareté OPCG (codes canoniques alignés sur la table `public.cards.rarity`).
enum CardRarity {
  secretRare('SEC', 'Secret Rare', 9),
  specialAlt('SP', 'Special', 8),
  treasureRare('TR', 'Treasure Rare', 7),
  superRare('SR', 'Super Rare', 6),
  leader('L', 'Leader', 5),
  rare('R', 'Rare', 4),
  uncommon('UC', 'Peu commune', 3),
  common('C', 'Commune', 2),
  don('DON', 'Don!!', 1),
  promo('P', 'Promo', 0);

  const CardRarity(this.code, this.label, this.rank);

  /// Code OPCG ('SEC', 'SR', 'L', 'R', 'UC', 'C', 'DON', 'P').
  final String code;

  /// Libellé francophone pour l'UI.
  final String label;

  /// Score numérique pour le tri (plus haut = plus rare).
  final int rank;

  /// Parse un code Postgres vers l'enum. Lance si inconnu.
  static CardRarity fromCode(String code) {
    for (final r in CardRarity.values) {
      if (r.code == code) return r;
    }
    throw ArgumentError('Code de rareté OPCG inconnu : "$code"');
  }
}

/// Identifiant d'un dégradé d'illustration placeholder.
/// Cf. AppColors.artA … artH (extraits de KamiTCG.html).
///
/// Pour les cartes du catalogue Supabase qui n'ont pas encore d'`image_url`,
/// on dérive un dégradé déterministe à partir de l'UUID via [forId].
enum CardArtKey {
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  h;

  /// Mapping déterministe UUID → CardArtKey (8 dégradés possibles).
  static CardArtKey forId(String anyId) {
    var sum = 0;
    for (final c in anyId.codeUnits) {
      sum = (sum + c) & 0x7fffffff;
    }
    return CardArtKey.values[sum % CardArtKey.values.length];
  }
}

/// Catalogue : ligne de `public.cards`.
class CatalogueCard {
  const CatalogueCard({
    required this.id,
    required this.setCode,
    required this.cardNumber,
    required this.code,
    required this.name,
    required this.rarity,
    required this.colors,
    required this.cardType,
    required this.imageUrl,
  });

  final String id;
  final String setCode;
  final String cardNumber;

  /// Concat `set_code-card_number` (ex `OP01-120`). Colonne générée côté SQL.
  final String code;
  final String name;
  final CardRarity rarity;
  final List<String> colors;

  /// 'Leader' | 'Character' | 'Event' | 'Stage' (peut être null pour les promos).
  final String? cardType;
  final String? imageUrl;

  CardArtKey get artKey => CardArtKey.forId(id);

  factory CatalogueCard.fromMap(Map<String, dynamic> map) {
    return CatalogueCard(
      id: map['id'] as String,
      setCode: map['set_code'] as String,
      cardNumber: map['card_number'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      rarity: CardRarity.fromCode(map['rarity'] as String),
      colors: (map['colors'] as List?)?.cast<String>() ?? const <String>[],
      cardType: map['card_type'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}

/// Variant : ligne de `public.card_variants` (un print spécifique d'une carte).
class CardVariant {
  const CardVariant({
    required this.id,
    required this.cardId,
    required this.isFoil,
    required this.isAltArt,
    required this.variantLabel,
    required this.imageUrl,
  });

  final String id;
  final String cardId;
  final bool isFoil;
  final bool isAltArt;
  final String? variantLabel;
  final String? imageUrl;

  factory CardVariant.fromMap(Map<String, dynamic> map) {
    return CardVariant(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      isFoil: map['is_foil'] as bool,
      isAltArt: map['is_alt_art'] as bool,
      variantLabel: map['variant_label'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}

/// Ligne de `public.user_collection` enrichie de la carte + variant +
/// dernier prix connu + variation 24 h.
class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.userId,
    required this.card,
    required this.variant,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseCurrency,
    required this.purchasedAt,
    required this.condition,
    required this.notes,
    required this.createdAt,
    required this.currentPrice,
    required this.change24h,
    required this.priceLow30d,
    required this.priceHigh30d,
  });

  final String id;
  final String userId;
  final CatalogueCard card;
  final CardVariant variant;
  final int quantity;
  final double? purchasePrice;
  final String purchaseCurrency;
  final DateTime? purchasedAt;
  final String? condition;
  final String? notes;
  final DateTime createdAt;

  /// Prix unitaire le plus récent (`price_history` triée desc). Null si jamais snapshot.
  final double? currentPrice;

  /// Variation 24 h en pourcentage. Null si pas assez d'historique.
  final double? change24h;

  /// Min sur 30 jours.
  final double? priceLow30d;

  /// Max sur 30 jours.
  final double? priceHigh30d;

  bool get isUp => (change24h ?? 0) >= 0;
  double get totalValue => (currentPrice ?? 0) * quantity;

  /// Convertit en [DisplayCard] consommable directement par les widgets UI.
  DisplayCard toDisplay() {
    return DisplayCard(
      id: id,
      name: card.name,
      code: card.code,
      set: card.setCode,
      rarity: card.rarity,
      art: card.artKey,
      value: currentPrice ?? 0,
      change24: change24h ?? 0,
      qty: quantity,
      low: priceLow30d ?? (currentPrice ?? 0),
      high: priceHigh30d ?? (currentPrice ?? 0),
      foil: variant.isFoil,
      hold: _humanHold(createdAt),
      imageUrl: variant.imageUrl ?? card.imageUrl,
    );
  }
}

/// View-model UI consolidé : ce que les widgets de la liste / dashboard / détail
/// consomment réellement. Construit depuis [CollectionItem] via `.toDisplay()`,
/// ou directement pour les fakes en attendant l'intégration data.
class DisplayCard {
  const DisplayCard({
    required this.id,
    required this.name,
    required this.code,
    required this.set,
    required this.rarity,
    required this.art,
    required this.value,
    required this.change24,
    required this.qty,
    required this.low,
    required this.high,
    required this.foil,
    required this.hold,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String code;
  final String set;
  final CardRarity rarity;
  final CardArtKey art;
  final double value;
  final double change24;
  final int qty;
  final double low;
  final double high;
  final bool foil;
  final String hold;

  /// URL de l'illustration HD Bandai. Null = fallback gradient.
  final String? imageUrl;

  bool get isUp => change24 >= 0;
  double get totalValue => value * qty;
}

/// Format humain "Xy Ym" / "Zm" / "kj" depuis une date de création.
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
