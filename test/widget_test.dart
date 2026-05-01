import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamitcg/core/constants/strings.dart';
import 'package:kamitcg/core/theme/app_theme.dart';
import 'package:kamitcg/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders the brand block in French',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(Strings.authTitle), findsOneWidget);
    expect(find.text(Strings.authTagline), findsOneWidget);
    expect(find.text(Strings.authSendMagicLink), findsOneWidget);
  });
}
