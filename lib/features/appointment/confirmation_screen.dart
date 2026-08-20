import 'package:flutter/material.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/features/appointment/appointment_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  final String salonName;
  final String salonLocation;

  const ConfirmationScreen({
    super.key,
    required this.salonName,
    required this.salonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: kWhite,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    'Success',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Salon header ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: kPurpleMid,
              child: Column(
                children: [
                  Text(
                    salonName,
                    style: TextStyle(
                      color: kPurpleLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: kPurpleLight,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        salonLocation,
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Success content ──────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: kPurpleAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: kPurpleAccent, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: kPurpleLight,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Congrats your seat\nhas booked!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your appointment has been confirmed.\nSee you soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Buttons ──────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurpleAccent,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate directly to My Appointments on top of Home Screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyAppointmentsScreen(),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kPurpleLight.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'View Appointment',
                        style: TextStyle(
                          color: kTextMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
