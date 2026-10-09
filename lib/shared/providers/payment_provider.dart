import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../repositories/payment_repository.dart';

/// Drives an eSewa / Khalti checkout: ask the Edge Function for a payment and
/// open its public checkout page in the system browser.
///
/// The browser eventually bounces back to `salonappview://payment-result`; that
/// link is handled once, centrally, in `run_app.dart`.
class PaymentProvider with ChangeNotifier {
  final PaymentRepository _repo = PaymentRepository();

  bool _isStarting = false;
  String? _error;
  String? _activeProvider;

  /// True while the initiate call / browser launch is in flight.
  bool get isStarting => _isStarting;
  String? get error => _error;

  /// 'esewa' | 'khalti' while a checkout is being started.
  String? get activeProvider => _activeProvider;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Starts a checkout for [bookingId]. Returns true once the browser has been
  /// handed the payment page.
  Future<bool> startCheckout({
    required String bookingId,
    required String provider,
  }) async {
    _isStarting = true;
    _activeProvider = provider;
    _error = null;
    notifyListeners();

    try {
      final initiation = await _repo.initiate(
        bookingId: bookingId,
        provider: provider,
      );

      final opened = await launchUrl(
        Uri.parse(initiation.checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw Exception('Could not open the payment page in a browser.');
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isStarting = false;
      _activeProvider = null;
      notifyListeners();
    }
  }
}
