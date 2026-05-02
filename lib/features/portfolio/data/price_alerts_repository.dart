import '../../../core/supabase/supabase_init.dart';
import '../domain/price_alert.dart';

/// CRUD sur les alertes de prix de l'utilisateur courant.
/// RLS scope par `auth.uid() = user_id`.
class PriceAlertsRepository {
  PriceAlertsRepository();

  /// Liste les alertes actives pour [variantId], plus récente en premier.
  Future<List<PriceAlert>> listForVariant(String variantId) async {
    final rows = await supabase
        .from('price_alerts')
        .select()
        .eq('variant_id', variantId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => PriceAlert.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Crée ou met à jour une alerte. Si une alerte existe déjà pour
  /// `(user_id, variant_id, direction)` (contrainte unique côté BDD), son
  /// seuil est remplacé et `enabled` repassé à true.
  Future<void> upsertAlert({
    required String variantId,
    required double threshold,
    required AlertDirection direction,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Pas de session active.');
    }
    await supabase.from('price_alerts').upsert(
      {
        'user_id': userId,
        'variant_id': variantId,
        'threshold': threshold,
        'direction': direction.code,
        'enabled': true,
        'triggered_at': null,
      },
      onConflict: 'user_id,variant_id,direction',
    );
  }

  /// Supprime une alerte.
  Future<void> deleteAlert(String alertId) async {
    await supabase.from('price_alerts').delete().eq('id', alertId);
  }
}
