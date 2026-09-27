import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/database.dart' as db;
import '../../core/services/interaction_service.dart';
import '../../core/utils/url_helper.dart';
import '../../providers/app_providers.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

final marketplaceRoleFilterProvider = StateProvider<String>((ref) => 'all');

/// Caddie tab: find caddies and coaches, the ones you've contacted, and the
/// ones you've played with.
class CaddieMarketplaceScreen extends ConsumerStatefulWidget {
  final String initialRole;

  const CaddieMarketplaceScreen({super.key, this.initialRole = 'all'});

  @override
  ConsumerState<CaddieMarketplaceScreen> createState() => _CaddieMarketplaceScreenState();
}

class _CaddieMarketplaceScreenState extends ConsumerState<CaddieMarketplaceScreen> {
  static const _personalities = ['Talkative & Fun', 'Strategic', 'Quiet & Focused', 'Laid-back'];
  static const _feeMin = 500.0, _feeMax = 5000.0;

  late String _selectedRole = widget.initialRole;
  final _searchController = TextEditingController();
  String _section = 'discover';
  int? _requiredExperience;
  String? _selectedPersonality;
  String? _selectedCourse;
  double _maxFee = _feeMax;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters => _requiredExperience != null || _selectedCourse != null;

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(marketplaceRoleFilterProvider, (prev, next) {
      if (next != _selectedRole) setState(() => _selectedRole = next);
    });

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ObTabHeader('Caddies & coaches', actions: [
              Stack(clipBehavior: Clip.none, children: [
                ObIconButton(icon: LucideIcons.slidersHorizontal, label: 'Filters', onPressed: _showFilterSheet),
                if (_hasFilters) Positioned(right: 2, top: 2, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Ob.lime, shape: BoxShape.circle, border: Border.all(color: Ob.bg, width: 2)))),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: ObGooSegmented<String>(
              options: const [('discover', 'Discover'), ('inquiries', 'Inquiries'), ('recent', 'Recent')],
              selected: _section,
              onChanged: (v) => setState(() => _section = v),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: const ['discover', 'inquiries', 'recent'].indexOf(_section),
              children: [_discover(), _inquiries(), _recent()],
            ),
          ),
        ]),
      ),
    );
  }

  // ── discover ────────────────────────────────────────────────────────────
  Widget _discover() {
    final providersAsync = ref.watch(allProvidersProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: Ob.body(15),
              cursorColor: Ob.lime,
              decoration: _fieldDecoration('Name or course', LucideIcons.search),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 176,
            child: ObGooSegmented<String>(
              height: 50,
              fontSize: 12,
              options: const [('all', 'All'), ('caddie', 'Caddies'), ('coach', 'Coaches')],
              selected: _selectedRole,
              onChanged: (r) {
                setState(() => _selectedRole = r);
                ref.read(marketplaceRoleFilterProvider.notifier).state = r;
              },
            ),
          ),
        ]),
        const SizedBox(height: 14),
        ObCard(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ObEyebrow(_selectedRole == 'coach' ? 'Most per hour' : 'Most you’ll pay',
                trailing: Text(_maxFee >= _feeMax ? 'Any price' : 'KES ${_fmt(_maxFee)}', style: Ob.display(22, height: 1))),
            const SizedBox(height: 4),
            ObLiquidSlider(
              value: _maxFee,
              min: _feeMin,
              max: _feeMax,
              labels: const ['500', '2,000', '3,500', 'Any'],
              onChanged: (v) => setState(() => _maxFee = (v / 100).round() * 100),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
            for (final p in _personalities)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ObButton(
                  tone: _selectedPersonality == p ? ObButtonTone.lime : ObButtonTone.dark,
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => setState(() => _selectedPersonality = _selectedPersonality == p ? null : p),
                  child: Text(p, style: Ob.label(14)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        providersAsync.when(
          loading: () => const SizedBox(height: 200, child: LoadingSpinner()),
          error: (e, _) => Text('Couldn’t load pros.', style: Ob.body(14, color: Ob.creamA(.7))),
          data: (providers) {
            if (providers.isEmpty) return _blobSays('No pros on ScoreCaddie yet. They’re on their way.');
            final q = _searchController.text.toLowerCase();
            final filtered = providers.where((p) {
              if (_selectedRole != 'all' && p.role.toLowerCase() != _selectedRole) return false;
              if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.coursesJson.toLowerCase().contains(q)) return false;
              if (_requiredExperience != null && p.experience < _requiredExperience!) return false;
              if (_selectedPersonality != null && p.personalityType != _selectedPersonality) return false;
              if (_selectedCourse != null && !p.coursesJson.contains(_selectedCourse!)) return false;
              if (_maxFee < _feeMax && (p.price ?? 0) > _maxFee) return false;
              return true;
            }).toList();
            if (filtered.isEmpty) return _blobSays('Nobody matches that. Try widening the budget or filters.');
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ObEyebrow('${filtered.length} ${filtered.length == 1 ? 'pro' : 'pros'}'),
              const SizedBox(height: 12),
              for (final p in filtered) Padding(padding: const EdgeInsets.only(bottom: 12), child: _ProviderCard(provider: p)),
            ]);
          },
        ),
      ],
    );
  }

  // ── inquiries and recent ────────────────────────────────────────────────
  Widget _inquiries() => ref.watch(pendingInteractionsProvider).when(
        loading: () => const LoadingSpinner(),
        error: (e, _) => Center(child: Text('Couldn’t load inquiries.', style: Ob.body(14, color: Ob.creamA(.7)))),
        data: (pending) => pending.isEmpty
            ? ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), children: [_blobSays('Quiet out here. Message a pro and they’ll show up here.')])
            : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), children: [for (final i in pending) _InquiryCard(interaction: i)]),
      );

  Widget _recent() => ref.watch(recentProsProvider).when(
        loading: () => const LoadingSpinner(),
        error: (e, _) => Center(child: Text('Couldn’t load your pros.', style: Ob.body(14, color: Ob.creamA(.7)))),
        data: (pros) => pros.isEmpty
            ? ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), children: [_blobSays('Pros you book show up here, ready to book again.')])
            : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), children: [for (final p in pros) Padding(padding: const EdgeInsets.only(bottom: 12), child: _ProviderCard(provider: p))]),
      );

  /// The caddie blob, dozing, for empty states.
  Widget _blobSays(String text) => ObGuideRow(botAsset: 'assets/bots/cast_blob.webp', botLabel: 'The caddie blob, dozing', text: text, size: 96, fontSize: 18);

  // ── filters ─────────────────────────────────────────────────────────────
  InputDecoration _fieldDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: Ob.body(15, color: Ob.creamA(.35)),
        prefixIcon: Icon(icon, size: 18, color: Ob.creamA(.5)),
        filled: true,
        fillColor: Ob.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Ob.fieldBorder, width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Ob.lime, width: 2)),
      );

  void _showFilterSheet() {
    final courses = {...(ref.read(coursesProvider).valueOrNull ?? const []).map((c) => c.name)}.toList()..sort();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          void set(VoidCallback f) {
            setSheet(f);
            setState(() {});
          }

          return Container(
            height: MediaQuery.of(sheet).size.height * .72,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1A12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: Color(0x40A3E635))),
            ),
            child: DefaultTextStyle(
              style: Ob.textBase,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Text('Filters', style: Ob.display(26))),
                  GestureDetector(
                    onTap: () => set(() {
                      _requiredExperience = null;
                      _selectedCourse = null;
                    }),
                    child: Text('Reset', style: Ob.label(14).copyWith(color: Ob.warn)),
                  ),
                ]),
                const SizedBox(height: 18),
                const ObEyebrow('Experience'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (v, l) in const [(null, 'Any'), (2, '2+ years'), (3, '3+ years'), (5, '5+ years')])
                    ObButton(
                      tone: _requiredExperience == v ? ObButtonTone.lime : ObButtonTone.dark,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => set(() => _requiredExperience = v),
                      child: Text(l, style: Ob.label(14)),
                    ),
                ]),
                const SizedBox(height: 20),
                const ObEyebrow('Knows this course'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(children: [
                    for (final c in [null, ...courses])
                      GestureDetector(
                        onTap: () => set(() => _selectedCourse = c),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedCourse == c ? Ob.lime.withValues(alpha: .08) : Ob.cardFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _selectedCourse == c ? Ob.lime : const Color(0x0FFFFFFF), width: 2),
                          ),
                          child: Text(c ?? 'Any course', style: Ob.body(15, weight: FontWeight.w700)),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
                ObButton(onPressed: () => Navigator.pop(sheet), child: Text('Show pros', style: Ob.label(16, weight: FontWeight.w800))),
              ]),
            ),
          );
        },
      ),
    );
  }
}

String _fmt(double v) => v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String _courses(String json) {
  try {
    final list = (jsonDecode(json) as List).whereType<String>().toList();
    return list.take(2).join(', ');
  } catch (_) {
    return json.replaceAll(RegExp(r'[\[\]"]'), '');
  }
}

class _ProviderCard extends ConsumerWidget {
  final db.Provider provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = provider;
    final caddie = p.role.toLowerCase() == 'caddie';
    final courses = _courses(p.coursesJson);
    return ObCard(
      onTap: () => context.push('/marketplace/provider/${p.userId}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(clipBehavior: Clip.none, children: [
            _ProviderAvatar(userId: p.userId, avatarUrl: p.avatarUrl),
            if (p.hasCertification || p.isAvailable)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: p.hasCertification ? Ob.lime : Ob.lime, shape: BoxShape.circle, border: Border.all(color: Ob.cardFill, width: 3)),
                  child: p.hasCertification ? const Icon(LucideIcons.check, size: 11, color: Ob.ink) : null,
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(21, height: 1.1)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(LucideIcons.star, size: 14, color: Color(0xFFF5C531)),
                const SizedBox(width: 4),
                Text(p.rating.toStringAsFixed(1), style: Ob.label(13, weight: FontWeight.w800)),
                Flexible(
                  child: Text(' · ${p.experience} yrs${courses.isNotEmpty ? ' · $courses' : ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(13, color: Ob.creamA(.66))),
                ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ObChip(caddie ? 'Caddie' : 'Coach', on: true),
                if (p.personalityType != null) ObChip(p.personalityType!),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: p.price == null
                ? Text('Price on request', style: Ob.body(13, color: Ob.creamA(.55)))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('KES ${_fmt(p.price!)}', style: Ob.display(24, height: 1)),
                    Text(caddie ? 'per round' : 'per hour', style: Ob.body(11, color: Ob.creamA(.55))),
                  ]),
          ),
          ObIconButton(
            icon: LucideIcons.phone,
            label: 'Call ${p.name}',
            onPressed: () async {
              await UrlHelper.launchCaller(p.phone);
              ref.read(interactionServiceProvider).logInteraction(providerId: p.userId, type: 'call');
            },
          ),
          const SizedBox(width: 10),
          ObButton(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onPressed: () async {
              if (caddie) {
                ref.read(interactionServiceProvider).logInteraction(providerId: p.userId, type: 'chat');
                if (context.mounted) context.push('/chat/${p.userId}');
              } else {
                await UrlHelper.launchWhatsApp(p.whatsapp ?? p.phone);
                ref.read(interactionServiceProvider).logInteraction(providerId: p.userId, type: 'whatsapp');
              }
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(caddie ? LucideIcons.messageCircle : LucideIcons.messageSquare, size: 16),
              const SizedBox(width: 6),
              Text(caddie ? 'Message' : 'WhatsApp', style: Ob.label(15, weight: FontWeight.w800)),
            ]),
          ),
        ]),
      ]),
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
    return ProfileImage(url: url, size: 64, isCircle: true);
  }
}

class _InquiryCard extends ConsumerWidget {
  final db.Interaction interaction;
  const _InquiryCard({required this.interaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = (ref.watch(allProvidersProvider).valueOrNull ?? const <db.Provider>[]).where((p) => p.userId == interaction.providerId).firstOrNull;
    if (provider == null) return const SizedBox.shrink();
    final via = switch (interaction.type.toLowerCase()) { 'call' => 'You called', 'whatsapp' => 'You messaged on WhatsApp', _ => 'You messaged' };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ObCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            _ProviderAvatar(userId: provider.userId, avatarUrl: provider.avatarUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(provider.name, style: Ob.display(20, height: 1.1)),
                const SizedBox(height: 2),
                Text(via, style: Ob.body(13, color: Ob.creamA(.6))),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text('Did you book ${provider.name.split(' ').first}?', style: Ob.body(14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ObButton(
                tone: ObButtonTone.dark,
                height: 44,
                onPressed: () => ref.read(interactionServiceProvider).ignoreInteraction(interaction.id),
                child: Text('Not booked', style: Ob.label(14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ObButton(
                height: 44,
                onPressed: () => ref.read(interactionServiceProvider).confirmBooking(interaction.id, true),
                child: Text('Yes, booked', style: Ob.label(14, weight: FontWeight.w800)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
