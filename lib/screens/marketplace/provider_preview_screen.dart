import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/url_helper.dart';
import 'dart:ui';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import 'package:drift/drift.dart' as drift;
import '../../core/services/interaction_service.dart';
import '../../widgets/profile_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Increment view count in real-time
    _incrementViews();
  }

  Future<void> _incrementViews() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('providers').doc(widget.providerUserId);
      await docRef.update({'views': FieldValue.increment(1)});
      
      // Update local DB too
      final database = ref.read(databaseProvider);
      final providerList = await (database.select(database.providers)..where((p) => p.userId.equals(widget.providerUserId))).get();
      if (providerList.isNotEmpty) {
        final provider = providerList.first;
        await (database.update(database.providers)..where((p) => p.userId.equals(widget.providerUserId)))
            .write(db.ProvidersCompanion(views: drift.Value(provider.views + 1)));
      }
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(allProvidersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: providersAsync.when(
        data: (providers) {
          try {
            final provider = providers.firstWhere((p) => p.userId == widget.providerUserId);
            return _buildContent(context, ref, provider);
          } catch(e) {
            return const Center(child: Text('Provider not found.'));
          }
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
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, provider, profile),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameAndAction(provider),
                    const SizedBox(height: 20),
                    _buildQuickTrustTags(provider),
                    const SizedBox(height: 32),
                    _buildStatsGrid(provider),
                    const SizedBox(height: 32),
                    _buildPrimaryCourses(provider),
                    const SizedBox(height: 32),
                    if (provider.specializationsJson != null && provider.role == 'coach') ...[
                      _buildBestFor(provider),
                      const SizedBox(height: 32),
                    ],
                    _buildAbout(provider),
                    const SizedBox(height: 32),
                    _buildReviewsSection(context, ref, provider),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildStickyBottomBar(context, ref, provider),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, db.Provider provider, db.UserProfile? profile) {
    final Color themeColor = provider.role == 'coach' ? AppColors.purple700 : AppColors.emerald700;
    
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: const Color(0xFFF2F2F7),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
              _buildLargeProfileImage(profile.avatarUrl!)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    provider.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white38),
                  ),
                ),
              ),
            
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.4), 
                      Colors.transparent, 
                      Colors.black.withValues(alpha: 0.6)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(LucideIcons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        provider.rating.toStringAsFixed(1), 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)
                      ),
                      const SizedBox(width: 8),
                      Text('(${provider.totalReviews} reviews)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.bio ?? 'Expert ${provider.role} ready for your next round.',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeProfileImage(String url) {
    ImageProvider? imageProvider;
    if (url.startsWith('http')) {
      imageProvider = NetworkImage(url);
    } else {
      final file = File(url);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    if (imageProvider == null) return Container(color: AppColors.grey200);

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.grey200),
    );
  }

  Widget _buildNameAndAction(db.Provider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(provider.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.grey900)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: provider.isAvailable ? AppColors.emerald500 : AppColors.grey400, 
                shape: BoxShape.circle
              ),
            ),
            const SizedBox(width: 8),
            Text(
              provider.isAvailable ? 'Available for booking' : 'Offline', 
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey600, fontSize: 14)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTrustTags(db.Provider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _TrustTag(icon: LucideIcons.badgeCheck, label: 'Verified', color: AppColors.emerald600),
          const SizedBox(width: 10),
          _TrustTag(icon: LucideIcons.calendar, label: '${provider.experience}+ yrs exp', color: AppColors.blue600),
          const SizedBox(width: 10),
          _TrustTag(icon: LucideIcons.checkSquare, label: '${provider.totalBookings}+ sessions', color: AppColors.purple600),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(db.Provider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatItem('${provider.experience}Y', 'Exp', LucideIcons.award),
          _buildVerticalDivider(),
          _buildStatItem('KES ${provider.price?.toInt() ?? 0}', 'Price', LucideIcons.creditCard),
          _buildVerticalDivider(),
          _buildStatItem('${provider.views}', 'Views', LucideIcons.trendingUp),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String subtitle, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.grey400),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey500)),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: AppColors.grey100);
  }

  Widget _buildPrimaryCourses(db.Provider provider) {
    final courses = provider.coursesJson.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').where((c) => c.trim().isNotEmpty).toList();
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('PRIMARY COURSES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500, letterSpacing: 0.5)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: courses.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(8)),
              child: Text(c.trim(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey800, fontSize: 13)),
            )).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBestFor(db.Provider provider) {
    final specs = provider.specializationsJson?.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',') ?? [];
    if (specs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('BEST MATCH FOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500, letterSpacing: 0.5)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.purple50.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.purple100)),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: specs.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.check, size: 14, color: AppColors.purple700),
                const SizedBox(width: 6),
                Text(s.trim(), style: const TextStyle(color: AppColors.purple700, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAbout(db.Provider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('WHAT YOU\'LL GET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500, letterSpacing: 0.5)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildBulletPoint('Course Strategy', 'Expert knowledge on wind, hazards, and pin placements.'),
              const Divider(height: 24, color: AppColors.grey50),
              _buildBulletPoint('Club Selection', 'Tailored recommendations based on your unique distances.'),
              const Divider(height: 24, color: AppColors.grey50),
              _buildBulletPoint('Green Reading', 'Precise reads on complex breaks using local knowledge.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String title, String desc) {
     return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.emerald600),
         const SizedBox(width: 12),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900, fontSize: 15)),
               const SizedBox(height: 2),
               Text(desc, style: const TextStyle(color: AppColors.grey600, height: 1.4, fontSize: 13)),
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
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('PLAYER REVIEWS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500, letterSpacing: 0.5)),
            ),
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
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
          error: (e, _) => const Text('Failed to load reviews.'),
        ),
      ],
    );
  }

  void _showWriteReviewModal(BuildContext context, WidgetRef ref, db.Provider provider) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review ${provider.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.grey900)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setModalState(() => rating = index + 1),
                    child: Icon(
                      index < rating ? LucideIcons.star : LucideIcons.star,
                      color: index < rating ? Colors.amber : AppColors.grey100,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              CupertinoTextField(
                controller: commentController,
                placeholder: 'Share your experience...',
                maxLines: 5,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.emerald700,
                  onPressed: isSubmitting ? null : () async {
                    if (commentController.text.trim().isEmpty) return;
                    setModalState(() => isSubmitting = true);
                    
                    try {
                      final database = ref.read(databaseProvider);
                      final syncService = ref.read(syncServiceProvider);
                      final currentUser = ref.read(userProfileProvider).valueOrNull;
                      if (currentUser == null) throw Exception('Not logged in');

                      await database.into(database.reviews).insert(db.ReviewsCompanion.insert(
                        providerId: provider.userId,
                        playerId: currentUser.firebaseUid ?? 'unknown',
                        playerName: currentUser.name,
                        playerAvatar: drift.Value(currentUser.avatarUrl),
                        rating: rating,
                        comment: commentController.text.trim(),
                      ));

                      await database.updateProviderRating(provider.userId);
                      final updatedProvider = await (database.select(database.providers)..where((p) => p.userId.equals(provider.userId))).get().then((list) => list.firstOrNull);
                      if (updatedProvider != null) await syncService.syncProvider(updatedProvider);

                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting ? const CupertinoActivityIndicator(color: Colors.white) : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, WidgetRef ref, db.Provider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              color: AppColors.emerald700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: () async {
                final phone = provider.whatsapp ?? provider.phone;
                await UrlHelper.launchWhatsApp(phone);
                ref.read(interactionServiceProvider).logInteraction(providerId: provider.userId, type: 'whatsapp');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.messageCircle, size: 18),
                  SizedBox(width: 8),
                  Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              color: AppColors.grey900,
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: () async {
                await UrlHelper.launchCaller(provider.phone);
                ref.read(interactionServiceProvider).logInteraction(providerId: provider.userId, type: 'call');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.phone, size: 18),
                  SizedBox(width: 8),
                  Text('Call Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _TrustTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey700)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final db.Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileImage(url: review.playerAvatar, size: 36, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.playerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900)),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < review.rating ? LucideIcons.star : LucideIcons.star, 
                        size: 12, 
                        color: index < review.rating ? Colors.amber : AppColors.grey100
                      )),
                    ),
                  ],
                ),
              ),
              Text('${DateTime.now().difference(review.createdAt).inDays}d ago', style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
            ],
          ),
          const SizedBox(height: 12),
          Text('"${review.comment}"', style: const TextStyle(fontSize: 14, color: AppColors.grey700, height: 1.4, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
