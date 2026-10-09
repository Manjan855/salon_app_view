import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/shared/models/available_slot.dart';
import 'package:salon_app_view/shared/models/booking_model.dart';
import 'package:salon_app_view/shared/models/salon_model.dart';
import 'package:salon_app_view/shared/models/service_model.dart';
import 'package:salon_app_view/shared/models/staff_model.dart';

void main() {
  group('AvailableSlot', () {
    test('converts UTC timestamps to Nepal wall-clock (UTC+05:45)', () {
      // 04:00 UTC == 09:45 in Asia/Kathmandu.
      final slot = AvailableSlot.fromJson({
        'slot_start': '2026-10-12T04:00:00Z',
        'slot_end': '2026-10-12T04:15:00Z',
        'is_available': true,
        'unavailable_reason': null,
      });

      expect(slot.startLocal.hour, 9);
      expect(slot.startLocal.minute, 45);
      expect(slot.endLocal.hour, 10);
      expect(slot.endLocal.minute, 0);
      expect(slot.isAvailable, isTrue);
    });

    test('formats a human label with 12-hour clock', () {
      final slot = AvailableSlot.fromJson({
        'slot_start': '2026-10-12T03:30:00Z', // 09:15 Nepal
        'slot_end': '2026-10-12T04:00:00Z', // 09:45 Nepal
        'is_available': true,
      });

      expect(slot.label, '9:15 AM to 9:45 AM');
      expect(slot.startLabel, '9:15 AM');
    });

    test('handles noon and midnight boundaries', () {
      expect(AvailableSlot.formatTime(DateTime.utc(2026, 1, 1, 12, 0)), '12:00 PM');
      expect(AvailableSlot.formatTime(DateTime.utc(2026, 1, 1, 0, 0)), '12:00 AM');
    });
  });

  group('BookingModel.staged', () {
    test('formats date and times the way Postgres expects', () {
      final booking = BookingModel.staged(
        userId: 'user-1',
        salonId: 'salon-1',
        staffId: 'staff-1',
        date: DateTime(2026, 10, 12),
        start: DateTime(2026, 10, 12, 9, 15),
        end: DateTime(2026, 10, 12, 9, 45),
        totalPrice: 350,
      );

      expect(booking.bookingDate, DateTime(2026, 10, 12));
      expect(booking.startTime, '09:15:00');
      expect(booking.endTime, '09:45:00');
      expect(booking.status, 'pending');
      expect(booking.paymentStatus, 'pending');

      final json = booking.toJson();
      expect(json['booking_date'], '2026-10-12');
      expect(json['start_time'], '09:15:00');
      expect(json['end_time'], '09:45:00');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('booking_date_time'), isFalse);
      expect(json.containsKey('otp_code'), isFalse);
    });

    test('returns salon address then city as the display location', () {
      final withAddress = BookingModel.fromJson({
        'id': 'b1',
        'user_id': 'u1',
        'salon_id': 's1',
        'booking_date': '2026-10-12',
        'start_time': '09:00:00',
        'end_time': '09:30:00',
        'total_price': 350,
        'salon': {'name': 'A', 'address': 'Main Road', 'city': 'Pokhara'},
        'staff': {'name': 'Rita'},
      });
      expect(withAddress.salonName, 'A');
      expect(withAddress.staffName, 'Rita');
      expect(withAddress.salonLocation, 'Main Road');

      final cityOnly = BookingModel.fromJson({
        'id': 'b2',
        'user_id': 'u1',
        'salon_id': 's1',
        'booking_date': '2026-10-12',
        'start_time': '09:00:00',
        'end_time': '09:30:00',
        'total_price': 350,
        'salon': {'name': 'B', 'address': '', 'city': 'Kathmandu'},
      });
      expect(cityOnly.salonLocation, 'Kathmandu');
    });
  });

  group('BookingServiceLine', () {
    test('serialises with the parent booking id', () {
      const line = BookingServiceLine(
        serviceId: 'svc-1',
        serviceName: 'Haircut',
        unitPrice: 350,
        durationMinutes: 30,
      );

      final json = line.toJson('booking-1');
      expect(json['booking_id'], 'booking-1');
      expect(json['service_id'], 'svc-1');
      expect(json['service_name'], 'Haircut');
      expect(json['unit_price'], 350);
      expect(json['duration_minutes'], 30);
      expect(json['quantity'], 1);
    });

    test('omits service_id when the line is not linked to a service row', () {
      const line = BookingServiceLine(serviceName: 'Custom', unitPrice: 100);
      expect(line.toJson('booking-2').containsKey('service_id'), isFalse);
    });
  });

  group('model parsing', () {
    test('SalonModel exposes location/image aliases', () {
      final salon = SalonModel.fromJson({
        'id': 's1',
        'name': 'Glam',
        'address': 'MG Road',
        'city': 'Pokhara',
        'image_url': 'https://example.com/a.jpg',
        'rating_avg': 4.5,
        'rating_count': 12,
        'slot_minutes': 15,
      });

      expect(salon.location, 'MG Road');
      expect(salon.image, 'https://example.com/a.jpg');
      expect(salon.ratingAvg, 4.5);
      expect(salon.ratingCount, 12);
      expect(salon.slotMinutes, 15);
    });

    test('ServiceModel parses duration and price', () {
      final service = ServiceModel.fromJson({
        'id': 'svc-1',
        'salon_id': 's1',
        'name': 'Haircut',
        'price': 350,
        'duration_minutes': 30,
        'category': 'hair',
      });

      expect(service.id, 'svc-1');
      expect(service.durationMinutes, 30);
      expect(service.price, 350);
    });

    test('StaffModel falls back to a generic title', () {
      final staff = StaffModel.fromJson({
        'id': 'st-1',
        'salon_id': 's1',
        'name': 'Rita',
      });
      expect(staff.displayTitle, 'Stylist');
    });
  });
}
