// Verifies the compile-time config wiring that `lib/main.dart` depends on:
// the JSON keys in config/supabase.json must match the names read by AppEnv,
// or the app throws StateError(missingConfigHint) at startup.
//
// To also assert that AppEnv actually resolved the file, run with the flag:
//   flutter test test/config_test.dart --dart-define-from-file=config/supabase.json
// Without the flag the file-shape checks still run and the AppEnv cross-check
// is skipped, so a plain `flutter test` stays green.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final configFile = File('config/supabase.json');

  test(
    'config/supabase.json names match AppEnv',
    () {
      final cfg =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;

      // The JSON must define exactly what AppEnv looks up.
      expect(
        cfg.keys,
        containsAll(['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY']),
      );

      // Guard against ever shipping a legacy JWT or a secret key by mistake.
      expect(cfg['SUPABASE_URL'], startsWith('https://'));
      expect(cfg['SUPABASE_PUBLISHABLE_KEY'], startsWith('sb_publishable_'));
      expect(cfg['SUPABASE_PUBLISHABLE_KEY'], isNot(contains('eyJ')));

      // AppEnv reads --dart-define values at compile time; only cross-check it
      // when the test was run with the flag.
      if (AppEnv.isConfigured) {
        expect(AppEnv.supabaseUrl, cfg['SUPABASE_URL']);
        expect(AppEnv.supabasePublishableKey, cfg['SUPABASE_PUBLISHABLE_KEY']);
      }
    },
    skip: configFile.existsSync()
        ? false
        : 'config/supabase.json is not present (copy the example first)',
  );
}
