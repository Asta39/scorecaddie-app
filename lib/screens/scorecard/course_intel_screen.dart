import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'round_setup_modal.dart';
import '../../core/database/database.dart' as db;
import '../../providers/app_providers.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

typedef _Intel = ({db.Course course, List<db.CourseHole> holes, List<db.Tee> tees});

final _intelProvider = FutureProvider.autoDispose.family<_Intel, int>((ref, id) async {
  final d = ref.watch(databaseProvider);
  final r = await Future.wait([d.getCourse(id), d.getHolesForCourse(id, deduplicate: false), d.getTeesForCourse(id)]);
  return (course: r[0] as db.Course, holes: r[1] as List<db.CourseHole>, tees: r[2] as List<db.Tee>);
});

Color teeColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('white')) return const Color(0xFFE8ECE6);
  if (n.contains('yellow') || n.contains('gold')) return const Color(0xFFF5C531);
  if (n.contains('red')) return const Color(0xFFF26B5B);
  if (n.contains('blue')) return const Color(0xFF7DD3FC);
  if (n.contains('green')) return Ob.lime;
  if (n.contains('simba')) return const Color(0xFFF59E0B);
  return Ob.creamA(.5);
}

class CourseIntelScreen extends ConsumerWidget {
  final int courseId;

  const CourseIntelScreen({super.key, required this.courseId});

  void _start(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RoundSetupModal(courseId: courseId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_intelProvider(courseId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: SafeArea(
            bottom: false,
            child: async.when(
              loading: () => const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const ObTopBar('Course'),
                  const SizedBox(height: 24),
                  Text('Couldn\'t load this course.', style: Ob.display(22)),
                ]),
              ),
              data: (d) => Column(children: [
                Expanded(child: _content(context, d)),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    child: ObButton(
                      onPressed: () => _start(context),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.flag, size: 18, color: Ob.ink),
                        const SizedBox(width: 8),
                        Text('Play this course', style: Ob.label(17, weight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, _Intel d) {
    final c = d.course;
    final unique = <int, db.CourseHole>{};
    for (final h in d.holes) {
      unique.putIfAbsent(h.holeNumber, () => h);
    }
    final holes = unique.values.toList()..sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
    final p3 = holes.where((h) => h.par == 3).length, p4 = holes.where((h) => h.par == 4).length, p5 = holes.where((h) => h.par == 5).length;
    final bySi = [...holes.where((h) => h.handicapIndex != null)]..sort((a, b) => a.handicapIndex!.compareTo(b.handicapIndex!));
    final longest = d.tees.isEmpty ? null : d.tees.map((t) => t.yardage ?? 0).reduce((a, b) => a > b ? a : b);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const ObTopBar('Course', eyebrow: 'Before you tee off'),
        const SizedBox(height: 16),
        Row(children: [
          ObCrest(c.name, size: 64, radius: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: Ob.display(26, height: 1.05)),
              const SizedBox(height: 4),
              Text([c.location, if ((c.city ?? '').isNotEmpty) c.city].join(', '), style: Ob.body(13, color: Ob.creamA(.6))),
            ]),
          ),
        ]).rise(),
        const SizedBox(height: 16),
        ObHeroCard(
          child: Row(children: [
            Expanded(child: ObStat('Par', '${c.par18 ?? c.par9front ?? 72}', valueColor: Ob.lime)),
            Expanded(child: ObStat('Holes', '${c.totalHoles}')),
            Expanded(child: ObStat('Longest', longest == null || longest == 0 ? '—' : '${longest}y')),
          ]),
        ).rise(1),
        if (holes.isNotEmpty) ...[
          const SizedBox(height: 12),
          ObCard(
            child: Column(children: [
              Row(children: [
                _parCount('Par 3s', p3, const Color(0xFF7DD3FC)),
                _parCount('Par 4s', p4, Ob.lime),
                _parCount('Par 5s', p5, const Color(0xFFF5C531)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Row(children: [
                    if (p3 > 0) Expanded(flex: p3, child: Container(color: const Color(0xFF7DD3FC))),
                    if (p4 > 0) Expanded(flex: p4, child: Container(color: Ob.lime)),
                    if (p5 > 0) Expanded(flex: p5, child: Container(color: const Color(0xFFF5C531))),
                  ]),
                ),
              ),
            ]),
          ),
        ],
        if (bySi.length >= 2) ...[
          const SizedBox(height: 12),
          ObSplitCards(
            left: ObStat('Hardest', 'Hole ${bySi.first.holeNumber}', valueSize: 24, valueColor: Ob.warn),
            right: ObStat('Easiest', 'Hole ${bySi.last.holeNumber}', valueSize: 24, valueColor: Ob.lime),
          ),
        ],
        if (d.tees.isNotEmpty) ...[
          const SizedBox(height: 24),
          const ObEyebrow('Tees'),
          const SizedBox(height: 10),
          ObCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              for (final (i, t) in d.tees.indexed) ...[
                if (i > 0) const ObHair(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(width: 14, height: 14, decoration: BoxDecoration(color: teeColor(t.name), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.name, style: Ob.body(15, weight: FontWeight.w800)),
                        Text(t.yardage == null ? 'Length not set' : '${t.yardage} yards', style: Ob.body(12, color: Ob.creamA(.55))),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${t.courseRating}', style: Ob.body(14, weight: FontWeight.w800)),
                      Text('Slope ${t.slopeRating}', style: Ob.body(11, color: Ob.creamA(.55))),
                    ]),
                  ]),
                ),
              ],
            ]),
          ),
        ],
        if (holes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const ObEyebrow('Hole by hole'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.25),
            itemCount: holes.length,
            itemBuilder: (_, i) {
              final h = holes[i];
              final hard = h.handicapIndex != null && h.handicapIndex! <= 3;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Ob.cardFill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: hard ? Ob.warn.withValues(alpha: .45) : Colors.transparent),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${h.holeNumber}', style: Ob.display(22, height: 1)),
                  Text('Par ${h.par}', style: Ob.body(13, weight: FontWeight.w800, color: Ob.lime)),
                  Text('SI ${h.handicapIndex ?? '–'}', style: Ob.body(11, color: Ob.creamA(.55))),
                ]),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _parCount(String label, int n, Color color) => Expanded(
        child: Column(children: [
          Text('$n', style: Ob.display(24, color: color)),
          Text(label, style: Ob.body(11, color: Ob.creamA(.55))),
        ]),
      );
}
