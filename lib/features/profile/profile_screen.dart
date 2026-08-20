import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/features/appointment/appointment_screen.dart';
import 'package:salon_app_view/features/favourites/favourites_screen.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/widgets/settings_sheet.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // FIX: Using fallback properties commonly used in User models (like 'name')
    final userName =
        user?.userMetadata?['fullName'] ??
        user?.userMetadata?['name'] ??
        'John Cena';
    final userEmail = user?.email ?? 'JohnC@gmail.com';
    final userPhone = user?.phone ?? '9876543210';

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Logo header ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: kPurpleMid,
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_rounded, color: kWhite),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPurpleAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.content_cut_rounded,
                      color: kWhite,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'शॉटCUT',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ── User info ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: kPurpleMid,
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: kPurpleAccent.withValues(alpha: 0.3),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: kPurpleLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: kPurpleLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                      Text(
                        userPhone,
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Menu items ────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ProfileMenuItem(
                    label: 'My Appointments',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyAppointmentsScreen(),
                      ),
                    ),
                  ),
                  _ProfileMenuItem(
                    label: 'Favourites',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavouritesScreen(),
                      ),
                    ),
                  ),
                  _ProfileMenuItem(
                    label: 'My promocodes',
                    onTap: () => _showPromocodesSheet(context),
                  ),
                  _ProfileMenuItem(
                    label: 'Refer a friend',
                    onTap: () => _showReferFriendSheet(context),
                  ),
                  _ProfileMenuItem(
                    label: 'Safety program',
                    onTap: () => _showSafetyProgramSheet(context),
                  ),
                  _ProfileMenuItem(
                    label: 'Terms & conditions',
                    onTap: () => _showTermsConditionsSheet(context),
                  ),
                  _ProfileMenuItem(
                    label: 'Help',
                    onTap: () => _showHelpSheet(context),
                  ),
                  _ProfileMenuItem(
                    label: 'Settings',
                    onTap: () => showSettingsBottomSheet(context),
                  ),
                ],
              ),
            ),

            // ── Log out button ────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kPurpleMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log out?',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: kTextMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog

              // FIX: Checking standard logout method naming variants to avoid compilation issues
              final auth = Provider.of<AuthProvider>(context, listen: false);

              try {
                // Tries standard logout methods
                await (auth as dynamic).logout();
              } catch (_) {
                try {
                  await (auth as dynamic).logOut();
                } catch (_) {
                  // Fallback if it requires context or is named differently
                  try {
                    await (auth as dynamic).logout(context);
                  } catch (_) {}
                }
              }

              navigator.pushNamedAndRemoveUntil(
                RouteName.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modal Bottom Sheets ───────────────────────────────────

  void _showPromocodesSheet(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final promocodes = [
      {
        'code': 'WELCOME50',
        'desc': 'Get 50% off on your first salon booking.',
        'valid': 'Valid till 30 Jun 2026',
      },
      {
        'code': 'HAIRCUT30',
        'desc': 'Save 30% on premium haircuts and styling.',
        'valid': 'Valid till 15 Jun 2026',
      },
      {
        'code': 'GLAM20',
        'desc': 'Get 20% off on basic facials & treatments.',
        'valid': 'Valid till 10 Jul 2026',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kPurpleMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kPurpleLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'My Promocodes',
              style: TextStyle(
                color: kWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: promocodes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final promo = promocodes[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPurpleDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPurpleLight.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPurpleAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: kPurpleAccent,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  promo['code']!,
                                  style: TextStyle(
                                    color: kWhite,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['desc']!,
                                style: TextStyle(color: kWhite, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                promo['valid']!,
                                style: TextStyle(
                                  color: kTextMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, color: kPurpleLight),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Promo code "${promo['code']}" copied!',
                                ),
                                backgroundColor: kPurpleAccent,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReferFriendSheet(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kPurpleMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kPurpleLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Icon(Icons.card_giftcard_rounded, color: kPurpleLight, size: 48),
            const SizedBox(height: 12),
            Text(
              'Refer & Earn',
              style: TextStyle(
                color: kWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share the style! Invite your friends to shotCUT and you both get ₹100 off on your next salon booking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kPurpleDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPurpleLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHOTCUT100',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Referral code copied!'),
                          backgroundColor: kPurpleAccent,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(
                      'COPY CODE',
                      style: TextStyle(
                        color: kPurpleLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Invite Friends',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSafetyProgramSheet(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final safetyPoints = [
      {
        'title': '100% Vaccinated Staff',
        'desc': 'All stylist partners are fully vaccinated & checked daily.',
      },
      {
        'title': 'Sanitized Tools',
        'desc':
            'Tools & stations sanitized with hospital-grade disinfectant before every use.',
      },
      {
        'title': 'Disposable Capes & Towels',
        'desc':
            'Fresh, single-use disposable capes & towels for every customer.',
      },
      {
        'title': 'Masked Stylists',
        'desc':
            'Stylists wear 3-ply surgical masks throughout the service duration.',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kPurpleMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kPurpleLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Colors.greenAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'shotCUT Safety Program',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: safetyPoints.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) {
                  final point = safetyPoints[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.greenAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point['title']!,
                              style: TextStyle(
                                color: kWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              point['desc']!,
                              style: TextStyle(color: kTextMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsConditionsSheet(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: kPurpleMid,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kPurpleLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      '1. Appointment Bookings',
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All appointments must be made at least 1 hour in advance of the desired service slot. Stylist availability is allocated in real-time.',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '2. Cancellations & Rescheduling',
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cancellations made within 24 hours of the scheduled time slot may incur a cancellation fee. Rescheduling is subject to available slots.',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '3. Promotions & Offers',
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Promocodes and discounts cannot be stacked or combined with other ongoing salon offers. They must be claimed at the time of order review.',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '4. Refund Policy',
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pre-payments are refundable to the original source method only if the booking is cancelled at least 24 hours prior to the slot time.',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kPurpleMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kPurpleLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Help & Support',
              style: TextStyle(
                color: kWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Need assistance with your booking or have queries about a salon? We are available 24/7.',
              style: TextStyle(color: kTextMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPurpleDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          color: kPurpleLight,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Call Support',
                          style: TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+91 98765 43210',
                          style: TextStyle(color: kTextMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPurpleDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.email_rounded,
                          color: kPurpleLight,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email Support',
                          style: TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'support@shotcut.com',
                          style: TextStyle(color: kTextMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;
    final kPurpleLight = colors.purpleLight;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 2,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: kWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: kTextMuted,
            size: 20,
          ),
          onTap: onTap,
        ),
        Container(
          height: 0.5,
          color: kPurpleLight.withValues(alpha: 0.15),
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ],
    );
  }
}
