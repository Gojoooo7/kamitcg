import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/profile_providers.dart';

/// Wrapper autour de [HapticFeedback] qui respecte le toggle utilisateur
/// (Profil → Préférences → Retours haptiques).
///
/// Utilisation : `Haptics.light(ref)` au lieu de `HapticFeedback.lightImpact()`.
class Haptics {
  const Haptics._();

  /// Tap léger sur un élément interactif (sélection dans une liste, toggle).
  static void selection(WidgetRef ref) {
    if (_enabled(ref)) HapticFeedback.selectionClick();
  }

  /// Confirmation d'une action utilisateur de niveau bas (ouverture d'écran,
  /// envoi d'un magic link, etc.).
  static void light(WidgetRef ref) {
    if (_enabled(ref)) HapticFeedback.lightImpact();
  }

  /// Événement notable mais non destructif (carte trouvée, ajout, switch UI).
  static void medium(WidgetRef ref) {
    if (_enabled(ref)) HapticFeedback.mediumImpact();
  }

  /// Action conclusive ou destructive (insertion en BDD, suppression confirmée).
  static void heavy(WidgetRef ref) {
    if (_enabled(ref)) HapticFeedback.heavyImpact();
  }

  static bool _enabled(WidgetRef ref) =>
      ref.read(preferencesProvider).hapticsEnabled;
}
