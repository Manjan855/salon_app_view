import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/app_notification.dart';

/// Read + mark-read access to `public.notifications`. Rows themselves are
/// created server-side, so there is no insert here.
class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _table = 'notifications';

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<AppNotification>> getNotifications() async {
    final userId = _userId;
    if (userId == null) return [];

    try {
      final rows = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (rows as List<dynamic>)
          .map((r) => AppNotification.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> markRead(String id) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase
          .from(_table)
          .update({'is_read': true}).eq('id', id).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  Future<void> markAllRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _supabase
          .from(_table)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to update notifications: $e');
    }
  }
}
