import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import 'caddie_orb_screen.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final bool isVoice;
  const PracticeSessionScreen({super.key, required this.sessionId, this.isVoice = false});

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  db.PracticeSession? _session;
  String? _drillName;
  List<db.DrillStep> _steps = [];
  int _currentStepIndex = 0;
  List<db.Club> _clubs = [];
  int? _selectedClubId;
  int _shotCount = 0;
  int _stepShotCount = 0;
  bool _isEnding = false;
  
  final _distanceController = TextEditingController(text: '0');
  Timer? _sessionTimer;
  Duration _elapsedTime = Duration.zero;
  final List<db.PracticeShot> _sessionShots = []; 
  String _dispersion = 'Straight'; 

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _distanceController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsedTime = Duration(seconds: timer.tick));
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  Future<void> _loadData() async {
    final database = ref.read(databaseProvider);
    final session = await (database.select(database.practiceSessions)..where((s) => s.id.equals(widget.sessionId))).get().then((list) => list.firstOrNull);
    if (session == null) return;
    final clubs = await (database.select(database.clubs)..where((c) => c.userId.equals(session.userId) & c.kind.equals('club'))).get();

    db.Drill? drill;
    List<db.DrillStep> steps = [];
    String? drillName;

    if (session.drillId != null) {
      drill = await (database.select(database.drills)..where((d) => d.id.equals(session.drillId!))).get().then((list) => list.firstOrNull);
      steps = await (database.select(database.drillSteps)
            ..where((s) => s.drillId.equals(session.drillId!))
            ..orderBy([(t) => drift.OrderingTerm.asc(t.stepOrder)]))
          .get();
      drillName = drill?.name;
    } else if (session.coachDrillId != null) {
      final coachDrill = await ref.read(coachingServiceProvider).getSessionById(session.coachDrillId!);
      if (coachDrill != null) {
        drillName = coachDrill.name;
        final rawSteps = await ref.read(coachingServiceProvider).getDrillSteps(session.coachDrillId!);
        steps = rawSteps.map((s) => db.DrillStep(
          id: 0, 
          drillId: 0, 
          stepOrder: s['step_order'], 
          instruction: s['instruction'], 
          ballsRequired: s['balls_required'],
        )).toList();
      }
    }

    if (mounted) {
      setState(() {
        _session = session;
        _drillName = drillName;
        _steps = steps;
        _clubs = clubs;
        if (clubs.isNotEmpty) {
          _selectedClubId = clubs.first.id;
          _updateDistanceForClub(_selectedClubId!);
        }
        _shotCount = session.totalBalls;
      });
    }
  }

  void _updateDistanceForClub(int clubId) {
    final club = _clubs.firstWhere((c) => c.id == clubId);
    if (club.averageDistance != null) {
      _distanceController.text = club.averageDistance!.toInt().toString();
      return;
    }
    
    int dist = 150;
    if (club.type == 'Driver') {
      dist = 240;
    } else if (club.type.contains('3')) {
      dist = 210;
    } else if (club.type.contains('5')) {
      dist = 180;
    } else if (club.type.contains('Putter')) {
      dist = 10;
    }
    _distanceController.text = '$dist';
  }

  Future<void> _logShot(String quality) async {
    if (_selectedClubId == null) return;
    final database = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final formatter = ref.read(unitFormatterProvider);
    final distance = formatter.toYards(double.tryParse(_distanceController.text) ?? 0.0);

    final companion = db.PracticeShotsCompanion.insert(
      sessionId: widget.sessionId,
      supabaseId: drift.Value(const Uuid().v4()),
      clubId: _selectedClubId!,
      quality: drift.Value(quality),
      distance: drift.Value(distance),
      timestamp: drift.Value(DateTime.now()),
    );

    final shotId = await database.into(database.practiceShots).insert(companion);
    HapticFeedback.mediumImpact();

    final fullShot = await (database.select(database.practiceShots)..where((s) => s.id.equals(shotId))).get().then((list) => list.firstOrNull);
    if (fullShot != null) {
      syncService.syncPracticeShot(fullShot).catchError((e) => debugPrint('Sync error: $e'));
      setState(() {
        _shotCount++;
        _stepShotCount++;
        _sessionShots.add(fullShot);
        if (_steps.isNotEmpty) {
          final currentStep = _steps[_currentStepIndex];
          if (_stepShotCount >= currentStep.ballsRequired) {
            if (_currentStepIndex < _steps.length - 1) {
              _currentStepIndex++;
              _stepShotCount = 0;
            }
          }
        }
      });
      await (database.update(database.practiceSessions)..where((s) => s.id.equals(widget.sessionId)))
        .write(db.PracticeSessionsCompanion(totalBalls: drift.Value(_shotCount)));
    }
  }

  void _openCaddieOrb(String clubType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.94,
        child: CaddieOrbScreen(
          preselectedClub: clubType,
          onShotSaved: (shotData) {
            final quality = shotData['quality']?.toString().toUpperCase() ?? 'GOOD';
            final distanceStr = shotData['distance']?.toString() ?? '150';
            _distanceController.text = distanceStr;
            _logShot(quality);
          },
        ),
      ),
    );
  }

  void _undoLastShot() async {
    if (_sessionShots.isEmpty) return;
    final lastShot = _sessionShots.last;
    final database = ref.read(databaseProvider);
    await (database.delete(database.practiceShots)..where((s) => s.id.equals(lastShot.id))).go();
    setState(() {
      _sessionShots.removeLast();
      _shotCount--;
      if (_stepShotCount > 0) {
        _stepShotCount--;
      } else if (_currentStepIndex > 0) {
        _currentStepIndex--;
        _stepShotCount = _steps[_currentStepIndex].ballsRequired - 1;
      }
    });
  }

  Future<void> _endSession() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);
    final database = ref.read(databaseProvider);
    await (database.update(database.practiceSessions)..where((s) => s.id.equals(widget.sessionId)))
      .write(db.PracticeSessionsCompanion(endTime: drift.Value(DateTime.now())));
    final updatedSession = await (database.select(database.practiceSessions)..where((s) => s.id.equals(widget.sessionId))).get().then((list) => list.firstOrNull);
    if (updatedSession != null) {
      await ref.read(syncServiceProvider).syncPracticeSession(updatedSession);
    }
    if (mounted) context.pushReplacement('/practice/summary/${widget.sessionId}');
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const Scaffold(backgroundColor: Ob.bg, body: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    final formatter = ref.watch(unitFormatterProvider);
    final selected = _clubs.where((c) => c.id == _selectedClubId).firstOrNull;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(children: [
                  ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.isVoice ? 'WITH DANIEL' : 'TYPED SESSION', style: Ob.eyebrow()),
                      Text(_drillName ?? 'Free practice', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(22)),
                    ]),
                  ),
                  if (_sessionShots.isNotEmpty) ObIconButton(icon: LucideIcons.undo2, label: 'Undo last shot', onPressed: _undoLastShot),
                ]),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ObSplitCards(
                  left: ObStat('Time', _formatDuration(_elapsedTime), valueSize: 26),
                  right: ObStat(_steps.isEmpty ? 'Balls hit' : 'Balls · done', _steps.isEmpty ? '$_shotCount' : '$_shotCount · ${_progress()}%', valueSize: 26, valueColor: Ob.lime),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (_steps.isNotEmpty) ...[_buildDrillContextCard(), const SizedBox(height: 20)],
                    if (_clubs.isEmpty)
                      _noClubs()
                    else ...[
                      ObEyebrow('Club'),
                      const SizedBox(height: 10),
                      _buildClubGrid(formatter),
                      const SizedBox(height: 20),
                      if (widget.isVoice)
                        _voiceCard(selected)
                      else
                        _buildShotRecorder(formatter),
                    ],
                  ],
                ),
              ),
              _buildBottomActionArea(),
            ]),
          ),
        ),
      ),
    );
  }

  int _progress() {
    final total = _steps.fold(0, (sum, s) => sum + s.ballsRequired);
    return total > 0 ? ((_shotCount / total) * 100).clamp(0, 100).toInt() : 0;
  }

  Widget _noClubs() {
    return ObCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ObGuideRow(botAsset: 'assets/bots/cast_blob.webp', botLabel: 'Daniel', text: 'Add your clubs first so I know what you\'re hitting.', size: 72, fontSize: 16),
        const SizedBox(height: 16),
        ObButton(
          onPressed: () async {
            await context.push('/profile/bag');
            _loadData();
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.briefcase, size: 18, color: Ob.ink),
            const SizedBox(width: 8),
            Text('Set up my bag', style: Ob.label(15, weight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }

  Widget _voiceCard(db.Club? club) {
    return ObHeroCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hit, then tell Daniel how it went.', style: Ob.display(20, height: 1.15)),
        const SizedBox(height: 6),
        Text('He logs the club, distance and quality for you.', style: Ob.body(13, color: Ob.creamA(.6))),
        const SizedBox(height: 16),
        ObButton(
          onPressed: club == null ? null : () => _openCaddieOrb(club.type),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.mic, size: 18, color: Ob.ink),
            const SizedBox(width: 8),
            Text('Talk to Daniel', style: Ob.label(15, weight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDrillContextCard() {
    final step = _steps[_currentStepIndex];
    return ObHeroCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STEP ${_currentStepIndex + 1} OF ${_steps.length}', style: Ob.eyebrow()),
        const SizedBox(height: 8),
        Text(step.instruction, style: Ob.display(20, height: 1.15)),
        const SizedBox(height: 16),
        Row(
          children: List.generate(step.ballsRequired, (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              height: 6,
              decoration: BoxDecoration(color: i < _stepShotCount ? Ob.lime : Ob.creamA(.1), borderRadius: BorderRadius.circular(3)),
            ),
          )),
        ),
      ]),
    );
  }

  Widget _buildClubGrid(UnitFormatter formatter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _clubs.map((club) {
        final on = _selectedClubId == club.id;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedClubId = club.id);
            _updateDistanceForClub(club.id);
            if (widget.isVoice) _openCaddieOrb(club.type);
          },
          child: ObChip(club.type, on: on),
        );
      }).toList(),
    );
  }

  Widget _buildShotRecorder(UnitFormatter formatter) {
    return ObCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DISTANCE', style: Ob.eyebrow()),
              TextField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                cursorColor: Ob.lime,
                style: Ob.display(38, color: Ob.cream),
                decoration: InputDecoration(border: InputBorder.none, isDense: true, suffixText: formatter.units.toLowerCase(), suffixStyle: Ob.body(14, color: Ob.creamA(.5))),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DIRECTION', style: Ob.eyebrow()),
            const SizedBox(height: 10),
            SizedBox(
              width: 180,
              child: ObGooSegmented<String>(
                options: const [('Left', 'Left'), ('Straight', 'Str.'), ('Right', 'Right')],
                selected: _dispersion,
                onChanged: (v) => setState(() => _dispersion = v),
                height: 38,
                fontSize: 12,
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 18),
        Text('HOW WAS IT?', style: Ob.eyebrow()),
        const SizedBox(height: 10),
        Row(children: [
          _buildQualityIOSButton('GREAT', Ob.lime),
          const SizedBox(width: 8),
          _buildQualityIOSButton('GOOD', const Color(0xFF7DD3FC)),
          const SizedBox(width: 8),
          _buildQualityIOSButton('OKAY', const Color(0xFFF5C531)),
          const SizedBox(width: 8),
          _buildQualityIOSButton('MISS', Ob.warn),
        ]),
      ]),
    );
  }

  Widget _buildQualityIOSButton(String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _logShot(label),
        child: Container(
          height: 56,
          decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .35))),
          child: Center(child: Text(label[0] + label.substring(1).toLowerCase(), style: Ob.body(14, weight: FontWeight.w800, color: color))),
        ),
      ),
    );
  }

  Widget _buildBottomActionArea() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ObButton(
          tone: _shotCount > 0 ? ObButtonTone.lime : ObButtonTone.dark,
          onPressed: _isEnding ? null : _endSession,
          child: Text(_isEnding ? 'Saving…' : 'Finish session', style: Ob.label(16, weight: FontWeight.w800)),
        ),
      ),
    );
  }
}
