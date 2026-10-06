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

  // Get upcoming bookings (Pending or confirmed and occurring in the future)
  List<BookingModel> get upcomingBookings {
    return _bookings
        .where(
          (booking) =>
              booking.isActive &&
              booking.bookingDateTime.isAfter(DateTime.now()),
        )
        .toList();
  }

  // Get past bookings (Completed or active but expired)
  List<BookingModel> get pastBookings {
    return _bookings
        .where(
          (booking) =>
              booking.isCompleted ||
              (booking.isActive &&
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
    String? staffId,
    required DateTime date,
    required DateTime start,
    required DateTime end,
    required double totalPrice,
    String? notes,
  }) {
    _clearError();

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _error = "You must be logged in to build an appointment reservation.";
      notifyListeners();
      return;
    }

    _currentBooking = BookingModel.staged(
      userId: currentUserId,
      salonId: salonId,
      staffId: staffId,
      date: date,
      start: start,
      end: end,
      totalPrice: totalPrice,
      notes: notes,
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
      // RLS only accepts `pending` on insert: the salon promotes it to
      // `confirmed` once it accepts the appointment.
      final bookingToSave = BookingModel(
        id: '',
        userId: _currentBooking!.userId,
        salonId: _currentBooking!.salonId,
        staffId: _currentBooking!.staffId,
        bookingDate: _currentBooking!.bookingDate,
        startTime: _currentBooking!.startTime,
        endTime: _currentBooking!.endTime,
        totalPrice: _currentBooking!.totalPrice,
        status: 'pending',
        paymentStatus: _currentBooking!.paymentStatus,
        paymentProvider: _currentBooking!.paymentProvider,
        notes: _currentBooking!.notes,
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
        final b = _bookings[index];
        _bookings[index] = BookingModel(
          id: b.id,
          userId: b.userId,
          salonId: b.salonId,
          staffId: b.staffId,
          bookingDate: b.bookingDate,
          startTime: b.startTime,
          endTime: b.endTime,
          totalPrice: b.totalPrice,
          status: 'cancelled',
          paymentStatus: b.paymentStatus,
          paymentProvider: b.paymentProvider,
          otpCode: b.otpCode,
          notes: b.notes,
          createdAt: b.createdAt,
          salonName: b.salonName,
          staffName: b.staffName,
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
    Duration duration = const Duration(minutes: 60),
  }) async {
    _setLoading(true);
    _clearError();

    final index = _bookings.indexWhere((b) => b.id == bookingId);
    final existing = index != -1 ? _bookings[index] : null;

    final start = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );
    final end = start.add(
      existing != null ? existing.duration : duration,
    );

    String two(int v) => v.toString().padLeft(2, '0');
    final dateStr = '${newDate.year}-${two(newDate.month)}-${two(newDate.day)}';
    final startStr = '${two(start.hour)}:${two(start.minute)}:00';
    final endStr = '${two(end.hour)}:${two(end.minute)}:00';

    try {
      // booking_date_time and otp_code are trigger-derived: only the split
      // date/time columns are writable here.
      await Supabase.instance.client
          .from('bookings')
          .update({
            'booking_date': dateStr,
            'start_time': startStr,
            'end_time': endStr,
          })
          .eq('id', bookingId);

      // Fast update targeted model within current cache stream
      if (existing != null) {
        _bookings[index] = BookingModel(
          id: existing.id,
          userId: existing.userId,
          salonId: existing.salonId,
          staffId: existing.staffId,
          bookingDate: DateTime(newDate.year, newDate.month, newDate.day),
          startTime: startStr,
          endTime: endStr,
          totalPrice: existing.totalPrice,
          status: existing.status,
          paymentStatus: existing.paymentStatus,
          paymentProvider: existing.paymentProvider,
          otpCode: existing.otpCode,
          notes: existing.notes,
          createdAt: existing.createdAt,
          salonName: existing.salonName,
          staffName: existing.staffName,
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
