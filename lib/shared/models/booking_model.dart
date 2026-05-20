import 'package:flutter/material.dart';

class BookingModel {
  final String id;
  final String salonId;
  final String salonName;
  final String serviceId;
  final String serviceName;
  final String? stylistId;
  final String? stylistName;
  final DateTime date;
  final TimeOfDay time;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  BookingModel({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.serviceId,
    required this.serviceName,
    this.stylistId,
    this.stylistName,
    required this.date,
    required this.time,
    required this.totalAmount,
    required this.status,
  });

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
