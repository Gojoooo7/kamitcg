import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_storage.dart';

/// Deep link de callback magic link / OAuth.
/// Doit être whitelisté côté Supabase Dashboard → Authentication → URL Configuration.
const String authRedirectUrl = 'kamitcg://auth/callback';

/// Initialise le client Supabase global.
/// Appelé une fois depuis [main] avant `runApp`.
Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL et SUPABASE_ANON_KEY doivent être renseignés dans .env',
    );
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: const SecureLocalStorage(),
      pkceAsyncStorage: SecureGotrueAsyncStorage(),
    ),
  );
}

/// Raccourci vers le client Supabase global.
SupabaseClient get supabase => Supabase.instance.client;
