import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/portfolio/presentation/home_shell.dart';
import '../theme/app_colors.dart';

/// Garde de routes racine — bascule entre [LoginScreen] et [HomeShell] selon
/// l'état d'auth Supabase. Pendant la restoration de session (au démarrage),
/// affiche un splash minimal pour éviter le flash login → home.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // Le stream d'auth émet immédiatement la session restaurée (ou null).
      // Tant qu'il n'a rien émis, on est en bootstrap → splash.
      loading: _Splash.new,
      error: (_, _) => const LoginScreen(),
      data: (_) {
        final session = ref.watch(currentSessionProvider);
        if (session == null) return const LoginScreen();
        return const HomeShell();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.bg0,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      ),
    );
  }
}
