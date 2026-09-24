class AppointmentModel {
  final String? id;
  final String customerId;
  final String salonId;
  final String? staffId;
  final String serviceId;
  final DateTime appointmentDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String status;
  final String? notes;

  AppointmentModel({
    this.id,
    required this.customerId,
    required this.salonId,
    this.staffId,
    required this.serviceId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.status = 'pending',
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      customerId: json['customer_id'],
      salonId: json['salon_id'],
      staffId: json['staff_id'],
      serviceId: json['service_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'salon_id': salonId,
      'staff_id': staffId,
      'service_id': serviceId,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'total_price': totalPrice,
      'status': status,
      'notes': notes,
    };
  }
}
