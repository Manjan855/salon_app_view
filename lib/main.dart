import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:salon_app_view/run_app.dart';

void main() async {
  // Required for interacting with native platform channels before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your Production Database Engine
  await Supabase.initialize(
    // FIXED: Removed '/rest/v1/' from the end of the URL string
    url: 'https://zhnfhkahspsqbfjetwlt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpobmZoa2Foc3BzcWJmamV0d2x0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNjQ2NTEsImV4cCI6MjA5NjY0MDY1MX0.drQfrWdbHdKZHVRythoc8WWSyUNEx7j23Zb_JG_mPn4',
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
