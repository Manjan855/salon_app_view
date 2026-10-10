import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/features/salon_detail/reviews_screen.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/features/salon_detail/salon_reviews_screen.dart';
import 'package:salon_app_view/repositories/salon_repositories.dart';
import 'package:salon_app_view/shared/models/salon_model.dart';
import 'package:salon_app_view/shared/models/service_model.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/providers/favourite_provider.dart';

const kGreen = Color(0xFF4CAF50);
const kGold = Color(0xFFFFD700);

// ─── Service Model ────────────────────────────────────────
class ServiceItem {
  /// `public.services.id` when this row came from the backend.
  final String? id;
  final String name;
  final double originalPrice;
  final double discountedPrice;
  final int durationMinutes;
  final bool freeCancellation;
  bool added;

  ServiceItem({
    this.id,
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
    this.durationMinutes = 30,
    this.freeCancellation = true,
    this.added = false,
  });

  factory ServiceItem.fromService(ServiceModel s) => ServiceItem(
        id: s.id,
        name: s.name,
        originalPrice: s.price,
        discountedPrice: s.price,
        durationMinutes: s.durationMinutes,
      );

  bool get hasDiscount => originalPrice > discountedPrice;
}

// ─── Services Screen ──────────────────────────────────────
class SalonServicesScreen extends StatefulWidget {
  /// Accepts the shared `SalonModel` (has `id`) or the UI-only model from
  /// `salon_info.dart` (also carries `id`). `salonId` overrides either.
  final dynamic salon;
  final String? salonId;

  const SalonServicesScreen({super.key, this.salon, this.salonId});

  @override
  State<SalonServicesScreen> createState() => _SalonServicesScreenState();
}

class _SalonServicesScreenState extends State<SalonServicesScreen> {
  final SalonRepository _repo = SalonRepository();

  List<ServiceItem> _services = [];
  bool _loading = false;
  String? _error;

  AppThemeColors get colors => AppThemeColors.of(context);

  String? get _salonId => widget.salonId ?? widget.salon?.id as String?;
  String get _salonName => widget.salon?.name as String? ?? 'Salon';
  String get _salonLocation => widget.salon?.location as String? ?? '';
  String? get _salonImage => widget.salon?.image as String?;

  /// The screen accepts either the shared `SalonModel` (has `ratingAvg`) or
  /// the UI-only model in `salon_info.dart` (has `rating`). Read whichever is
  /// present without hard-depending on the other type.
  double get _ratingAvg {
    final s = widget.salon;
    if (s == null) return 0;
    if (s is SalonModel) return s.ratingAvg;
    try {
      return (s.rating as num).toDouble();
    } on NoSuchMethodError {
      return 0;
    }
  }

  int get _ratingCount {
    final s = widget.salon;
    if (s == null) return 0;
    if (s is SalonModel) return s.ratingCount;
    try {
      return (s.ratingCount as num).toInt();
    } on NoSuchMethodError {
      return 0;
    }
  }

  void _openReviews() {
    final id = _salonId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalonReviewsScreen(salonId: id, salonName: _salonName),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (_salonId != null) {
      _loadServices();
    } else {
      _services = _mockServices();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user?.id;
      context.read<FavouriteProvider>().ensureLoaded(userId: userId);
    });
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final models = await _repo.getServicesBySalon(_salonId!);
      if (!mounted) return;
      setState(() {
        _services = models.map(ServiceItem.fromService).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static List<ServiceItem> _mockServices() => [
        ServiceItem(
          name: 'Men: Haircut',
          originalPrice: 220,
          discountedPrice: 150,
        ),
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

  String get _totalTime {
    final mins = _services
        .where((s) => s.added)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    return '$mins mins';
  }

  double get _totalPrice => _services
      .where((s) => s.added)
      .fold(0, (sum, s) => sum + s.discountedPrice);

  bool get _hasSelection => _services.any((s) => s.added);

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (!_loading && _services.isNotEmpty) _buildBottomCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, _salonName, _salonLocation),
          _buildInfoRow(),
          if (_salonId != null) _buildReviewsRow(),
          const SizedBox(height: 4),
          _buildDivider(),
          if (_services.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No services listed for this salon yet.',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
            ),
          ..._services.asMap().entries.map(
                (e) => _ServiceTile(
                  item: e.value,
                  isFirst: e.key == 0,
                  onToggle: () => setState(() => e.value.added = !e.value.added),
                ),
              ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: colors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Could not load services.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadServices,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header with image + back ──────────────────────────────
  Widget _buildHeader(BuildContext context, String name, String location) {
    final kPurpleDark = colors.purpleDark;
    final kPurpleAccent = colors.purpleAccent;
    final kWhite = colors.white;

    return Stack(
      children: [
        // Hero image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: Image.network(
            _salonImage ??
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
        // Favourite button
        if (_salonId != null)
          Positioned(
            top: 12,
            right: 16,
            child: Builder(
              builder: (context) {
                final isFav = context
                    .watch<FavouriteProvider>()
                    .isFavourite(_salonId);
                return GestureDetector(
                  onTap: () async {
                    try {
                      await context
                          .read<FavouriteProvider>()
                          .toggle(_salonId!);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e
                                .toString()
                                .replaceAll('Exception:', '')
                                .trim(),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPurpleDark.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? Colors.redAccent : kWhite,
                      size: 20,
                    ),
                  ),
                );
              },
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

  // ── Reviews entry point ───────────────────────────────────
  Widget _buildReviewsRow() {
    final kPurpleAccent = colors.purpleAccent;
    final kTextMuted = colors.textMuted;
    final rating = _ratingAvg;
    final count = _ratingCount;

    return InkWell(
      onTap: _openReviews,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(
          children: [
            RatingStars(rating: rating, size: 15),
            const SizedBox(width: 8),
            Text(
              rating > 0
                  ? '${rating.toStringAsFixed(1)} ($count)'
                  : 'No ratings yet',
              style: TextStyle(color: kTextMuted, fontSize: 12),
            ),
            const Spacer(),
            Text(
              'See all reviews',
              style: TextStyle(
                color: kPurpleAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: kPurpleAccent, size: 18),
          ],
        ),
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
                        'Rs ${_totalPrice.toStringAsFixed(0)}',
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
                                serviceId: s.id,
                                name: s.name,
                                originalPrice: s.originalPrice,
                                discountedPrice: s.discountedPrice,
                                durationMinutes: s.durationMinutes,
                              ))
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewOrderScreen(
                            services: selectedItems,
                            salonId: _salonId,
                            salonName: _salonName,
                            salonLocation: _salonLocation,
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
                        'Total Time : 0 mins',
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
                  // Original price (strikethrough) — only when discounted.
                  if (item.hasDiscount)
                    Text(
                      'Rs ${item.originalPrice.toInt()}',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: kTextMuted,
                      ),
                    ),
                  // Price
                  Text(
                    'Rs ${item.discountedPrice.toInt()}',
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
