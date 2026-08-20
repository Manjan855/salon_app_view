import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 2), _navigateNext);
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    // 1. Check if context is still valid before retrieving the Provider
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 2. Removed 'await authProvider.loadUser();' since user state is handled synchronously
    if (seenOnboarding) {
      if (authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, RouteName.home);
      } else {
        Navigator.pushReplacementNamed(context, RouteName.login);
      }
    } else {
      Navigator.pushReplacementNamed(context, RouteName.onboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: const Color(0xFFC56AFF),
                child: SvgPicture.asset(
                  "assets/logo.svg",
                  height: 100,
                  width: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
