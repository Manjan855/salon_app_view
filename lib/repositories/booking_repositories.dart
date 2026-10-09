import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/booking_model.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Insert a new booking and return its database-generated id.
  ///
  /// RLS only accepts `status = 'pending'` on insert; the salon promotes it to
  /// `confirmed` once it accepts the appointment.
  Future<String> createBooking(BookingModel booking) async {
    try {
      final response = await _supabase
          .from('bookings')
          .insert(booking.toJson())
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to secure booking appointment: $e');
    }
  }

  /// Attach the ordered services to a freshly created booking.
  Future<void> addBookingServices(
    String bookingId,
    List<BookingServiceLine> lines,
  ) async {
    if (lines.isEmpty) return;
    try {
      await _supabase
          .from('booking_services')
          .insert(lines.map((l) => l.toJson(bookingId)).toList());
    } catch (e) {
      throw Exception('Failed to save the booked services: $e');
    }
  }

  /// Fetch only the logged-in user's bookings, with salon + stylist names
  /// embedded for display.
  Future<List<BookingModel>> getUserBookings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('bookings')
          .select('*, salon:salons(name, address, city), staff:staff(name)')
          .eq('user_id', user.id)
          .order('booking_date', ascending: false);

      return (response as List<dynamic>)
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get your bookings: $e');
    }
  }
}
