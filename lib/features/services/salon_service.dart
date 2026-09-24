import 'package:salon_app_view/shared/models/appointment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salon_app_view/shared/models/salon_model.dart';
import 'package:salon_app_view/shared/models/service_model.dart';

class SalonService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Fetch all available salons
  Future<List<SalonModel>> getSalons() async {
    final response = await _supabase.from('salons').select();
    return (response as List).map((json) => SalonModel.fromJson(json)).toList();
  }

  // 2. Fetch services offered by a specific salon
  Future<List<ServiceModel>> getSalonServices(String salonId) async {
    final response = await _supabase
        .from('services')
        .select()
        .eq('salon_id', salonId);
    return (response as List)
        .map((json) => ServiceModel.fromJson(json))
        .toList();
  }

  // 3. Create a new appointment
  Future<AppointmentModel> createAppointment(
    AppointmentModel appointment,
  ) async {
    final response = await _supabase
        .from('appointments')
        .insert(appointment.toJson())
        .select()
        .single();
    return AppointmentModel.fromJson(response);
  }

  // 4. Fetch appointment history for logged-in user
  Future<List<AppointmentModel>> getUserAppointments(String customerId) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('customer_id', customerId)
        .order('appointment_date', ascending: false);
    return (response as List)
        .map((json) => AppointmentModel.fromJson(json))
        .toList();
  }
}
