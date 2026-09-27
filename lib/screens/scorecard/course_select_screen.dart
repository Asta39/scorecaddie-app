import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../core/cloud/group_sync_service.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/loading_spinner.dart';
import '../../providers/scorecard_scanner_provider.dart';
import 'package:intl/intl.dart';

class CourseSelectScreen extends ConsumerStatefulWidget {
  const CourseSelectScreen({super.key});
  @override
  ConsumerState<CourseSelectScreen> createState() => _CourseSelectScreenState();
}

class _CourseSelectScreenState extends ConsumerState<CourseSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String _search = '';
  bool isLoading = false;
  bool isGroupRound = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRound() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _showJoinRoundDialog();
    } else if (mounted) {
      TopNotification.showError(context, 'Camera permission is required to scan QR codes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: Stack(children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverList.list(children: [
                    ObTopBar('Where are you playing?', onBack: () => context.pop()),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      cursorColor: Ob.lime,
                      style: Ob.body(15, weight: FontWeight.w600),
                      decoration: obInput(null, hint: 'Search Kenyan courses', prefix: Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5))).copyWith(
                        fillColor: Ob.creamA(.05),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Ob.creamA(.14), width: 2)),
                      ),
                    ).rise(),
                    const SizedBox(height: 14),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _quick(LucideIcons.scanLine, 'Scan a card', 'Photo to scores in seconds', false, _showScanScorecardWorkflow)),
                      const SizedBox(width: 10),
                      Expanded(child: _quick(LucideIcons.users, 'Group round', isGroupRound ? 'On · pick a course' : 'Score together, live', isGroupRound, () => setState(() => isGroupRound = !isGroupRound))),
                      const SizedBox(width: 10),
                      Expanded(child: _quick(LucideIcons.qrCode, 'Join a round', 'Scan or enter a code', false, _joinRound)),
                    ]).rise(1),
                  ]),
                ),
                ..._buildCourseSections(ref),
              ],
            ),
          ),
          if (isLoading) Container(color: Colors.black.withValues(alpha: 0.5), child: const LoadingSpinner(size: 80)),
        ]),
      ),
    );
  }

  Widget _quick(IconData icon, String title, String sub, bool on, VoidCallback onTap) {
    return ObSelectTile(
      selected: on,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: SizedBox(
        height: 104,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: on ? Ob.lime : Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: on ? Ob.ink : Ob.lime),
          ),
          const Spacer(),
          Text(title, style: Ob.body(14, weight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(11, height: 1.35, color: Ob.creamA(.55))),
        ]),
      ),
    );
  }

  void _onCourseSelected(dynamic course) async {
    if (isGroupRound) {
      _CourseSetupModal.show(context, course, isGroup: true);
    } else {
      context.push('/scorecard/intel/${course.id}');
    }
  }

  void _showJoinRoundDialog() {
    showObSheet(
      context,
      (sheetContext) => ObSheet(
        title: 'Join a round',
        subtitle: 'Scan the QR on your friend\'s phone, or type the code.',
        height: MediaQuery.of(context).size.height * .8,
        child: DefaultTabController(
          length: 2,
          child: Column(children: [
            TabBar(
              tabs: const [Tab(text: 'Scan QR'), Tab(text: 'Type code')],
              labelColor: Ob.ink,
              unselectedLabelColor: Ob.creamA(.6),
              labelStyle: Ob.body(14, weight: FontWeight.w800),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(color: Ob.lime, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 8),
            Expanded(child: TabBarView(children: [_buildQrScanner(), _buildCodeInput()])),
          ]),
        ),
      ),
    );
  }

  void _showScanScorecardWorkflow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ScanCoursePickerSheet(
        onCourseSelected: (course) {
          // Update scanning provider course
          ref.read(scorecardScannerProvider.notifier).reset();
          ref.read(scorecardScannerProvider.notifier).setCourse(course);
          Navigator.pop(sheetContext); // Close Course Picker sheet

          // Show Setup sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (setupContext) => _ScanSetupSheet(
              course: course,
              onProceed: () {
                // Open camera screen
                context.push('/scanner/camera');
              },
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCourseSections(WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final nearby = ref.watch(nearbyCoursesProvider).valueOrNull ?? const <CourseWithDistance>[];
    final recent = ref.watch(recentlyPlayedCoursesProvider).valueOrNull ?? const [];
    final homeId = ref.watch(userProfileProvider).valueOrNull?.homeCourseId;

    return coursesAsync.when(
      loading: () => [const SliverFillRemaining(child: LoadingSpinner())],
      error: (e, _) => [SliverFillRemaining(child: Center(child: Text('Couldn\'t load courses.', style: Ob.body(14, color: Ob.creamA(.7)))))],
      data: (all) {
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          final hits = all.where((c) => c.name.toLowerCase().contains(q) || c.location.toLowerCase().contains(q)).toList();
          return [
            if (hits.isEmpty) _buildEmptyState() else ...[_buildSectionHeader('${hits.length} ${hits.length == 1 ? 'course' : 'courses'}', LucideIcons.search), _list([for (final c in hits) (c, null)])],
          ];
        }
        final here = nearby.where((n) => n.distance < 500).firstOrNull;
        final km = {for (final n in nearby) n.course.id: n.distance};
        final recentIds = [for (final r in recent.take(3)) (r as dynamic).id as int].where((id) => id != here?.course.id).toList();
        final recents = [for (final id in recentIds) all.where((c) => c.id == id).firstOrNull].whereType<db.Course>().toList();
        final near = nearby.where((n) => n != here && !recentIds.contains(n.course.id)).take(5).map((n) => n.course).toList();
        final rest = all.where((c) => c.id != here?.course.id && !recentIds.contains(c.id) && !near.any((n) => n.id == c.id)).toList();

        return [
          if (here != null)
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), sliver: SliverToBoxAdapter(child: _hereCard(here.course, homeId == here.course.id).rise(2))),
          if (recents.isNotEmpty) ...[_buildSectionHeader('Played lately', LucideIcons.history), _list([for (final c in recents) (c, km[c.id])])],
          if (near.isNotEmpty) ...[_buildSectionHeader('Nearby courses', LucideIcons.navigation), _list([for (final c in near) (c, km[c.id])])],
          _buildSectionHeader(here == null && recents.isEmpty && near.isEmpty ? 'All courses' : 'Everywhere else', LucideIcons.list),
          _list([for (final c in rest) (c, km[c.id])]),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 60),
              child: Center(
                child: TextButton(
                  onPressed: () => context.push('/courses/add'),
                  child: Text('Can\'t find your course? Add it', style: Ob.body(14, weight: FontWeight.w700, color: Ob.lime)),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _hereCard(db.Course c, bool home) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(28), border: Border.all(color: Ob.lime.withValues(alpha: .22))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Ob.lime, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('YOU\'RE HERE', style: Ob.eyebrow()),
          const Spacer(),
          Text('GPS', style: Ob.body(12, color: Ob.creamA(.6))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          ObCrest(c.name, size: 64, radius: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: Ob.display(24, height: 1.05)),
              const SizedBox(height: 3),
              Text(['Par ${c.par18 ?? '—'}', if (home) 'your home club'].join(' · '), style: Ob.body(13, color: Ob.creamA(.62))),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            flex: 7,
            child: ObButton(
              onPressed: () => _onCourseSelected(c),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.flag, size: 18, color: Ob.ink),
                const SizedBox(width: 8),
                Text('Play here', style: Ob.label(16, weight: FontWeight.w800)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: ObButton(tone: ObButtonTone.dark, onPressed: () => context.push('/scorecard/intel/${c.id}'), child: Text('Course info', style: Ob.label(15, weight: FontWeight.w800))),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 10), child: ObEyebrow(title)));
  }

  Widget _list(List<(db.Course, double?)> rows) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: ObCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            for (final (i, (c, d)) in rows.indexed) ...[
              if (i > 0) const ObHair(),
              InkWell(
                onTap: () => _onCourseSelected(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    ObCrest(c.name, size: 44, radius: 13),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700)),
                        Text('${c.location} · Par ${c.par18 ?? '—'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.55))),
                      ]),
                    ),
                    if (d != null) Text(d < 1000 ? '${d.round()} m' : '${(d / 1000).toStringAsFixed(d < 10000 ? 1 : 0)} km', style: Ob.body(13, weight: FontWeight.w800, color: Ob.creamA(.72))),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverToBoxAdapter(
        child: ObCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No course called "$_search".', style: Ob.body(15, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            ObButton(
              onPressed: () => context.push('/courses/add'),
              child: Text('Add it yourself', style: Ob.label(15, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildQrScanner() {
    return Column(children: [
      const SizedBox(height: 24),
      Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: Ob.lime, width: 3)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  _handleJoin(code.contains('/') ? code.split('/').last : code);
                  break;
                }
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text('Line the QR up inside the frame', style: Ob.body(14, color: Ob.creamA(.6))),
    ]);
  }

  Widget _buildCodeInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(children: [
        TextField(
          controller: _codeController,
          cursorColor: Ob.lime,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: Ob.display(34, color: Ob.cream).copyWith(letterSpacing: 6),
          decoration: obInput(null, hint: 'ABC123'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ObButton(
            onPressed: () => _handleJoin(_codeController.text.trim()),
            child: Text('Join round', style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  void _handleJoin(String code) async {
    setState(() => isLoading = true);
    
    try {
      final query = await Supabase.instance.client
          .from('GroupRound')
          .select('id, courseId')
          .eq('roundCode', code.toUpperCase())
          .eq('status', 'PENDING')
          .limit(1);

      if (query.isEmpty) {
        if (mounted) {
          TopNotification.showError(context, 'Invalid round code or round already started.');
        }
        setState(() => isLoading = false);
        return;
      }

      final roundId = query.first['id'];
      // Just a generic name since we don't store courseName right now

      if (mounted) {
        setState(() => isLoading = false);
        final confirmed = await showObSheet<bool>(
          context,
          (ctx) => ObSheet(
            title: 'Join this round?',
            subtitle: 'You\'ll wait in the lobby until the host starts.',
            child: Row(children: [
              Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: Ob.label(15, weight: FontWeight.w800)))),
              const SizedBox(width: 10),
              Expanded(child: ObButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Join', style: Ob.label(15, weight: FontWeight.w800)))),
            ]),
          ),
        );

        if (confirmed == true) {
          setState(() => isLoading = true);
          final groupSync = ref.read(groupSyncServiceProvider);
          final success = await groupSync.joinGroupRound(code);
          
          if (success && mounted) {
            context.pushReplacement('/round/lobby/$roundId');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Error joining: $e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

class _CourseCard extends StatelessWidget {
  final db.Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ObCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          ObCrest(course.name, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(16, weight: FontWeight.w800)),
              Text(course.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          ObChip('Par ${course.par18 ?? '?'}'),
        ]),
      ),
    );
  }
}

class _CourseSetupModal extends ConsumerStatefulWidget {
  final dynamic course;
  final bool isGroup;
  const _CourseSetupModal({required this.course, this.isGroup = false});

  static Future<void> show(BuildContext context, dynamic course, {bool isGroup = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseSetupModal(course: course, isGroup: isGroup),
    );
  }

  @override
  ConsumerState<_CourseSetupModal> createState() => _CourseSetupModalState();
}

class _CourseSetupModalState extends ConsumerState<_CourseSetupModal> {
  int _holesPlayed = 18;
  int? _selectedTeeId;
  bool _isCreating = false;

  void _startRound() async {
    if (_selectedTeeId == null) {
      TopNotification.showError(context, 'Please select a tee box');
      return;
    }

    final profile = ref.read(userProfileProvider).valueOrNull;
    final hIndex = profile?.handicap;

    if (widget.isGroup) {
      setState(() => _isCreating = true);
      try {
        final groupSync = ref.read(groupSyncServiceProvider);
        final roundCode = await groupSync.createGroupRound(
          courseId: widget.course.id,
          courseName: widget.course.name,
          coursePar: widget.course.par18 ?? 72,
          scoringMode: 'INDIVIDUAL_DEVICES',
          holesPlayed: _holesPlayed.abs(),
          teeId: _selectedTeeId!,
          handicapBefore: hIndex,
        );

        if (roundCode != null) {
          final query = await Supabase.instance.client
              .from('GroupRound')
              .select('id')
              .eq('roundCode', roundCode)
              .limit(1);
          
          if (query.isNotEmpty && mounted) {
            Navigator.pop(context);
            context.pushReplacement('/round/lobby/${query.first['id']}');
          }
        }
      } catch (e) {
        if (mounted) {
          TopNotification.showError(context, 'Error: $e');
        }
      } finally {
        if (mounted) setState(() => _isCreating = false);
      }
    } else {
      Navigator.pop(context);
      context.push('/scoring', extra: {
        'courseId': widget.course.id,
        'holesPlayed': _holesPlayed.abs(),
        'teeId': _selectedTeeId,
        'courseHandicap': 0, // Calculated in scoring screen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final teesAsync = ref.watch(courseTeesProvider(widget.course.id));

    return ObSheet(
      title: widget.course.name,
      subtitle: widget.isGroup ? 'Group round · everyone joins from the lobby' : 'How are you playing today?',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const ObEyebrow('Holes'),
        const SizedBox(height: 10),
        ObGooSegmented<int>(
          options: const [(18, '18 holes'), (9, 'Front 9'), (-9, 'Back 9')],
          selected: _holesPlayed,
          onChanged: (v) => setState(() => _holesPlayed = v),
        ),
        const SizedBox(height: 20),
        const ObEyebrow('Tee'),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: teesAsync.when(
            data: (tees) {
              if (tees.isEmpty) return Text('No tees set up for this course yet.', style: Ob.body(14, color: Ob.creamA(.6)));
              if (_selectedTeeId == null) Future.microtask(() => setState(() => _selectedTeeId = tees.first.id));
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tees.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final tee = tees[i];
                  return ObSelectTile(
                    selected: _selectedTeeId == tee.id,
                    onTap: () => setState(() => _selectedTeeId = tee.id),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tee.name, style: Ob.body(14, weight: FontWeight.w800)),
                      Text('${tee.courseRating} / ${tee.slopeRating}', style: Ob.body(11, color: Ob.creamA(.55))),
                    ]),
                  );
                },
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
            error: (e, _) => Text('Couldn\'t load tees: $e', style: Ob.body(13, color: Ob.warn)),
          ),
        ),
        const SizedBox(height: 24),
        ObButton(
          onPressed: _isCreating ? null : _startRound,
          child: Text(_isCreating ? 'Setting up…' : (widget.isGroup ? 'Open the lobby' : 'Tee off'), style: Ob.label(17, weight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _ScanCoursePickerSheet extends ConsumerStatefulWidget {
  final Function(db.Course) onCourseSelected;
  const _ScanCoursePickerSheet({required this.onCourseSelected});

  @override
  ConsumerState<_ScanCoursePickerSheet> createState() => _ScanCoursePickerSheetState();
}

class _ScanCoursePickerSheetState extends ConsumerState<_ScanCoursePickerSheet> {
  String _sheetSearch = '';
  final _sheetSearchController = TextEditingController();

  @override
  void dispose() {
    _sheetSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    return ObSheet(
      title: 'Which course?',
      subtitle: 'The one printed on the card.',
      height: MediaQuery.of(context).size.height * .85,
      child: Column(children: [
        TextField(
          controller: _sheetSearchController,
          onChanged: (v) => setState(() => _sheetSearch = v),
          cursorColor: Ob.lime,
          style: Ob.body(15, weight: FontWeight.w600),
          decoration: obInput(null, hint: 'Search courses', prefix: Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5))),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: coursesAsync.when(
            data: (list) {
              final q = _sheetSearch.toLowerCase();
              final filtered = list.where((c) => c.name.toLowerCase().contains(q) || c.location.toLowerCase().contains(q)).toList();
              if (filtered.isEmpty) return Center(child: Text('No courses found.', style: Ob.body(14, color: Ob.creamA(.6))));
              return ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _CourseCard(course: filtered[i], onTap: () => widget.onCourseSelected(filtered[i])),
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
            error: (e, _) => Center(child: Text('Couldn\'t load courses: $e', style: Ob.body(13, color: Ob.warn))),
          ),
        ),
      ]),
    );
  }
}

class _ScanSetupSheet extends ConsumerStatefulWidget {
  final db.Course course;
  final VoidCallback onProceed;
  const _ScanSetupSheet({required this.course, required this.onProceed});

  @override
  ConsumerState<_ScanSetupSheet> createState() => _ScanSetupSheetState();
}

class _ScanSetupSheetState extends ConsumerState<_ScanSetupSheet> {
  final _nameController = TextEditingController();
  List<db.Tee> _tees = [];
  db.Tee? _selectedTee;
  DateTime _selectedDate = DateTime.now();
  bool _loadingTees = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      _nameController.text = profile.name;
      ref.read(scorecardScannerProvider.notifier).setPlayerName(profile.name);
    }
    
    ref.read(scorecardScannerProvider.notifier).setDate(_selectedDate);

    try {
      final dbInstance = ref.read(databaseProvider);
      final tees = await dbInstance.getTeesForCourse(widget.course.id);
      setState(() {
        _tees = tees;
        if (tees.isNotEmpty) {
          _selectedTee = tees.first;
          ref.read(scorecardScannerProvider.notifier).setTee(tees.first);
        }
        _loadingTees = false;
      });
    } catch (e) {
      debugPrint('Error fetching tees: $e');
      setState(() => _loadingTees = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: obPickerTheme,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      ref.read(scorecardScannerProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTees) {
      return const ObSheet(child: SizedBox(height: 240, child: Center(child: CupertinoActivityIndicator(color: Ob.lime))));
    }
    return ObSheet(
      title: 'Before we scan',
      subtitle: widget.course.name,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller: _nameController,
          onChanged: (v) => ref.read(scorecardScannerProvider.notifier).setPlayerName(v),
          cursorColor: Ob.lime,
          style: Ob.body(15, weight: FontWeight.w700),
          decoration: obInput('Your name as written on the card'),
        ),
        const SizedBox(height: 12),
        ObSelectTile(
          selected: false,
          onTap: _selectDate,
          child: Row(children: [
            const Icon(LucideIcons.calendar, color: Ob.lime, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Played on', style: Ob.body(11, color: Ob.creamA(.55))),
                Text(DateFormat('EEE d MMMM yyyy').format(_selectedDate), style: Ob.body(15, weight: FontWeight.w800)),
              ]),
            ),
            Icon(LucideIcons.chevronDown, size: 18, color: Ob.creamA(.5)),
          ]),
        ),
        const SizedBox(height: 18),
        const ObEyebrow('Tee you played'),
        const SizedBox(height: 10),
        if (_tees.isEmpty)
          Text('This course has no tees yet, so we can\'t work out a handicap from it.', style: Ob.body(13, color: Ob.creamA(.6)))
        else
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tees.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _tees[i];
                return ObSelectTile(
                  selected: _selectedTee?.id == t.id,
                  onTap: () {
                    setState(() => _selectedTee = t);
                    ref.read(scorecardScannerProvider.notifier).setTee(t);
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: Ob.body(14, weight: FontWeight.w800)),
                    Text('Slope ${t.slopeRating}', style: Ob.body(11, color: Ob.creamA(.55))),
                  ]),
                );
              },
            ),
          ),
        const SizedBox(height: 22),
        ObButton(
          onPressed: _selectedTee == null
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onProceed();
                },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.camera, size: 18, color: Ob.ink),
            const SizedBox(width: 8),
            Text('Open the camera', style: Ob.label(16, weight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 10),
        ObButton(
          tone: ObButtonTone.dark,
          onPressed: _selectedTee == null ? null : () async {
                        final ImagePicker picker = ImagePicker();
                        try {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                            maxWidth: 1600,
                            maxHeight: 1600,
                          );
                          if (image != null) {
                            final file = File(image.path);
                            final bytes = await file.readAsBytes();
                            ref.read(scorecardScannerProvider.notifier).setImage(bytes, image.path);
                            if (context.mounted) {
                              Navigator.pop(context); // Close setup bottom sheet
                              context.push('/scanner/camera'); // Go directly to camera screen (shows preview & confirm button)
                            }
                          }
                        } catch (e) {
                          debugPrint('Error picking image: $e');
                        }
                      },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.image, size: 18, color: Ob.cream),
            const SizedBox(width: 8),
            Text('Pick a photo instead', style: Ob.label(16, weight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}
