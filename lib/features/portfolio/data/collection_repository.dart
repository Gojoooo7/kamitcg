import '../../../core/supabase/supabase_init.dart';
import '../domain/card_models.dart';

/// CRUD sur la collection de l'utilisateur (`user_collection`).
/// RLS scope par `auth.uid() = user_id`.
class CollectionRepository {
  CollectionRepository();

  /// Lit la collection brute (sans prix). Le provider compose ensuite avec
  /// [PriceRepository] pour assembler des [CollectionItem] complets.
  Future<List<RawCollectionRow>> fetchUserCollection() async {
    // Join card_variants → cards via PostgREST embed
    final rows = await supabase
        .from('user_collection')
        .select('''
          id, user_id, variant_id, quantity,
          purchase_price, purchase_currency, purchased_at,
          condition, notes, created_at, updated_at,
          variant:card_variants!inner (
            id, card_id, is_foil, is_alt_art, variant_label, image_url,
            card:cards!inner (
              id, set_code, card_number, code, name, rarity, colors, card_type, image_url
            )
          )
        ''')
        .order('created_at', ascending: false);

    return rows
        .map((r) => RawCollectionRow.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Ajoute une carte à la collection, ou incrémente la quantité si la ligne
  /// existe déjà (unique sur `(user_id, variant_id)`).
  Future<void> addVariantToCollection(
    String variantId, {
    int quantity = 1,
    double? purchasePrice,
    String? condition,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Pas de session active : impossible d\'ajouter une carte.');
    }

    // Lookup d'une éventuelle ligne existante.
    final existing = await supabase
        .from('user_collection')
        .select('id, quantity')
        .eq('user_id', userId)
        .eq('variant_id', variantId)
        .maybeSingle();

    if (existing != null) {
      final currentQty = existing['quantity'] as int;
      await supabase.from('user_collection').update({
        'quantity': currentQty + quantity,
      }).eq('id', existing['id'] as String);
      return;
    }

    await supabase.from('user_collection').insert({
      'user_id': userId,
      'variant_id': variantId,
      'quantity': quantity,
      'purchase_price': ?purchasePrice,
      'condition': ?condition,
    });
  }

  /// Supprime une ligne complète de la collection.
  Future<void> removeFromCollection(String collectionItemId) {
    return supabase.from('user_collection').delete().eq('id', collectionItemId);
  }

  /// Suppression batch — utilisé par la multi-sélection de la Collection.
  /// La RLS `auth.uid() = user_id` garantit qu'on ne peut supprimer que
  /// ses propres lignes.
  Future<void> removeManyFromCollection(List<String> ids) async {
    if (ids.isEmpty) return;
    await supabase.from('user_collection').delete().inFilter('id', ids);
  }

  /// Met à jour la quantité d'une ligne. Supprime si quantity ≤ 0.
  Future<void> updateQuantity(String collectionItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCollection(collectionItemId);
      return;
    }
    await supabase
        .from('user_collection')
        .update({'quantity': quantity})
        .eq('id', collectionItemId);
  }

  /// Met à jour le prix d'achat unitaire d'une ligne. `null` = pas de prix
  /// (la plus-value latente n'est plus calculable pour cette ligne).
  Future<void> updatePurchasePrice(
    String collectionItemId,
    double? price,
  ) async {
    await supabase
        .from('user_collection')
        .update({'purchase_price': price})
        .eq('id', collectionItemId);
  }
}

/// Ligne brute issue de la requête PostgREST avec les jointures variant + card.
/// Le provider l'enrichit avec les prix pour produire un [CollectionItem] complet.
class RawCollectionRow {
  RawCollectionRow({
    required this.id,
    required this.userId,
    required this.variant,
    required this.card,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseCurrency,
    required this.purchasedAt,
    required this.condition,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final CardVariant variant;
  final CatalogueCard card;
  final int quantity;
  final double? purchasePrice;
  final String purchaseCurrency;
  final DateTime? purchasedAt;
  final String? condition;
  final String? notes;
  final DateTime createdAt;

  factory RawCollectionRow.fromMap(Map<String, dynamic> row) {
    final variantMap = Map<String, dynamic>.from(row['variant'] as Map);
    final cardMap = Map<String, dynamic>.from(variantMap['card'] as Map);
    return RawCollectionRow(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      variant: CardVariant.fromMap(variantMap),
      card: CatalogueCard.fromMap(cardMap),
      quantity: row['quantity'] as int,
      purchasePrice: (row['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: row['purchase_currency'] as String? ?? 'EUR',
      purchasedAt: row['purchased_at'] == null
          ? null
          : DateTime.parse(row['purchased_at'] as String),
      condition: row['condition'] as String?,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  CollectionItem toItemWith({
    required double? currentPrice,
    required double? change24h,
    required double? priceLow30d,
    required double? priceHigh30d,
  }) {
    return CollectionItem(
      id: id,
      userId: userId,
      card: card,
      variant: variant,
      quantity: quantity,
      purchasePrice: purchasePrice,
      purchaseCurrency: purchaseCurrency,
      purchasedAt: purchasedAt,
      condition: condition,
      notes: notes,
      createdAt: createdAt,
      currentPrice: currentPrice,
      change24h: change24h,
      priceLow30d: priceLow30d,
      priceHigh30d: priceHigh30d,
    );
  }
}

