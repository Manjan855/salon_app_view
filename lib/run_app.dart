import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/features/onboarding/screens/splash_screen.dart';
import 'package:salon_app_view/features/onboarding/screens/onboarding_screen.dart';
import 'package:salon_app_view/features/auth/screens/login_screen.dart';
import 'package:salon_app_view/features/auth/screens/register_screen.dart';
import 'package:salon_app_view/features/auth/screens/personal_info.dart';
import 'package:salon_app_view/features/auth/screens/location_screen.dart';
import 'package:salon_app_view/features/home/home_screen.dart';
import 'package:salon_app_view/features/salon_detail/salon_info.dart';
import 'package:salon_app_view/features/appointment/appointment_screen.dart';
import 'package:salon_app_view/features/profile/profile_screen.dart';
import 'package:salon_app_view/features/favourites/favourites_screen.dart';
import 'package:salon_app_view/features/notifications/notifications_screen.dart';

import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/providers/salon_provider.dart';
import 'package:salon_app_view/shared/providers/booking_provider.dart';
import 'package:salon_app_view/shared/providers/theme_provider.dart';

class RunApp extends StatelessWidget {
  const RunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SalonProvider()..fetchSalons()),
        ChangeNotifierProvider(create: (_) => BookingProvider()..fetchUserBookings()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Salon App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: RouteName.splash,
            routes: {
              RouteName.splash: (context) => const SplashScreen(),
              RouteName.onboard: (context) => const OnboardingScreen(),
              RouteName.login: (context) => const LoginScreen(),
              RouteName.signUp: (context) => const RegisterScreen(),
              RouteName.persona: (context) => const PersonalInfo(),
              RouteName.location: (context) => const LocationScreen(),
              RouteName.home: (context) => const SalonHomeScreen(),
              RouteName.salonInfo: (context) => const SalonInfoScreen(),
              RouteName.myBookings: (context) => const MyAppointmentsScreen(),
              RouteName.profile: (context) => const ProfileScreen(),
              RouteName.notifications: (context) => const NotificationsScreen(),
              RouteName.wishlist: (context) => const FavouritesScreen(),
            },
          );
        },
      ),
    );
  }
}
