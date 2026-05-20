import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;
  double _averageRating = 0.0;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get averageRating => _averageRating;

  // Submit review
  Future<bool> submitReview({
    required String salonId,
    required String serviceId,
    required double rating,
    required String comment,
    List<String>? tags,
  }) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final review = ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        salonId: salonId,
        serviceId: serviceId,
        userId: 'current_user_id',
        userName: 'John Doe',
        userAvatar: null,
        rating: rating,
        comment: comment,
        tags: tags ?? [],
        date: DateTime.now(),
        helpful: 0,
      );

      _reviews.insert(0, review);
      _calculateAverageRating();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Fetch reviews for salon
  Future<void> fetchSalonReviews(String salonId) async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Sample reviews
      _reviews = [
        ReviewModel(
          id: '1',
          salonId: salonId,
          serviceId: '1',
          userId: 'user1',
          userName: 'Sarah Johnson',
          userAvatar: null,
          rating: 5.0,
          comment:
              'Excellent service! The stylist was very professional and friendly.',
          tags: ['Great Service', 'Friendly Staff'],
          date: DateTime.now().subtract(const Duration(days: 2)),
          helpful: 12,
        ),
        ReviewModel(
          id: '2',
          salonId: salonId,
          serviceId: '2',
          userId: 'user2',
          userName: 'Michael Brown',
          userAvatar: null,
          rating: 4.0,
          comment: 'Good experience overall. Will visit again.',
          tags: ['Clean Environment', 'On Time'],
          date: DateTime.now().subtract(const Duration(days: 5)),
          helpful: 8,
        ),
        ReviewModel(
          id: '3',
          salonId: salonId,
          serviceId: '1',
          userId: 'user3',
          userName: 'Emily Davis',
          userAvatar: null,
          rating: 5.0,
          comment: 'Best salon in town! Highly recommended.',
          tags: ['Great Service', 'Value for Money', 'Professional'],
          date: DateTime.now().subtract(const Duration(days: 7)),
          helpful: 25,
        ),
      ];

      _calculateAverageRating();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Mark review as helpful
  Future<void> markHelpful(String reviewId) async {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _reviews[index] = ReviewModel(
        id: _reviews[index].id,
        salonId: _reviews[index].salonId,
        serviceId: _reviews[index].serviceId,
        userId: _reviews[index].userId,
        userName: _reviews[index].userName,
        userAvatar: _reviews[index].userAvatar,
        rating: _reviews[index].rating,
        comment: _reviews[index].comment,
        tags: _reviews[index].tags,
        date: _reviews[index].date,
        helpful: _reviews[index].helpful + 1,
      );
      notifyListeners();
    }
  }

  void _calculateAverageRating() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      return;
    }

    final total = _reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    _averageRating = total / _reviews.length;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
