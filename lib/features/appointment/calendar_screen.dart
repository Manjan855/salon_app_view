import 'package:flutter/material.dart';

const kPurpleDark = Color(0xFF1A0A3B);
const kPurpleMid = Color(0xFF2D1B6B);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(2022, 8);
  DateTime? _selectedDate = DateTime(2022, 8, 15);
  int _bottomIndex = 0;

  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);

  int get _firstWeekday =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: kWhite,
                        size: 24,
                      ),
                    ),
                  ),
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Calendar card ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: kPurpleMid,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Month navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month - 1,
                            );
                          }),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: kTextMuted,
                            size: 22,
                          ),
                        ),
                        Text(
                          '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month + 1,
                            );
                          }),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: kTextMuted,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Day headers
                    Row(
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map(
                            (d) => Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                color: kPurpleAccent.withOpacity(0.6),
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      color: kWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),

                    // Day grid
                    _buildDayGrid(),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Continue button (shows when date selected) ──
            if (_selectedDate != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.maybePop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurpleAccent,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue with ${_selectedDate!.day} ${_monthName(_selectedDate!.month)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDayGrid() {
    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < _firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= _daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday =
          date.day == 16 &&
          date.month == _focusedMonth.month; // highlight today

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? kPurpleAccent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? kWhite
                      : isToday
                      ? kPurpleLight
                      : kWhite,
                  fontSize: 13,
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }

  Widget _buildBottomNav() {
    final items = [
      Icons.calendar_month_rounded,
      Icons.home_rounded,
      Icons.search_rounded,
    ];
    return Container(
      height: 56 + MediaQuery.of(context).padding.bottom,
      color: kPurpleMid,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final selected = e.key == _bottomIndex;
          return GestureDetector(
            onTap: () => setState(() => _bottomIndex = e.key),
            child: Icon(
              e.value,
              color: selected ? kPurpleAccent : kTextMuted,
              size: 24,
            ),
          );
        }).toList(),
      ),
    );
  }
}
