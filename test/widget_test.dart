import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamitcg/core/constants/strings.dart';
import 'package:kamitcg/core/theme/app_theme.dart';
import 'package:kamitcg/features/portfolio/presentation/home_shell.dart';

void main() {
  testWidgets('App boots and renders Dashboard greeting in French', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(Strings.welcomeBack), findsOneWidget);
    expect(find.text(Strings.userDisplayName), findsOneWidget);
    expect(find.text(Strings.portfolioValueLabel), findsOneWidget);
  });
}
