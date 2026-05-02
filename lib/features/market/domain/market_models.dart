import '../../portfolio/domain/card_models.dart';

/// Une entrée dans la liste des "top movers" / "top expensive". Mappe sur la
/// row retournée par les RPC `market_top_movers` / `market_top_expensive`.
class MarketCard {
  const MarketCard({
    required this.variantId,
    required this.cardId,
    required this.code,
    required this.name,
    required this.rarity,
    required this.setCode,
    required this.variantLabel,
    required this.isFoil,
    required this.isAltArt,
    required this.imageUrl,
    required this.currentPrice,
    required this.changePct,
  });

  final String variantId;
  final String cardId;
  final String code;
  final String name;
  final CardRarity rarity;
  final String setCode;
  final String? variantLabel;
  final bool isFoil;
  final bool isAltArt;
  final String? imageUrl;
  final double currentPrice;

  /// Variation 24 h en %. Null pour les listings "top expensive" (n'a pas de
  /// notion de variation, juste de prix absolu).
  final double? changePct;

  factory MarketCard.fromMap(Map<String, dynamic> m) {
    return MarketCard(
      variantId: m['variant_id'] as String,
      cardId: m['card_id'] as String,
      code: m['card_code'] as String,
      name: m['card_name'] as String,
      rarity: CardRarity.fromCode(m['rarity'] as String),
      setCode: m['set_code'] as String,
      variantLabel: m['variant_label'] as String?,
      isFoil: m['is_foil'] as bool,
      isAltArt: m['is_alt_art'] as bool,
      imageUrl: m['image_url'] as String?,
      currentPrice: (m['current_price'] as num).toDouble(),
      changePct: (m['change_pct'] as num?)?.toDouble(),
    );
  }

  /// Construit un [DisplayCard] pour réutiliser les widgets UI (CardArtTile).
  /// `qty=0` car le marché ne sait pas combien tu en possèdes.
  DisplayCard toDisplay() => DisplayCard(
        id: variantId,
        name: name,
        code: code,
        set: setCode,
        rarity: rarity,
        art: CardArtKey.forId(cardId),
        value: currentPrice,
        change24: changePct ?? 0,
        qty: 0,
        low: currentPrice,
        high: currentPrice,
        foil: isFoil,
        hold: '',
        imageUrl: imageUrl,
      );
}

/// Indice de marché pour un set (variation moyenne 24 h pondérée).
class MarketSetIndex {
  const MarketSetIndex({
    required this.setCode,
    required this.variantCount,
    required this.avgChangePct,
    required this.avgPrice,
  });

  final String setCode;
  final int variantCount;
  final double avgChangePct;
  final double avgPrice;

  factory MarketSetIndex.fromMap(Map<String, dynamic> m) {
    return MarketSetIndex(
      setCode: m['set_code'] as String,
      variantCount: (m['variant_count'] as num).toInt(),
      avgChangePct: (m['avg_change_pct'] as num).toDouble(),
      avgPrice: (m['avg_price'] as num).toDouble(),
    );
  }

  bool get isUp => avgChangePct >= 0;
}
