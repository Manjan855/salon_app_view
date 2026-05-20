// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class DateTimeUtils {
//   // Format date to string
//   static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
//     return DateFormat(pattern).format(date);
//   }

//   // Format time to string
//   static String formatTime(TimeOfDay time, {String pattern = 'h:mm a'}) {
//     final now = DateTime.now();
//     final dateTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );
//     return DateFormat(pattern).format(dateTime);
//   }

//   // Format date and time together
//   static String formatDateTime(
//     DateTime dateTime, {
//     String pattern = 'MMM dd, yyyy • h:mm a',
//   }) {
//     return DateFormat(pattern).format(dateTime);
//   }

//   // Parse time string to TimeOfDay
//   static TimeOfDay parseTime(String timeString) {
//     try {
//       // Try 12-hour format first (e.g., "02:30 PM")
//       final format12 = DateFormat('h:mm a');
//       final dateTime = format12.parse(timeString);
//       return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
//     } catch (e) {
//       try {
//         // Try 24-hour format (e.g., "14:30")
//         final format24 = DateFormat('HH:mm');
//         final dateTime = format24.parse(timeString);
//         return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
//       } catch (e) {
//         // Default fallback
//         return const TimeOfDay(hour: 9, minute: 0);
//       }
//     }
//   }

//   // Parse date string to DateTime
//   static DateTime? parseDate(
//     String dateString, {
//     String pattern = 'yyyy-MM-dd',
//   }) {
//     try {
//       return DateFormat(pattern).parse(dateString);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Get available dates (next 7 days)
//   static List<DateTime> getAvailableDates({int days = 7}) {
//     final List<DateTime> dates = [];
//     final now = DateTime.now();

//     // Start from today
//     final today = DateTime(now.year, now.month, now.day);

//     for (int i = 0; i < days; i++) {
//       dates.add(today.add(Duration(days: i)));
//     }

//     return dates;
//   }

//   // Get available dates with formatted strings
//   static List<Map<String, dynamic>> getAvailableDatesWithFormat({
//     int days = 7,
//   }) {
//     final List<Map<String, dynamic>> dates = [];
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);

//     for (int i = 0; i < days; i++) {
//       final date = today.add(Duration(days: i));
//       dates.add({
//         'date': date,
//         'dayName': getShortDayName(date),
//         'dayNumber': date.day.toString(),
//         'month': getShortMonthName(date),
//         'isToday': isToday(date),
//         'isTomorrow': isTomorrow(date),
//         'fullDate': formatDate(date),
//       });
//     }

//     return dates;
//   }

//   // Check if date is available (not past)
//   static bool isDateAvailable(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final compareDate = DateTime(date.year, date.month, date.day);

//     // Date is available if it's today or future
//     return compareDate.isAfter(today.subtract(const Duration(days: 1)));
//   }

//   // Check if time slot is available (not past for today)
//   static bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
//     if (!isDateAvailable(date)) {
//       return false;
//     }

//     if (isToday(date)) {
//       final now = DateTime.now();
//       final currentHour = now.hour;
//       final currentMinute = now.minute;

//       if (time.hour < currentHour) {
//         return false;
//       }

//       if (time.hour == currentHour && time.minute < currentMinute) {
//         return false;
//       }
//     }

//     return true;
//   }

//   // Get day name
//   static String getDayName(DateTime date) {
//     return DateFormat('EEEE').format(date);
//   }

//   // Get short day name
//   static String getShortDayName(DateTime date) {
//     return DateFormat('EEE').format(date);
//   }

//   // Get day with suffix (1st, 2nd, 3rd, 4th)
//   static String getDayWithSuffix(DateTime date) {
//     final day = date.day;
//     if (day >= 11 && day <= 13) {
//       return '${day}th';
//     }
//     switch (day % 10) {
//       case 1:
//         return '${day}st';
//       case 2:
//         return '${day}nd';
//       case 3:
//         return '${day}rd';
//       default:
//         return '${day}th';
//     }
//   }

//   // Get month name
//   static String getMonthName(DateTime date) {
//     return DateFormat('MMMM').format(date);
//   }

//   // Get short month name
//   static String getShortMonthName(DateTime date) {
//     return DateFormat('MMM').format(date);
//   }

//   // Check if date is today
//   static bool isToday(DateTime date) {
//     final now = DateTime.now();
//     return date.year == now.year &&
//         date.month == now.month &&
//         date.day == now.day;
//   }

//   // Check if date is tomorrow
//   static bool isTomorrow(DateTime date) {
//     final tomorrow = DateTime.now().add(const Duration(days: 1));
//     return date.year == tomorrow.year &&
//         date.month == tomorrow.month &&
//         date.day == tomorrow.day;
//   }

//   // Get difference in days between two dates
//   static int getDaysDifference(DateTime from, DateTime to) {
//     final fromDate = DateTime(from.year, from.month, from.day);
//     final toDate = DateTime(to.year, to.month, to.day);
//     return toDate.difference(fromDate).inDays;
//   }

//   // Add days to date
//   static DateTime addDays(DateTime date, int days) {
//     return DateTime(date.year, date.month, date.day).add(Duration(days: days));
//   }

//   // Get start of day
//   static DateTime getStartOfDay(DateTime date) {
//     return DateTime(date.year, date.month, date.day, 0, 0, 0);
//   }

//   // Get end of day
//   static DateTime getEndOfDay(DateTime date) {
//     return DateTime(date.year, date.month, date.day, 23, 59, 59);
//   }

//   // Get time slots between start and end time
//   static List<TimeOfDay> getTimeSlots({
//     required TimeOfDay start,
//     required TimeOfDay end,
//     int intervalMinutes = 30,
//   }) {
//     final List<TimeOfDay> slots = [];

//     int startMinutes = start.hour * 60 + start.minute;
//     int endMinutes = end.hour * 60 + end.minute;

//     for (
//       int minutes = startMinutes;
//       minutes <= endMinutes;
//       minutes += intervalMinutes
//     ) {
//       final hour = minutes ~/ 60;
//       final minute = minutes % 60;
//       slots.add(TimeOfDay(hour: hour, minute: minute));
//     }

//     return slots;
//   }

//   // Get formatted time slots as strings
//   static List<String> getFormattedTimeSlots({
//     required TimeOfDay start,
//     required TimeOfDay end,
//     int intervalMinutes = 30,
//   }) {
//     final slots = getTimeSlots(
//       start: start,
//       end: end,
//       intervalMinutes: intervalMinutes,
//     );

//     return slots.map((slot) => formatTime(slot)).toList();
//   }

//   // Format duration in minutes to readable string
//   static String formatDuration(int minutes) {
//     if (minutes < 60) {
//       return '$minutes min';
//     }

//     final hours = minutes ~/ 60;
//     final remainingMinutes = minutes % 60;

//     if (remainingMinutes == 0) {
//       return '$hours hour${hours > 1 ? 's' : ''}';
//     }

//     return '$hours hr $remainingMinutes min';
//   }

//   // Parse duration string to minutes
//   static int parseDuration(String durationString) {
//     if (durationString.contains('min')) {
//       final minutes = int.tryParse(durationString.replaceAll('min', '').trim());
//       return minutes ?? 0;
//     }

//     if (durationString.contains('hr')) {
//       final parts = durationString.split('hr');
//       final hours = int.tryParse(parts[0].trim()) ?? 0;

//       if (parts.length > 1 && parts[1].contains('min')) {
//         final minutes =
//             int.tryParse(parts[1].replaceAll('min', '').trim()) ?? 0;
//         return hours * 60 + minutes;
//       }

//       return hours * 60;
//     }

//     return 0;
//   }

//   // Get relative time string (e.g., "2 days ago", "tomorrow")
//   static String getRelativeTimeString(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 365) {
//       return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
//     }
//     if (difference.inDays > 30) {
//       return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
//     }
//     if (difference.inDays > 7) {
//       return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
//     }
//     if (difference.inDays > 0) {
//       return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
//     }
//     if (difference.inHours > 0) {
//       return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
//     }
//     if (difference.inMinutes > 0) {
//       return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
//     }

//     return 'Just now';
//   }

//   // Combine date and time to DateTime
//   static DateTime combineDateTime(DateTime date, TimeOfDay time) {
//     return DateTime(date.year, date.month, date.day, time.hour, time.minute);
//   }

//   // Check if two dates are the same
//   static bool isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }

//   // Get week number of the year
//   static int getWeekNumber(DateTime date) {
//     final firstDayOfYear = DateTime(date.year, 1, 1);
//     final daysDifference = date.difference(firstDayOfYear).inDays;
//     return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
//   }
// }
