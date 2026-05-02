import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/preferences_repository.dart';

/// Initialise SharedPreferences une seule fois au démarrage de l'app et expose
/// l'instance via le repository.
final preferencesRepositoryProvider =
    FutureProvider<PreferencesRepository>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferencesRepository(prefs);
});

/// Snapshot des préférences courantes — bool/string getters pour l'UI.
class UserPreferences {
  const UserPreferences({
    required this.hapticsEnabled,
    required this.notificationsEnabled,
    required this.currency,
  });

  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final String currency;

  static const fallback = UserPreferences(
    hapticsEnabled: true,
    notificationsEnabled: true,
    currency: 'EUR',
  );

  UserPreferences copyWith({
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    String? currency,
  }) =>
      UserPreferences(
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        currency: currency ?? this.currency,
      );
}

/// State notifier pour les préférences. Reflète les valeurs persistées
/// dans SharedPreferences et les met à jour à chaque toggle.
class PreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    final repo = ref.watch(preferencesRepositoryProvider).value;
    if (repo == null) return UserPreferences.fallback;
    return UserPreferences(
      hapticsEnabled: repo.hapticsEnabled,
      notificationsEnabled: repo.notificationsEnabled,
      currency: repo.currency,
    );
  }

  Future<void> setHapticsEnabled(bool value) async {
    final repo = ref.read(preferencesRepositoryProvider).value;
    if (repo == null) return;
    await repo.setHapticsEnabled(value);
    state = state.copyWith(hapticsEnabled: value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final repo = ref.read(preferencesRepositoryProvider).value;
    if (repo == null) return;
    await repo.setNotificationsEnabled(value);
    state = state.copyWith(notificationsEnabled: value);
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, UserPreferences>(
  PreferencesNotifier.new,
);
