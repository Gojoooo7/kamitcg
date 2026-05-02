/// Direction d'une alerte de prix : déclenche quand le prix passe au-dessus
/// (`above`) ou en-dessous (`below`) du seuil.
enum AlertDirection {
  above('above', '↑'),
  below('below', '↓');

  const AlertDirection(this.code, this.arrow);

  /// Code stocké en BDD (cf. CHECK constraint sur `price_alerts.direction`).
  final String code;

  /// Glyphe directionnel pour l'UI.
  final String arrow;

  static AlertDirection fromCode(String code) {
    for (final d in AlertDirection.values) {
      if (d.code == code) return d;
    }
    throw ArgumentError('Direction inconnue : "$code"');
  }
}

/// Alerte de prix configurée par l'utilisateur sur un variant donné.
/// Mappe 1:1 sur `public.price_alerts`.
class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.userId,
    required this.variantId,
    required this.threshold,
    required this.direction,
    required this.enabled,
    required this.triggeredAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String variantId;
  final double threshold;
  final AlertDirection direction;
  final bool enabled;
  final DateTime? triggeredAt;
  final DateTime createdAt;

  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    return PriceAlert(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      variantId: map['variant_id'] as String,
      threshold: (map['threshold'] as num).toDouble(),
      direction: AlertDirection.fromCode(map['direction'] as String),
      enabled: map['enabled'] as bool,
      triggeredAt: map['triggered_at'] == null
          ? null
          : DateTime.parse(map['triggered_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
