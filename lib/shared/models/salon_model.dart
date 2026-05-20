class SalonModel {
  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final double rating;
  final int reviews;
  final String distance;
  final List<String> services;
  final String openingTime;
  final String closingTime;

  SalonModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.services,
    required this.openingTime,
    required this.closingTime,
  });

  // Sample data
  static List<SalonModel> getSampleSalons() {
    return [
      SalonModel(
        id: '1',
        name: 'Glamour Studio',
        imageUrl: 'https://via.placeholder.com/150',
        address: '123 Main Street, Downtown',
        rating: 4.8,
        reviews: 234,
        distance: '0.5 km',
        services: ['Haircut', 'Styling', 'Color'],
        openingTime: '09:00',
        closingTime: '21:00',
      ),
      SalonModel(
        id: '2',
        name: 'Royal Beauty Spa',
        imageUrl: 'https://via.placeholder.com/150',
        address: '456 Park Avenue',
        rating: 4.9,
        reviews: 567,
        distance: '1.2 km',
        services: ['Facial', 'Massage', 'Waxing'],
        openingTime: '10:00',
        closingTime: '22:00',
      ),
    ];
  }
}
