// class ServiceModel {
//   final String id;
//   final String name;
//   final String description;
//   final double price;
//   final int duration; // in minutes
//   final String imageUrl;
//   final List<String>? addOns;

//   ServiceModel({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.price,
//     required this.duration,
//     required this.imageUrl,
//     this.addOns,
//   });

//   // Sample services
//   static List<ServiceModel> getSampleServices() {
//     return [
//       ServiceModel(
//         id: '1',
//         name: 'Haircut & Styling',
//         description: 'Professional haircut with styling',
//         price: 35.00,
//         duration: 45,
//         imageUrl: 'https://via.placeholder.com/150',
//         addOns: ['Hair Wash', 'Scalp Massage'],
//       ),
//       ServiceModel(
//         id: '2',
//         name: 'Premium Facial',
//         description: 'Deep cleansing and glow facial',
//         price: 50.00,
//         duration: 60,
//         imageUrl: 'https://via.placeholder.com/150',
//         addOns: ['Face Mask', 'Serum Application'],
//       ),
//     ];
//   }
// }
class ServiceModel {
  final String id;
  final String salonId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final String category;

  /// Audience facet from `public.services.gender`
  /// ('men' | 'women' | 'unisex'), used by the Explore Gender filter.
  final String gender;
  final String? imageUrl;

  ServiceModel({
    required this.id,
    required this.salonId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    this.gender = 'unisex',
    this.imageUrl,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      salonId: json['salon_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['duration_minutes'],
      category: json['category'] ?? 'General',
      gender: json['gender'] ?? 'unisex',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salon_id': salonId,
      'name': name,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'category': category,
      'gender': gender,
      'image_url': imageUrl,
    };
  }
}
