import '../../../core/supabase/supabase_init.dart';

/// Lecture de l'historique des prix par variant (`price_history`).
class PriceRepository {
  PriceRepository();

  /// Dernier prix connu pour [variantId]. Null si aucun snapshot.
  Future<double?> latestPriceFor(String variantId) async {
    final rows = await supabase
        .from('price_history')
        .select('price')
        .eq('variant_id', variantId)
        .order('recorded_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return (rows.first['price'] as num).toDouble();
  }

  /// Map variant_id → dernier prix, en une seule requête.
  Future<Map<String, double>> latestPriceForAll(List<String> variantIds) async {
    if (variantIds.isEmpty) return const {};
    // Stratégie naïve : fetch des 30 derniers jours pour les variants demandés
    // et regroupement côté client. À optimiser avec une vue SQL en V2.
    final since =
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    final rows = await supabase
        .from('price_history')
        .select('variant_id, price, recorded_at')
        .inFilter('variant_id', variantIds)
        .gte('recorded_at', since)
        .order('recorded_at', ascending: false);

    final result = <String, double>{};
    for (final row in rows) {
      final id = row['variant_id'] as String;
      if (!result.containsKey(id)) {
        result[id] = (row['price'] as num).toDouble();
      }
    }
    return result;
  }

  /// Historique des [days] derniers jours pour [variantId], trié ascendant.
  Future<List<({DateTime at, double price})>> fetchHistory(
    String variantId, {
    int days = 30,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await supabase
        .from('price_history')
        .select('price, recorded_at')
        .eq('variant_id', variantId)
        .gte('recorded_at', since)
        .order('recorded_at');
    return rows
        .map((row) => (
              at: DateTime.parse(row['recorded_at'] as String),
              price: (row['price'] as num).toDouble(),
            ))
        .toList();
  }

  /// Bulk : map variant_id → liste de points (prix triés ascendant).
  /// Utilisé pour calculer change24h et low/high 30j en une requête.
  Future<Map<String, List<({DateTime at, double price})>>> fetchHistoryForAll(
    List<String> variantIds, {
    int days = 30,
  }) async {
    if (variantIds.isEmpty) return const {};
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await supabase
        .from('price_history')
        .select('variant_id, price, recorded_at')
        .inFilter('variant_id', variantIds)
        .gte('recorded_at', since)
        .order('recorded_at');

    final result = <String, List<({DateTime at, double price})>>{};
    for (final row in rows) {
      final id = row['variant_id'] as String;
      result.putIfAbsent(id, () => []).add((
        at: DateTime.parse(row['recorded_at'] as String),
        price: (row['price'] as num).toDouble(),
      ));
    }
    return result;
  }
}
