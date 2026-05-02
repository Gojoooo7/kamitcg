import 'package:shared_preferences/shared_preferences.dart';

/// Préférences utilisateur non-sensibles (toggles UI, devise par défaut).
///
/// **Pas** pour les tokens ou les données financières — ces données vont dans
/// `flutter_secure_storage` (cf. [SecureLocalStorage]). Ici on stocke juste
/// les choix d'interface qui doivent persister entre les sessions.
class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kHaptics = 'kamitcg.prefs.haptics_enabled';
  static const _kNotifications = 'kamitcg.prefs.notifications_enabled';
  static const _kCurrency = 'kamitcg.prefs.currency';

  bool get hapticsEnabled => _prefs.getBool(_kHaptics) ?? true;
  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  String get currency => _prefs.getString(_kCurrency) ?? 'EUR';

  Future<void> setHapticsEnabled(bool value) =>
      _prefs.setBool(_kHaptics, value);
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotifications, value);
  Future<void> setCurrency(String value) => _prefs.setString(_kCurrency, value);
}
