class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int duration; // in minutes
  final String imageUrl;
  final List<String>? addOns;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.imageUrl,
    this.addOns,
  });

  // Sample services
  static List<ServiceModel> getSampleServices() {
    return [
      ServiceModel(
        id: '1',
        name: 'Haircut & Styling',
        description: 'Professional haircut with styling',
        price: 35.00,
        duration: 45,
        imageUrl: 'https://via.placeholder.com/150',
        addOns: ['Hair Wash', 'Scalp Massage'],
      ),
      ServiceModel(
        id: '2',
        name: 'Premium Facial',
        description: 'Deep cleansing and glow facial',
        price: 50.00,
        duration: 60,
        imageUrl: 'https://via.placeholder.com/150',
        addOns: ['Face Mask', 'Serum Application'],
      ),
    ];
  }
}
