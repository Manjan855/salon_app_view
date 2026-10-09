import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/salon_model.dart';

/// Backs the Wishlist screen and the heart toggles on salon cards.
/// RLS restricts every row to the signed-in user.
class FavouriteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _table = 'favourites';

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Favourite salon ids for the current user (empty when signed out).
  Future<Set<String>> getFavouriteIds() async {
    final userId = _userId;
    if (userId == null) return <String>{};

    try {
      final rows = await _supabase
          .from(_table)
          .select('salon_id')
          .eq('user_id', userId);

      return (rows as List<dynamic>)
          .map((r) => (r as Map<String, dynamic>)['salon_id'] as String)
          .toSet();
    } catch (e) {
      throw Exception('Failed to load favourites: $e');
    }
  }

  /// Full salon rows (newest favourite first) for the Wishlist screen.
  Future<List<SalonModel>> getFavouriteSalons() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final rows = await _supabase
          .from(_table)
          .select('created_at, salon:salons(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (rows as List<dynamic>)
          .where((r) => (r as Map<String, dynamic>)['salon'] != null)
          .map((r) =>
              SalonModel.fromJson(r['salon'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load favourite salons: $e');
    }
  }

  Future<void> addFavourite(String salonId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Sign in to save favourites');
    try {
      await _supabase
          .from(_table)
          .insert({'user_id': userId, 'salon_id': salonId});
    } catch (e) {
      throw Exception('Failed to add favourite: $e');
    }
  }

  Future<void> removeFavourite(String salonId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Sign in to save favourites');
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('salon_id', salonId);
    } catch (e) {
      throw Exception('Failed to remove favourite: $e');
    }
  }
}
