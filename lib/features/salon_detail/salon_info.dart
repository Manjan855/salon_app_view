import 'package:flutter/material.dart';
import 'package:salon_app_view/features/salon_detail/services_screen.dart';

// ─── Colors ───────────────────────────────────────────────
const kPurpleDark = Color(0xFF2D1B6B);
const kPurpleMid = Color(0xFF3D2080);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);
const kGold = Color(0xFFFFD700);
const kGreen = Color(0xFF4CAF50);

// ─── Salon Model ──────────────────────────────────────────
class SalonModel {
  final String name;
  final String location;
  final double rating;
  final int ratingCount;
  final String offerText;
  final String price;
  final String discount;
  final String image;

  const SalonModel({
    required this.name,
    required this.location,
    required this.rating,
    required this.ratingCount,
    required this.offerText,
    required this.price,
    required this.discount,
    required this.image,
  });
}

// ─── Info Screen ──────────────────────────────────────────
class SalonInfoScreen extends StatefulWidget {
  const SalonInfoScreen({super.key});

  @override
  State<SalonInfoScreen> createState() => _SalonInfoScreenState();
}

class _SalonInfoScreenState extends State<SalonInfoScreen> {
  String _selectedGender = 'All';

  final List<SalonModel> _salons = const [
    SalonModel(
      name: 'Prince Hair Salon',
      location: 'Near Town Hall',
      rating: 4.5,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹150 for Men',
      discount: '35% off',
      image:
          'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=300',
    ),
    SalonModel(
      name: 'CD Hair Salon',
      location: 'Near Town Hall',
      rating: 4.8,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹170 for Men',
      discount: '25% off',
      image:
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=300',
    ),
    SalonModel(
      name: 'Affinity Salon',
      location: 'Near Town Hall',
      rating: 4.5,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹200 for Men',
      discount: '30% off',
      image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=300',
    ),
    SalonModel(
      name: 'Hair Masters Salon',
      location: 'Near Town Hall',
      rating: 4.5,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹130 for Men',
      discount: '35% off',
      image:
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=300',
    ),
    SalonModel(
      name: 'Good Looks Hair Salon',
      location: 'Near Town Hall',
      rating: 4.8,
      ratingCount: 245,
      offerText: 'Offers on Haircuts',
      price: '₹160 for Men',
      discount: '20% off',
      image:
          'https://images.unsplash.com/photo-1582095133179-bfd08e2594b9?w=300',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildFilterBar(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _salons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _SalonCard(
                  salon: _salons[i],
                  onViewTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalonServicesScreen(salon: _salons[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: kWhite,
                size: 24,
              ),
            )
          else
            const SizedBox(width: 24),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.search_rounded, color: kWhite, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kPurpleMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showFilterSheet(),
              child:const Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.filter_list_rounded, color: kWhite, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 0.5,
            height: 36,
            color: kPurpleLight.withOpacity(0.4),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showGenderSheet(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedGender == 'All' ? 'Gender' : _selectedGender,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: kWhite,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(),
    );
  }

  void _showGenderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenderSheet(
        selected: _selectedGender,
        onSelect: (g) {
          setState(() => _selectedGender = g);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Salon Card ───────────────────────────────────────────
class _SalonCard extends StatelessWidget {
  const _SalonCard({required this.salon, required this.onViewTap});
  final SalonModel salon;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kPurpleMid,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: image + info ──
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    salon.image,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      color: kPurpleAccent,
                      child: const Icon(Icons.store, color: kWhite),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salon.name,
                        style: const TextStyle(
                          color: kPurpleLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        salon.location,
                        style: const TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final full = i < salon.rating.floor();
                            final half = !full && i < salon.rating;
                            return Icon(
                              full
                                  ? Icons.star_rounded
                                  : half
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                              color: kGold,
                              size: 14,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '${salon.rating} (${salon.ratingCount} ratings)',
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Container(height: 0.5, color: kPurpleLight.withOpacity(0.2)),

          // ── Bottom row: offer + view button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salon.offerText,
                        style: const TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        salon.price,
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        salon.discount,
                        style: const TextStyle(
                          color: kGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: onViewTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurpleAccent,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {},
                      child:const Row(
                        children: const [
                          Text(
                            'Add to Favourites',
                            style: TextStyle(color: kTextMuted, fontSize: 10),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.favorite_border_rounded,
                            color: kTextMuted,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────
class _FilterSheet extends StatefulWidget {
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  double _maxPrice = 200;
  String _sortBy = 'Rating';
  final _sorts = ['Rating', 'Distance', 'Price: Low', 'Price: High'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kPurpleMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kPurpleLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _maxPrice = 200;
                  _sortBy = 'Rating';
                }),
                child: const Text(
                  'Reset',
                  style: TextStyle(color: kPurpleLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sort by',
            style: TextStyle(
              color: kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _sorts
                .map(
                  (s) => GestureDetector(
                    onTap: () => setState(() => _sortBy = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _sortBy == s ? kPurpleAccent : kPurpleDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _sortBy == s
                              ? kPurpleAccent
                              : kPurpleLight.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: _sortBy == s ? kWhite : kTextMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Max Price',
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${_maxPrice.round()}',
                style: const TextStyle(
                  color: kPurpleLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kPurpleAccent,
              inactiveTrackColor: kPurpleDark,
              thumbColor: kPurpleLight,
              overlayColor: kPurpleAccent.withOpacity(0.2),
            ),
            child: Slider(
              value: _maxPrice,
              min: 50,
              max: 500,
              divisions: 45,
              onChanged: (v) => setState(() => _maxPrice = v),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurpleAccent,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gender Bottom Sheet ──────────────────────────────────
class _GenderSheet extends StatelessWidget {
  const _GenderSheet({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = ['All', 'Men', 'Women', 'Unisex'];
    return Container(
      decoration: const BoxDecoration(
        color: kPurpleMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kPurpleLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Gender',
            style: TextStyle(
              color: kWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (g) => GestureDetector(
              onTap: () => onSelect(g),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected == g ? kPurpleAccent : kPurpleDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == g
                        ? kPurpleAccent
                        : kPurpleLight.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      g,
                      style: TextStyle(
                        color: selected == g ? kWhite : kTextMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selected == g)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: kWhite,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
