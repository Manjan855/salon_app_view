import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/salon_model.dart';

class SalonRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SalonModel>> getAllSalons() async {
    try {
      // Supabase auto-generates REST endpoints for your tables
      final response = await _supabase.from('salons').select();

      return (response as List<dynamic>)
          .map((json) => SalonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load salons from backend: $e');
    }
  }
}
