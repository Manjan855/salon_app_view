import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/features/salon_detail/salon_info.dart';
import 'package:salon_app_view/features/salon_detail/services_screen.dart';
import 'package:salon_app_view/features/appointment/appointment_screen.dart';
import 'package:salon_app_view/features/profile/profile_screen.dart';
import 'package:salon_app_view/core/router/route_name.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/shared/widgets/settings_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final List<Map<String, String>> _womenServices = [
    {
      'title': 'Hair Styling',
      'image':
          'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=300',
    },
    {
      'title': 'Facial & Cleanup',
      'image':
          'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=300',
    },
    {
      'title': 'Manicure',
      'image':
          'https://images.unsplash.com/photo-1604654894610-df4906b18563?w=300',
    },
    {
      'title': 'Hair Coloring',
      'image':
          'https://images.unsplash.com/photo-1605497746444-ac9da58d440f?w=300',
    },
  ];

  AppThemeColors get colors => AppThemeColors.of(context);

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kPurpleDark,
      drawer: AppDrawer(
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
                      _buildServicesGrid(_menServices),
                      const SizedBox(height: 28),
                      _buildSectionTitle('  Services for Women'),
                      const SizedBox(height: 12),
                      _buildServicesGrid(_womenServices),
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

  Widget _buildTopBar() {
    final kPurpleMid = colors.purpleMid;
    final kWhite = colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kPurpleMid,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Icon(Icons.menu_rounded, color: kWhite, size: 26),
          ),
          const Spacer(),
          Flexible(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Location',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: kWhite,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteName.notifications),
            child: Stack(
              children: [
                Icon(Icons.notifications_outlined, color: kWhite, size: 26),
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

  Widget _buildSectionTitle(String title) {
    final kWhite = colors.white;
    return Text(
      title,
      style: TextStyle(
        color: kWhite,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildNearbySalons() {
    final kPurpleAccent = colors.purpleAccent;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

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
              // Ensure SalonModel matches your project definition structure
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
                    Image.network(
                      salon['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kPurpleAccent,
                        child: Icon(Icons.store, color: kWhite, size: 40),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            kPurpleAccent.withOpacity(0.8),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salon['name']!,
                            style: TextStyle(
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
                            style: TextStyle(color: kTextMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildTagline() {
    final kPurpleLight = colors.purpleLight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildOffersRow() {
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleDark = colors.purpleDark;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

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
                            kPurpleDark.withValues(alpha: 0.85),
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
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            offer['discount']!,
                            style: TextStyle(
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

  Widget _buildServicesGrid(List<Map<String, String>> servicesList) {
    final kPurpleAccent = colors.purpleAccent;
    final kWhite = colors.white;

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: servicesList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final svc = servicesList[i];
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
                        child: Icon(Icons.person, color: kWhite),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  svc['title']!,
                  style: TextStyle(
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

  Widget _buildBottomNav() {
    final kPurpleMid = colors.purpleMid;
    final kPurpleLight = colors.purpleLight;
    final kTextMuted = colors.textMuted;

    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.explore_outlined, 'label': 'Explore'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Bookings'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: kPurpleMid,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        ? kPurpleLight.withValues(alpha: 0.2)
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

// class _AppDrawer extends StatelessWidget {
//   const _AppDrawer({required this.onTabSelected});
//   final ValueChanged<int> onTabSelected;

//   @override
//   Widget build(BuildContext context) {
//     final user = Supabase.instance.client.auth.currentUser;
//    // final authProvider = Provider.of<AuthProvider>(context);
//     final String userEmail = user?.email ?? 'No Email';
// // Check Supabase metadata if you attached a name during sign up
// final String userName = user?.userMetadata?['name'] ?? 'Guest User';

//     // Fixed: Corrected missing bracket token syntax for safely isolating first initial
//     final userInitials = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

//     final colors = AppThemeColors.of(context);
// return Drawer(
//   child: ListView(
//     children: [
//       UserAccountsDrawerHeader(
//         accountName: Text(userName),
//         accountEmail: Text(userEmail),
//         currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
//       ),
//       // ... rest of your drawer items
//          Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//               color: colors.purpleAccent,
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 28,
//                     backgroundColor: Colors.white24,
//                     child: Text(
//                       userInitials,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           userName,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           userEmail,
//                           style: const TextStyle(color: Colors.white70, fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   _DrawerItem(
//                     icon: Icons.home_outlined,
//                     label: 'Home',
//                     onTap: () {
//                       Navigator.pop(context);
//                       onTabSelected(0);
//                     },
//                   ),
//                   _DrawerItem(
//                     icon: Icons.calendar_today_outlined,
//                     label: 'My Appointments',
//                     onTap: () {
//                       Navigator.pop(context);
//                       onTabSelected(2);
//                     },
//                   ),
//                   _DrawerItem(
//                     icon: Icons.favorite_border_rounded,
//                     label: 'Wishlist',
//                     onTap: () {
//                       Navigator.pop(context);
//                       Navigator.pushNamed(context, RouteName.wishlist);
//                     },
//                   ),
//                   _DrawerItem(
//                     icon: Icons.local_offer_outlined,
//                     label: 'Offers & Promos',
//                     badge: '3',
//                     onTap: () {},
//                   ),
//                   _DrawerItem(
//                     icon: Icons.person_outline_rounded,
//                     label: 'Profile',
//                     onTap: () {
//                       Navigator.pop(context);
//                       onTabSelected(3);
//                     },
//                   ),
//                   _DrawerItem(
//                     icon: Icons.settings_outlined,
//                     label: 'Settings',
//                     onTap: () {
//                       Navigator.pop(context);
//                       showSettingsBottomSheet(context);
//                     },
//                   ),
//                   Divider(
//                     indent: 20,
//                     endIndent: 20,
//                     height: 24,
//                     color: colors.purpleLight.withOpacity(0.2),
//                   ),
//                   _DrawerItem(
//                     icon: Icons.help_outline_rounded,
//                     label: 'Help & Support',
//                     onTap: () {},
//                   ),
//                   _DrawerItem(
//                     icon: Icons.logout_rounded,
//                     label: 'Logout',
//                     iconColor: Colors.redAccent,
//                     labelColor: Colors.redAccent,
//                     onTap: () {
//                       Navigator.pop(context);
//                       _showLogoutDialog(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Text(
//                 'Version 1.0.0',
//                 style: TextStyle(color: colors.textMuted, fontSize: 12),
//               ),
//             ),
//     ],
//   ),
// );
//   }

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onTabSelected});
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    // Watch the AuthProvider for changes
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Pull email and user_metadata dynamically
    final String email = user?.email ?? 'Guest User';
    final String name = user?.userMetadata?['name'] ?? 'Welcome!';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.brown),
            ),
            decoration: const BoxDecoration(
              color: Colors.brown, // Or your app theme color
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          // ... other items ...
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
            label: 'Wishlist',
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
            onTap: () {
              Navigator.pop(context);
              showSettingsBottomSheet(context);
            },
          ),
          Divider(
            indent: 20,
            endIndent: 20,
            height: 24,
            color: Colors.purple.withValues(alpha: 0.2),
          ),
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
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteName.login,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  final colors = AppThemeColors.of(context);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: colors.purpleMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Log out?',
        style: TextStyle(color: colors.white, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Are you sure you want to log out?',
        style: TextStyle(color: colors.textMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            navigator.pop(); // Close dialog

            // Fixed: Call 'logoutUser()' to match the exact method defined inside your AuthProvider
            Provider.of<AuthProvider>(context, listen: false).logoutUser();

            navigator.pushNamedAndRemoveUntil(
              RouteName.login,
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.purpleAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Log out',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

// Fixed: Removed the broken custom extension on User? entirely since name metadata configuration is handled elegantly inside AuthProvider. userName is now checked contextually.

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
  final String? badge;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: iconColor ?? colors.white, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? colors.white,
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
