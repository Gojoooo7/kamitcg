import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_root.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await initSupabase();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ProviderScope(child: KamiTcgApp()));
}

class KamiTcgApp extends StatelessWidget {
  const KamiTcgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KamiTCG',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      home: const AppRoot(),
    );
  }
}
