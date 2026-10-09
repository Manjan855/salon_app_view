import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/shared/models/app_notification.dart';
import 'package:salon_app_view/shared/models/coupon_model.dart';

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
}
