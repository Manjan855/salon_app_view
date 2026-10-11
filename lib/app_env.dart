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

  /// Deep link the payments Edge Function bounces the browser back to after an
  /// eSewa / Khalti round-trip. Its `?status=paid|failed&provider=…&booking_id=…`
  /// params are read by the app-links listener in `run_app.dart`.
  ///
  /// Like [authRedirectUrl], the scheme must be declared in the Android
  /// manifest and iOS Info.plist. The host does NOT need to be on Supabase's
  /// allow list — providers redirect to the *function* callback, which then
  /// 302s to this link.
  static const String paymentResultUrl = 'salonappview://payment-result';

  /// Google OAuth **web** client ID (a.k.a. the "server client ID"). Android's
  /// Credential Manager flow returns an ID token whose audience (`aud`) is this
  /// client, and `signInWithIdToken` verifies it. Required on Android when the
  /// app does not ship a `google-services.json` — this project does not.
  ///
  /// Injected with the same `--dart-define-from-file=config/supabase.json` as
  /// the Supabase keys. See `docs/google_signin.md` for the Google Cloud setup.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Google OAuth **iOS** client ID. The iOS plugin reads it from
  /// `Info.plist` (`GIDClientID`) and its reversed form
  /// (`com.googleusercontent.apps.…`) from `CFBundleURLSchemes`; this constant
  /// exists so a test can assert the plist stays in sync with the build config.
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// True when a Google web/server client ID was injected.
  static const bool hasGoogleServerClientId = googleServerClientId != '';

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
