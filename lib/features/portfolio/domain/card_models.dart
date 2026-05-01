/// Rareté d'une carte. Ordre du plus rare au plus commun.
/// `label` est la chaîne francophone affichée dans l'UI ; quand l'EN sera ajouté,
/// migrer vers une lookup via `flutter_localizations`.
enum CardRarity {
  mythic('Mythique'),
  legendary('Légendaire'),
  rare('Rare'),
  common('Commun');

  const CardRarity(this.label);
  final String label;

  /// Score numérique pour le tri (plus haut = plus rare).
  int get rank => switch (this) {
        CardRarity.mythic => 4,
        CardRarity.legendary => 3,
        CardRarity.rare => 2,
        CardRarity.common => 1,
      };
}

/// Identifiant d'un dégradé d'illustration placeholder.
/// Cf. AppColors.artA … artH (extraits de KamiTCG.html).
enum CardArtKey { a, b, c, d, e, f, g, h }

/// Carte présente dans la collection de l'utilisateur.
/// Modèle UI (mock) — sera mappé vers Supabase ultérieurement.
class TcgCard {
  const TcgCard({
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
  });

  final String id;
  final String name;
  final String code;
  final String set;
  final CardRarity rarity;
  final CardArtKey art;

  /// Valeur unitaire actuelle en euros.
  final double value;

  /// Variation 24 h en pourcentage.
  final double change24;

  final int qty;
  final double low;
  final double high;
  final bool foil;

  /// Durée de détention (libre, ex: '2y 4m', '7m').
  final String hold;

  bool get isUp => change24 >= 0;
  double get totalValue => value * qty;
}
