// class SalonModel {
//   final String id;
//   final String name;
//   final String imageUrl;
//   final String address;
//   final double rating;
//   final int reviews;
//   final String distance;
//   final List<String> services;
//   final String openingTime;
//   final String closingTime;

//   SalonModel({
//     required this.id,
//     required this.name,
//     required this.imageUrl,
//     required this.address,
//     required this.rating,
//     required this.reviews,
//     required this.distance,
//     required this.services,
//     required this.openingTime,
//     required this.closingTime,
//   });

//   // Sample data
//   static List<SalonModel> getSampleSalons() {
//     return [
//       SalonModel(
//         id: '1',
//         name: 'Glamour Studio',
//         imageUrl: 'https://via.placeholder.com/150',
//         address: '123 Main Street, Downtown',
//         rating: 4.8,
//         reviews: 234,
//         distance: '0.5 km',
//         services: ['Haircut', 'Styling', 'Color'],
//         openingTime: '09:00',
//         closingTime: '21:00',
//       ),
//       SalonModel(
//         id: '2',
//         name: 'Royal Beauty Spa',
//         imageUrl: 'https://via.placeholder.com/150',
//         address: '456 Park Avenue',
//         rating: 4.9,
//         reviews: 567,
//         distance: '1.2 km',
//         services: ['Facial', 'Massage', 'Waxing'],
//         openingTime: '10:00',
//         closingTime: '22:00',
//       ),
//     ];
//   }
// }
class SalonModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double rating;
  final List<String> images;
  final List<SalonService> services;

  SalonModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.rating,
    required this.images,
    required this.services,
  });

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      services:
          (json['services'] as List<dynamic>?)
              ?.map((e) => SalonService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'rating': rating,
      'images': images,
      'services': services.map((e) => e.toJson()).toList(),
    };
  }
}

class SalonService {
  final String name;
  final double price;
  final int durationMinutes;

  SalonService({
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  factory SalonService.fromJson(Map<String, dynamic> json) {
    return SalonService(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price, 'duration_minutes': durationMinutes};
  }
}
