import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/url_helper.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/cloud/api_service.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart' as db;
import '../../core/services/interaction_service.dart';
import '../../widgets/profile_image.dart';

class ProviderPreviewScreen extends ConsumerStatefulWidget {
  final String providerUserId;
  const ProviderPreviewScreen({super.key, required this.providerUserId});

  @override
  ConsumerState<ProviderPreviewScreen> createState() => _ProviderPreviewScreenState();
}

class _ProviderPreviewScreenState extends ConsumerState<ProviderPreviewScreen> {
  @override
  void initState() {
    super.initState();
    _incrementViews();
  }

  Future<void> _incrementViews() async {
    try {
      await ref.read(databaseProvider).incrementProviderViews(widget.providerUserId);
      await ref.read(apiServiceProvider).incrementViews(widget.providerUserId);
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(specificProviderProvider(widget.providerUserId));

    return Scaffold(
      body: providerAsync.when(
        data: (provider) {
          if (provider == null) {
            return const Center(child: Text('Provider not found.'));
          }
          return _buildContent(context, ref, provider);
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, db.Provider provider) {
    final profileAsync = ref.watch(specificUserProfileProvider(provider.userId));
    final profile = profileAsync.valueOrNull;

    return Stack(
      children: [
        Container(color: AppColors.grey25), // Signature off-white background
        
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Transparent AppBar with Back Button
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.2),
                        child: IconButton(
                          icon: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
                          onPressed: () => UrlHelper.shareProfile(
                            userId: provider.userId,
                            name: provider.name,
                            role: provider.role,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Bank Card Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _buildBankCard(provider, profile),
              ),
            ),

            // 3. Info Sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsSection(provider),
                  const SizedBox(height: 32),
                  _buildAboutSection(provider),
                  const SizedBox(height: 32),
                  if (provider.role == 'COACH' || provider.role == 'coach') ...[
                    _buildCertifications(provider),
                    const SizedBox(height: 32),
                  ],
                  _buildPrimaryCoursesSection(provider),
                  const SizedBox(height: 32),
                  _buildReviewsSection(context, ref, provider),
                  const SizedBox(height: 160), // Extra space for floating CTA
                ]),
              ),
            ),
          ],
        ),
        
        // 4. Floating Action Pill
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: _buildFloatingActionPill(context, ref, provider),
        ),
      ],
    );
  }

  Widget _buildBankCard(db.Provider provider, db.UserProfile? profile) {
    final isAvailable = provider.isAvailable;
    final courses = _parseList(provider.coursesJson);
    final homeClub = courses.isNotEmpty ? courses.first : 'Independent';

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(
          image: (provider.avatarUrl != null && provider.avatarUrl!.isNotEmpty)
              ? NetworkImage(provider.avatarUrl!) as ImageProvider
              : const AssetImage('assets/images/onboarding_golfer.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.4, 0.6, 1.0],
              ),
            ),
          ),
          
          // Availability Badge
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.golfLime : AppColors.grey400,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.circle, size: 8, color: Colors.white, fill: 1.0),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? 'AVAILABLE' : 'OFFLINE',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),

          // Name and Details at bottom
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.checkCircle2, color: AppColors.golfLime, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Colors.white60, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      homeClub,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    const Text('•', style: TextStyle(color: Colors.white30)),
                    const SizedBox(width: 12),
                    Text(
                      '${provider.experience} Years Exp',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _buildStatsSection(db.Provider provider) {
    return _buildSectionContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statTile('Rating', provider.rating.toStringAsFixed(1), Icons.star_rounded, color: Colors.amber),
          _divider(),
          _statTile('Rounds', provider.totalBookings.toString(), LucideIcons.flag),
          _divider(),
          _statTile('Views', provider.views.toString(), LucideIcons.eye),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.grey400),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900)),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.grey400, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.grey100);

  Widget _buildAboutSection(db.Provider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('WHAT YOU\'LL GET'),
        _buildSectionContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.bio ?? 'No professional bio provided yet.',
                style: const TextStyle(fontSize: 15, color: AppColors.grey700, height: 1.6, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCoursesSection(db.Provider provider) {
    final courses = _parseList(provider.coursesJson);
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('HOME CLUB & RATES'),
        _buildSectionContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.grey25, borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.landmark, color: AppColors.grey900),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courses.first, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                    const SizedBox(height: 2),
                    Text(
                      'Standard rates apply at ${courses.first}. Call for specific 18/9 hole details.',
                      style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertifications(db.Provider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('CERTIFICATIONS'),
        _buildSectionContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(LucideIcons.award, color: AppColors.emerald700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.certificationName ?? 'KGU Professional Certification',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, WidgetRef ref, db.Provider provider) {
    final reviewsAsync = ref.watch(providerReviewsProvider(provider.userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('PLAYER REVIEWS'),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showWriteReviewModal(context, ref, provider),
              child: const Text('Write Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald700)),
            ),
           ],
        ),
        const SizedBox(height: 8),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildSectionContainer(
                padding: const EdgeInsets.all(32),
                child: const Column(
                  children: [
                    Icon(LucideIcons.messageSquare, color: AppColors.grey200, size: 32),
                    SizedBox(height: 12),
                    Text('No reviews yet', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey400)),
                  ],
                ),
              );
            }

            return Column(
              children: reviews.take(3).map((r) => _ReviewCard(review: r)).toList(),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => _buildSectionContainer(
            child: const Center(child: Text('Failed to load reviews.', style: TextStyle(color: Colors.redAccent))),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionPill(BuildContext context, WidgetRef ref, db.Provider provider) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book with ${provider.name.split(" ").first}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                ),
                Text(
                  provider.isAvailable ? 'Available Now' : 'Currently Offline',
                  style: TextStyle(color: provider.isAvailable ? AppColors.golfLime : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: AppColors.golfLime,
            borderRadius: BorderRadius.circular(28),
            onPressed: () async {
              ref.read(interactionServiceProvider).logInteraction(providerId: provider.userId, type: 'call');
              await UrlHelper.launchCaller(provider.phone);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.phone, color: AppColors.grey900, size: 18),
                SizedBox(width: 8),
                Text('CALL', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showWriteReviewModal(BuildContext context, WidgetRef ref, db.Provider provider) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Write a Review', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.grey900)),
                          Text('Share your experience with ${provider.name}', style: const TextStyle(color: AppColors.grey500, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(LucideIcons.x, color: AppColors.grey300),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text('RATING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isSelected = index < rating;
                    return GestureDetector(
                      onTap: () => setModalState(() => rating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isSelected ? Colors.amber : AppColors.grey300,
                            size: 44,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                const Text('COMMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Tell others about their service...',
                    filled: true,
                    fillColor: AppColors.grey25,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: isSubmitting ? null : () async {
                      if (commentController.text.trim().isEmpty) return;
                      setModalState(() => isSubmitting = true);
                      try {
                        final syncService = ref.read(syncServiceProvider);
                        final currentUser = ref.read(userProfileProvider).valueOrNull;
                        if (currentUser == null) throw Exception('Not logged in');

                        final reviewRecord = db.Review(
                          id: 0,
                          providerId: provider.userId,
                          playerId: currentUser.uid ?? 'unknown',
                          playerName: currentUser.name,
                          playerAvatar: currentUser.avatarUrl,
                          rating: rating,
                          comment: commentController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        final localDb = ref.read(databaseProvider);
                        await localDb.into(localDb.reviews).insert(db.ReviewsCompanion.insert(
                          providerId: reviewRecord.providerId,
                          playerId: reviewRecord.playerId,
                          playerName: reviewRecord.playerName,
                          playerAvatar: drift.Value(reviewRecord.playerAvatar),
                          rating: reviewRecord.rating,
                          comment: reviewRecord.comment,
                        ));

                        await syncService.syncReview(reviewRecord);
                        await localDb.updateProviderRating(provider.userId);

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error posting review: $e');
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grey900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: isSubmitting 
                        ? const CupertinoActivityIndicator(color: Colors.white) 
                        : const Text('Post Review', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.golfLime)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey500, letterSpacing: 1.2)
      ),
    );
  }

  List<String> _parseList(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }
}

class _ReviewCard extends StatelessWidget {
  final db.Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileImage(url: review.playerAvatar, name: review.playerName, size: 40, isCircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.playerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.grey900)),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < review.rating ? Icons.star_rounded : Icons.star_border_rounded, 
                        size: 14, 
                        color: index < review.rating ? Colors.amber : AppColors.grey300,
                      )),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d').format(review.createdAt), 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey400)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.comment, 
            style: const TextStyle(fontSize: 14, color: AppColors.grey700, height: 1.5, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}
