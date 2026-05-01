import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

/// Repository d'auth — singleton via Riverpod.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream d'évènements d'auth (Supabase). Émet à chaque sign-in / sign-out /
/// refresh de token.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Session courante. Recompute à chaque event d'auth.
/// `null` = non connecté, non `null` = connecté.
final currentSessionProvider = Provider<Session?>((ref) {
  // On `watch` authStateProvider pour invalider à chaque event,
  // mais on lit la session via le repo (source de vérité).
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentSession;
});
