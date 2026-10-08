/// Compile-time configuration, injected with `--dart-define`.
///
/// Never hardcode secrets in `main.dart` again. Run with:
///
/// ```sh
/// flutter run --dart-define-from-file=config/supabase.json
/// flutter build apk --dart-define-from-file=config/supabase.json
/// ```
///
/// The real `config/supabase.json` is gitignored; commit only
/// `config/supabase.example.json` (placeholders).
class AppEnv {
  const AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The publishable (`sb_publishable_...`) key — safe to ship in the binary.
  /// It only reaches what Row Level Security allows; never a secret key here.
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Deep link Supabase bounces the browser back to after an OAuth /
  /// magic-link / password-reset round-trip (`scheme://host`).
  ///
  /// The exact same scheme + host MUST be declared in all three places:
  /// * `android/app/src/main/AndroidManifest.xml` — VIEW / BROWSABLE
  ///   intent-filter
  /// * `ios/Runner/Info.plist` — `CFBundleURLTypes`
  /// * the Supabase dashboard — Authentication → URL Configuration →
  ///   Redirect URLs (Supabase rejects anything not on that allow list)
  ///
  /// `test/deep_link_test.dart` fails if the declarations drift apart.
  static const String authRedirectUrl = 'salonappview://auth-callback';

  /// True once both values were injected at build/run time.
  static const bool isConfigured =
      supabaseUrl != '' && supabasePublishableKey != '';

  /// Human-readable guidance used when [isConfigured] is false.
  static const String missingConfigHint =
      'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY were not injected.\n'
      'Run the app with:\n'
      '  flutter run --dart-define-from-file=config/supabase.json\n'
      '(copy config/supabase.example.json to config/supabase.json first)';
}
