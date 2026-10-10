import 'package:flutter/foundation.dart';

import '../../repositories/review_repository.dart';
import '../models/review_model.dart';

/// Holds the reviews for the salon currently on screen, plus the set of the
/// signed-in user's already-reviewed booking ids (so "Rate your visit" can
/// show a Reviewed state without a second round-trip per booking).
class ReviewProvider with ChangeNotifier {
  final ReviewRepository _repo = ReviewRepository();

  List<ReviewModel> _reviews = [];
  Set<String> _reviewedBookingIds = {};
  bool _isLoading = false;
  String? _error;
  String? _loadedForSalonId;
  String? _reviewedLoadedForUserId;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get reviewedBookingIds => _reviewedBookingIds;

  int get reviewCount => _reviews.length;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / _reviews.length;
  }

  bool isBookingReviewed(String? bookingId) =>
      bookingId != null && _reviewedBookingIds.contains(bookingId);

  /// Loads the salon's reviews; skips the network when the same salon is
  /// already loaded unless [force] is set (used by pull-to-refresh).
  Future<void> loadSalonReviews(String salonId, {bool force = false}) async {
    if (!force && _loadedForSalonId == salonId) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _repo.getSalonReviews(salonId);
      _loadedForSalonId = salonId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads once per signed-in user; re-loads if the user changes.
  Future<void> ensureReviewedLoaded({String? userId}) async {
    if (userId == null) {
      _reviewedBookingIds = {};
      _reviewedLoadedForUserId = null;
      return;
    }
    if (_reviewedLoadedForUserId == userId) return;

    try {
      _reviewedBookingIds = await _repo.getReviewedBookingIds(userId);
      _reviewedLoadedForUserId = userId;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  /// Submits a review and, when the reviewed salon is on screen, prepends it
  /// so the list updates immediately. Returns the created review (or null).
  Future<ReviewModel?> submitReview({
    required String salonId,
    required String userId,
    String? bookingId,
    required int rating,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _repo.submitReview(
        salonId: salonId,
        userId: userId,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );

      if (bookingId != null) {
        _reviewedBookingIds = {..._reviewedBookingIds, bookingId};
      }
      if (_loadedForSalonId == salonId) {
        _reviews = [created, ..._reviews];
      }
      return created;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReview(String id) async {
    try {
      await _repo.deleteReview(id);
      _reviews = _reviews.where((r) => r.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }
}
