import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../repositories/payment_repository.dart';

/// Drives an eSewa / Khalti checkout: ask the Edge Function for a payment and
/// open its public checkout page in the system browser.
///
/// The browser eventually bounces back to `salonappview://payment-result`; that
/// link is handled once, centrally, in `run_app.dart`.
class PaymentProvider with ChangeNotifier {
  PaymentProvider({PaymentRepository? repository})
      : _repo = repository ?? PaymentRepository();

  final PaymentRepository _repo;

  bool _isStarting = false;
  String? _error;
  String? _activeProvider;
  bool _notDeployed = false;
  bool _checkingDeployment = false;

  /// True while the initiate call / browser launch is in flight.
  bool get isStarting => _isStarting;
  String? get error => _error;

  /// True when the last probe says the `payments` function is missing (HTTP
  /// 404) — either from [checkDeployment] or from a failed checkout attempt.
  bool get notDeployed => _notDeployed;

  /// True while the one-off startup probe in [checkDeployment] is running.
  bool get checkingDeployment => _checkingDeployment;

  /// 'esewa' | 'khalti' while a checkout is being started.
  String? get activeProvider => _activeProvider;

  /// Probes the `payments` Edge Function once (called when the payment screen
  /// opens) so the UI can steer the user to "Pay at salon" right away instead
  /// of failing only after they tap a wallet.
  Future<void> checkDeployment() async {
    if (_checkingDeployment) return;
    _checkingDeployment = true;
    notifyListeners();
    try {
      _notDeployed = !await _repo.isDeployed();
    } catch (_) {
      // Network errors are not "not deployed" — keep the previous state and
      // never pre-emptively block payments on an unknown outcome.
    } finally {
      _checkingDeployment = false;
      notifyListeners();
    }
  }

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
    _notDeployed = false;
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
    } on PaymentException catch (e) {
      _error = e.message;
      _notDeployed = e.isNotDeployed;
      return false;
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
