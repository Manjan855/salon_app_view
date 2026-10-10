import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/review_model.dart';

/// Backs the salon reviews screen and the "rate your visit" flow.
///
/// Reads are public (`reviews_public_read`); writes are RLS-guarded to the
/// signed-in user and only allowed when they have a completed/confirmed
/// booking at the salon (`reviews_insert_own_with_booking`).
///
/// Reviewer names/avatars come from `public.profiles_public` — a manual join,
/// because the raw `profiles` table is PII-locked and not embeddable.
class ReviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _table = 'reviews';
  static const _columns =
      'id, salon_id, user_id, booking_id, rating, comment, reply, '
      'is_visible, created_at';

  /// Visible reviews for a salon, newest first, with reviewer names merged in.
  Future<List<ReviewModel>> getSalonReviews(String salonId) async {
    try {
      final rows = await _supabase
          .from(_table)
          .select(_columns)
          .eq('salon_id', salonId)
          .eq('is_visible', true)
          .order('created_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      final profiles = await _profilesFor(
        list.map((r) => r['user_id'] as String),
      );

      return list.map((r) {
        final p = profiles[r['user_id']];
        return ReviewModel.fromJson({
          ...r,
          'user_name': p?['name'],
          'user_avatar': p?['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  /// Booking ids the current user has already reviewed (one review per
  /// booking, enforced by the unique `booking_id`).
  Future<Set<String>> getReviewedBookingIds(String userId) async {
    try {
      final rows = await _supabase
          .from(_table)
          .select('booking_id')
          .eq('user_id', userId)
          .not('booking_id', 'is', null);

      return (rows as List<dynamic>)
          .map((r) => (r as Map)['booking_id'])
          .whereType<String>()
          .toSet();
    } catch (e) {
      throw Exception('Failed to load your reviews: $e');
    }
  }

  /// Insert a review. `bookingId` links it to the visit the RLS insert policy
  /// checks for completed/confirmed status.
  Future<ReviewModel> submitReview({
    required String salonId,
    required String userId,
    String? bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final clean = (comment ?? '').trim();
      final row = await _supabase
          .from(_table)
          .insert({
            'salon_id': salonId,
            'user_id': userId,
            if (bookingId != null) 'booking_id': bookingId,
            'rating': rating,
            if (clean.isNotEmpty) 'comment': clean,
          })
          .select(_columns)
          .single();

      return ReviewModel.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<void> deleteReview(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  /// id → {name, profile_image_url} for the sanctioned public projection.
  Future<Map<String, Map<String, dynamic>>> _profilesFor(
    Iterable<String> ids,
  ) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return {};
    final rows = await _supabase
        .from('profiles_public')
        .select('id, name, profile_image_url')
        .inFilter('id', unique);

    return {
      for (final r in rows as List<dynamic>)
        (r as Map)['id'] as String: Map<String, dynamic>.from(r),
    };
  }
}
