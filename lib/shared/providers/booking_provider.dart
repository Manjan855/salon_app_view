import 'package:flutter/material.dart';
import 'package:salon_app_view/repositories/booking_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final BookingRepository _bookingRepo = BookingRepository();

  List<BookingModel> _bookings = [];
  BookingModel? _currentBooking;
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  BookingModel? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- GETTERS (Filtering lists locally out of cached state) ---

  // Get upcoming bookings (Confirmed and occurring in the future)
  List<BookingModel> get upcomingBookings {
    return _bookings
        .where(
          (booking) =>
              booking.status == 'confirmed' &&
              booking.bookingDateTime.isAfter(DateTime.now()),
        )
        .toList();
  }

  // Get past bookings (Completed or confirmed but expired)
  List<BookingModel> get pastBookings {
    return _bookings
        .where(
          (booking) =>
              booking.status == 'completed' ||
              (booking.status == 'confirmed' &&
                  booking.bookingDateTime.isBefore(DateTime.now())),
        )
        .toList();
  }

  // Get cancelled bookings
  List<BookingModel> get cancelledBookings {
    return _bookings.where((booking) => booking.status == 'cancelled').toList();
  }

  // --- ACTION METHODS (Communicating with Supabase Backend) ---

  // 1. Fetch live user bookings from the database
  Future<void> fetchUserBookings() async {
    _setLoading(true);
    _clearError();

    try {
      _bookings = await _bookingRepo.getUserBookings();
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '');
    } finally {
      _setLoading(false);
    }
  }

  // 2. Step One: Stage a pending booking inside local app memory
  void stageBooking({
    required String salonId,
    required double totalPrice,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
  }) {
    _clearError();

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _error = "You must be logged in to build an appointment reservation.";
      notifyListeners();
      return;
    }

    // Combine Date and TimeOfDay into a single DateTime object for PostgreSQL compatibility
    final bookingDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    _currentBooking = BookingModel(
      id: '', // Blank id since Supabase generates UUID automatically on insert
      userId: currentUserId,
      salonId: salonId,
      bookingDateTime: bookingDateTime,
      totalPrice: totalPrice,
      status: 'pending',
    );
    notifyListeners();
  }

  // 3. Step Two: Commit the staged booking directly to Supabase cloud
  Future<bool> confirmAndSaveBooking() async {
    if (_currentBooking == null) {
      _error = 'No staged booking session found to confirm';
      return false;
    }

    _setLoading(true);

    try {
      // Modify status before sending payload
      final bookingToSave = BookingModel(
        id: _currentBooking!.id,
        userId: _currentBooking!.userId,
        salonId: _currentBooking!.salonId,
        bookingDateTime: _currentBooking!.bookingDateTime,
        totalPrice: _currentBooking!.totalPrice,
        status: 'confirmed',
      );

      // Save to database via repository
      await _bookingRepo.createBooking(bookingToSave);

      // Refresh local cache to include newly generated ticket row
      await fetchUserBookings();

      _currentBooking = null; // Reset slot
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 4. Cancel booking inside Supabase DB
  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    _clearError();

    try {
      // Update database record status string safely to cancelled
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      // Fast sync local list item state layout
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = BookingModel(
          id: _bookings[index].id,
          userId: _bookings[index].userId,
          salonId: _bookings[index].salonId,
          bookingDateTime: _bookings[index].bookingDateTime,
          totalPrice: _bookings[index].totalPrice,
          status: 'cancelled',
        );
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 5. Reschedule booking date/time in backend database
  Future<bool> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required TimeOfDay newTime,
  }) async {
    _setLoading(true);
    _clearError();

    final updatedDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'booking_date_time': updatedDateTime.toIso8601String()})
          .eq('id', bookingId);

      // Fast update targeted model within current cache stream
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = BookingModel(
          id: _bookings[index].id,
          userId: _bookings[index].userId,
          salonId: _bookings[index].salonId,
          bookingDateTime: updatedDateTime,
          totalPrice: _bookings[index].totalPrice,
          status: _bookings[index].status,
        );
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  BookingModel? getBookingById(String bookingId) {
    try {
      return _bookings.firstWhere((booking) => booking.id == bookingId);
    } catch (_) {
      return null;
    }
  }

  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }

  // --- INTERNAL UTILS ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
