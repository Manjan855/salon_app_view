import 'package:flutter/material.dart';
import 'package:salon_app_view/features/salon_detail/salon_info.dart';
import 'package:salon_app_view/features/salon_detail/services_screen.dart';
import 'package:salon_app_view/features/appointment/appointment_screen.dart';
import 'package:salon_app_view/features/profile/profile_screen.dart';
import 'package:salon_app_view/core/router/route_name.dart';

const kPurpleDark = Color(0xFF2D1B6B);
const kPurpleMid = Color(0xFF3D2080);
const kPurpleAccent = Color(0xFF7B5EA7);
const kPurpleLight = Color(0xFF9B6FD4);
const kWhite = Color(0xFFFFFFFF);
const kTextMuted = Color(0xFFB8A9D9);


class SalonHomeScreen extends StatefulWidget {
  const SalonHomeScreen({super.key});
  @override
  State<SalonHomeScreen> createState() => _SalonHomeScreenState();
}

class _SalonHomeScreenState extends State<SalonHomeScreen> {
  int _bottomIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  
  final List<Map<String, String>> _nearbySalons = [
    {
      'name': 'Prince Hair Salon',
      'location': 'Near Town Hall',
      'image':
          'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=300',
    },
    {
      'name': 'Siddhi Beauty Parlour',
      'location': 'Near Cinema Hall',
      'image':
          'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=300',
    },
    {
      'name': 'CD Hair Studio',
      'location': 'Near Cinema Hall',
      'image':
          'https://images.unsplash.com/photo-1582095133179-bfd08e2594b9?w=300',
    },
    {
      'name': 'Glam Studio',
      'location': 'Near MG Road',
      'image':
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=300',
    },
  ];

  final List<Map<String, String>> _offers = [
    {
      'title': 'Haircuts',
      'discount': 'Upto\n55% off',
      'image':
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
    },
    {
      'title': 'Hair\nTreatment',
      'discount': 'Upto\n50% off',
      'image':
          'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400',
    },
    {
      'title': 'Skin Care',
      'discount': 'Upto\n40% off',
      'image':
          'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=400',
    },
  ];

  final List<Map<String, String>> _menServices = [
    {
      'title': 'Hair Cut',
      'image':
          'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=300',
    },
    {
      'title': 'Beard Trim',
      'image':
          'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=300',
    },
    {
      'title': 'Shaving',
      'image':
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=300',
    },
    {
      'title': 'Facial',
      'image':
          'https://images.unsplash.com/photo-1616394584738-fc6e612e71b9?w=300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kPurpleDark,
      drawer: _AppDrawer(
        onTabSelected: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
      ),
      body: _buildBodyContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBodyContent() {
    switch (_bottomIndex) {
      case 0:
        return SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionTitle('  📍 Salons near you'),
                      const SizedBox(height: 12),
                      _buildNearbySalons(),
                      const SizedBox(height: 28),
                      _buildTagline(),
                      const SizedBox(height: 20),
                      _buildOffersRow(),
                      const SizedBox(height: 28),
                      _buildSectionTitle('  Services for Men'),
                      const SizedBox(height: 12),
                      _buildMenServices(),
                      const SizedBox(height: 28),
                      _buildSectionTitle('  Services for Women'),
                      const SizedBox(height: 12),
                      _buildMenServices(), // reuse with different data in real app
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return const SalonInfoScreen();
      case 2:
        return const MyAppointmentsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Top App Bar ─────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kPurpleMid,
      child: Row(
        children: [
          // Hamburger
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu_rounded, color: kWhite, size: 26),
          ),
          const Spacer(),
          // Location
          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Text(
                  'Location',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: kWhite,
                  size: 20,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Notification bell with badge
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteName.notifications),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: kWhite, size: 26),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: kWhite,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  // ── Nearby Salons Horizontal List ────────────────────────
  Widget _buildNearbySalons() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _nearbySalons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final salon = _nearbySalons[i];
          return GestureDetector(
            onTap: () {
              final selectedSalon = SalonModel(
                name: salon['name']!,
                location: salon['location']!,
                image: salon['image']!,
                rating: 4.8,
                ratingCount: 154,
                offerText: 'Offers on haircuts',
                price: '₹150 for Men',
                discount: '30% off',
              );
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => SalonServicesScreen(salon: selectedSalon),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Image.network(
                      salon['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kPurpleAccent,
                        child: const Icon(Icons.store, color: kWhite, size: 40),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC1A0A4B)],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Text
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salon['name']!,
                            style: const TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            salon['location']!,
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tagline Banner ───────────────────────────────────────
  Widget _buildTagline() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Are you ready to\nexperience a Different you',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kPurpleLight,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.3,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ── Offers Row ───────────────────────────────────────────
  Widget _buildOffersRow() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final offer = _offers[i];
          return GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: i == 0 ? 220 : 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      offer['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: kPurpleAccent),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.transparent,
                            kPurpleDark.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            offer['title']!,
                            style: const TextStyle(
                              color: kWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            offer['discount']!,
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Men Services Grid ─────────────────────────────────────
  Widget _buildMenServices() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _menServices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final svc = _menServices[i];
          return GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Image.network(
                      svc['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kPurpleAccent,
                        child: const Icon(Icons.person, color: kWhite),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  svc['title']!,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Bottom Nav Bar ────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.explore_outlined, 'label': 'Explore'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Bookings'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: kPurpleMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _bottomIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _bottomIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? kPurpleLight.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: selected ? kPurpleLight : kTextMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: selected ? kPurpleLight : kTextMuted,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onTabSelected});
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
          
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: Colors.deepPurple,
              child: const Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: const Text(
                      'R',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rahul Sharma',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'rahul@email.com',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(0);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'My Appointments',
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(2);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favourites',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, RouteName.wishlist);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Offers & Promos',
                    badge: '3',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(3);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 24),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    iconColor: Colors.redAccent,
                    labelColor: Colors.redAccent,
                    onTap: () {},
                  ),
                ],
              ),
            ),

           
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge; // optional red badge text e.g. '3'
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
