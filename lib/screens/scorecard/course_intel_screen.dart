import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'round_setup_modal.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart' as db;
import '../../providers/app_providers.dart';

class CourseIntelScreen extends ConsumerWidget {
  final int courseId;

  const CourseIntelScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          bottom: false,
          child: FutureBuilder<db.Course>(
            future: database.getCourse(courseId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());
              final course = snapshot.data!;

              return FutureBuilder<List<db.CourseHole>>(
                future: database.getHolesForCourse(courseId, deduplicate: false),
                builder: (context, holeSnapshot) {
                  final holes = holeSnapshot.data ?? [];
                  return FutureBuilder<List<db.Tee>>(
                    future: database.getTeesForCourse(courseId),
                    builder: (context, teeSnapshot) {
                      final tees = teeSnapshot.data ?? [];
                      return _buildSliverContent(context, course, holes, tees);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(BuildContext context, db.Course course, List<db.CourseHole> holes, List<db.Tee> tees) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('COURSE INTEL', style: TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          centerTitle: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Header Card ───────────────────────────────────────────
              _buildHeroCard(course, tees),
              const SizedBox(height: 32),

              // ── Available Tees ────────────────────────────────────────
              const Text('AVAILABLE TEES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              ...tees.map((t) => _buildTeeCard(t)),
              
              const SizedBox(height: 32),

              // ── Hole Distribution ─────────────────────────────────────
              const Text('HOLE OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildParDistribution(holes),
              
              const SizedBox(height: 32),

              // ── Hardest / Easiest ────────────────────────────────────
              _buildHoleInsights(holes),

              const SizedBox(height: 32),

              // ── Hole by Hole Details ──────────────────────────────────
              const Text('HOLE-BY-HOLE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildHoleList(holes, tees),

              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => RoundSetupModal(courseId: courseId),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grey900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('START ROUND', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, size: 18),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(db.Course course, List<db.Tee> tees) {
    final maxYardage = tees.isNotEmpty ? tees.map((t) => t.yardage ?? 0).reduce((a, b) => a > b ? a : b) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.grey900.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('${course.location}, ${course.city ?? ""}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildHeroStat('PAR', '${course.par18 ?? course.par9front ?? 72}'),
              _buildHeroDivider(),
              _buildHeroStat('HOLES', '${course.totalHoles}'),
              _buildHeroDivider(),
              _buildHeroStat('MAX', '${maxYardage}y'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildHeroDivider() {
    return Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 24));
  }

  Widget _buildTeeCard(db.Tee tee) {
    final color = _getTeeColor(tee.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tee.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                Text('${tee.yardage ?? "???"} Yards', style: const TextStyle(color: AppColors.grey400, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${tee.courseRating} CR', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Text('${tee.slopeRating} Slope', style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParDistribution(List<db.CourseHole> holes) {
    if (holes.isEmpty) return const SizedBox();
    
    // Filter to unique holes to avoid double counting from multiple tees
    final uniqueHoles = <int, db.CourseHole>{};
    for (var h in holes) {
      if (!uniqueHoles.containsKey(h.holeNumber)) {
        uniqueHoles[h.holeNumber] = h;
      }
    }
    final displayHoles = uniqueHoles.values.toList();
    
    final p3 = displayHoles.where((h) => h.par == 3).length;
    final p4 = displayHoles.where((h) => h.par == 4).length;
    final p5 = displayHoles.where((h) => h.par == 5).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Row(
            children: [
              _buildParSegment('PAR 3s', p3, Colors.blue),
              _buildParSegment('PAR 4s', p4, Colors.green),
              _buildParSegment('PAR 5s', p5, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (p3 > 0) Expanded(flex: p3, child: Container(height: 8, color: Colors.blue)),
                if (p4 > 0) Expanded(flex: p4, child: Container(height: 8, color: Colors.green)),
                if (p5 > 0) Expanded(flex: p5, child: Container(height: 8, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParSegment(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.grey400)),
        ],
      ),
    );
  }

  Widget _buildHoleInsights(List<db.CourseHole> holes) {
    if (holes.isEmpty) return const SizedBox();
    
    // Filter to unique holes to avoid double counting
    final uniqueHoles = <int, db.CourseHole>{};
    for (var h in holes) {
      if (!uniqueHoles.containsKey(h.holeNumber)) {
        uniqueHoles[h.holeNumber] = h;
      }
    }
    final displayHoles = uniqueHoles.values.toList();
    
    final sortedByDifficulty = List<db.CourseHole>.from(displayHoles)..sort((a, b) => (a.handicapIndex ?? 99).compareTo(b.handicapIndex ?? 99));
    final hardest = sortedByDifficulty.first;
    final easiest = sortedByDifficulty.last;

    return Row(
      children: [
        Expanded(child: _buildMiniInsight('HARDEST', '#${hardest.holeNumber}', 'Par ${hardest.par} · SI 1', AppColors.doubleBogey)),
        const SizedBox(width: 16),
        Expanded(child: _buildMiniInsight('EASIEST', '#${easiest.holeNumber}', 'Par ${easiest.par} · SI ${easiest.handicapIndex}', AppColors.emerald700)),
      ],
    );
  }

  Widget _buildMiniInsight(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
          Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500)),
        ],
      ),
    );
  }

  Widget _buildHoleList(List<db.CourseHole> holes, List<db.Tee> tees) {
    if (holes.isEmpty) return const SizedBox();

    // Group holes by number
    final Map<int, List<db.CourseHole>> holesByNumber = {};
    for (var h in holes) {
      holesByNumber.putIfAbsent(h.holeNumber, () => []).add(h);
    }

    final sortedHoleNumbers = holesByNumber.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedHoleNumbers.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.grey200, indent: 24, endIndent: 24),
        itemBuilder: (context, index) {
          final holeNum = sortedHoleNumbers[index];
          final holeVariants = holesByNumber[holeNum]!;
          final firstHole = holeVariants.first;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
                  child: Center(child: Text('$holeNum', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Par ${firstHole.par}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('Stroke Index ${firstHole.handicapIndex ?? "?"}', style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getTeeColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('white')) return Colors.grey[500]!;
    if (n.contains('yellow')) return Colors.amber[700]!;
    if (n.contains('red')) return Colors.red[600]!;
    if (n.contains('blue')) return Colors.blue[600]!;
    if (n.contains('green')) return Colors.green[600]!;
    if (n.contains('simba')) return Colors.orange[800]!;
    if (n.contains('chui')) return Colors.black;
    return Colors.black;
  }
}
