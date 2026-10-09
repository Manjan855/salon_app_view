import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/available_slot.dart';
import '../shared/models/salon_model.dart';
import '../shared/models/service_model.dart';
import '../shared/models/staff_model.dart';

class SalonRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SalonModel>> getAllSalons() async {
    try {
      // Supabase auto-generates REST endpoints for your tables
      final response = await _supabase
          .from('salons')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List<dynamic>)
          .map((json) => SalonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load salons from backend: $e');
    }
  }

  /// Active services for one salon, in the salon's own display order.
  Future<List<ServiceModel>> getServicesBySalon(String salonId) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('salon_id', salonId)
          .eq('is_active', true)
          .order('sort_order');

      return (response as List<dynamic>)
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load services: $e');
    }
  }

  /// Active stylists for one salon.
  Future<List<StaffModel>> getStaffBySalon(String salonId) async {
    try {
      final response = await _supabase
          .from('staff')
          .select()
          .eq('salon_id', salonId)
          .eq('is_active', true)
          .order('name');

      return (response as List<dynamic>)
          .map((json) => StaffModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load stylists: $e');
    }
  }

  /// Real availability from the `get_available_slots` RPC.
  ///
  /// [date] is the salon-local calendar day. [staffId] narrows to one stylist;
  /// [durationMinutes] should be the total duration of the selected services.
  Future<List<AvailableSlot>> getAvailableSlots({
    required String salonId,
    required DateTime date,
    String? staffId,
    int? durationMinutes,
    bool includeUnavailable = false,
  }) async {
    try {
      String two(int v) => v.toString().padLeft(2, '0');
      final day = '${date.year}-${two(date.month)}-${two(date.day)}';

      final response = await _supabase.rpc(
        'get_available_slots',
        params: {
          'p_salon_id': salonId,
          'p_date': day,
          'p_staff_id': staffId,
          'p_duration_minutes': durationMinutes,
          'p_include_unavailable': includeUnavailable,
        },
      );

      return (response as List<dynamic>)
          .map((json) => AvailableSlot.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load available slots: $e');
    }
  }
}
