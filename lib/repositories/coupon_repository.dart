import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/coupon_model.dart';

/// Publicly-readable active coupons (RLS hides expired/inactive rows).
class CouponRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _table = 'coupons';

  Future<List<CouponModel>> getActiveCoupons() async {
    try {
      final rows = await _supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('discount_percent', ascending: false);

      return (rows as List<dynamic>)
          .map((r) => CouponModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load offers: $e');
    }
  }
}
