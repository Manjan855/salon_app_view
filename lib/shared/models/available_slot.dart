/// One row of the `get_available_slots(...)` RPC result.
///
/// The RPC returns `timestamptz` values. PostgREST serialises them in UTC, so
/// the wall-clock helpers below add Nepal's fixed offset (UTC+05:45, no DST)
/// to produce the salon-local time the customer actually sees.
class AvailableSlot {
  /// Absolute instants (UTC) as returned by the database.
  final DateTime start;
  final DateTime end;

  final bool isAvailable;
  final String? unavailableReason; // past | booked | null

  const AvailableSlot({
    required this.start,
    required this.end,
    required this.isAvailable,
    this.unavailableReason,
  });

  static const Duration nepalOffset = Duration(hours: 5, minutes: 45);

  /// Salon-local (Nepal) start/end. The returned values are UTC, so shift them
  /// explicitly instead of relying on the device timezone.
  DateTime get startLocal => start.toUtc().add(nepalOffset);
  DateTime get endLocal => end.toUtc().add(nepalOffset);

  /// e.g. "9:30 AM to 10:00 AM".
  String get label => '${formatTime(startLocal)} to ${formatTime(endLocal)}';

  /// e.g. "9:30 AM".
  String get startLabel => formatTime(startLocal);

  static String formatTime(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      start: DateTime.parse(json['slot_start'] as String),
      end: DateTime.parse(json['slot_end'] as String),
      isAvailable: json['is_available'] as bool? ?? false,
      unavailableReason: json['unavailable_reason'] as String?,
    );
  }

  @override
  String toString() => 'AvailableSlot($label, available: $isAvailable)';
}
