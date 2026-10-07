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
