import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:salon_app_view/app_env.dart';
import 'package:salon_app_view/run_app.dart';

void main() async {
  // Required for interacting with native platform channels before running the app
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (!AppEnv.isConfigured) {
      // Fail fast with an actionable message instead of a cryptic 401 later.
      throw StateError(AppEnv.missingConfigHint);
    }

    // Initialize your Production Database Engine
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (error, stack) {
    // Without this the app would show a blank/black screen and the only clue
    // would be a line in the console. Render the failure instead.
    debugPrint('Startup failed: $error');
    debugPrint('$stack');
    runApp(StartupErrorApp(message: error.toString()));
    return;
  }

  debugRepaintRainbowEnabled = false;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RunApp());
}

/// Shown when the app can't configure Supabase (bad/missing `--dart-define`
/// values, no network on first boot, etc.). Turns the "black screen" into an
/// on-device explanation.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A0B2E),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not start the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SelectableText(
                    'flutter run --dart-define-from-file=config/supabase.json',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFC56AFF),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
