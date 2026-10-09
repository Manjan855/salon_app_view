/// Staff row mapped to the `public.staff` table.
///
/// Column contract (see supabase/migrations/20261006000001_schema.sql):
///   id, salon_id, user_id, name, title, specialties, image_url, phone,
///   is_active, created_at, updated_at
class StaffModel {
  final String id;
  final String salonId;
  final String name;
  final String? title;
  final List<String> specialties;
  final String? imageUrl;

  const StaffModel({
    required this.id,
    required this.salonId,
    required this.name,
    this.title,
    this.specialties = const [],
    this.imageUrl,
  });

  /// Label the booking UI shows on the stylist card.
  String get displayTitle => (title?.trim().isNotEmpty ?? false) ? title! : 'Stylist';

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      name: json['name'] as String,
      title: json['title'] as String?,
      specialties: (json['specialties'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'salon_id': salonId,
        'name': name,
        'title': title,
        'specialties': specialties,
        'image_url': imageUrl,
      };
}
