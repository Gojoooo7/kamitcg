import '../../../core/supabase/supabase_init.dart';
import '../domain/card_models.dart';

/// Lecture du catalogue OPCG (table `cards` + `card_variants`).
/// SELECT public côté RLS — fonctionne sans authentification.
class CardRepository {
  CardRepository();

  /// PostgREST limite par défaut à 1000 lignes par requête. On pagine pour
  /// ramener le catalogue complet (2500+ cartes / 4000+ variants).
  static const int _pageSize = 1000;

  /// Toutes les cartes du catalogue, triées par set puis numéro.
  Future<List<CatalogueCard>> fetchAllCards() async {
    final result = <CatalogueCard>[];
    var from = 0;
    while (true) {
      final rows = await supabase
          .from('cards')
          .select()
          .order('set_code')
          .order('card_number')
          .range(from, from + _pageSize - 1);
      if (rows.isEmpty) break;
      result.addAll(
        rows.map((r) => CatalogueCard.fromMap(Map<String, dynamic>.from(r))),
      );
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return result;
  }

  /// Tous les variants. À utiliser conjointement avec [fetchAllCards].
  Future<List<CardVariant>> fetchAllVariants() async {
    final result = <CardVariant>[];
    var from = 0;
    while (true) {
      final rows = await supabase
          .from('card_variants')
          .select()
          .range(from, from + _pageSize - 1);
      if (rows.isEmpty) break;
      result.addAll(
        rows.map((r) => CardVariant.fromMap(Map<String, dynamic>.from(r))),
      );
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return result;
  }

  /// Cherche une carte + tous ses variants depuis un code OCR brut (ex
  /// `OP01-120`). Le suffixe `_pX` est ignoré au lookup (on prend la carte de
  /// base puis on retourne tous ses variants), pour laisser l'utilisateur
  /// choisir lui-même via le picker du scanner.
  Future<({CatalogueCard card, List<CardVariant> variants})?>
      findCardWithVariantsByCode(String fullCode) async {
    final match =
        RegExp(r'^([A-Z]+\d*)-(\d+)(_P\d+)?$', caseSensitive: false)
            .firstMatch(fullCode.toUpperCase());
    if (match == null) return null;
    final setCode = match.group(1)!.toUpperCase();
    final cardNumber = match.group(2)!;

    final cardRow = await supabase
        .from('cards')
        .select()
        .eq('set_code', setCode)
        .eq('card_number', cardNumber)
        .maybeSingle();
    if (cardRow == null) return null;
    final card = CatalogueCard.fromMap(Map<String, dynamic>.from(cardRow));

    final variantRows = await supabase
        .from('card_variants')
        .select()
        .eq('card_id', card.id)
        .order('is_alt_art')
        .order('is_foil')
        .order('variant_label');
    final variants = variantRows
        .map((row) => CardVariant.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    if (variants.isEmpty) return null;

    return (card: card, variants: variants);
  }

  /// Cherche une carte + son variant à partir d'un code OCR (ex `OP01-120` ou
  /// `OP01-051_P1` pour un alt-art). Retourne null si la carte n'est pas dans
  /// le catalogue.
  ///
  /// Le suffixe `_pX` détermine si on récupère le variant base ou alt-art.
  Future<({CatalogueCard card, CardVariant variant})?> findEntryByCode(
    String fullCode,
  ) async {
    // 1) Décomposer le code en (baseCode, isAltArt)
    final match =
        RegExp(r'^([A-Z]+\d*)-(\d+)(_P\d+)?$', caseSensitive: false)
            .firstMatch(fullCode.toUpperCase());
    if (match == null) return null;
    final setCode = match.group(1)!.toUpperCase();
    final cardNumber = match.group(2)!;
    final hasVariantSuffix = match.group(3) != null;

    // 2) Trouver la carte de base
    final cardRow = await supabase
        .from('cards')
        .select()
        .eq('set_code', setCode)
        .eq('card_number', cardNumber)
        .maybeSingle();
    if (cardRow == null) return null;
    final card = CatalogueCard.fromMap(Map<String, dynamic>.from(cardRow));

    // 3) Trouver le variant (alt-art si suffixe `_pX`, sinon base)
    final variantRow = await supabase
        .from('card_variants')
        .select()
        .eq('card_id', card.id)
        .eq('is_alt_art', hasVariantSuffix)
        .eq('is_foil', false)
        .limit(1)
        .maybeSingle();
    if (variantRow == null) return null;
    final variant = CardVariant.fromMap(Map<String, dynamic>.from(variantRow));

    return (card: card, variant: variant);
  }

  /// Recherche par nom ou code (ex `Luffy` ou `OP01-120`). Insensible à la casse.
  Future<List<CatalogueCard>> searchCards(String query) async {
    final q = query.trim();
    if (q.isEmpty) return fetchAllCards();
    final rows = await supabase
        .from('cards')
        .select()
        .or('name.ilike.%$q%,code.ilike.%$q%')
        .order('set_code')
        .order('card_number')
        .limit(50);
    return rows
        .map((row) => CatalogueCard.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
