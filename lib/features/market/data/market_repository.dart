import '../../../core/supabase/supabase_init.dart';
import '../domain/market_models.dart';

/// Lecture des agrégats marché via les RPC Postgres (cf. migration
/// `market_aggregates_rpcs`). RPCs SECURITY INVOKER → tables catalogue
/// publiques, pas besoin d'auth.
class MarketRepository {
  MarketRepository();

  /// Top variants en hausse 24 h. [direction] = 'up' ou 'down'.
  Future<List<MarketCard>> topMovers({
    String direction = 'up',
    int limit = 5,
  }) async {
    final rows = await supabase.rpc<List<dynamic>>(
      'market_top_movers',
      params: {'direction': direction, 'result_limit': limit},
    );
    return rows
        .map((r) => MarketCard.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Indices par set (variation moyenne 24 h).
  Future<List<MarketSetIndex>> setIndices() async {
    final rows = await supabase.rpc<List<dynamic>>('market_set_indices');
    return rows
        .map((r) => MarketSetIndex.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Top N cartes les plus chères du catalogue.
  Future<List<MarketCard>> topExpensive({int limit = 5}) async {
    final rows = await supabase.rpc<List<dynamic>>(
      'market_top_expensive',
      params: {'result_limit': limit},
    );
    return rows
        .map((r) => MarketCard.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }
}
