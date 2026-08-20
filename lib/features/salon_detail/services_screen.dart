import 'package:flutter/material.dart';
import 'package:salon_app_view/features/salon_detail/reviews_screen.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';

const kGreen = Color(0xFF4CAF50);
const kGold = Color(0xFFFFD700);

// ─── Service Model ────────────────────────────────────────
class ServiceItem {
  final String name;
  final double originalPrice;
  final double discountedPrice;
  final bool freeCancellation;
  bool added;

  ServiceItem({
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
    this.freeCancellation = true,
    this.added = false,
  });
}

// ─── Services Screen ──────────────────────────────────────
class SalonServicesScreen extends StatefulWidget {
  final dynamic salon; // accepts SalonModel or null for standalone use
  const SalonServicesScreen({super.key, this.salon});

  @override
  State<SalonServicesScreen> createState() => _SalonServicesScreenState();
}

class _SalonServicesScreenState extends State<SalonServicesScreen> {
  final List<ServiceItem> _services = [
    ServiceItem(name: 'Men: Haircut', originalPrice: 220, discountedPrice: 150),
    ServiceItem(
      name: 'Men: Haircut+Hair Wash\n+Beard Styling',
      originalPrice: 450,
      discountedPrice: 350,
    ),
    ServiceItem(
      name: 'Women: Haircut+Hair Wash\n+Blow-Dry',
      originalPrice: 700,
      discountedPrice: 580,
    ),
    ServiceItem(
      name: 'Women: Threading\n(Eyebrows)',
      originalPrice: 120,
      discountedPrice: 80,
    ),
    ServiceItem(
      name: 'Men: Beard Trim',
      originalPrice: 150,
      discountedPrice: 100,
    ),
    ServiceItem(
      name: 'Women: Facial\n(Basic)',
      originalPrice: 800,
      discountedPrice: 620,
    ),
  ];

  AppThemeColors get colors => AppThemeColors.of(context);

  String get _totalTime {
    final count = _services.where((s) => s.added).length;
    return '${count * 30} mins';
  }

  double get _totalPrice => _services
      .where((s) => s.added)
      .fold(0, (sum, s) => sum + s.discountedPrice);

  bool get _hasSelection => _services.any((s) => s.added);

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;

    final salonName = widget.salon?.name ?? 'Prince Hair Salon';
    final salonLocation = widget.salon?.location ?? 'Near Town Hall';

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, salonName, salonLocation),
                    _buildInfoRow(),
                    const SizedBox(height: 4),
                    _buildDivider(),
                    ..._services.asMap().entries.map(
                      (e) => _ServiceTile(
                        item: e.value,
                        isFirst: e.key == 0,
                        onToggle: () =>
                            setState(() => e.value.added = !e.value.added),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ──────────────────────────────────
            _buildBottomCTA(context),
          ],
        ),
      ),
    );
  }

  // ── Header with image + back ──────────────────────────────
  Widget _buildHeader(BuildContext context, String name, String location) {
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    return Stack(
      children: [
        // Hero image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: Image.network(
            widget.salon?.image ??
                'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=600',
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 220,
              color: kPurpleAccent,
              child: Icon(Icons.store, color: kWhite, size: 60),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: 12,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kPurpleDark.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: kWhite,
                size: 20,
              ),
            ),
          ),
        ),
        // Salon name overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [kPurpleDark, kPurpleDark.withValues(alpha: 0.0)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kPurpleMid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kPurpleLight.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.navigation_rounded,
                        color: kPurpleLight,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '1.5km',
                        style: TextStyle(
                          color: kPurpleLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Call button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurpleAccent,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Call',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Category / Hours row ──────────────────────────────────
  Widget _buildInfoRow() {
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: TextStyle(color: kTextMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Unisex',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mon-Sun',
                style: TextStyle(color: kTextMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                '10:00 am - 10:00 pm',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final kPurpleLight = colors.purpleLight;
    return Container(
      height: 0.5,
      color: kPurpleLight.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  // ── Bottom CTA ────────────────────────────────────────────
  Widget _buildBottomCTA(BuildContext context) {
    final salonName = widget.salon?.name ?? 'Prince Hair Salon';
    final salonLocation = widget.salon?.location ?? 'Near Town Hall';

    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kPurpleMid,
        border: Border(
          top: BorderSide(color: kPurpleLight.withOpacity(0.2), width: 0.5),
        ),
      ),
      child: _hasSelection
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total price row
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_services.where((s) => s.added).length} service(s) selected',
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                      Text(
                        '₹${_totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedItems = _services
                          .where((s) => s.added)
                          .map((s) => OrderedService(
                                name: s.name,
                                originalPrice: s.originalPrice,
                                discountedPrice: s.discountedPrice,
                              ))
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewOrderScreen(
                            services: selectedItems,
                            salonName: salonName,
                            salonLocation: salonLocation,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tap and review',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kPurpleDark.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Total Time : $_totalTime',
                            style: TextStyle(
                              fontSize: 10,
                              color: kTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurpleAccent.withOpacity(0.4),
                  foregroundColor: kTextMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tap and review',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPurpleDark.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Total Time : 30 mins',
                        style: TextStyle(fontSize: 10, color: kTextMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Service Tile ─────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.item,
    required this.onToggle,
    this.isFirst = false,
  });

  final ServiceItem item;
  final VoidCallback onToggle;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: kGreen,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Free Cancellation',
                          style: TextStyle(
                            color: kGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pricing + button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Original price (strikethrough)
                  Text(
                    '₹${item.originalPrice.toInt()}',
                    style: TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: kTextMuted,
                    ),
                  ),
                  // Discounted price
                  Text(
                    '₹${item.discountedPrice.toInt()}',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'inc. of all taxes',
                    style: TextStyle(color: kTextMuted, fontSize: 9),
                  ),
                  const SizedBox(height: 6),
                  // Add / Booked button
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.added
                            ? kGreen.withOpacity(0.15)
                            : kPurpleAccent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item.added ? kGreen : kPurpleAccent,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        item.added ? 'Booked ✓' : 'Add+',
                        style: TextStyle(
                          color: item.added ? kGreen : kWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 0.5,
          color: kPurpleLight.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ],
    );
  }
}
