import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/features/salon_detail/salon_reviews_screen.dart';
import 'package:salon_app_view/shared/models/booking_model.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/providers/booking_provider.dart';
import 'package:salon_app_view/shared/providers/review_provider.dart';

const kRed = Color(0xFFE53935);

// ─── Appointment Model ────────────────────────────────────
class AppointmentModel {
  final String id;
  final String salonId;
  final String salonName;
  final String location;
  final String date;
  final String time;
  final String status; // ongoing | completed | cancelled
  final String otp;

  /// RLS only accepts a review when the booking is actually `completed` or
  /// `confirmed`; a past-but-still-`pending` visit must not offer the button.
  final bool canReview;

  const AppointmentModel({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.location,
    required this.date,
    required this.time,
    required this.status,
    required this.otp,
    this.canReview = false,
  });
}

// ─── My Appointments Screen ───────────────────────────────
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  AppThemeColors get colors => AppThemeColors.of(context);

  final Map<String, bool> _otpVisible = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    // Pull the live rows (the provider is also refreshed after a payment).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingProvider>().fetchUserBookings();
      final userId = context.read<AuthProvider>().user?.id;
      context.read<ReviewProvider>().ensureReviewedLoaded(userId: userId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _formatDate(DateTime d) =>
      '${_two(d.day)} ${_month(d.month)} ${d.year}';

  static String _month(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];

  static String _formatTime(String hhmmss) {
    final parts = hhmmss.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  static AppointmentModel _toAppointment(BookingModel b) {
    String status;
    if (b.isCancelled) {
      status = 'cancelled';
    } else if (b.isCompleted || !b.bookingDateTime.isAfter(DateTime.now())) {
      status = 'completed';
    } else {
      status = 'ongoing';
    }

    return AppointmentModel(
      id: b.id,
      salonId: b.salonId,
      salonName: b.salonName ?? 'Salon',
      location: b.salonLocation ?? '',
      date: _formatDate(b.bookingDate),
      time: '${_formatTime(b.startTime)} to ${_formatTime(b.endTime)}',
      status: status,
      otp: b.otpCode ?? '------',
      canReview: b.status == 'completed' || b.status == 'confirmed',
    );
  }

  List<AppointmentModel> _filtered(
    List<AppointmentModel> all,
    String status,
  ) =>
      all.where((a) => a.status == status).toList();

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final bookings = context.watch<BookingProvider>().bookings;
    final appointments = bookings.map(_toAppointment).toList();

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
                  if (Navigator.canPop(context))
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
                    'My Appointments',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: kPurpleMid,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: kPurpleAccent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: kWhite,
                  unselectedLabelColor: kTextMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab views ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(appointments, 'ongoing'),
                  _buildList(appointments, 'completed'),
                  _buildList(appointments, 'cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AppointmentModel> all, String status) {
    final list = _filtered(all, status);

    final kPurpleLight = colors.purpleLight;
    final kTextMuted = colors.textMuted;
    final kWhite = colors.white;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: kTextMuted.withOpacity(0.4),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No ${status[0].toUpperCase()}${status.substring(1)} appointments',
              style: TextStyle(color: kTextMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final apt = list[i];
        final showOtp = _otpVisible[apt.id] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: colors.purpleMid,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kPurpleLight.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Appointment info ──────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              apt.salonName,
                              style: TextStyle(
                                color: kPurpleLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (apt.location.isNotEmpty) ...[
                            Text(
                              ' | ',
                              style: TextStyle(color: kTextMuted, fontSize: 13),
                            ),
                            Flexible(
                              child: Text(
                                apt.location,
                                style: TextStyle(
                                  color: kTextMuted,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date & Time',
                        style: TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${apt.date} | ${apt.time}',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Action buttons ────────────────────
                if (status == 'ongoing') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showCancelDialog(context, apt),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: kPurpleLight.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: kTextMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Show OTP button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() => _otpVisible[apt.id] = !showOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.purpleAccent,
                              foregroundColor: kWhite,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              showOtp ? 'Hide OTP' : 'Show OTP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── OTP display ───────────────────
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: Column(
                        children: [
                          Container(
                            height: 0.5,
                            color: kPurpleLight.withOpacity(0.2),
                            margin: const EdgeInsets.only(bottom: 14),
                          ),
                          Text(
                            'OTP',
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: apt.otp
                                .split('')
                                .map((digit) => _OtpBox(digit))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: showOtp
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
                if (status == 'completed' && apt.canReview)
                  _buildRateRow(context, apt),
              ],
            ),
          ),
        );
      },
    );
  }

  /// "Rate this salon" / "Reviewed" action for a completed appointment.
  Widget _buildRateRow(BuildContext context, AppointmentModel apt) {
    final reviewed = context.watch<ReviewProvider>().isBookingReviewed(apt.id);
    final kPurpleLight = colors.purpleLight;
    final kPurpleAccent = colors.purpleAccent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: reviewed ? null : () => _showReviewSheet(context, apt),
          icon: Icon(
            reviewed ? Icons.check_circle_rounded : Icons.star_outline_rounded,
            size: 16,
            color: reviewed ? Colors.greenAccent : kPurpleAccent,
          ),
          label: Text(
            reviewed ? 'Reviewed' : 'Rate this salon',
            style: TextStyle(
              color: reviewed ? Colors.greenAccent : kPurpleAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: kPurpleLight.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReviewSheet(
    BuildContext context,
    AppointmentModel apt,
  ) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to leave a review.')),
      );
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WriteReviewSheet(
        salonId: apt.salonId,
        salonName: apt.salonName,
        userId: userId,
        bookingId: apt.id,
      ),
    );

    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your review has been posted.')),
      );
    }
  }

  void _showCancelDialog(BuildContext context, AppointmentModel apt) {
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: kPurpleMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kPurpleLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.cancel_outlined, color: kRed, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Cancel appointment?',
              style: TextStyle(
                color: kWhite,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${apt.salonName} · ${apt.date}',
              style: TextStyle(color: kTextMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Cancellations within 24 hours may incur a fee.',
              style: TextStyle(color: kTextMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPurpleLight.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Keep',
                      style: TextStyle(color: kTextMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final messenger = ScaffoldMessenger.of(context);
                      await context
                          .read<BookingProvider>()
                          .cancelBooking(apt.id);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Appointment cancelled.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Yes, Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

// ─── OTP Box Widget ───────────────────────────────────────
class _OtpBox extends StatelessWidget {
  const _OtpBox(this.digit);
  final String digit;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;

    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: kPurpleDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPurpleLight.withOpacity(0.4), width: 1),
      ),
      child: Center(
        child: Text(
          digit,
          style: TextStyle(
            color: kWhite,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
