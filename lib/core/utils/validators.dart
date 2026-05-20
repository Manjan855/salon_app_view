// import 'package:flutter/material.dart';


// class Helpers {
//   // Show snackbar
//   static void showSnackBar(
//     BuildContext context,
//     String message, {
//     bool isError = false,
//     Duration duration = const Duration(seconds: 2),
//   }) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: duration,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   // Show loading dialog
//   static void showLoadingDialog(
//     BuildContext context, {
//     String message = 'Loading...',
//   }) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               Text(message),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Hide loading dialog
//   static void hideLoadingDialog(BuildContext context) {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     }
//   }

//   // Format currency
//   static String formatCurrency(double amount) {
//     return '\$${amount.toStringAsFixed(2)}';
//   }

//   // Format date
//   static String formatDate(DateTime date) {
//     return DateFormat('MMM dd, yyyy').format(date);
//   }

//   // Format time
//   static String formatTime(TimeOfDay time) {
//     final now = DateTime.now();
//     final dateTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );
//     return DateFormat('h:mm a').format(dateTime);
//   }

//   // Get time slots
//   static List<TimeOfDay> getTimeSlots({
//     required TimeOfDay startTime,
//     required TimeOfDay endTime,
//     int intervalMinutes = 30,
//   }) {
//     final List<TimeOfDay> slots = [];

//     int startMinutes = startTime.hour * 60 + startTime.minute;
//     int endMinutes = endTime.hour * 60 + endTime.minute;

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

//   // Validate email
//   static bool isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     return emailRegex.hasMatch(email);
//   }

//   // Validate phone
//   static bool isValidPhone(String phone) {
//     final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
//     return phoneRegex.hasMatch(phone);
//   }

//   // Capitalize first letter
//   static String capitalize(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1).toLowerCase();
//   }

//   // Truncate text
//   static String truncateText(String text, int maxLength) {
//     if (text.length <= maxLength) return text;
//     return '${text.substring(0, maxLength)}...';
//   }

//   // Get days difference
//   static int getDaysDifference(DateTime from, DateTime to) {
//     return to.difference(from).inDays;
//   }

//   // Check if date is today
//   static bool isToday(DateTime date) {
//     final now = DateTime.now();
//     return date.year == now.year &&
//         date.month == now.month &&
//         date.day == now.day;
//   }

//   // Get greeting message based on time
//   static String getGreeting() {
//     final hour = DateTime.now().hour;

//     if (hour < 12) {
//       return 'Good Morning';
//     } else if (hour < 17) {
//       return 'Good Afternoon';
//     } else {
//       return 'Good Evening';
//     }
//   }
// }
