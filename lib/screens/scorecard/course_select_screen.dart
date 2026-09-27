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
                    ObTopBar('Start a round', onBack: () => context.pop()),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _search = v),
                            cursorColor: Ob.lime,
                            style: Ob.body(15, weight: FontWeight.w600),
                            decoration: InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Search courses', hintStyle: Ob.body(14, color: Ob.creamA(.4))),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _optionRow(
                      icon: LucideIcons.scanLine,
                      title: 'Scan a scorecard',
                      sub: 'Played already? Snap the card and we\'ll read it.',
                      hero: true,
                      onTap: _showScanScorecardWorkflow,
                    ),
                    const SizedBox(height: 10),
                    _optionRow(
                      icon: LucideIcons.users,
                      title: 'Group round',
                      sub: 'Everyone scores on their own phone',
                      trailing: Switch.adaptive(
                        value: isGroupRound,
                        activeTrackColor: Ob.lime,
                        activeThumbColor: Ob.ink,
                        onChanged: (val) => setState(() => isGroupRound = val),
                      ),
                      onTap: () => setState(() => isGroupRound = !isGroupRound),
                      on: isGroupRound,
                    ),
                    if (!isGroupRound) ...[
                      const SizedBox(height: 10),
                      _optionRow(
                        icon: LucideIcons.qrCode,
                        title: 'Join a friend\'s round',
                        sub: 'Scan their QR or type the code',
                        onTap: () async {
                          final status = await Permission.camera.request();
                          if (status.isGranted) {
                            _showJoinRoundDialog();
                          } else if (context.mounted) {
                            TopNotification.showError(context, 'Camera permission is required to scan QR codes');
                          }
                        },
                      ),
                    ],
                    if (isGroupRound) ...[
                      const SizedBox(height: 10),
                      Text('Pick the course and you\'ll get a lobby code to share.', style: Ob.body(13, color: Ob.creamA(.6))),
                    ],
                  ]),
                ),
                ..._buildCourseSections(ref),
              ],
            ),
          ),
          if (isLoading)
            Container(color: Colors.black.withValues(alpha: 0.5), child: const LoadingSpinner(size: 80)),
        ]),
      ),
    );
  }

  Widget _optionRow({required IconData icon, required String title, required String sub, required VoidCallback onTap, Widget? trailing, bool hero = false, bool on = false}) {
    final child = Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: hero ? Ob.ink.withValues(alpha: .12) : Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 20, color: hero ? Ob.ink : Ob.lime),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Ob.body(16, weight: FontWeight.w800, color: hero ? Ob.ink : Ob.cream)),
          Text(sub, style: Ob.body(12, color: hero ? Ob.ink.withValues(alpha: .7) : Ob.creamA(.6))),
        ]),
      ),
      trailing ?? Icon(LucideIcons.chevronRight, size: 18, color: hero ? Ob.ink : Ob.creamA(.4)),
    ]);
    if (hero) {
      return GestureDetector(
        onTap: onTap,
        child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Ob.lime, borderRadius: BorderRadius.circular(24)), child: child),
      );
    }
    return ObSelectTile(selected: on, onTap: onTap, padding: const EdgeInsets.all(16), child: child);
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
    final nearbyCoursesAsync = ref.watch(nearbyCoursesProvider);
    final recentCoursesAsync = ref.watch(recentlyPlayedCoursesProvider);

    return coursesAsync.when(
      data: (allCourses) {
        // If searching, just show filtered list
        if (_search.isNotEmpty) {
          final filtered = allCourses.where((c) {
            final query = _search.toLowerCase();
            return c.name.toLowerCase().contains(query) ||
                   c.location.toLowerCase().contains(query);
          }).toList();

          return [
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              _buildCourseListSliver(filtered, showAddCTA: true)
          ];
        }

        // Identify if there is a Current Course (within 500m)
        final List<dynamic> currentCourse = [];
        final List<dynamic> restNearby = [];
        
        nearbyCoursesAsync.whenData((nearby) {
          for (var item in nearby) {
            final double dist = item.distance;
            if (dist < 500 && currentCourse.isEmpty) {
              currentCourse.add(item);
            } else {
              restNearby.add(item);
            }
          }
        });

        return [
          // 1. CURRENT COURSE (If at course)
          if (currentCourse.isNotEmpty)
            SliverMainAxisGroup(
              slivers: [
                _buildSectionHeader('Current Course', LucideIcons.mapPin),
                _buildCourseListSliver(currentCourse),
              ],
            ),

          // 2. RECENTLY PLAYED
          recentCoursesAsync.when(
            data: (recent) {
              if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              final top3 = recent.take(3).toList();
              // Filter out current course if it exists in recent
              final filteredRecent = currentCourse.isEmpty 
                  ? top3 
                  : top3.where((r) => (r.id) != (currentCourse.first is CourseWithDistance ? (currentCourse.first as CourseWithDistance).course.id : (currentCourse.first as db.Course).id)).toList();
              
              if (filteredRecent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              
              return SliverMainAxisGroup(
                slivers: [
                  _buildSectionHeader('Recently Played', LucideIcons.history),
                  _buildCourseListSliver(filteredRecent),
                ],
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // 3. NEARBY COURSES
          if (restNearby.isNotEmpty)
            SliverMainAxisGroup(
              slivers: [
                _buildSectionHeader('Nearby Courses', LucideIcons.navigation),
                _buildCourseListSliver(restNearby.take(3).toList()),
              ],
            ),

          // 4. ALL COURSES
          SliverMainAxisGroup(
            slivers: [
              _buildSectionHeader('All Courses', LucideIcons.list),
              _buildCourseListSliver(allCourses, showAddCTA: true),
            ],
          ),
        ];
      },
      loading: () => [
        const SliverFillRemaining(
          child: LoadingSpinner(),
        )
      ],
      error: (e, _) => [
        SliverFillRemaining(
          child: Center(child: Text('Error loading courses: $e')),
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: ObEyebrow(title),
      ),
    );
  }

  Widget _buildCourseListSliver(List<dynamic> items, {bool showAddCTA = false}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            final db.Course course = item is CourseWithDistance ? item.course : item;
            final double? distance = item is CourseWithDistance ? item.distance : null;

            return Column(
              children: [
                _CourseCard(
                  course: course,
                  distance: distance,
                  onTap: () => _onCourseSelected(course),
                ),
                if (showAddCTA && index == items.length - 1) ...[
                  const SizedBox(height: 8),
                  _AddCustomCourseCTA(
                    onTap: () => context.push('/courses/add'),
                  ),
                  const SizedBox(height: 100),
                ],
              ],
            );
          },
          childCount: items.length,
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
  final double? distance;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap, this.distance});

  @override
  Widget build(BuildContext context) {
    final here = distance != null && distance! < 500;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: here ? Ob.roleFill : Ob.cardFill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: here ? Ob.lime : Colors.transparent, width: 1.5),
          ),
          child: Row(children: [
            ObCrest(course.name, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(course.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(16, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  distance != null ? '${(distance! / 1000).toStringAsFixed(1)} km · ${course.location}' : course.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ob.body(12, color: Ob.creamA(.55)),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            if (here) const ObChip('You\'re here', on: true) else ObChip('Par ${course.par18 ?? '?'}'),
          ]),
        ),
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

class _AddCustomCourseCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCustomCourseCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: Ob.lime.withValues(alpha: .4))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.plus, color: Ob.lime, size: 18),
          const SizedBox(width: 8),
          Text('Course not listed? Add it', style: Ob.body(14, weight: FontWeight.w800, color: Ob.lime)),
        ]),
      ),
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
