// Smoke tests for the startup-failure screen. `main()` renders this when the
// compile-time Supabase config is missing or invalid, so it must build with no
// platform channels, network, or `Supabase.initialize()`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/app_env.dart';
import 'package:salon_app_view/main.dart';

void main() {
  testWidgets('StartupErrorApp shows the reason and the run command', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupErrorApp(message: 'Missing config'));

    expect(find.text('Could not start the app'), findsOneWidget);
    expect(find.text('Missing config'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(
      find.text('flutter run --dart-define-from-file=config/supabase.json'),
      findsOneWidget,
    );
  });

  testWidgets('StartupErrorApp surfaces AppEnv.missingConfigHint', (
    tester,
  ) async {
    await tester.pumpWidget(StartupErrorApp(message: AppEnv.missingConfigHint));

    expect(find.text(AppEnv.missingConfigHint), findsOneWidget);
  });
}
