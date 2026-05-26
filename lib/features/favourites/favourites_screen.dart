import 'package:flutter/material.dart';
import 'package:salon_app_view/features/salon_detail/salon_info.dart';
import 'package:salon_app_view/features/salon_detail/services_screen.dart';

const kPurpleDark = Color(0xFF1A0A3B);
const kPurpleMid = Color(0xFF2D1B6B);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);
const kGold = Color(0xFFFFD700);

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  // Mock favorites list
  final List<SalonModel> _favSalons = [
    const SalonModel(
      name: 'Prince Hair Salon',
      location: 'Near Town Hall',
      rating: 4.5,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹150 for Men',
      discount: '35% off',
      image: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=300',
    ),
    const SalonModel(
      name: 'Affinity Salon',
      location: 'Near Town Hall',
      rating: 4.5,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹200 for Men',
      discount: '30% off',
      image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=300',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurpleDark,
      appBar: AppBar(
        title: const Text(
          'Favourites',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w700),
        ),
        backgroundColor: kPurpleMid,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: kWhite),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _favSalons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    color: kTextMuted.withOpacity(0.3),
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Favourites Yet',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your favorite salons will show up here.',
                    style: TextStyle(color: kTextMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _favSalons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final salon = _favSalons[i];
                return Container(
                  decoration: BoxDecoration(
                    color: kPurpleMid,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kPurpleLight.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                salon.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: kPurpleAccent,
                                  child: const Icon(Icons.store, color: kWhite),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    salon.name,
                                    style: const TextStyle(
                                      color: kWhite,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    salon.location,
                                    style: const TextStyle(
                                      color: kTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: kGold, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${salon.rating} (${salon.ratingCount} reviews)',
                                        style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _favSalons.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(height: 0.5, color: kPurpleLight.withOpacity(0.2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              salon.price,
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SalonServicesScreen(salon: salon),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPurpleAccent,
                                foregroundColor: kWhite,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Book Now',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
