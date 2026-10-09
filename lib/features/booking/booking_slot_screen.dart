import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/features/explore/payment_screen.dart';
import 'package:salon_app_view/features/salon_detail/reviews_screen.dart';
import 'package:salon_app_view/repositories/salon_repositories.dart';
import 'package:salon_app_view/shared/models/available_slot.dart';
import 'package:salon_app_view/shared/models/booking_model.dart';
import 'package:salon_app_view/shared/models/staff_model.dart';
import 'package:salon_app_view/shared/providers/booking_provider.dart';

// ─── Barber Model (mock fallback) ─────────────────────────
class BarberModel {
  final String name;
  final List<String> timeSlots;
  String? selectedSlot;

  BarberModel({required this.name, required this.timeSlots, this.selectedSlot});
}

/// Nepal is UTC+05:45 with no DST.
DateTime _nepalToday() {
  final n = DateTime.now().toUtc().add(AvailableSlot.nepalOffset);
  return DateTime(n.year, n.month, n.day);
}

// ─── Booking Slots Screen ─────────────────────────────────
class BookingSlotsScreen extends StatefulWidget {
  final String salonName;

  /// e.g. "9 AM to 10 AM" (mock) or the outer slot label (real).
  final String selectedSlot;

  final String salonLocation;

  /// When set, the screen works against real backend data and writes a
  /// `public.bookings` row; when null it keeps the original demo behaviour.
  final String? salonId;
  final DateTime? date;
  final AvailableSlot? slot;
  final int durationMinutes;
  final double totalAmount;
  final List<OrderedService> services;

  const BookingSlotsScreen({
    super.key,
    required this.salonName,
    required this.selectedSlot,
    this.salonLocation = '',
    this.salonId,
    this.date,
    this.slot,
    this.durationMinutes = 30,
    this.totalAmount = 0,
    this.services = const [],
  });

  @override
  State<BookingSlotsScreen> createState() => _BookingSlotsScreenState();
}

class _BookingSlotsScreenState extends State<BookingSlotsScreen> {
  AppThemeColors get colors => AppThemeColors.of(context);
  final SalonRepository _repo = SalonRepository();

  bool get _isReal => widget.salonId != null;

  // ── Real state ────────────────────────────────────────────
  List<StaffModel> _staff = [];
  bool _loadingStaff = false;
  String? _staffError;
  final Map<String, List<AvailableSlot>> _staffSlots = {};
  final Set<String> _loadingStaffSlots = {};
  final Map<String, String> _staffSlotErrors = {};

  String? _confirmedStaffId;
  String? _confirmedStaffName;
  AvailableSlot? _confirmedSlot;
  bool _saving = false;

  // ── Mock state ────────────────────────────────────────────
  int? _expandedBarber;
  final List<BarberModel> _barbers = [
    BarberModel(
      name: 'Barber 1',
      timeSlots: ['9 : 00', '9 : 15', '9 : 30', '9 : 45'],
    ),
    BarberModel(
      name: 'Barber 2',
      timeSlots: ['9 : 00', '9 : 15', '9 : 30', '9 : 45'],
    ),
    BarberModel(name: 'Barber 3', timeSlots: ['9 : 00', '9 : 15', '9 : 30']),
  ];
  final Set<String> _unavailableSlots = {'9 : 45'};
  int? _confirmedBarberIndex;
  String? _confirmedMockSlot;

  DateTime get _date => widget.date ?? widget.slot?.startLocal ?? _nepalToday();

  bool get _canConfirm {
    if (_isReal) return _confirmedStaffId != null && _confirmedSlot != null;
    return _confirmedBarberIndex != null && _confirmedMockSlot != null;
  }

  @override
  void initState() {
    super.initState();
    if (_isReal) _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loadingStaff = true;
      _staffError = null;
    });
    try {
      final staff = await _repo.getStaffBySalon(widget.salonId!);
      if (!mounted) return;
      setState(() => _staff = staff);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _staffError = e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _loadingStaff = false);
    }
  }

  Future<void> _loadStaffSlots(StaffModel staff) async {
    if (_staffSlots.containsKey(staff.id) ||
        _loadingStaffSlots.contains(staff.id)) {
      return;
    }
    setState(() {
      _loadingStaffSlots.add(staff.id);
      _staffSlotErrors.remove(staff.id);
    });
    try {
      final slots = await _repo.getAvailableSlots(
        salonId: widget.salonId!,
        date: _date,
        staffId: staff.id,
        durationMinutes: widget.durationMinutes,
      );
      if (!mounted) return;
      setState(() => _staffSlots[staff.id] = slots);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _staffSlotErrors[staff.id] =
            e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _loadingStaffSlots.remove(staff.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;
    final kPurpleLight = colors.purpleLight;
    final kTextMuted = colors.textMuted;

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────
            _buildAppBar(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Salon name ────────────────────────
                    Center(
                      child: Text(
                        widget.salonName,
                        style: TextStyle(
                          color: kPurpleLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Availability of Barbers as per your\nselected services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kTextMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Selected slot chip ────────────────
                    Row(
                      children: [
                        Text(
                          'Slot : ',
                          style: TextStyle(
                            color: colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.selectedSlot,
                            style: TextStyle(
                              color: kPurpleLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Barbers/Stylists',
                      style: TextStyle(
                        color: kPurpleLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isReal) ..._buildRealStaff() else ..._buildMockBarbers(),
                  ],
                ),
              ),
            ),

            // ── Confirm button ───────────────────────────
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    final kWhite = colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Icon(
              Icons.arrow_back_rounded,
              color: kWhite,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ── Real staff list ───────────────────────────────────────
  List<Widget> _buildRealStaff() {
    final kTextMuted = colors.textMuted;

    if (_loadingStaff) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_staffError != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                _staffError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadStaff, child: const Text('Retry')),
            ],
          ),
        ),
      ];
    }
    if (_staff.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'No stylists available for this salon yet.',
              style: TextStyle(color: kTextMuted, fontSize: 13),
            ),
          ),
        ),
      ];
    }
    return _staff.map(_buildStaffCard).toList();
  }

  Widget _buildStaffCard(StaffModel staff) {
    final isSelected = _confirmedStaffId == staff.id;
    final isExpanded = isSelected ||
        (_confirmedStaffId == null && _expandedBarber == _staffIndex(staff));

    final kPurpleAccent = colors.purpleAccent;
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedBarber =
                    isExpanded ? null : _staffIndex(staff);
                if (!isExpanded) {
                  _confirmedStaffId = null;
                  _confirmedStaffName = null;
                  _confirmedSlot = null;
                }
              });
              if (!isExpanded) _loadStaffSlots(staff);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isSelected ? kPurpleAccent.withOpacity(0.3) : kPurpleMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? kPurpleAccent
                      : isExpanded
                      ? kPurpleLight.withOpacity(0.5)
                      : kPurpleLight.withOpacity(0.15),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  staff.name,
                  style: TextStyle(
                    color: isSelected ? kPurpleLight : kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPurpleMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kPurpleLight.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: _buildStaffSlotsBody(staff),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSlotsBody(StaffModel staff) {
    final kTextMuted = colors.textMuted;

    if (_loadingStaffSlots.contains(staff.id)) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_staffSlotErrors.containsKey(staff.id)) {
      return Text(
        _staffSlotErrors[staff.id]!,
        style: TextStyle(color: kTextMuted, fontSize: 12),
      );
    }
    final slots = _staffSlots[staff.id] ?? const <AvailableSlot>[];
    if (slots.isEmpty) {
      return Text(
        'No open slots for this stylist on that day.',
        style: TextStyle(color: kTextMuted, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSlotSelected =
            _confirmedStaffId == staff.id && _confirmedSlot?.start == slot.start;
        return GestureDetector(
          onTap: () {
            setState(() {
              _confirmedStaffId = staff.id;
              _confirmedStaffName = staff.name;
              _confirmedSlot = slot;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSlotSelected ? colors.purpleAccent : colors.purpleDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSlotSelected
                    ? colors.purpleAccent
                    : colors.purpleLight.withOpacity(0.3),
                width: isSlotSelected ? 1.5 : 0.5,
              ),
            ),
            child: Text(
              slot.startLabel,
              style: TextStyle(
                color: isSlotSelected ? colors.white : colors.textMuted,
                fontSize: 13,
                fontWeight: isSlotSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  int _staffIndex(StaffModel staff) => _staff.indexOf(staff);

  // ── Mock barbers ──────────────────────────────────────────
  List<Widget> _buildMockBarbers() {
    return _barbers
        .asMap()
        .entries
        .map((e) => _buildBarberCard(e.key, e.value))
        .toList();
  }

  Widget _buildBarberCard(int index, BarberModel barber) {
    final isSelected = _confirmedBarberIndex == index;
    final isExpanded = _expandedBarber == index;

    final kPurpleAccent = colors.purpleAccent;
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kDisabled = colors.disabled;
    final kPurpleDark = colors.purpleDark;
    final kTextMuted = colors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedBarber = isExpanded ? null : index;
                if (!isExpanded) {
                  _confirmedBarberIndex = null;
                  _confirmedMockSlot = null;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isSelected ? kPurpleAccent.withOpacity(0.3) : kPurpleMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? kPurpleAccent
                      : isExpanded
                      ? kPurpleLight.withOpacity(0.5)
                      : kPurpleLight.withOpacity(0.15),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  barber.name,
                  style: TextStyle(
                    color: isSelected ? kPurpleLight : kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPurpleMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kPurpleLight.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: barber.timeSlots.map((slot) {
                  final isUnavailable = _unavailableSlots.contains(slot);
                  final isSlotSelected =
                      _confirmedBarberIndex == index && _confirmedMockSlot == slot;

                  return GestureDetector(
                    onTap: isUnavailable
                        ? null
                        : () {
                            setState(() {
                              _confirmedBarberIndex = index;
                              _confirmedMockSlot = slot;
                              barber.selectedSlot = slot;
                            });
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isUnavailable
                            ? kDisabled.withOpacity(0.3)
                            : isSlotSelected
                            ? kPurpleAccent
                            : kPurpleDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUnavailable
                              ? kDisabled
                              : isSlotSelected
                              ? kPurpleAccent
                              : kPurpleLight.withOpacity(0.3),
                          width: isSlotSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isUnavailable
                              ? kDisabled
                              : isSlotSelected
                              ? kWhite
                              : kTextMuted,
                          fontSize: 13,
                          fontWeight: isSlotSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ── Confirm Button ────────────────────────────────────────
  Widget _buildConfirmButton(BuildContext context) {
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kTextMuted = colors.textMuted;
    final kPurpleAccent = colors.purpleAccent;
    final kWhite = colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kPurpleMid,
        border: Border(
          top: BorderSide(color: kPurpleLight.withOpacity(0.2), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show selection summary when barber+slot chosen
          if (_canConfirm) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isReal
                        ? (_confirmedStaffName ?? '')
                        : _barbers[_confirmedBarberIndex!].name,
                    style: TextStyle(color: kTextMuted, fontSize: 12),
                  ),
                  Text(
                    _isReal ? (_confirmedSlot?.label ?? '') : _confirmedMockSlot!,
                    style: TextStyle(
                      color: kPurpleLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_canConfirm && !_saving)
                  ? () => _showConfirmationSheet(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canConfirm
                    ? kPurpleAccent
                    : kPurpleAccent.withOpacity(0.4),
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirmation Bottom Sheet ─────────────────────────────
  void _showConfirmationSheet(BuildContext context) {
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kPurpleAccent = colors.purpleAccent;
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
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kPurpleLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Success icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPurpleAccent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: kPurpleAccent, width: 1.5),
              ),
              child: Icon(
                Icons.check_rounded,
                color: kPurpleLight,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Confirm Booking?',
              style: TextStyle(
                color: kWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Summary rows
            _SheetRow(label: 'Salon', value: widget.salonName),
            _SheetRow(
              label: 'Barber',
              value: _isReal
                  ? (_confirmedStaffName ?? '')
                  : _barbers[_confirmedBarberIndex!].name,
            ),
            _SheetRow(label: 'Slot', value: widget.selectedSlot),
            _SheetRow(
              label: 'Time',
              value: _isReal
                  ? (_confirmedSlot?.label ?? '')
                  : _confirmedMockSlot!,
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPurpleLight.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: kTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      if (_isReal) {
                        _saveRealBooking();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentOptionsScreen(
                              salonName: widget.salonName,
                              salonLocation: widget.salonLocation,
                              totalAmount: widget.totalAmount > 0
                                  ? widget.totalAmount
                                  : 150.0,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurpleAccent,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm & Book',
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

  /// Writes `bookings` + `booking_services`, then hands the new `bookingId` to
  /// the payment screen.
  Future<void> _saveRealBooking() async {
    final staffId = _confirmedStaffId;
    final slot = _confirmedSlot;
    final salonId = widget.salonId;
    if (staffId == null || slot == null || salonId == null) return;

    setState(() => _saving = true);

    final lines = widget.services
        .map(
          (s) => BookingServiceLine(
            serviceId: s.serviceId,
            serviceName: s.name,
            unitPrice: s.discountedPrice,
            durationMinutes: s.durationMinutes,
          ),
        )
        .toList();

    final provider = context.read<BookingProvider>();
    final booking = await provider.createBooking(
      salonId: salonId,
      staffId: staffId,
      date: slot.startLocal,
      start: slot.startLocal,
      end: slot.endLocal,
      totalPrice: widget.totalAmount,
      services: lines,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not save the booking.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentOptionsScreen(
          salonName: widget.salonName,
          salonLocation: widget.salonLocation,
          totalAmount: widget.totalAmount,
          bookingId: booking.id,
        ),
      ),
    );
  }
}

// ─── Sheet Summary Row ────────────────────────────────────
class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kTextMuted = colors.textMuted;
    final kWhite = colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kTextMuted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: kWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
