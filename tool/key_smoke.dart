// Smoke test: proves the Supabase Dart SDK can reach the project with the
// publishable key from config/supabase.json (which is gitignored — this script
// contains no credentials of its own).
// Run: dart run tool/key_smoke.dart
import 'dart:convert';
import 'dart:io';

import 'package:salon_app_view/app_env.dart';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final cfg = jsonDecode(File('config/supabase.json').readAsStringSync())
      as Map<String, dynamic>;
  final url = cfg['SUPABASE_URL'] as String;
  final key = cfg['SUPABASE_PUBLISHABLE_KEY'] as String;
  final isPublishable = key.startsWith('sb_publishable_');
  stdout.writeln('key format: ${isPublishable ? "publishable OK" : "UNEXPECTED"}');
  // String.fromEnvironment is empty under plain `dart run` (no --dart-define).
  if (AppEnv.supabasePublishableKey.isNotEmpty) {
    stdout.writeln('AppEnv wired: ${AppEnv.supabasePublishableKey == key ? "matches config file" : "DIFFERS from config file"}');
  } else {
    stdout.writeln('AppEnv wired: not injected (run via flutter for --dart-define)');
  }

  final client = SupabaseClient(url, key);

  for (final table in [
    'salons',
    'services',
    'coupons',
    'profiles_public',
    'bookings',
  ]) {
    try {
      final rows = await client.from(table).select('*').limit(1);
      stdout.writeln('$table -> ${rows.length} row(s)');
    } catch (e) {
      stdout.writeln('$table -> ERROR: $e');
    }
  }

  final session = client.auth.currentSession;
  stdout.writeln(
      'auth client: ${session == null ? "signed out (expected)" : "signed in"}');
  client.dispose();
}
