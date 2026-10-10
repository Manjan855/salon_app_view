/// Review row mapped to the `public.reviews` table.
///
/// Column contract (see supabase/migrations/20261006000001_schema.sql):
///   id, salon_id, user_id, booking_id, rating, comment, reply, is_visible,
///   created_at, updated_at
///
/// `userName` / `userAvatar` are display-only: the repository joins them in
/// from the sanctioned `public.profiles_public` view (the raw `profiles` table
/// is PII-locked by RLS). They are never written back.
class ReviewModel {
  final String id;
  final String salonId;
  final String userId;
  final String? bookingId;
  final int rating; // 1..5
  final String? comment;
  final String? reply; // salon's public response
  final bool isVisible;
  final DateTime createdAt;

  final String userName;
  final String? userAvatar;

  const ReviewModel({
    required this.id,
    required this.salonId,
    required this.userId,
    this.bookingId,
    required this.rating,
    this.comment,
    this.reply,
    this.isVisible = true,
    required this.createdAt,
    this.userName = 'Anonymous',
    this.userAvatar,
  });

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final name = json['user_name'] as String? ??
        (user is Map ? user['name'] as String? : null);
    final avatar = json['user_avatar'] as String? ??
        (user is Map ? user['profile_image_url'] as String? : null);

    return ReviewModel(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      userId: json['user_id'] as String,
      bookingId: json['booking_id'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      reply: json['reply'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      userName: (name == null || name.trim().isEmpty) ? 'Anonymous' : name,
      userAvatar: avatar,
    );
  }
}
