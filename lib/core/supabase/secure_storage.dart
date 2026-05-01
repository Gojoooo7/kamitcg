import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend [FlutterSecureStorage] commun aux deux storages Supabase.
/// - iOS : Keychain (`first_unlock_this_device` — nécessite un déverrouillage
///   de l'appareil après reboot, mais pas à chaque session).
/// - Android : Keystore via le backend par défaut (chiffrement sym AES-GCM
///   géré par flutter_secure_storage 10.x).
const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// Persistance de la session Supabase.
///
/// CLAUDE.md interdit `SharedPreferences` pour les tokens — on utilise
/// `flutter_secure_storage` (Keychain iOS / Keystore Android via EncryptedSharedPreferences).
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  static const String _key = 'kamitcg.supabase.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _secureStorage.containsKey(key: _key);

  @override
  Future<String?> accessToken() async {
    final raw = await _secureStorage.read(key: _key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final session = map['currentSession'] as Map<String, dynamic>?;
      return session?['access_token'] as String?;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() => _secureStorage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secureStorage.write(key: _key, value: persistSessionString);
}

/// Persistance du code verifier PKCE.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) =>
      _secureStorage.read(key: key);

  @override
  Future<void> removeItem({required String key}) =>
      _secureStorage.delete(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _secureStorage.write(key: key, value: value);
}
