import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import 'course_intel_screen.dart' show teeColor;
import '../../core/database/database.dart' as db;
import '../../core/utils/whs_engine.dart';
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';

class RoundSetupModal extends ConsumerStatefulWidget {
  final int courseId;
  const RoundSetupModal({super.key, required this.courseId});

  static Future<void> show(BuildContext context, db.Course course, {bool isGroup = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoundSetupModal(courseId: course.id),
    );
  }

  @override
  ConsumerState<RoundSetupModal> createState() => _RoundSetupModalState();
}

class _RoundSetupModalState extends ConsumerState<RoundSetupModal> {
  String _format = '18 Holes';
  db.Tee? _selectedTee;
  List<db.Tee> _tees = [];
  bool _loading = true;
  int? _frontPar, _backPar;
  int? get _ninePar => _format == 'Front 9' ? _frontPar : _backPar;
  
  // Marker state
  db.Friend? _selectedMarker;
  String _manualMarkerName = '';
  final TextEditingController _markerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTees();
  }

  Future<void> _loadTees() async {
    final database = ref.read(databaseProvider);
    final tees = await database.getTeesForCourse(widget.courseId);
    final holes = await database.getHolesForCourse(widget.courseId);
    int? sumPar(bool front) {
      final h = holes.where((h) => front ? h.holeNumber <= 9 : h.holeNumber > 9).toList();
      return h.length == 9 ? h.fold<int>(0, (a, x) => a + x.par) : null;
    }
    _frontPar = sumPar(true);
    _backPar = sumPar(false);
    setState(() {
      _tees = tees;
      if (tees.isNotEmpty) _selectedTee = tees.first;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _markerNameController.dispose();
    super.dispose();
  }

  int _calculateCH(double handicapIndex) {
    final t = _selectedTee;
    if (t == null) return 0;
    if (_format == '18 Holes') {
      return WHSEngine.calculateCourseHandicap(
        handicapIndex: handicapIndex,
        slopeRating: t.slopeRating,
        courseRating: t.courseRating,
        par: t.par ?? 72,
      );
    }
    final front = _format == 'Front 9';
    return WHSEngine.calculateNineHoleCourseHandicap(
      handicapIndex: handicapIndex,
      slopeRating: t.slopeRating,
      courseRating: t.courseRating,
      par: t.par ?? 72,
      nineSlopeRating: front ? t.slopeRatingFront : t.slopeRatingBack,
      nineCourseRating: front ? t.courseRatingFront : t.courseRatingBack,
      ninePar: _ninePar,
    );
  }

  void _play(double hIndex) {
    final markerName = _selectedMarker?.friendName ?? _manualMarkerName.trim();
    if (markerName.isEmpty) {
      TopNotification.showError(context, 'Add a marker so the round counts for your handicap.');
      return;
    }
    final ch = _calculateCH(hIndex);
    Navigator.pop(context);
    context.push('/scoring', extra: {
      'courseId': widget.courseId,
      'holesPlayed': _format == '18 Holes' ? 18 : (_format == 'Front 9' ? 9 : -9),
      'teeId': _selectedTee?.id,
      'courseHandicap': ch,
      'markerName': markerName,
      'markerId': _selectedMarker?.friendId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hIndex = profile?.handicap ?? 0.0;

    if (_loading) return const ObSheet(child: SizedBox(height: 260, child: Center(child: CupertinoActivityIndicator(color: Ob.lime))));
    final friends = ref.watch(friendsProvider).valueOrNull ?? const <db.Friend>[];

    final courseName = ref.watch(coursesProvider).valueOrNull?.where((c) => c.id == widget.courseId).firstOrNull?.name ?? 'Your course';
    return ObSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .78),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              ObCrest(courseName, size: 44, radius: 13),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ROUND SETUP', style: Ob.eyebrow()),
                  Text(courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(22, height: 1.1)),
                ]),
              ),
              ObIconButton(icon: LucideIcons.x, label: 'Close', onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            const ObEyebrow('Holes'),
            const SizedBox(height: 10),
            ObGooSegmented<String>(
              options: const [('18 Holes', '18 holes'), ('Front 9', 'Front 9'), ('Back 9', 'Back 9')],
              selected: _format,
              onChanged: (v) => setState(() => _format = v),
            ),
            const SizedBox(height: 20),
            const ObEyebrow('Tee'),
            const SizedBox(height: 10),
            if (_tees.isEmpty)
              Text('No tees set up for this course yet.', style: Ob.body(14, color: Ob.creamA(.6)))
            else
              for (final t in _tees)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ObSelectTile(
                    selected: _selectedTee?.id == t.id,
                    onTap: () => setState(() => _selectedTee = t),
                    child: Row(children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(color: teeColor(t.name), shape: BoxShape.circle, border: Border.all(color: Ob.creamA(.3), width: 2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name, style: Ob.body(15, weight: FontWeight.w800)),
                          Text('Rating ${t.courseRating} · slope ${t.slopeRating}', style: Ob.body(12, color: Ob.creamA(.58))),
                        ]),
                      ),
                      if (t.yardage != null) Text('${t.yardage}y', style: Ob.display(20)),
                    ]),
                  ),
                ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(22), border: Border.all(color: Ob.lime.withValues(alpha: .2))),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('COURSE HANDICAP', style: Ob.eyebrow()),
                    Text('From your ${hIndex.toStringAsFixed(1)} index on these tees', style: Ob.body(12, color: Ob.creamA(.6))),
                  ]),
                ),
                Text('${_calculateCH(hIndex)}', style: Ob.display(44, height: 1)),
                const SizedBox(width: 6),
                Text('shots', style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.6))),
              ]),
            ),
            const SizedBox(height: 20),
            const ObEyebrow('Your marker · needed for a WHS round'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in friends)
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedMarker = _selectedMarker?.friendId == f.friendId ? null : f;
                    _manualMarkerName = '';
                    _markerNameController.clear();
                  }),
                  child: ObChip(f.friendName ?? 'Friend', on: _selectedMarker?.friendId == f.friendId),
                ),
            ]),
            if (_selectedMarker == null) ...[
              if (friends.isNotEmpty) const SizedBox(height: 10),
              TextField(
                controller: _markerNameController,
                cursorColor: Ob.lime,
                style: Ob.body(15, weight: FontWeight.w700),
                decoration: obInput(friends.isEmpty ? 'Marker\'s name' : 'Or type their name'),
                onChanged: (v) => _manualMarkerName = v,
              ),
            ],
            const SizedBox(height: 8),
            Text('Your marker signs off the card so it counts for WHS.', style: Ob.body(12, color: Ob.creamA(.5))),
            const SizedBox(height: 20),
            ObButton(
              onPressed: _tees.isEmpty ? null : () => _play(hIndex),
              child: Text('Tee off', style: Ob.label(17, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}
