import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (_selectedTee == null) return 0;
    return WHSEngine.calculateCourseHandicap(
      handicapIndex: handicapIndex,
      slopeRating: _selectedTee!.slopeRating,
      courseRating: _selectedTee!.courseRating,
      par: _selectedTee!.par ?? 72,
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

    return ObSheet(
      title: 'Round setup',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
              SizedBox(
                height: 66,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tees.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = _tees[i];
                    return ObSelectTile(
                      selected: _selectedTee?.id == t.id,
                      onTap: () => setState(() => _selectedTee = t),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: teeColor(t.name), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(t.name, style: Ob.body(14, weight: FontWeight.w800)),
                        ]),
                        Text(t.yardage == null ? 'Slope ${t.slopeRating}' : '${t.yardage}y · slope ${t.slopeRating}', style: Ob.body(11, color: Ob.creamA(.55))),
                      ]),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ObHeroCard(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOU GET', style: Ob.eyebrow()),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text('${_calculateCH(hIndex)}', style: Ob.display(40, color: Ob.lime, height: 1)),
                      Text(' strokes', style: Ob.body(15, weight: FontWeight.w700, color: Ob.creamA(.7))),
                    ]),
                  ]),
                ),
                Text('Index ${hIndex.toStringAsFixed(1)}', style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.6))),
              ]),
            ),
            const SizedBox(height: 20),
            const ObEyebrow('Who\'s marking your card?'),
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
              child: Text('Let\'s play', style: Ob.label(17, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}
