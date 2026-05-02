import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/market_repository.dart';
import '../domain/market_models.dart';

final marketRepositoryProvider = Provider<MarketRepository>((_) {
  return MarketRepository();
});

/// Top 5 gagnants 24 h sur tout le catalogue.
final marketTopGainersProvider =
    FutureProvider<List<MarketCard>>((ref) {
  return ref
      .watch(marketRepositoryProvider)
      .topMovers(direction: 'up', limit: 5);
});

/// Top 5 perdants 24 h sur tout le catalogue.
final marketTopLosersProvider =
    FutureProvider<List<MarketCard>>((ref) {
  return ref
      .watch(marketRepositoryProvider)
      .topMovers(direction: 'down', limit: 5);
});

/// Indices par set (variation moyenne 24 h).
final marketSetIndicesProvider =
    FutureProvider<List<MarketSetIndex>>((ref) {
  return ref.watch(marketRepositoryProvider).setIndices();
});

/// Top 5 cartes les plus chères du catalogue.
final marketTopExpensiveProvider =
    FutureProvider<List<MarketCard>>((ref) {
  return ref.watch(marketRepositoryProvider).topExpensive(limit: 5);
});
