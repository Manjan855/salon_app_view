import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/payment_model.dart';

/// Raised whenever a checkout can't be started. Carries a message that is safe
/// to show the user, plus the HTTP [status] when the failure came from the
/// Edge Function (so the UI can tell "not deployed" from "session expired").
class PaymentException implements Exception {
  const PaymentException(
    this.message, {
    this.status,
    this.notDeployed = false,
  });

  final String message;
  final int? status;

  /// True when the `payments` function/route itself is missing — a platform
  /// gateway 404, not one of the function's own 404s (e.g. "Booking not found").
  final bool notDeployed;

  bool get isNotDeployed => notDeployed;

  @override
  String toString() => message;
}

/// True when [details] is the function's own `{ "error": "…" }` body (as
/// opposed to the platform gateway's error page/shape).
bool _isOwnError(dynamic details) =>
    details is Map &&
    details['error'] is String &&
    (details['error'] as String).trim().isNotEmpty;

/// Extracts a useful string from a `FunctionException.details` value, which is
/// a decoded JSON map for our own errors but a string (sometimes HTML) for the
/// platform gateway.
String? _detail(dynamic details) {
  if (details is Map) {
    final v = details['error'] ?? details['message'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  if (details is String) {
    final s = details.trim();
    if (s.isEmpty || s.startsWith('<')) return null; // HTML gateway page
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }
  return null;
}

/// Maps an Edge Function failure to a user-facing message.
///
/// Kept public and pure so it can be unit-tested without a network call.
String paymentErrorMessage(int status, {dynamic details}) {
  final detail = _detail(details);
  switch (status) {
    case 404:
      // The function's own 404 (e.g. "Booking not found") must win; only a
      // gateway 404 with no `error` field means "not deployed".
      return _isOwnError(details)
          ? detail!
          : 'Online payment is not available yet — the payment service has not '
              'been deployed. Please choose "Pay at salon" for now.';
    case 401:
      return 'Your session has expired. Please sign in again and retry.';
    case 403:
      return detail ?? 'You are not allowed to pay for this booking.';
    case 503:
      return detail ??
          'Online payment is temporarily unavailable. Please try again later '
              'or pay at the salon.';
    default:
      return detail ?? 'Payment service error ($status).';
  }
}

/// Whether a failure means the `payments` function is not deployed at all.
bool _functionMissing(int status, dynamic details) =>
    status == 404 && !_isOwnError(details);

/// Talks to the `payments` Edge Function. The function owns every
/// money-related write; this repository only starts a checkout.
class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a `pending` payment for [bookingId] and returns the public
  /// checkout URL to open in the browser.
  Future<PaymentInitiation> initiate({
    required String bookingId,
    required String provider,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'payments/initiate',
        body: {'booking_id': bookingId, 'provider': provider},
      );

      final data = response.data;
      if (data is Map) {
        return PaymentInitiation.fromJson(Map<String, dynamic>.from(data));
      }
      throw const PaymentException(
        'Unexpected response from the payments service.',
      );
    } on FunctionException catch (e) {
      throw PaymentException(
        paymentErrorMessage(e.status, details: e.details),
        status: e.status,
        notDeployed: _functionMissing(e.status, e.details),
      );
    } on PaymentException {
      rethrow;
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment service. Check your connection and try '
        'again.',
      );
    }
  }
}
