import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/repositories/payment_repository.dart';
import 'package:salon_app_view/shared/models/app_notification.dart';
import 'package:salon_app_view/shared/models/coupon_model.dart';
import 'package:salon_app_view/shared/models/review_model.dart';

void main() {
  group('CouponModel', () {
    test('formats whole and fractional discounts', () {
      expect(
        CouponModel(id: '1', code: 'WELCOME50', discountPercent: 50)
            .discountLabel,
        '50% off',
      );
      expect(
        CouponModel(id: '1', code: 'ODD', discountPercent: 12.5).discountLabel,
        '12.5% off',
      );
    });

    test('parses a coupons row', () {
      final coupon = CouponModel.fromJson({
        'id': 'c1',
        'code': 'GLAM20',
        'salon_id': null,
        'discount_percent': 20,
        'max_discount': 150,
        'valid_to': '2026-07-10T00:00:00.000Z',
        'is_active': true,
      });

      expect(coupon.code, 'GLAM20');
      expect(coupon.discountPercent, 20);
      expect(coupon.maxDiscount, 150);
      expect(coupon.validTo, isNotNull);
      expect(coupon.discountLabel, '20% off');
    });

    test('tolerates null optional fields', () {
      final coupon = CouponModel.fromJson({
        'id': 'c2',
        'code': 'BASIC',
        'discount_percent': 5,
      });

      expect(coupon.salonId, isNull);
      expect(coupon.maxDiscount, isNull);
      expect(coupon.validTo, isNull);
    });
  });

  group('AppNotification', () {
    test('parses a notifications row and defaults the type', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'title': 'Booking confirmed',
        'body': 'See you soon',
        'is_read': false,
        'created_at': '2026-05-28T10:00:00.000Z',
      });

      expect(n.title, 'Booking confirmed');
      expect(n.type, 'general');
      expect(n.isRead, isFalse);
    });

    test('relativeTime buckets recent timestamps', () {
      final now = DateTime.now().toUtc();
      String rel(int minutes) => AppNotification(
            id: 'x',
            title: 't',
            body: 'b',
            createdAt: now.subtract(Duration(minutes: minutes)),
          ).relativeTime;

      expect(rel(0), 'Just now');
      expect(rel(5), '5m ago');
      expect(rel(120), '2h ago');
      expect(rel(60 * 24 * 3), '3d ago');
      expect(rel(60 * 24 * 14), '2w ago');
    });
  });

  group('ReviewModel', () {
    test('parses a reviews row with a joined public profile', () {
      final review = ReviewModel.fromJson({
        'id': 'r1',
        'salon_id': 's1',
        'user_id': 'u1',
        'booking_id': 'b1',
        'rating': 5,
        'comment': 'Great cut',
        'reply': null,
        'is_visible': true,
        'created_at': '2026-05-01T09:00:00.000Z',
        'user_name': 'Sita',
        'user_avatar': 'https://example.com/a.png',
      });

      expect(review.rating, 5);
      expect(review.userName, 'Sita');
      expect(review.userAvatar, isNotNull);
      expect(review.hasComment, isTrue);
      expect(review.bookingId, 'b1');
    });

    test('reads an embedded user object and defaults a blank name', () {
      final embedded = ReviewModel.fromJson({
        'id': 'r2',
        'salon_id': 's1',
        'user_id': 'u2',
        'rating': 4,
        'created_at': '2026-05-01T09:00:00.000Z',
        'user': {'name': 'Ramesh', 'profile_image_url': null},
      });
      expect(embedded.userName, 'Ramesh');

      final anonymous = ReviewModel.fromJson({
        'id': 'r3',
        'salon_id': 's1',
        'user_id': 'u3',
        'rating': 3,
        'created_at': '2026-05-01T09:00:00.000Z',
      });
      expect(anonymous.userName, 'Anonymous');
      expect(anonymous.hasComment, isFalse);
    });
  });

  group('paymentErrorMessage', () {
    test('maps a gateway 404 (not deployed) to a clear message', () {
      final msg = paymentErrorMessage(404);
      expect(msg.toLowerCase(), contains('not been deployed'));
      expect(
        const PaymentException('x', status: 404, notDeployed: true).isNotDeployed,
        isTrue,
      );
      expect(const PaymentException('x', status: 404).isNotDeployed, isFalse);
    });

    test("keeps the function's own 404 body", () {
      expect(
        paymentErrorMessage(404, details: {'error': 'Booking not found'}),
        'Booking not found',
      );
    });

    test('prefers the function-provided error detail', () {
      expect(
        paymentErrorMessage(503, details: {
          'error': 'Payments function has no admin key',
        }),
        'Payments function has no admin key',
      );
      expect(
        paymentErrorMessage(403, details: {
          'error': 'You do not own this booking',
        }),
        'You do not own this booking',
      );
    });

    test('maps a missing session to a sign-in hint', () {
      expect(paymentErrorMessage(401).toLowerCase(), contains('sign in'));
    });

    test('ignores an HTML gateway page and falls back to the status', () {
      expect(
        paymentErrorMessage(500, details: '<html>oops</html>'),
        'Payment service error (500).',
      );
    });
  });
}
