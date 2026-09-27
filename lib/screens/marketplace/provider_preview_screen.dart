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
import '../onboarding/ob_widgets.dart';
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

    return Column(children: [
      Expanded(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(children: [
              ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
              const Spacer(),
              ObIconButton(
                icon: LucideIcons.share2,
                label: 'Share profile',
                onPressed: () => UrlHelper.shareProfile(userId: p.userId, name: p.name, role: p.role),
              ),
            ]),
            Column(children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Ob.lime.withValues(alpha: .6), width: 3)),
                  child: ProfileImage(url: p.avatarUrl, name: p.name, size: 106, isCircle: true),
                ),
                if (p.profileComplete)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: Ob.lime, shape: BoxShape.circle, border: Border.all(color: Ob.bg, width: 4)),
                      child: const Icon(LucideIcons.check, size: 14, color: Ob.ink),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Text(p.name, textAlign: TextAlign.center, style: Ob.display(32, height: 1.05)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                ObChip(coach ? 'Coach' : 'Caddie', on: true, color: coach ? const Color(0xFFF5C531) : Ob.lime),
                if (!coach && (p.personalityType ?? '').isNotEmpty) ObChip(p.personalityType!),
                if (coach && p.hasCertification) ObChip(p.certificationName ?? 'Certified'),
                ObChip(p.isAvailable ? 'Available now' : 'Offline', on: p.isAvailable),
              ]),
              const SizedBox(height: 6),
              Text(
                [
                  if (p.experience > 0) '${p.experience} years ${coach ? 'coaching' : 'on the bag'}',
                  if (courses.isNotEmpty) courses.first,
                ].join(' · '),
                textAlign: TextAlign.center,
                style: Ob.body(14, color: Ob.creamA(.62)),
              ),
            ]).rise(),
            const SizedBox(height: 18),
            Row(children: [
              _stat(p.rating == 0 ? '—' : p.rating.toStringAsFixed(1), 'Rating', const Color(0xFFF5C531)),
              const SizedBox(width: 8),
              _stat(_compact(p.totalBookings), coach ? 'Bookings' : 'Rounds', Ob.cream),
              const SizedBox(width: 8),
              _stat(_compact(p.views), 'Profile views', Ob.cream),
            ]).rise(1),
            if (coach) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push('/marketplace/coach/${p.userId}/sessions'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .08), borderRadius: BorderRadius.circular(24), border: Border.all(color: Ob.lime, width: 2)),
                  child: Row(children: [
                    Image.asset(ObBot.star.happy, width: 52, height: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('See $first\'s sessions', style: Ob.body(16, weight: FontWeight.w800)),
                        Text('Group programmes and private lessons', style: Ob.body(12, color: Ob.creamA(.6))),
                      ]),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.5)),
                  ]),
                ),
              ),
            ],
            if ((p.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              ObCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ObEyebrow('About $first'),
                  const SizedBox(height: 8),
                  Text(p.bio!, style: Ob.body(14, height: 1.55, color: Ob.creamA(.8))),
                ]),
              ),
            ],
            if (coach && specs.isNotEmpty) ...[
              const SizedBox(height: 22),
              const ObEyebrow('Coaches'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in specs) ObChip(t)]),
            ],
            if (courses.isNotEmpty) ...[
              const SizedBox(height: 22),
              ObEyebrow(coach ? 'Where $first coaches' : 'Where $first caddies'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in courses)
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
                    decoration: BoxDecoration(color: Ob.creamA(.06), borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ObCrest(c, size: 28, radius: 999),
                      const SizedBox(width: 8),
                      Text(c, style: Ob.body(13, weight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ],
            if (coach && p.hasCertification) ...[
              const SizedBox(height: 14),
              ObCard(
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFF5C531).withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.award, color: Color(0xFFF5C531), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.certificationName ?? 'Certified professional', style: Ob.body(15, weight: FontWeight.w800)),
                      Text('Certificate on file with ScoreCaddie', style: Ob.body(12, color: Ob.creamA(.58))),
                    ]),
                  ),
                  const Icon(LucideIcons.check, color: Ob.lime, size: 18),
                ]),
              ),
            ],
            const SizedBox(height: 22),
            ObEyebrow('Reviews', action: 'Write one', onAction: () => _showWriteReviewModal(context, ref, p)),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              ObCard(child: Text('No reviews yet. Played with $first? Be the first.', style: Ob.body(13, color: Ob.creamA(.6))))
            else
              for (final r in reviews.take(5)) _ReviewCard(review: r),
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: Ob.bg, border: Border(top: BorderSide(color: Ob.creamA(.06)))),
        child: Row(children: [
          Semantics(
            button: true,
            label: 'Call $first',
            child: GestureDetector(
              onTap: () async {
                ref.read(interactionServiceProvider).logInteraction(providerId: p.userId, type: 'call');
                await UrlHelper.launchCaller(p.phone);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Ob.cardFill, shape: BoxShape.circle, border: Border.all(color: Ob.creamA(.1))),
                child: const Icon(LucideIcons.phone, color: Ob.cream, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ObButton(
              onPressed: coach
                  ? () => context.push('/marketplace/coach/${p.userId}/sessions')
                  : () {
                      ref.read(interactionServiceProvider).logInteraction(providerId: p.userId, type: 'chat');
                      context.push('/chat/${p.userId}');
                    },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(coach ? LucideIcons.calendarPlus : LucideIcons.messageCircle, size: 18, color: Ob.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    coach ? 'Book a session' : (price == null ? 'Book $first' : 'Book $first · $price'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ob.label(16, weight: FontWeight.w800),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _stat(String v, String label, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(20), border: Border.all(color: Ob.creamA(.06))),
          child: Column(children: [
            Text(v, style: Ob.display(24, height: 1, color: c)),
            const SizedBox(height: 4),
            Text(label, style: Ob.body(11, color: Ob.creamA(.55))),
          ]),
        ),
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
                      child: Icon(Icons.star_rounded, size: 44, color: i < rating ? const Color(0xFFF5C531) : Ob.creamA(.15)),
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

class _ReviewCard extends StatelessWidget {
  final db.Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ObCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ProfileImage(url: review.playerAvatar, name: review.playerName, size: 34, isCircle: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(review.playerName, style: Ob.body(14, weight: FontWeight.w800)),
                Text(DateFormat('d MMM yyyy').format(review.createdAt), style: Ob.body(11, color: Ob.creamA(.5))),
              ]),
            ),
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5C531)),
            const SizedBox(width: 3),
            Text('${review.rating}', style: Ob.body(13, weight: FontWeight.w800, color: const Color(0xFFF5C531))),
          ]),
          const SizedBox(height: 8),
          Text(review.comment, style: Ob.body(14, height: 1.5, color: Ob.creamA(.8))),
        ]),
      ),
    );
  }
}
