// Verifies the compile-time config wiring that `lib/main.dart` depends on:
// the JSON keys in config/supabase.json must match the names read by AppEnv,
// or the app throws StateError(missingConfigHint) at startup.
//
// Run with:
//   flutter test test/config_test.dart --dart-define-from-file=config/supabase.json
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppEnv reads config/supabase.json names correctly', () {
    final cfg = jsonDecode(File('config/supabase.json').readAsStringSync())
        as Map<String, dynamic>;

    // The JSON must define exactly what AppEnv looks up.
    expect(cfg.keys,
        containsAll(['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY']));
    expect(AppEnv.supabaseUrl, cfg['SUPABASE_URL']);
    expect(AppEnv.supabasePublishableKey, cfg['SUPABASE_PUBLISHABLE_KEY']);
    expect(AppEnv.isConfigured, isTrue,
        reason: 'AppEnv.missingConfigHint: ${AppEnv.missingConfigHint}');

    // Guard against ever shipping a legacy JWT or a secret key by mistake.
    expect(AppEnv.supabaseUrl, startsWith('https://'));
    expect(AppEnv.supabasePublishableKey, startsWith('sb_publishable_'));
    expect(AppEnv.supabasePublishableKey, isNot(contains('eyJ')));
  });
}
