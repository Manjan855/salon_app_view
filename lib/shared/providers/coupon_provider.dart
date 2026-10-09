import 'package:flutter/foundation.dart';
import '../models/coupon_model.dart';
import '../../repositories/coupon_repository.dart';

/// Active coupons, shown in the Home offers row and the Profile promocodes
/// sheet. Falls back to an empty list (callers decide on mock content).
class CouponProvider with ChangeNotifier {
  final CouponRepository _repo = CouponRepository();

  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<CouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> ensureLoaded() async {
    if (_hasLoaded) return;
    await fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    _isLoading = true;
    notifyListeners();

    try {
      _coupons = await _repo.getActiveCoupons();
      _hasLoaded = true;
    } catch (_) {
      // Keep any previously loaded coupons; the UI degrades to its fallback.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
