import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  BookingModel? _currentBooking;
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  BookingModel? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get upcoming bookings
  List<BookingModel> get upcomingBookings {
    return _bookings
        .where(
          (booking) =>
              booking.status == 'confirmed' &&
              booking.date.isAfter(DateTime.now()),
        )
        .toList();
  }

  // Get past bookings
  List<BookingModel> get pastBookings {
    return _bookings
        .where(
          (booking) =>
              booking.status == 'completed' ||
              (booking.status == 'confirmed' &&
                  booking.date.isBefore(DateTime.now())),
        )
        .toList();
  }

  // Get cancelled bookings
  List<BookingModel> get cancelledBookings {
    return _bookings.where((booking) => booking.status == 'cancelled').toList();
  }

  // Create booking
  Future<bool> createBooking({
    required String salonId,
    required String salonName,
    required String serviceId,
    required String serviceName,
    required double price,
    required DateTime date,
    required TimeOfDay time,
    String? stylistId,
    String? stylistName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _currentBooking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        salonId: salonId,
        salonName: salonName,
        serviceId: serviceId,
        serviceName: serviceName,
        stylistId: stylistId,
        stylistName: stylistName,
        date: date,
        time: time,
        totalAmount: price,
        status: 'pending',
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Confirm booking
  Future<bool> confirmBooking() async {
    if (_currentBooking == null) {
      _error = 'No booking to confirm';
      return false;
    }

    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      _currentBooking = BookingModel(
        id: _currentBooking!.id,
        salonId: _currentBooking!.salonId,
        salonName: _currentBooking!.salonName,
        serviceId: _currentBooking!.serviceId,
        serviceName: _currentBooking!.serviceName,
        stylistId: _currentBooking!.stylistId,
        stylistName: _currentBooking!.stylistName,
        date: _currentBooking!.date,
        time: _currentBooking!.time,
        totalAmount: _currentBooking!.totalAmount,
        status: 'confirmed',
      );

      // Add to bookings list
      _bookings.add(_currentBooking!);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Get user bookings
  Future<void> fetchUserBookings() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Sample bookings data
      _bookings = [
        BookingModel(
          id: '1',
          salonId: '1',
          salonName: 'Glamour Studio',
          serviceId: '1',
          serviceName: 'Haircut & Styling',
          stylistId: '1',
          stylistName: 'Jane Smith',
          date: DateTime.now().add(const Duration(days: 2)),
          time: const TimeOfDay(hour: 14, minute: 30),
          totalAmount: 35.00,
          status: 'confirmed',
        ),
        BookingModel(
          id: '2',
          salonId: '2',
          salonName: 'Royal Beauty Spa',
          serviceId: '2',
          serviceName: 'Premium Facial',
          stylistId: '2',
          stylistName: 'Sarah Johnson',
          date: DateTime.now().add(const Duration(days: 5)),
          time: const TimeOfDay(hour: 11, minute: 0),
          totalAmount: 50.00,
          status: 'confirmed',
        ),
        BookingModel(
          id: '3',
          salonId: '1',
          salonName: 'Glamour Studio',
          serviceId: '3',
          serviceName: 'Manicure & Pedicure',
          date: DateTime.now().subtract(const Duration(days: 3)),
          time: const TimeOfDay(hour: 15, minute: 0),
          totalAmount: 40.00,
          status: 'completed',
        ),
        BookingModel(
          id: '4',
          salonId: '3',
          salonName: 'Luxury Nails',
          serviceId: '4',
          serviceName: 'Nail Art',
          date: DateTime.now().add(const Duration(days: 1)),
          time: const TimeOfDay(hour: 10, minute: 0),
          totalAmount: 25.00,
          status: 'pending',
        ),
      ];

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Get booking by ID
  BookingModel? getBookingById(String bookingId) {
    try {
      return _bookings.firstWhere((booking) => booking.id == bookingId);
    } catch (e) {
      return null;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        final booking = _bookings[index];
        _bookings[index] = BookingModel(
          id: booking.id,
          salonId: booking.salonId,
          salonName: booking.salonName,
          serviceId: booking.serviceId,
          serviceName: booking.serviceName,
          stylistId: booking.stylistId,
          stylistName: booking.stylistName,
          date: booking.date,
          time: booking.time,
          totalAmount: booking.totalAmount,
          status: 'cancelled',
        );
      }

      // Also update current booking if it's the same
      if (_currentBooking?.id == bookingId) {
        _currentBooking = BookingModel(
          id: _currentBooking!.id,
          salonId: _currentBooking!.salonId,
          salonName: _currentBooking!.salonName,
          serviceId: _currentBooking!.serviceId,
          serviceName: _currentBooking!.serviceName,
          stylistId: _currentBooking!.stylistId,
          stylistName: _currentBooking!.stylistName,
          date: _currentBooking!.date,
          time: _currentBooking!.time,
          totalAmount: _currentBooking!.totalAmount,
          status: 'cancelled',
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Reschedule booking
  Future<bool> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required TimeOfDay newTime,
  }) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        final booking = _bookings[index];
        _bookings[index] = BookingModel(
          id: booking.id,
          salonId: booking.salonId,
          salonName: booking.salonName,
          serviceId: booking.serviceId,
          serviceName: booking.serviceName,
          stylistId: booking.stylistId,
          stylistName: booking.stylistName,
          date: newDate,
          time: newTime,
          totalAmount: booking.totalAmount,
          status: 'confirmed',
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Clear current booking
  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
