import 'package:flutter/material.dart';
import 'package:salon_app_view/features/booking/booking_slot_screen.dart';

// ─── Colors ───────────────────────────────────────────────
const kPurpleDark = Color(0xFF2D1B6B);
const kPurpleMid = Color(0xFF3D2080);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);

// ─── Time Slot Range Model ────────────────────────────────
class SlotRange {
  final String label; // e.g. "8 AM to 11 AM"
  final List<String> slots; // e.g. ["8 AM to 9 AM", "9 AM to 10 AM", ...]
  bool isExpanded;

  SlotRange({
    required this.label,
    required this.slots,
    this.isExpanded = false,
  });
}

// ─── Slots Availability Screen ────────────────────────────
class SlotsAvailabilityScreen extends StatefulWidget {
  final String salonName;

  const SlotsAvailabilityScreen({super.key, required this.salonName});

  @override
  State<SlotsAvailabilityScreen> createState() =>
      _SlotsAvailabilityScreenState();
}

class _SlotsAvailabilityScreenState extends State<SlotsAvailabilityScreen> {
  final List<SlotRange> _ranges = [
    SlotRange(
      label: '8 AM to 11 AM',
      slots: ['8 AM to 9 AM', '9 AM to 10 AM', '10 AM to 11 AM'],
    ),
    SlotRange(
      label: '11 AM to 2 PM',
      slots: ['11 AM to 12 PM', '12 PM to 1 PM', '1 PM to 2 PM'],
    ),
    SlotRange(
      label: '2 PM to 5 PM',
      slots: ['2 PM to 3 PM', '3 PM to 4 PM', '4 PM to 5 PM'],
    ),
    SlotRange(
      label: '5 PM to 8 PM',
      slots: ['5 PM to 6 PM', '6 PM to 7 PM', '7 PM to 8 PM'],
    ),
  ];

  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Salon image ──────────────────────
                    _buildSalonImage(),
                    // ── Availability banner ──────────────
                    //  _buildAvailability(),
                    _buildBanner(),
                    // ── Slot ranges ──────────────────────
                    ..._ranges.asMap().entries.map(
                      (e) => _buildSlotRange(e.key, e.value),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          const SizedBox(width: 16),
          Text(
            widget.salonName,
            style: const TextStyle(
              color: kPurpleLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=600',
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 250,
            color: kPurpleAccent,
            child: const Icon(Icons.store, color: kWhite, size: 60),
          ),
          // errorBuilder: (_, __, ___) => Container(
          //   height: 250,
          //   color: kPurpleAccent,
          //   child: const Icon(Icons.store, color: kWhite, size: 60),
          // ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kPurpleAccent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPurpleAccent.withOpacity(0.5), width: 0.5),
        ),
        child: const Text(
          'Availability of slots for the Day?',
          style: TextStyle(
            color: kPurpleLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Widget _buildAvailability() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

  //       decoration: BoxDecoration(
  //         color: kPurpleAccent.withValues(alpha: 0.3),
  //         borderRadius: BorderRadius.circular(10),
  //         border: Border.all(color: kTextMuted, width: 0.5),
  //       ),
  //       child: const Center(
  //         child: Text(
  //           "Availability of the slot",
  //           style: TextStyle(
  //             color: kPurpleLight,
  //             fontSize: 13,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSlotRange(int index, SlotRange range) {
    return Column(
      children: [
        // ── Range row (always visible) ──────────────────
        GestureDetector(
          onTap: () {
            setState(() {
              for (int i = 0; i < _ranges.length; i++) {
                _ranges[i].isExpanded = (i == index && !range.isExpanded);
              }
            });
          },

          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: range.isExpanded ? kPurpleMid : kPurpleDark,
              borderRadius: BorderRadius.circular(range.isExpanded ? 12 : 0),
              border: Border(
                bottom: BorderSide(
                  color: kPurpleLight.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  range.label,
                  style: TextStyle(
                    color: range.isExpanded ? kPurpleLight : kWhite,
                    fontSize: 14,
                    fontWeight: range.isExpanded
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                AnimatedRotation(
                  turns: range.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: kPurpleLight,
                    size: 30,
                  ),
                ),
                // AnimatedRotation(
                //   turns: range.isExpanded ? 0.25 : 0,
                //   duration: const Duration(milliseconds: 200),
                //   child: const Icon(
                //     Icons.chevron_right_rounded,
                //     color: kTextMuted,
                //     size: 20,
                //   ),
                // ),
              ],
            ),
          ),
        ),

        // ── Expanded sub-slots ───────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: kPurpleMid,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: range.slots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSlot = slot);
                    // Navigate to booking slots
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingSlotsScreen(
                          salonName: widget.salonName,
                          selectedSlot: slot,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPurpleAccent.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: kPurpleLight.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: isSelected ? kPurpleLight : kWhite,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: range.isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
