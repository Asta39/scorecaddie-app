import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/achievement_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/achievement_dialog.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

Set<String> parseBadges(String? json) {
  if (json == null || json.isEmpty) return {};
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) return decoded.map((e) => '$e').toSet();
  } catch (_) {}
  return {};
}

class AchievementsGalleryScreen extends ConsumerStatefulWidget {
  const AchievementsGalleryScreen({super.key});

  @override
  ConsumerState<AchievementsGalleryScreen> createState() => _AchievementsGalleryScreenState();
}

class _AchievementsGalleryScreenState extends ConsumerState<AchievementsGalleryScreen> {
  AchievementCategory? _category;

  @override
  Widget build(BuildContext context) {
    final earned = parseBadges(ref.watch(userProfileProvider).valueOrNull?.badgesJson);
    const all = Achievement.allAchievements;
    final got = all.where((a) => earned.contains(a.id)).toList();
    final points = got.fold<int>(0, (s, a) => s + a.points);
    final shown = all.where((a) => _category == null || a.category == _category).toList()
      ..sort((a, b) {
        final ea = earned.contains(a.id), eb = earned.contains(b.id);
        return ea == eb ? 0 : (ea ? -1 : 1);
      });

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList.list(children: [
                  Row(children: [
                    if (context.canPop()) ...[
                      ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
                      const SizedBox(width: 10),
                    ],
                    Text('Achievements', style: Ob.display(28)),
                  ]).rise(),
                  const SizedBox(height: 16),
                  ObHeroCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOUR SHELF', style: Ob.eyebrow()),
                      const SizedBox(height: 6),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('${got.length}', style: Ob.display(52, color: Ob.lime, height: 1)),
                        Text(' of ${all.length}', style: Ob.body(16, weight: FontWeight.w700, color: Ob.creamA(.6))),
                        const Spacer(),
                        Text('$points pts', style: Ob.display(22)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(value: all.isEmpty ? 0 : got.length / all.length, minHeight: 10, backgroundColor: Ob.creamA(.08), color: Ob.lime),
                      ),
                      if (got.isEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Play a round and the first ones start waking up.', style: Ob.body(13, color: Ob.creamA(.6))),
                      ],
                    ]),
                  ).rise(1),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 34,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      _filter(null, 'All', all.length),
                      for (final c in AchievementCategory.values)
                        _filter(c, AchievementDialog.categoryName(c), all.where((a) => a.category == c).length),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: .74),
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final a = shown[i];
                    final on = earned.contains(a.id);
                    return Semantics(
                      button: true,
                      label: '${a.title}, ${on ? 'earned' : 'locked'}',
                      child: GestureDetector(
                        onTap: () => AchievementDialog.show(context, a, isEarned: on),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                          decoration: BoxDecoration(
                            color: on ? Ob.roleFill : Ob.cardFill,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: on ? Ob.lime.withValues(alpha: .35) : Colors.transparent),
                          ),
                          child: Column(children: [
                            Expanded(
                              child: AchievementAvatar(a, earned: on),
                            ),
                            const SizedBox(height: 4),
                            Text(a.title,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: Ob.body(12, weight: FontWeight.w800, height: 1.15, color: on ? Ob.cream : Ob.creamA(.5))),
                            Text('${a.points} pts', style: Ob.body(11, color: on ? Ob.lime : Ob.creamA(.35))),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filter(AchievementCategory? c, String label, int count) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _category = c),
          child: ObChip('$label · $count', on: _category == c),
        ),
      );
}
