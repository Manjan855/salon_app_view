import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app_view/core/theme/app_theme.dart';
import 'package:salon_app_view/shared/models/review_model.dart';
import 'package:salon_app_view/shared/providers/review_provider.dart';

const kGold = Color(0xFFFFD700);

// ─── Stars ────────────────────────────────────────────────
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
  });

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating;
        return Icon(
          full
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: kGold,
          size: size,
        );
      }),
    );
  }
}

// ─── Salon Reviews Screen ─────────────────────────────────
class SalonReviewsScreen extends StatefulWidget {
  const SalonReviewsScreen({
    super.key,
    required this.salonId,
    required this.salonName,
  });

  final String salonId;
  final String salonName;

  @override
  State<SalonReviewsScreen> createState() => _SalonReviewsScreenState();
}

class _SalonReviewsScreenState extends State<SalonReviewsScreen> {
  AppThemeColors get colors => AppThemeColors.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewProvider>().loadSalonReviews(widget.salonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kPurpleDark = colors.purpleDark;
    final kWhite = colors.white;

    final provider = context.watch<ReviewProvider>();

    return Scaffold(
      backgroundColor: kPurpleDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, kWhite),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadSalonReviews(
                  widget.salonId,
                  force: true,
                ),
                color: colors.purpleAccent,
                backgroundColor: colors.purpleMid,
                child: _buildBody(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color kWhite) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_rounded, color: kWhite),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.salonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ReviewProvider provider) {
    if (provider.isLoading && provider.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.reviews.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: colors.textMuted, size: 40),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => provider.loadSalonReviews(
                    widget.salonId,
                    force: true,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (provider.reviews.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          Icon(Icons.rate_review_outlined,
              color: colors.textMuted.withOpacity(0.5), size: 52),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'No reviews yet',
              style: TextStyle(
                color: colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Be the first to review ${widget.salonName}.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: provider.reviews.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildSummary(provider);
        return _ReviewCard(review: provider.reviews[i - 1]);
      },
    );
  }

  Widget _buildSummary(ReviewProvider provider) {
    final kWhite = colors.white;
    final avg = provider.averageRating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.purpleMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.purpleLight.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            avg.toStringAsFixed(1),
            style: TextStyle(
              color: kWhite,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingStars(rating: avg, size: 18),
              const SizedBox(height: 4),
              Text(
                '${provider.reviewCount} review'
                '${provider.reviewCount == 1 ? '' : 's'}',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Single review card ───────────────────────────────────
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final name = review.userName;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.purpleMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.purpleLight.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.purpleAccent,
                backgroundImage: (review.userAvatar?.isNotEmpty ?? false)
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: (review.userAvatar?.isNotEmpty ?? false)
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          color: colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        RatingStars(rating: review.rating.toDouble(), size: 13),
                        const SizedBox(width: 6),
                        Text(
                          _relativeTime(review.createdAt),
                          style: TextStyle(
                            color: colors.textMuted,
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
          if (review.hasComment) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!.trim(),
              style: TextStyle(
                color: colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          if (review.reply != null && review.reply!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.purpleDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_rounded,
                      color: colors.purpleAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      review.reply!.trim(),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

// ─── Write-review bottom sheet ────────────────────────────
/// Returns `true` via `Navigator.pop` when a review was submitted.
class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.salonId,
    required this.salonName,
    required this.userId,
    this.bookingId,
  });

  final String salonId;
  final String salonName;
  final String userId;
  final String? bookingId;

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final created = await context.read<ReviewProvider>().submitReview(
          salonId: widget.salonId,
          userId: widget.userId,
          bookingId: widget.bookingId,
          rating: _rating,
          comment: _commentCtrl.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (created != null) {
      Navigator.pop(context, true);
    } else {
      final message = context.read<ReviewProvider>().error ??
          'Could not submit your review.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.purpleMid,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: insets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.purpleLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Rate your visit',
              style: TextStyle(
                color: colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.salonName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  return IconButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: kGold,
                      size: 38,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              enabled: !_submitting,
              maxLines: 4,
              maxLength: 2000,
              style: TextStyle(color: colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share what you liked (optional)',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                filled: true,
                fillColor: colors.purpleDark,
                counterStyle:
                    TextStyle(color: colors.textMuted, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.purpleAccent,
                  foregroundColor: colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit review',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
