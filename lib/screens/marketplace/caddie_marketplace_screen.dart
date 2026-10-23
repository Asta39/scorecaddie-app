import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/database.dart' as db;
import '../../core/services/interaction_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

final marketplaceRoleFilterProvider = StateProvider<String>((ref) => 'all');

/// Find a caddie or coach. One list: anything waiting on you first, then the
/// pros you've played with, then everyone, narrowed by search and filters.
class CaddieMarketplaceScreen extends ConsumerStatefulWidget {
  final String initialRole;

  const CaddieMarketplaceScreen({super.key, this.initialRole = 'all'});

  @override
  ConsumerState<CaddieMarketplaceScreen> createState() => _CaddieMarketplaceScreenState();
}

class _CaddieMarketplaceScreenState extends ConsumerState<CaddieMarketplaceScreen> {
  static const _personalities = ['Talkative & Fun', 'Strategic', 'Quiet & Focused', 'Laid-back'];
  static const _prices = [1000.0, 2000.0, 3000.0];

  late String _role = widget.initialRole;
  String _query = '';
  double? _maxPrice;
  int? _minYears;
  String? _personality;
  String? _course;

  bool get _filtered => _maxPrice != null || _minYears != null || _personality != null || _course != null;

  bool _matches(db.Provider p) {
    if (_role != 'all' && p.role.toLowerCase() != _role) return false;
    final q = _query.toLowerCase();
    if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.coursesJson.toLowerCase().contains(q)) return false;
    if (_minYears != null && p.experience < _minYears!) return false;
    if (_personality != null && p.personalityType != _personality) return false;
    if (_course != null && !p.coursesJson.contains(_course!)) return false;
    if (_maxPrice != null && (p.price ?? 0) > _maxPrice!) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(marketplaceRoleFilterProvider, (prev, next) {
      if (next != _role) setState(() => _role = next);
    });

    final async = ref.watch(allProvidersProvider);
    final all = async.valueOrNull ?? const <db.Provider>[];
    final shown = all.where(_matches).toList()..sort((a, b) => b.rating.compareTo(a.rating));
    final pending = ref.watch(pendingInteractionsProvider).valueOrNull ?? const <db.Interaction>[];
    final recent = (ref.watch(recentProsProvider).valueOrNull ?? const <db.Provider>[]).where(_matches).toList();
    final searching = _query.isNotEmpty || _filtered;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            ObTabHeader('Caddies & coaches', actions: [
              ObIconButton(
                icon: _filtered ? LucideIcons.listFilterPlus : LucideIcons.listFilter,
                label: _filtered ? 'Filters, on' : 'Filters',
                onPressed: _showFilters,
              ),
            ]),
            const SizedBox(height: 12),
            CupertinoSearchTextField(placeholder: 'Name or course', style: Ob.body(17), onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 12),
            ObGooSegmented<String>(
              options: const [('all', 'All'), ('caddie', 'Caddies'), ('coach', 'Coaches')],
              selected: _role,
              onChanged: (r) {
                setState(() => _role = r);
                ref.read(marketplaceRoleFilterProvider.notifier).state = r;
              },
            ),
            if (_filtered) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (_maxPrice != null) _token('Up to KES ${_fmt(_maxPrice!)}', () => setState(() => _maxPrice = null)),
                if (_minYears != null) _token('$_minYears+ years', () => setState(() => _minYears = null)),
                if (_personality != null) _token(_personality!, () => setState(() => _personality = null)),
                if (_course != null) _token(_course!, () => setState(() => _course = null)),
              ]),
            ],
            if (pending.isNotEmpty && !searching) ...[
              const SizedBox(height: 22),
              ObGroup(
                header: 'Did you book them?',
                footer: 'Tell us so your pros and history stay right.',
                children: [for (final i in pending) _InquiryRow(interaction: i, all: all)],
              ),
            ],
            if (recent.isNotEmpty && !searching) ...[
              const SizedBox(height: 22),
              ObGroup(header: 'Played with', children: [for (final p in recent.take(3)) _ProRow(provider: p)]),
            ],
            const SizedBox(height: 22),
            if (async.isLoading && all.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
            else if (async.hasError && all.isEmpty)
              ObGroup(children: [ObRow('Couldn’t load pros', subtitle: 'Tap to try again', onTap: () => ref.invalidate(allProvidersProvider))])
            else if (shown.isEmpty)
              ObGroup(children: [
                ObRow(all.isEmpty ? 'No pros here yet' : 'Nobody matches that',
                    subtitle: all.isEmpty ? 'Caddies and coaches show up as they join' : 'Try a wider price or fewer filters'),
                if (_filtered) ObRow('Clear filters', titleColor: Ob.lime, onTap: _clear),
              ])
            else
              ObGroup(
                header: '${shown.length} ${_role == 'caddie' ? (shown.length == 1 ? 'caddie' : 'caddies') : _role == 'coach' ? (shown.length == 1 ? 'coach' : 'coaches') : (shown.length == 1 ? 'pro' : 'pros')}',
                footer: 'Caddie prices are per round, coach prices per hour.',
                children: [for (final p in shown) _ProRow(provider: p)],
              ),
          ],
        ),
      ),
    );
  }

  void _clear() => setState(() {
        _maxPrice = null;
        _minYears = null;
        _personality = null;
        _course = null;
      });

  /// An active filter, with an x to remove it.
  Widget _token(String label, VoidCallback onRemove) => Semantics(
        button: true,
        label: 'Remove filter $label',
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: Ob.body(15)),
              const SizedBox(width: 4),
              Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: Ob.creamA(.35)),
            ]),
          ),
        ),
      );

  Future<T?> _pick<T>(String title, List<(T?, String)> options, T? current) => showCupertinoModalPopup<T>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(title),
          actions: [
            for (final (v, l) in options)
              CupertinoActionSheetAction(isDefaultAction: v == current, onPressed: () => Navigator.pop(ctx, v), child: Text(l)),
          ],
          cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ),
      );

  /// Filters as a short settings list; each row opens its choices.
  void _showFilters() {
    final courses = {...(ref.read(coursesProvider).valueOrNull ?? const []).map((c) => c.name)}.toList()..sort();
    showObSheet<void>(
      context,
      (sheet) => StatefulBuilder(builder: (sheet, setSheet) {
        // Choices apply straight away, so the count behind the sheet updates.
        Future<void> choose<T>(String title, List<(T?, String)> options, T? current, void Function(T?) apply) async {
          final v = await _pick<Object>(title, [for (final (o, l) in options) (o ?? _any, l)], current ?? _any);
          if (v == null) return;
          setState(() => apply(v == _any ? null : v as T));
          setSheet(() {});
        }

        return ObSheet(
          title: 'Filters',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ObGroup(children: [
              ObRow('Price', value: _maxPrice == null ? 'Any' : 'Up to KES ${_fmt(_maxPrice!)}', onTap: () => choose<double>(
                    'Most you’ll pay',
                    [(null, 'Any price'), for (final p in _prices) (p, 'Up to KES ${_fmt(p)}')],
                    _maxPrice,
                    (v) => _maxPrice = v,
                  )),
              ObRow('Experience', value: _minYears == null ? 'Any' : '$_minYears+ years', onTap: () => choose<int>(
                    'Experience',
                    const [(null, 'Any'), (2, '2+ years'), (3, '3+ years'), (5, '5+ years')],
                    _minYears,
                    (v) => _minYears = v,
                  )),
              if (_role != 'coach')
                ObRow('Caddie style', value: _personality ?? 'Any', onTap: () => choose<String>(
                      'Caddie style',
                      [(null, 'Any'), for (final p in _personalities) (p, p)],
                      _personality,
                      (v) => _personality = v,
                    )),
              ObRow('Knows the course', value: _course ?? 'Any', onTap: () => choose<String>(
                    'Knows the course',
                    [(null, 'Any course'), for (final c in courses) (c, c)],
                    _course,
                    (v) => _course = v,
                  )),
            ]),
            const SizedBox(height: 12),
            if (_filtered)
              CupertinoButton(
                onPressed: () {
                  _clear();
                  setSheet(() {});
                },
                child: Text('Clear filters', style: Ob.body(17, color: Ob.warn)),
              ),
            ObButton(height: 50, radius: 14, onPressed: () => Navigator.pop(sheet), child: Text('Done', style: Ob.label(17))),
          ]),
        );
      }),
    );
  }

  static const _any = '__any__';
}

String _fmt(double v) => v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String _courses(String json) {
  try {
    final list = (jsonDecode(json) as List).whereType<String>().toList();
    return list.take(1).join(', ');
  } catch (_) {
    return json.replaceAll(RegExp(r'[\[\]"]'), '');
  }
}

/// A caddie or coach as one list row: who, what they are, where, and price.
class _ProRow extends StatelessWidget {
  const _ProRow({required this.provider});
  final db.Provider provider;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final caddie = p.role.toLowerCase() == 'caddie';
    final course = _courses(p.coursesJson);
    return ObRow(
      p.name,
      subtitle: [
        caddie ? 'Caddie' : 'Coach',
        if (p.experience > 0) '${p.experience} yrs',
        if (p.rating > 0) '★ ${p.rating.toStringAsFixed(1)}',
        if (course.isNotEmpty) course,
      ].join(' · '),
      leading: Stack(clipBehavior: Clip.none, children: [
        _ProviderAvatar(userId: p.userId, avatarUrl: p.avatarUrl),
        if (p.hasCertification)
          Positioned(
            right: -3,
            bottom: -3,
            child: Semantics(
              label: 'Verified',
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: Color(0xFF2563EB)),
              ),
            ),
          ),
      ]),
      value: p.price == null ? null : 'KES ${_fmt(p.price!)}',
      onTap: () => context.push('/marketplace/provider/${p.userId}'),
    );
  }
}

class _ProviderAvatar extends ConsumerWidget {
  final String userId;
  final String? avatarUrl;
  const _ProviderAvatar({required this.userId, this.avatarUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(specificUserProfileProvider(userId)).valueOrNull?.avatarUrl ?? avatarUrl;
    return ProfileImage(url: url, size: 44, isCircle: true);
  }
}

/// A pro the golfer called: did it turn into a booking?
class _InquiryRow extends ConsumerWidget {
  const _InquiryRow({required this.interaction, required this.all});
  final db.Interaction interaction;
  final List<db.Provider> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = all.where((p) => p.userId == interaction.providerId).firstOrNull;
    if (provider == null) return const SizedBox.shrink();
    final service = ref.read(interactionServiceProvider);
    Widget answer(String label, Color color, VoidCallback onTap) => CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(44, 44),
          onPressed: onTap,
          child: Text(label, style: Ob.body(17, weight: FontWeight.w600, color: color)),
        );
    return ObRow(
      provider.name,
      subtitle: 'You called ${provider.role.toLowerCase() == 'caddie' ? 'this caddie' : 'this coach'}',
      leading: _ProviderAvatar(userId: provider.userId, avatarUrl: provider.avatarUrl),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        answer('No', Ob.creamA(.6), () => service.ignoreInteraction(interaction.id)),
        answer('Yes', Ob.lime, () => service.confirmBooking(interaction.id, true)),
      ]),
    );
  }
}
