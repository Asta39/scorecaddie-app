import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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
  db.Drill? _drill;
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
    final clubs = await (database.select(database.clubs)..where((c) => c.userId.equals(session.userId))).get();

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
        _drill = drill;
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
    if (_session == null) return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    final formatter = ref.watch(unitFormatterProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(_drillName ?? '${_session!.sessionType} Session', 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.grey900, letterSpacing: -0.5)),
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (widget.isVoice)
               const Padding(
                 padding: EdgeInsets.only(right: 12),
                 child: Center(
                   child: Row(
                     children: [
                       Icon(LucideIcons.sparkles, color: AppColors.emerald700, size: 14),
                       SizedBox(width: 4),
                       Text('AI ACTIVE', style: TextStyle(color: AppColors.emerald700, fontSize: 10, fontWeight: FontWeight.w900)),
                     ],
                   ),
                 ),
               ),
            if (_sessionShots.isNotEmpty)
              IconButton(
                onPressed: _undoLastShot,
                icon: const Icon(LucideIcons.undo2, color: AppColors.doubleBogey),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildSessionStatsHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_steps.isNotEmpty) ...[
                      _buildDrillContextCard(),
                      const SizedBox(height: 32),
                    ],
                    _buildSectionLabel('SELECT CLUB'),
                    const SizedBox(height: 16),
                    _buildClubGrid(formatter),
                    if (!widget.isVoice) ...[
                      const SizedBox(height: 32),
                      _buildSectionLabel('SHOT ENTRY'),
                      const SizedBox(height: 16),
                      _buildShotRecorder(formatter),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5));
  }

  Widget _buildSessionStatsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderStat(LucideIcons.timer, _formatDuration(_elapsedTime)),
          _buildHeaderStat(LucideIcons.target, '$_shotCount BALLS', color: AppColors.emerald700),
          if (_steps.isNotEmpty)
            Builder(
              builder: (context) {
                final totalBallsRequired = _steps.fold(0, (sum, s) => sum + s.ballsRequired);
                final progress = totalBallsRequired > 0 ? ((_shotCount / totalBallsRequired) * 100).toInt() : 0;
                return _buildHeaderStat(LucideIcons.checkCircle2, '$progress% DONE');
              }
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.grey400),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: color ?? AppColors.grey900, fontSize: 12, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDrillContextCard() {
    final step = _steps.isNotEmpty ? _steps[_currentStepIndex] : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.grey900.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               const Icon(LucideIcons.sparkles, color: AppColors.golfLime, size: 16),
               const SizedBox(width: 8),
               Text('ACTIVE GOAL', style: TextStyle(color: AppColors.golfLime.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(step?.instruction ?? 'Grind your swing', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          Row(
            children: List.generate(step?.ballsRequired ?? 0, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 6,
                decoration: BoxDecoration(
                  color: i < _stepShotCount ? AppColors.golfLime : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildClubGrid(UnitFormatter formatter) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _clubs.length,
      itemBuilder: (context, index) {
        final club = _clubs[index];
        final isSelected = _selectedClubId == club.id;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedClubId = club.id);
            _updateDistanceForClub(club.id);
            if (widget.isVoice) _openCaddieOrb(club.type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.emerald700 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.emerald700 : AppColors.grey100, width: 2),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(club.type, style: TextStyle(color: isSelected ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(formatter.units.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.6) : AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShotRecorder(UnitFormatter formatter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EST. DISTANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
                    TextField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -1),
                      decoration: InputDecoration(border: InputBorder.none, suffixText: formatter.units.toLowerCase(), suffixStyle: const TextStyle(fontSize: 16, color: AppColors.grey300, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Container(height: 50, width: 1, color: const Color(0xFFF2F2F7), margin: const EdgeInsets.symmetric(horizontal: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DISPERSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _dispersion,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.grey300),
                      items: ['Left', 'Straight', 'Right'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.grey900)))).toList(),
                      onChanged: (v) => setState(() => _dispersion = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, color: Color(0xFFF2F2F7))),
          const Text('LOG SHOT QUALITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildQualityIOSButton('GREAT', AppColors.emerald500),
              const SizedBox(width: 10),
              _buildQualityIOSButton('GOOD', AppColors.birdie),
              const SizedBox(width: 10),
              _buildQualityIOSButton('OKAY', AppColors.bogey),
              const SizedBox(width: 10),
              _buildQualityIOSButton('MISS', AppColors.doubleBogey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityIOSButton(String label, Color color) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _logShot(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5)),
          child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ),
      ),
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E5EA)))),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              onPressed: _endSession,
              color: AppColors.grey900,
              padding: const EdgeInsets.symmetric(vertical: 18),
              borderRadius: BorderRadius.circular(20),
              child: const Text('Finish Grinding', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
