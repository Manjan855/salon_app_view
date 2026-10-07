import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:salon_app_view/app_env.dart';
import 'package:salon_app_view/run_app.dart';

void main() async {
  // Required for interacting with native platform channels before running the app
  WidgetsFlutterBinding.ensureInitialized();

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

  debugRepaintRainbowEnabled = false;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RunApp());
}
