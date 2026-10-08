// Guards the OAuth / PKCE redirect wiring: AppEnv.authRedirectUrl,
// android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist must all
// declare the same scheme + host, otherwise Supabase's browser flows
// (OAuth fallback, magic link, password reset, email confirmation) bounce the
// user to a link nothing on the device can open.
//
// Run with:
//   flutter test test/deep_link_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/app_env.dart';

void main() {
  final uri = Uri.parse(AppEnv.authRedirectUrl);
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  test('authRedirectUrl is a custom-scheme deep link', () {
    // RFC 3986 scheme: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    expect(uri.scheme, matches(RegExp(r'^[a-z][a-z0-9+.-]*$')),
        reason: 'AppEnv.authRedirectUrl must be scheme://host[/path]');
    expect(uri.host, isNotEmpty);
    expect(uri.query, isEmpty,
        reason: 'no query parameters belong in the redirect base URL');
    expect(AppEnv.authRedirectUrl, startsWith('${uri.scheme}://${uri.host}'));
  });

  test('AndroidManifest declares the redirect scheme', () {
    expect(manifest, contains('android:scheme="${uri.scheme}"'),
        reason: 'Android needs a VIEW/BROWSABLE intent-filter for '
            '${AppEnv.authRedirectUrl} or the PKCE ?code= never reaches the app');
    expect(manifest, contains('android:host="${uri.host}"'),
        reason: 'the intent-filter host must match AppEnv.authRedirectUrl');
    expect(manifest, contains('android.intent.action.VIEW'));
    expect(manifest, contains('android.intent.category.BROWSABLE'));
  });

  test('Info.plist declares the redirect scheme', () {
    expect(plist, contains('<key>CFBundleURLTypes</key>'),
        reason: 'iOS needs CFBundleURLTypes or iOS opens Safari and strands '
            'the user after the OAuth round-trip');
    expect(plist, contains('<string>${uri.scheme}</string>'),
        reason: 'CFBundleURLSchemes must list "${uri.scheme}" to match '
            'AppEnv.authRedirectUrl');
  });
}
