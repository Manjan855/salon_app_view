// Guards the Google Sign-In wiring: the client ID must be injected via
// config/supabase.json (read by AppEnv), never hardcoded in source; and when a
// real client ID is injected the iOS Info.plist must stay in sync with it.
//
// To also run the Info.plist cross-check:
//   flutter test test/google_signin_test.dart --dart-define-from-file=config/supabase.json
// Without the flag those checks are skipped, so a plain `flutter test` is green.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/app_env.dart';

void main() {
  final providerSrc =
      File('lib/shared/providers/auth_provider.dart').readAsStringSync();
  final exampleCfg = File('config/supabase.example.json');

  test('auth_provider never hardcodes a Google client ID', () {
    expect(
      providerSrc,
      isNot(contains('.apps.googleusercontent.com')),
      reason: 'the client ID belongs in config/supabase.json (AppEnv), not source',
    );
  });

  test('auth_provider reads the server client ID from AppEnv', () {
    expect(providerSrc, contains('AppEnv.googleServerClientId'));
    expect(
      providerSrc,
      contains('hasGoogleServerClientId'),
      reason: 'a build without the client ID must fail with a clear message, '
          'not a cryptic plugin error',
    );
  });

  test('auth_provider surfaces GoogleSignInException instead of swallowing it', () {
    expect(
      providerSrc,
      contains('on GoogleSignInException'),
      reason: 'native Google failures must not collapse into a generic message',
    );
    expect(
      providerSrc,
      contains('GoogleSignInExceptionCode.clientConfigurationError'),
      reason: 'the package/SHA-1 misconfiguration must name its fix',
    );
  });

  test('the config example documents both Google keys', () {
    final cfg =
        jsonDecode(exampleCfg.readAsStringSync()) as Map<String, dynamic>;
    expect(cfg.keys, contains('GOOGLE_SERVER_CLIENT_ID'));
    expect(cfg.keys, contains('GOOGLE_IOS_CLIENT_ID'));
  });

  test(
    'iOS Info.plist matches the injected Google client IDs',
    () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      // The app's own deep link must survive any Google edit.
      expect(plist, contains('<string>salonappview</string>'));

      if (AppEnv.googleServerClientId.isEmpty &&
          AppEnv.googleIosClientId.isEmpty) {
        return; // nothing injected — nothing to cross-check
      }

      if (AppEnv.googleIosClientId.isNotEmpty) {
        final reversed = 'com.googleusercontent.apps.'
            '${AppEnv.googleIosClientId.replaceFirst('.apps.googleusercontent.com', '')}';
        expect(
          plist,
          contains(AppEnv.googleIosClientId),
          reason: 'uncomment + set GIDClientID to the injected '
              'GOOGLE_IOS_CLIENT_ID (see docs/google_signin.md)',
        );
        expect(
          plist,
          contains(reversed),
          reason: 'add "$reversed" to CFBundleURLSchemes',
        );
      }
    },
    skip:
        AppEnv.googleServerClientId.isEmpty && AppEnv.googleIosClientId.isEmpty
            ? 'no Google client ID injected (run with '
                '--dart-define-from-file=config/supabase.json)'
            : false,
  );
}
