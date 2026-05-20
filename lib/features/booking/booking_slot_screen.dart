import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────
const kPurpleDark = Color(0xFF2D1B6B);
const kPurpleMid = Color(0xFF3D2080);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);
const kDisabled = Color(0xFF4A4A6A);

// ─── Barber Model ─────────────────────────────────────────
class BarberModel {
  final String name;
  final List<String> timeSlots;
  String? selectedSlot;

  BarberModel({required this.name, required this.timeSlots, this.selectedSlot});
}

// ─── Booking Slots Screen ─────────────────────────────────
class BookingSlotsScreen extends StatefulWidget {
  final String salonName;
  final String selectedSlot; // e.g. "9 AM to 10 AM"

  const BookingSlotsScreen({
    super.key,
    required this.salonName,
    required this.selectedSlot,
  });

  @override
  State<BookingSlotsScreen> createState() => _BookingSlotsScreenState();
}

class _BookingSlotsScreenState extends State<BookingSlotsScreen> {
  // Which barber card is expanded
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

  // Slots that are unavailable (grayed out)
  final Set<String> _unavailableSlots = {'9 : 45'};

  // Which barber + slot is confirmed
  int? _confirmedBarberIndex;
  String? _confirmedSlot;

  bool get _canConfirm =>
      _confirmedBarberIndex != null && _confirmedSlot != null;

  @override
  Widget build(BuildContext context) {
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
                        style: const TextStyle(
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
                        style: const TextStyle(
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
                        const Text(
                          'Slot : ',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.selectedSlot,
                          style: const TextStyle(
                            color: kPurpleLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Barbers/Stylists',
                      style: TextStyle(
                        color: kPurpleLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Barber cards ──────────────────────
                    ..._barbers.asMap().entries.map(
                      (e) => _buildBarberCard(e.key, e.value),
                    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: kWhite,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barber Card ───────────────────────────────────────────
  Widget _buildBarberCard(int index, BarberModel barber) {
    final isSelected = _confirmedBarberIndex == index;
    final isExpanded = _expandedBarber == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // ── Barber name button ──────────────────────────
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedBarber = isExpanded ? null : index;
                // Clear slot selection when switching barber
                if (!isExpanded) {
                  _confirmedBarberIndex = null;
                  _confirmedSlot = null;
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

          // ── Time slots (expanded) ───────────────────────
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
                      _confirmedBarberIndex == index && _confirmedSlot == slot;

                  return GestureDetector(
                    onTap: isUnavailable
                        ? null
                        : () {
                            setState(() {
                              _confirmedBarberIndex = index;
                              _confirmedSlot = slot;
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
                    _barbers[_confirmedBarberIndex!].name,
                    style: const TextStyle(color: kTextMuted, fontSize: 12),
                  ),
                  Text(
                    _confirmedSlot!,
                    style: const TextStyle(
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
              onPressed: _canConfirm
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
              child: const Text(
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kPurpleMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              child: const Icon(
                Icons.check_rounded,
                color: kPurpleLight,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
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
              value: _barbers[_confirmedBarberIndex!].name,
            ),
            _SheetRow(label: 'Slot', value: widget.selectedSlot),
            _SheetRow(label: 'Time', value: _confirmedSlot!),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPurpleLight.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
                      Navigator.pop(context);
                      _showBookingSuccess(context);
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

  // ── Booking Success Dialog ────────────────────────────────
  void _showBookingSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: kPurpleMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.salonName}\n${_barbers[_confirmedBarberIndex!].name} · ${widget.selectedSlot}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                      ..pop() // dialog
                      ..popUntil((r) => r.isFirst); // back to home
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
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: kWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
