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
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True once both values were injected at build/run time.
  static const bool isConfigured =
      supabaseUrl != '' && supabaseAnonKey != '';

  /// Human-readable guidance used when [isConfigured] is false.
  static const String missingConfigHint =
      'SUPABASE_URL / SUPABASE_ANON_KEY were not injected.\n'
      'Run the app with:\n'
      '  flutter run --dart-define-from-file=config/supabase.json\n'
      '(copy config/supabase.example.json to config/supabase.json first)';
}
