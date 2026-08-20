// import 'package:flutter/material.dart';

// class BookingModel {
//   final String id;
//   final String salonId;
//   final String salonName;
//   final String serviceId;
//   final String serviceName;
//   final String? stylistId;
//   final String? stylistName;
//   final DateTime date;
//   final TimeOfDay time;
//   final double totalAmount;
//   final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

//   BookingModel({
//     required this.id,
//     required this.salonId,
//     required this.salonName,
//     required this.serviceId,
//     required this.serviceName,
//     this.stylistId,
//     this.stylistName,
//     required this.date,
//     required this.time,
//     required this.totalAmount,
//     required this.status,
//   });

//   String get formattedDate {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   String get formattedTime {
//     return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
//   }
// }
class BookingModel {
  final String id;
  final String userId;
  final String salonId;
  final DateTime bookingDateTime;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'completed'

  BookingModel({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.bookingDateTime,
    required this.totalPrice,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      salonId: json['salon_id'] as String,
      bookingDateTime: DateTime.parse(json['booking_date_time'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'salon_id': salonId,
      'booking_date_time': bookingDateTime.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
    };
  }
}
