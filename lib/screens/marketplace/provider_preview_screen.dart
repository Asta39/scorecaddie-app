import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/url_helper.dart';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
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
    final async = ref.watch(specificProviderProvider(widget.providerUserId));
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: async.when(
            loading: () => const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
            error: (e, _) => _missing('Couldn\'t load this profile.'),
            data: (p) => p == null ? _missing('This profile isn\'t available.') : _content(p),
          ),
        ),
      ),
    );
  }

  Widget _missing(String text) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ObTopBar('', onBack: () => context.pop()),
          const SizedBox(height: 24),
          Text(text, style: Ob.display(22)),
        ]),
      );

  bool _isCoach(db.Provider p) => p.role.toLowerCase() == 'coach';

  String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k' : '$n';

  Widget _content(db.Provider p) {
    final coach = _isCoach(p);
    final first = p.name.split(' ').first;
    final courses = _parseList(p.coursesJson);
    final specs = _parseList(p.specializationsJson ?? '[]');
    final reviews = ref.watch(providerReviewsProvider(p.userId)).valueOrNull ?? const <db.Review>[];
    final price = p.price == null || p.price == 0 ? null : 'KES ${NumberFormat('#,###').format(p.price)}';

    Future<void> call() async {
      ref.read(interactionServiceProvider).logInteraction(providerId: p.userId, type: 'call');
      await UrlHelper.launchCaller(p.phone);
    }

    return Column(children: [
      Expanded(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ObTopBar('', onBack: () => context.pop(), actions: [
              ObIconButton(
                icon: LucideIcons.share,
                label: 'Share profile',
                onPressed: () => UrlHelper.shareProfile(userId: p.userId, name: p.name, role: p.role),
              ),
            ]),
            const SizedBox(height: 8),
            Center(child: ProfileImage(url: p.avatarUrl, name: p.name, size: 96, isCircle: true)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: Text(p.name, textAlign: TextAlign.center, style: Ob.display(28, height: 1.1))),
              if (p.hasCertification) ...[
                const SizedBox(width: 6),
                Semantics(label: 'Verified', child: const Icon(CupertinoIcons.checkmark_seal_fill, size: 22, color: Color(0xFF2563EB))),
              ],
            ]),
            const SizedBox(height: 4),
            Text(
              [
                coach ? 'Coach' : 'Caddie',
                if (p.experience > 0) '${p.experience} years',
                if (courses.isNotEmpty) courses.first,
              ].join(' · '),
              textAlign: TextAlign.center,
              style: Ob.body(15, color: Ob.creamA(.6)),
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: p.isAvailable ? const Color(0xFF34C759) : Ob.creamA(.3), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(p.isAvailable ? 'Available now' : 'Not taking bookings', style: Ob.body(15, color: Ob.creamA(.6))),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _stat(p.rating == 0 ? '—' : '★ ${p.rating.toStringAsFixed(1)}', '${p.totalReviews} reviews'),
                _stat(price ?? '—', coach ? 'per hour' : 'per round'),
                _stat(_compact(p.totalBookings), coach ? 'bookings' : 'rounds'),
              ]),
            ),
            if (coach) ...[
              const SizedBox(height: 22),
              ObGroup(children: [
                ObRow('$first’s sessions', subtitle: 'Group programmes and private lessons',
                    leading: const ObRowIcon(LucideIcons.calendar, Ob.lime),
                    onTap: () => context.push('/marketplace/coach/${p.userId}/sessions')),
              ]),
            ],
            if ((p.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: 22),
              ObGroup(header: 'About', children: [ObRow(p.bio!)]),
            ],
            const SizedBox(height: 22),
            ObGroup(header: 'Details', children: [
              if (!coach && (p.personalityType ?? '').isNotEmpty) ObRow('Style', value: p.personalityType),
              if (coach && specs.isNotEmpty) ObRow('Teaches', subtitle: specs.join(', ')),
              if (courses.isNotEmpty) ObRow(coach ? 'Coaches at' : 'Caddies at', subtitle: courses.join(', ')),
              if (coach && p.hasCertification) ObRow('Certified', subtitle: p.certificationName ?? 'Certificate on file with ScoreCaddie'),
              ObRow('Profile views', value: _compact(p.views)),
            ]),
            const SizedBox(height: 22),
            ObGroup(header: 'Reviews', children: [
              if (reviews.isEmpty) ObRow('No reviews yet', subtitle: 'Played with $first? Be the first.'),
              for (final r in reviews.take(5))
                ObRow(r.playerName,
                    subtitle: r.comment,
                    leading: ProfileImage(url: r.playerAvatar, name: r.playerName, size: 36, isCircle: true),
                    value: '★ ${r.rating}'),
              ObRow('Write a review', titleColor: Ob.lime, onTap: () => _showWriteReviewModal(context, ref, p)),
            ]),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + MediaQuery.of(context).padding.bottom),
        child: Row(children: [
          if (coach) ...[
            Expanded(
              child: ObButton(
                height: 54,
                radius: 14,
                tone: ObButtonTone.light,
                onPressed: call,
                child: Text('Call', style: Ob.body(17, weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ObButton(
              height: 54,
              radius: 14,
              onPressed: coach ? () => context.push('/marketplace/coach/${p.userId}/sessions') : call,
              child: Text(coach ? 'Book a session' : 'Call $first', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.label(17)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _stat(String v, String label) => Expanded(
        child: Column(children: [
          Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(17, height: 1.2)),
          Text(label, style: Ob.body(13, color: Ob.creamA(.6))),
        ]),
      );

  void _showWriteReviewModal(BuildContext context, WidgetRef ref, db.Provider provider) {
    int rating = 5;
    final comment = TextEditingController();
    bool busy = false;
    showObSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ObSheet(
          title: 'Review ${provider.name.split(' ').first}',
          subtitle: 'Other golfers read these before booking.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 5; i++)
                GestureDetector(
                  onTap: () => setSheet(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedScale(
                      scale: i < rating ? 1.1 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.star_rounded, size: 44, color: i < rating ? const Color(0xFFB7791F) : Ob.creamA(.15)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: comment,
              maxLines: 4,
              cursorColor: Ob.lime,
              style: Ob.body(15, weight: FontWeight.w600),
              decoration: obInput(null, hint: 'Read the greens perfectly, kept me calm on 18…'),
            ),
            const SizedBox(height: 16),
            ObButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (comment.text.trim().isEmpty) return;
                      setSheet(() => busy = true);
                      try {
                        final me = ref.read(userProfileProvider).valueOrNull;
                        if (me == null) throw Exception('Not logged in');
                        final review = db.Review(
                          id: 0,
                          providerId: provider.userId,
                          playerId: me.uid ?? 'unknown',
                          playerName: me.name,
                          playerAvatar: me.avatarUrl,
                          rating: rating,
                          comment: comment.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        final local = ref.read(databaseProvider);
                        await local.into(local.reviews).insert(db.ReviewsCompanion.insert(
                          providerId: review.providerId,
                          playerId: review.playerId,
                          playerName: review.playerName,
                          playerAvatar: drift.Value(review.playerAvatar),
                          rating: review.rating,
                          comment: review.comment,
                        ));
                        await ref.read(syncServiceProvider).syncReview(review);
                        await local.updateProviderRating(provider.userId);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        debugPrint('Error posting review: $e');
                        setSheet(() => busy = false);
                      }
                    },
              child: Text(busy ? 'Posting…' : 'Post review', style: Ob.label(16, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    ).whenComplete(comment.dispose);
  }

  List<String> _parseList(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }
}
