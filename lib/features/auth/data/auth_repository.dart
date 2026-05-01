import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';

/// Wrapper minimaliste autour de Supabase Auth.
///
/// V1 = magic link uniquement (Google + Apple seront ajoutés ensemble en V2,
/// cf. App Store guideline 4.8).
class AuthRepository {
  AuthRepository();

  GoTrueClient get _auth => supabase.auth;

  /// Stream d'événements auth (signedIn, signedOut, tokenRefreshed, …).
  /// À écouter via `authStateProvider`.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Session courante (null si non connecté).
  Session? get currentSession => _auth.currentSession;

  /// User courant (null si non connecté).
  User? get currentUser => _auth.currentUser;

  /// Envoie un magic link à [email]. Le serveur Supabase répond OK même si
  /// l'email n'existe pas (anti-énumération). Le redirect_to doit être
  /// whitelisté côté dashboard.
  Future<void> sendMagicLink(String email) {
    return _auth.signInWithOtp(
      email: email,
      emailRedirectTo: authRedirectUrl,
    );
  }

  /// Sign-out global. La purge du secure storage est gérée par le SDK
  /// (notre [SecureLocalStorage] est invoqué dans `removePersistedSession`).
  Future<void> signOut() => _auth.signOut();
}
