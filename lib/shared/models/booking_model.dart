/// Booking row mapped to the `public.bookings` table.
///
/// Column contract (see supabase/migrations/20261006000001_schema.sql):
///   id, user_id, salon_id, staff_id, booking_date, start_time, end_time,
///   booking_date_time, total_price, status, payment_status, payment_provider,
///   otp_code, notes, cancelled_reason, created_at, updated_at
///
/// `booking_date_time`, `end_time` and `otp_code` are maintained by database
/// triggers, so they are never sent in toJson().
class BookingModel {
  final String id;
  final String userId;
  final String salonId;
  final String? staffId;

  /// Local wall-clock values. `bookingDate` is date-only (time = 00:00);
  /// `startTime` / `endTime` are raw `HH:mm:ss` strings straight from Postgres.
  final DateTime bookingDate;
  final String startTime;
  final String endTime;

  final double totalPrice;
  final String status; // pending | confirmed | completed | cancelled | no_show
  final String paymentStatus; // pending | paid | failed | refunded | expired
  final String? paymentProvider; // cash | esewa | khalti | connect_ips | ime_pay | fonepay

  final String? otpCode;
  final String? notes;
  final String? cancelledReason;
  final DateTime? createdAt;

  /// Denormalised display fields — present only when the repository asks for
  /// `*, salon:salons(name, address, city), staff:staff(name)`. Null on a
  /// plain select.
  final String? salonName;
  final String? salonAddress;
  final String? salonCity;
  final String? staffName;

  /// Salon location for display, falling back across the embedded columns.
  String? get salonLocation {
    if (salonAddress != null && salonAddress!.isNotEmpty) return salonAddress;
    if (salonCity != null && salonCity!.isNotEmpty) return salonCity;
    return null;
  }

  const BookingModel({
    required this.id,
    required this.userId,
    required this.salonId,
    this.staffId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentProvider,
    this.otpCode,
    this.notes,
    this.cancelledReason,
    this.createdAt,
    this.salonName,
    this.salonAddress,
    this.salonCity,
    this.staffName,
  });

  /// Combined local date+time. Derived from booking_date + start_time so the
  /// wall-clock reading is correct in Asia/Kathmandu regardless of the
  /// `timestamptz` offset Supabase returns.
  DateTime get bookingDateTime => DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        _hour(startTime),
        _minute(startTime),
      );

  Duration get duration =>
      DateTime(_hour(endTime), 0, 0, _hour(startTime), _minute(startTime))
          .difference(DateTime(0));

  bool get isActive => status == 'pending' || status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get formattedDate =>
      '${bookingDate.day.toString().padLeft(2, '0')}/'
      '${bookingDate.month.toString().padLeft(2, '0')}/'
      '${bookingDate.year}';

  String get formattedTime {
    final h = _hour(startTime);
    final m = _minute(startTime);
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $suffix';
  }

  static int _hour(String hhmmss) => int.parse(hhmmss.split(':').first);
  static int _minute(String hhmmss) {
    final parts = hhmmss.split(':');
    return parts.length > 1 ? int.parse(parts[1]) : 0;
  }

  /// Convenience constructor for the staging step: takes the picked date and
  /// time separately, exactly as the slot picker produces them.
  factory BookingModel.staged({
    required String userId,
    required String salonId,
    String? staffId,
    required DateTime date,
    required DateTime start,
    required DateTime end,
    required double totalPrice,
    String? notes,
  }) {
    String two(int v) => v.toString().padLeft(2, '0');
    return BookingModel(
      id: '',
      userId: userId,
      salonId: salonId,
      staffId: staffId,
      bookingDate: DateTime(date.year, date.month, date.day),
      startTime: '${two(start.hour)}:${two(start.minute)}:00',
      endTime: '${two(end.hour)}:${two(end.minute)}:00',
      totalPrice: totalPrice,
      notes: notes,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final bookingDate = json['booking_date'] != null
        ? DateTime.parse(json['booking_date'] as String)
        : DateTime.parse(json['booking_date_time'] as String);

    final salonRel = json['salon'];
    final staffRel = json['staff'];

    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      salonId: json['salon_id'] as String,
      staffId: json['staff_id'] as String?,
      bookingDate: DateTime(bookingDate.year, bookingDate.month, bookingDate.day),
      startTime: json['start_time'] as String? ?? '00:00:00',
      endTime: json['end_time'] as String? ?? '00:00:00',
      totalPrice: (json['total_price'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentProvider: json['payment_provider'] as String?,
      otpCode: json['otp_code'] as String?,
      notes: json['notes'] as String?,
      cancelledReason: json['cancelled_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      salonName: salonRel is Map ? salonRel['name'] as String? : null,
      salonAddress: salonRel is Map ? salonRel['address'] as String? : null,
      salonCity: salonRel is Map ? salonRel['city'] as String? : null,
      staffName: staffRel is Map ? staffRel['name'] as String? : null,
    );
  }

  /// Insert payload. Omits id (DB-generated), booking_date_time and otp_code
  /// (trigger-generated), and updated_at (trigger-generated).
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'salon_id': salonId,
        if (staffId != null) 'staff_id': staffId,
        'booking_date': bookingDate.toIso8601String().substring(0, 10),
        'start_time': startTime,
        'end_time': endTime,
        'total_price': totalPrice,
        'status': status,
        'payment_status': paymentStatus,
        if (paymentProvider != null) 'payment_provider': paymentProvider,
        if (notes != null) 'notes': notes,
      };
}

/// One `public.booking_services` line item, written right after the parent
/// booking so the salon knows exactly which services were ordered.
class BookingServiceLine {
  final String? serviceId;
  final String serviceName;
  final double unitPrice;
  final int quantity;
  final int durationMinutes;

  const BookingServiceLine({
    this.serviceId,
    required this.serviceName,
    required this.unitPrice,
    this.quantity = 1,
    this.durationMinutes = 30,
  });

  Map<String, dynamic> toJson(String bookingId) => {
        'booking_id': bookingId,
        if (serviceId != null) 'service_id': serviceId,
        'service_name': serviceName,
        'unit_price': unitPrice,
        'quantity': quantity,
        'duration_minutes': durationMinutes,
      };
}
