class SalonModel {
  final String id;
  final String? ownerId;
  final String name;
  final String? description;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? imageUrl;
  final String openingTime;
  final String closingTime;

  SalonModel({
    required this.id,
    this.ownerId,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.imageUrl,
    required this.openingTime,
    required this.closingTime,
  });

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'],
      imageUrl: json['image_url'],
      openingTime: json['opening_time'] ?? '09:00:00',
      closingTime: json['closing_time'] ?? '19:00:00',
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
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'image_url': imageUrl,
      'opening_time': openingTime,
      'closing_time': closingTime,
    };
  }
}
