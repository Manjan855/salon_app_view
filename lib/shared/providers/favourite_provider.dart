import 'package:flutter/foundation.dart';
import '../models/salon_model.dart';
import '../../repositories/favourite_repository.dart';

/// Holds the signed-in user's favourite salon ids (for heart toggles) and the
/// full salon rows (for the Wishlist screen).
class FavouriteProvider with ChangeNotifier {
  final FavouriteRepository _repo = FavouriteRepository();

  Set<String> _ids = {};
  List<SalonModel> _salons = [];
  bool _isLoading = false;
  String? _error;
  String? _loadedForUserId;

  Set<String> get ids => _ids;
  List<SalonModel> get salons => _salons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavourite(String? salonId) => salonId != null && _ids.contains(salonId);

  /// Load once per signed-in user; re-loads automatically if the user changes.
  Future<void> ensureLoaded({String? userId}) async {
    if (_loadedForUserId == userId && userId != null) return;
    await refresh(userId: userId);
  }

  Future<void> refresh({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ids = await _repo.getFavouriteIds();
      final salons = await _repo.getFavouriteSalons();
      _ids = ids;
      _salons = salons;
      _loadedForUserId = userId;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistically flips the favourite and rolls back on failure.
  /// Returns the new state (`true` = now favourited).
  Future<bool> toggle(String salonId) async {
    final wasFavourite = _ids.contains(salonId);
    _applyLocal(salonId, !wasFavourite);

    try {
      if (wasFavourite) {
        await _repo.removeFavourite(salonId);
      } else {
        await _repo.addFavourite(salonId);
        // Refresh so the Wishlist's full rows stay in sync.
        _salons = await _repo.getFavouriteSalons();
      }
      notifyListeners();
      return !wasFavourite;
    } catch (e) {
      _applyLocal(salonId, wasFavourite); // roll back
      _error = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      rethrow;
    }
  }

  void _applyLocal(String salonId, bool favourite) {
    final next = {..._ids};
    if (favourite) {
      next.add(salonId);
    } else {
      next.remove(salonId);
    }
    _ids = next;
    if (!favourite) {
      _salons = _salons.where((s) => s.id != salonId).toList();
    }
    notifyListeners();
  }
}
