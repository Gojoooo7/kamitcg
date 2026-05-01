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
