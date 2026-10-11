// Unit tests for the Explore Gender filter (lib/features/salon_detail/gender_filter.dart)
// and the `services.gender` facet on ServiceModel.
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/features/salon_detail/gender_filter.dart';
import 'package:salon_app_view/shared/models/service_model.dart';

void main() {
  // salonId → genders offered (from public.services.gender)
  const gents = {
    'men-only-salon': {'men'},
    'women-only-salon': {'women'},
    'unisex-salon': {'unisex'},
    'mixed-salon': {'men', 'women'},
  };

  group('salonMatchesGender', () {
    test("'All' never filters", () {
      expect(salonMatchesGender(gents, 'men-only-salon', 'All'), isTrue);
      expect(salonMatchesGender({}, null, 'All'), isTrue);
    });

    test('men-only salon shows under Men but not Women/Unisex', () {
      expect(salonMatchesGender(gents, 'men-only-salon', 'Men'), isTrue);
      expect(salonMatchesGender(gents, 'men-only-salon', 'Women'), isFalse);
      expect(salonMatchesGender(gents, 'men-only-salon', 'Unisex'), isFalse);
    });

    test('women-only salon shows under Women but not Men/Unisex', () {
      expect(salonMatchesGender(gents, 'women-only-salon', 'Women'), isTrue);
      expect(salonMatchesGender(gents, 'women-only-salon', 'Men'), isFalse);
      expect(salonMatchesGender(gents, 'women-only-salon', 'Unisex'), isFalse);
    });

    test('unisex salon serves men and women (survives Men and Women filters)', () {
      expect(salonMatchesGender(gents, 'unisex-salon', 'Unisex'), isTrue);
      expect(salonMatchesGender(gents, 'unisex-salon', 'Men'), isTrue);
      expect(salonMatchesGender(gents, 'unisex-salon', 'Women'), isTrue);
    });

    test('mixed salon appears under both Men and Women', () {
      expect(salonMatchesGender(gents, 'mixed-salon', 'Men'), isTrue);
      expect(salonMatchesGender(gents, 'mixed-salon', 'Women'), isTrue);
      expect(salonMatchesGender(gents, 'mixed-salon', 'Unisex'), isFalse);
    });

    test('unknown salon id behaves like no data: only Unisex keeps it', () {
      expect(salonMatchesGender(gents, 'not-in-map', 'Men'), isFalse);
      expect(salonMatchesGender(gents, 'not-in-map', 'Women'), isFalse);
      expect(salonMatchesGender(gents, 'not-in-map', 'Unisex'), isTrue);
    });

    test('offline demo rows (null id) are gender-neutral: Unisex only', () {
      expect(salonMatchesGender(gents, null, 'Unisex'), isTrue);
      expect(salonMatchesGender(gents, null, 'Men'), isFalse);
      expect(salonMatchesGender(gents, null, 'Women'), isFalse);
    });

    test('empty facets (services.gender not migrated yet) filter to Unisex', () {
      const noFacets = <String, Set<String>>{};
      expect(salonMatchesGender(noFacets, 'men-only-salon', 'Men'), isFalse);
      expect(salonMatchesGender(noFacets, 'men-only-salon', 'Women'), isFalse);
      expect(salonMatchesGender(noFacets, 'men-only-salon', 'Unisex'), isTrue);
    });

    test('unknown gender label never filters (forward-compatible)', () {
      expect(salonMatchesGender(gents, 'men-only-salon', 'Kids'), isTrue);
    });
  });

  group('ServiceModel gender facet', () {
    test('parses the gender column and defaults to unisex', () {
      final menRow = ServiceModel.fromJson({
        'id': 's1',
        'salon_id': 'sal1',
        'name': 'Beard Trim & Shape',
        'price': 200,
        'duration_minutes': 20,
        'category': 'beard',
        'gender': 'men',
      });
      final legacyRow = ServiceModel.fromJson({
        'id': 's2',
        'salon_id': 'sal1',
        'name': 'Haircut',
        'price': 350,
        'duration_minutes': 30,
        'category': 'hair',
        // no 'gender' key: pre-migration rows
      });

      expect(menRow.gender, 'men');
      expect(legacyRow.gender, 'unisex');
      expect(menRow.toJson()['gender'], 'men');
    });
  });
}