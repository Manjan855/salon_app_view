import 'package:flutter/material.dart';
import 'package:salon_app_view/features/salon_detail/slots_screen.dart';

// ─── Colors ───────────────────────────────────────────────
const kPurpleDark = Color(0xFF2D1B6B);
const kPurpleMid = Color(0xFF3D2080);
const kPurpleAccent = Color(0xFF7B2FBE);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);
const kGreen = Color(0xFF4CAF50);
const kRed = Color(0xFFE53935);

// ─── Ordered Service Model ────────────────────────────────
class OrderedService {
  final String name;
  final double originalPrice;
  final double discountedPrice;

  const OrderedService({
    required this.name,
    required this.originalPrice,
    required this.discountedPrice,
  });

  double get saved => originalPrice - discountedPrice;
}

// ─── Review Order Screen ──────────────────────────────────
class ReviewOrderScreen extends StatefulWidget {
  final List<OrderedService> services;
  final String salonName;
  final String salonLocation;

  const ReviewOrderScreen({
    super.key,
    required this.services,
    required this.salonName,
    required this.salonLocation,
  });

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  late List<OrderedService> _services;

  @override
  void initState() {
    super.initState();
    _services = List.from(widget.services);
  }

  double get _total => _services.fold(0, (sum, s) => sum + s.discountedPrice);

  int get _totalMins => _services.length * 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ─────────────────────────────────
            _buildAppBar(context),

            Expanded(
              child: Column(
                children: [
                  // ── Salon header ──────────────────────
                  _buildSalonHeader(),

                  // ── Order details title ───────────────
                  _buildOrderTitle(),

                  // ── Service list ──────────────────────
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _services.length,
                      separatorBuilder: (_, __) => Container(
                        height: 0.5,
                        color: kPurpleLight.withOpacity(0.2),
                      ),
                      itemBuilder: (ctx, i) => _OrderServiceTile(
                        service: _services[i],
                        onDelete: () => setState(() => _services.removeAt(i)),
                      ),
                    ),
                  ),

                  // ── Total + Continue ──────────────────
                  _buildBottomBar(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: kWhite,
                size: 24,
              ),
            ),
          ),
          const Text(
            'Review Order',
            style: TextStyle(
              color: kWhite,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: kPurpleMid,
      child: Column(
        children: [
          Text(
            widget.salonName,
            style: const TextStyle(
              color: kPurpleLight,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: kPurpleLight,
                size: 13,
              ),
              const SizedBox(width: 3),
              Text(
                widget.salonLocation,
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Order Details',
            style: TextStyle(
              color: kWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$_totalMins mins',
            style: const TextStyle(color: kTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Total amount',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Inclusive of all taxes & charges',
                    style: TextStyle(color: kTextMuted, fontSize: 11),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      '₹${_total.toInt()}',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: kTextMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SlotsAvailabilityScreen(salonName: widget.salonName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurpleAccent,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Service Tile ───────────────────────────────────
class _OrderServiceTile extends StatelessWidget {
  const _OrderServiceTile({required this.service, required this.onDelete});

  final OrderedService service;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              const  Row(
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: kGreen,
                      size: 11,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Free Cancellation',
                      style: TextStyle(color: kGreen, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '₹${service.originalPrice.toInt()}',
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: kTextMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${service.discountedPrice.toInt()}',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Saved ₹${service.saved.toInt()}',
                style: const TextStyle(
                  color: kGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: kRed,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
