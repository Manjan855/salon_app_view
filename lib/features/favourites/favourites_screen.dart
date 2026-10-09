import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app_view/features/salon_detail/services_screen.dart';
import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/shared/models/salon_model.dart';
import 'package:salon_app_view/shared/providers/auth_provider.dart';
import 'package:salon_app_view/shared/providers/favourite_provider.dart';

const kGold = Color(0xFFFFD700);

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user?.id;
      context.read<FavouriteProvider>().ensureLoaded(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final kPurpleDark = colors.purpleDark;
    final kPurpleMid = colors.purpleMid;
    final kPurpleAccent = colors.purpleAccent;
    final kPurpleLight = colors.purpleLight;
    final kWhite = colors.white;
    final kTextMuted = colors.textMuted;

    final favourites = context.watch<FavouriteProvider>();
    final signedIn = context.watch<AuthProvider>().user != null;
    final salons = favourites.salons;

    return Scaffold(
      backgroundColor: kPurpleDark,
      appBar: AppBar(
        title: Text(
          'Favourites',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w700),
        ),
        backgroundColor: kPurpleMid,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: kWhite),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _buildBody(
        context,
        favourites: favourites,
        salons: salons,
        signedIn: signedIn,
        kPurpleMid: kPurpleMid,
        kPurpleAccent: kPurpleAccent,
        kPurpleLight: kPurpleLight,
        kWhite: kWhite,
        kTextMuted: kTextMuted,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required FavouriteProvider favourites,
    required List<SalonModel> salons,
    required bool signedIn,
    required Color kPurpleMid,
    required Color kPurpleAccent,
    required Color kPurpleLight,
    required Color kWhite,
    required Color kTextMuted,
  }) {
    if (favourites.isLoading && salons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (salons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: kTextMuted.withAlpha(77),
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                'No Favourites Yet',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                signedIn
                    ? 'Tap the ♥ on any salon to save it here.'
                    : 'Sign in to save your favourite salons.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: salons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final salon = salons[i];
        return Container(
          decoration: BoxDecoration(
            color: kPurpleMid,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kPurpleLight.withAlpha(51),
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
                        salon.image ?? '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: kPurpleAccent,
                          child: Icon(Icons.store, color: kWhite),
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
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            salon.location,
                            style: TextStyle(
                              color: kTextMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: kGold,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${salon.ratingAvg.toStringAsFixed(1)} (${salon.ratingCount} reviews)',
                                  style: TextStyle(
                                    color: kTextMuted,
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
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        try {
                          await context
                              .read<FavouriteProvider>()
                              .toggle(salon.id);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception:', '').trim(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: kPurpleLight.withAlpha(51)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      salon.city.isNotEmpty ? salon.city : 'View services',
                      style: TextStyle(
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
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
