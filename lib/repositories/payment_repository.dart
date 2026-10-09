import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/payment_model.dart';

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
        return PaymentInitiation.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      throw Exception('Unexpected response from the payments service.');
    } on FunctionException catch (e) {
      throw Exception(_message(e.details) ?? 'Payment service error (${e.status}).');
    }
  }

  String? _message(dynamic details) {
    if (details is Map) {
      final value = details['error'];
      if (value is String) return value;
    }
    if (details is String && details.isNotEmpty) return details;
    return null;
  }
}
