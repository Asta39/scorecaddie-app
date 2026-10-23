import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/app_providers.dart';
import '../../core/utils/handicap.dart';
import '../../widgets/profile_image.dart';

class PlayerProfileScreen extends ConsumerWidget {
  final String userId;
  final String? name;

  const PlayerProfileScreen({
    super.key,
    required this.userId,
    this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final statsAsync = ref.watch(publicProfileStatsProvider(userId));
    final profile = profileAsync.valueOrNull;
    final stats = statsAsync.valueOrNull;

    Widget body;
    if (profileAsync.isLoading && profile == null) {
      body = const Padding(padding: EdgeInsets.all(48), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    } else if (profile == null) {
      body = ObGroup(children: [
        ObRow(
          profileAsync.hasError ? 'Couldn’t load this golfer' : 'Golfer not found',
          subtitle: profileAsync.hasError ? 'Check your connection, then try again' : 'They may have deleted their account',
          onTap: profileAsync.hasError ? () => ref.invalidate(publicProfileProvider(userId)) : null,
        ),
      ]);
    } else {
      final hcp = (profile['handicapIndex'] as num?)?.toDouble();
      final recent = stats?['recentScore'] as Map<String, dynamic>?;
      final achievements = (stats?['achievements'] as List?) ?? const [];
      final role = (profile['role'] as String?)?.toLowerCase();
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ProfileImage(url: profile['avatarUrl'], name: profile['name'] ?? 'G', size: 64, isCircle: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile['name'] ?? 'Golfer', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(22, height: 1.15)),
              Text(
                [if (role == 'coach') 'Coach' else if (role == 'caddie') 'Caddie' else 'Player', if (stats?['homeCourse'] != null) stats!['homeCourse']].join(' · '),
                style: Ob.body(15, color: Ob.creamA(.6)),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Handicap Index', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.6))),
            Text(hcp == null ? '—' : HandicapCalculator.format(hcp), style: Ob.display(48, height: 1.1)),
          ]),
        ),
        const SizedBox(height: 22),
        ObGroup(header: 'Rounds', children: [
          ObRow('Rounds played', value: '${stats?['totalRounds'] ?? 0}'),
          ObRow('Best score', value: stats?['bestScore']?.toString() ?? '—'),
          ObRow('Average score', value: stats?['avgScore']?.toString() ?? '—'),
          if (recent != null)
            ObRow(
              'Last round',
              subtitle: '${recent['course']} · ${DateFormat('d MMM y').format(DateTime.parse(recent['date']))}',
              value: '${recent['score']}',
              valueColor: Ob.cream,
            ),
        ]),
        if (achievements.isNotEmpty) ...[
          const SizedBox(height: 22),
          ObGroup(header: 'Achievements', children: [for (final a in achievements) ObRow('${a['title']}')]),
        ],
        const SizedBox(height: 22),
        ObGroup(header: 'About', children: [
          ObRow('Skill level', value: profile['skillLevel'] ?? '—'),
          ObRow('Play style', value: profile['playStyle'] ?? '—'),
        ]),
      ]);
    }

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
            children: [
              ObTopBar(name ?? 'Golfer', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 14),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

final publicProfileProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.read(friendServiceProvider).streamProfile(uid);
});

final publicProfileStatsProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.read(friendServiceProvider).streamPlayerStats(uid);
});
