import 'package:flutter/material.dart';
import 'dart:math';
import 'package:salon_app_view/core/theme/app_theme.dart';

const kRed = Color(0xFFE53935);

// ─── Appointment Model ────────────────────────────────────
class AppointmentModel {
  final String salonName;
  final String location;
  final String date;
  final String time;
  final String status; // ongoing | completed | cancelled
  final String otp;

  const AppointmentModel({
    required this.salonName,
    required this.location,
    required this.date,
    required this.time,
    required this.status,
    required this.otp,
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

  final List<AppointmentModel> _appointments = [
    const AppointmentModel(
      salonName: 'Prince Hair Salon',
      location: 'Near Town Hall',
      date: '12 Oct 2022',
      time: '9:00AM to 9:30AM',
      status: 'ongoing',
      otp: '9371',
    ),
    const AppointmentModel(
      salonName: 'CD Hair Salon',
      location: 'Near Cinema Hall',
      date: '5 Oct 2022',
      time: '11:00AM to 11:30AM',
      status: 'completed',
      otp: '4829',
    ),
    const AppointmentModel(
      salonName: 'Affinity Salon',
      location: 'Near Town Hall',
      date: '1 Oct 2022',
      time: '3:00PM to 3:30PM',
      status: 'cancelled',
      otp: '1234',
    ),
  ];

  final Map<String, bool> _otpVisible = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AppointmentModel> _filtered(String status) =>
      _appointments.where((a) => a.status == status).toList();

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
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
                  _buildList('ongoing'),
                  _buildList('completed'),
                  _buildList('cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String status) {
    final list = _filtered(status);

    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kTextMuted = colors.textMuted;
    final kWhite = colors.white;
    final kPurpleAccent = colors.purpleAccent;

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
        final showOtp = _otpVisible[apt.otp] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: kPurpleMid,
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
                                setState(() => _otpVisible[apt.otp] = !showOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPurpleAccent,
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

                if (status == 'completed')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurpleAccent.withOpacity(0.2),
                          foregroundColor: kPurpleLight,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Rate & Review',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, AppointmentModel apt) {
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      Navigator.pop(context);
                      setState(
                        () => _appointments.firstWhere((a) => a.otp == apt.otp),
                        // In real app, update status via provider
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
