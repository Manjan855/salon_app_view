/// Response of `POST /functions/v1/payments/initiate`.
///
/// The server creates a `pending` row in `public.payments` and returns the
/// public checkout URL the browser must visit. The client never sees or sends
/// the amount — it is read from the booking row server-side.
class PaymentInitiation {
  final String paymentId;
  final String checkoutUrl;
  final double amount;
  final String currency;
  final String provider; // esewa | khalti

  const PaymentInitiation({
    required this.paymentId,
    required this.checkoutUrl,
    required this.amount,
    required this.currency,
    required this.provider,
  });

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      paymentId: json['payment_id'] as String,
      checkoutUrl: json['checkout_url'] as String,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'NPR',
      provider: json['provider'] as String,
    );
  }
}

/// Result delivered on the `salonappview://payment-result` deep link after the
/// provider round-trip completes.
class PaymentResult {
  final bool paid;
  final String? provider;
  final String? paymentId;
  final String? bookingId;
  final String? reason;

  const PaymentResult({
    required this.paid,
    this.provider,
    this.paymentId,
    this.bookingId,
    this.reason,
  });

  /// Returns null when [uri] is not a payment-result deep link.
  static PaymentResult? fromUri(Uri uri) {
    if (uri.host != 'payment-result') return null;
    final q = uri.queryParameters;
    return PaymentResult(
      paid: q['status'] == 'paid',
      provider: q['provider'],
      paymentId: q['payment_id'],
      bookingId: q['booking_id'],
      reason: q['reason'],
    );
  }
}
