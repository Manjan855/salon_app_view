import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/booking_model.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Insert a new booking into the db
  Future<void> createBooking(BookingModel booking) async {
    try {
      await _supabase.from('bookings').insert(booking.toJson());
    } catch (e) {
      throw Exception('Failed to secure booking appointment: $e');
    }
  }

  // Fetch only the logged-in user's bookings
  Future<List<BookingModel>> getUserBookings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', user.id);

      return (response as List<dynamic>)
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get your bookings: $e');
    }
  }
}
