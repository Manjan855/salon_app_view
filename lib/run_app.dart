import 'package:flutter/material.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
//import 'package:salon_app_view/features/home/home_screen.dart';
import 'package:salon_app_view/features/salon_detail/salots_screen.dart';

// Fixed class name (should be MyApp or SalonApp instead of RunApp)
class RunApp extends StatelessWidget {
  const RunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SlotsAvailabilityScreen(salonName: 'Bob Salon'),
      title: 'Salon App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      initialRoute: RouteName.splash,
    );
  }
}
