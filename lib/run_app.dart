import 'dart:async';

import 'package:app_links/app_links.dart';
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
import 'package:salon_app_view/shared/models/payment_model.dart';

import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/providers/salon_provider.dart';
import 'package:salon_app_view/shared/providers/booking_provider.dart';
import 'package:salon_app_view/shared/providers/payment_provider.dart';
import 'package:salon_app_view/shared/providers/theme_provider.dart';

/// Lets the deep-link handler surface a SnackBar even though it sits above the
/// MaterialApp in the widget tree.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RunApp extends StatelessWidget {
  const RunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SalonProvider()..fetchSalons()),
        ChangeNotifierProvider(
          create: (_) => BookingProvider()..fetchUserBookings(),
        ),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      // Handles `salonappview://payment-result?…` and kicks the app to refresh.
      child: const _PaymentLinkHandler(child: _ThemedApp()),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Salon App',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
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
    );
  }
}

/// Listens for the payment provider's return deep link and reflects the result
/// in the UI: refresh the user's bookings, then tell them what happened.
class _PaymentLinkHandler extends StatefulWidget {
  const _PaymentLinkHandler({required this.child});

  final Widget child;

  @override
  State<_PaymentLinkHandler> createState() => _PaymentLinkHandlerState();
}

class _PaymentLinkHandlerState extends State<_PaymentLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleUri(Uri uri) {
    final result = PaymentResult.fromUri(uri);
    if (result == null) return; // not ours (auth links are handled by Supabase)

    // The Edge Function already wrote the new status; pull it in.
    if (result.bookingId != null && result.paid) {
      context.read<BookingProvider>().fetchUserBookings();
    }

    final messenger = rootScaffoldMessengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          result.paid
              ? 'Payment successful — your booking is confirmed.'
              : 'Payment was not completed${result.reason != null ? ' (${result.reason})' : ''}.',
        ),
        backgroundColor: result.paid ? const Color(0xFF2E7D32) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
