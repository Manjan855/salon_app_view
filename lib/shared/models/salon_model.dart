class SalonModel {
  final String id;
  final String? ownerId;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String? province;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? imageUrl;
  final String openingTime;
  final String closingTime;

  /// Rollups / scheduling fields seeded on `public.salons`.
  final double ratingAvg;
  final int ratingCount;
  final int slotMinutes;

  SalonModel({
    required this.id,
    this.ownerId,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.province,
    this.latitude,
    this.longitude,
    this.phone,
    this.imageUrl,
    required this.openingTime,
    required this.closingTime,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.slotMinutes = 30,
  });

  /// Human-readable location for the SalonServicesScreen header. Mirrors the
  /// UI-only model in `features/salon_detail/salon_info.dart` so either model
  /// can be passed to the (dynamic) `salon` parameter.
  String get location => address.isNotEmpty ? address : city;

  /// Alias for [imageUrl], mirroring the UI-only model's `image` field.
  String? get image => imageUrl;

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      province: json['province'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'],
      imageUrl: json['image_url'],
      openingTime: json['opening_time'] ?? '09:00:00',
      closingTime: json['closing_time'] ?? '19:00:00',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      slotMinutes: (json['slot_minutes'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'image_url': imageUrl,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'slot_minutes': slotMinutes,
    };
  }
}
