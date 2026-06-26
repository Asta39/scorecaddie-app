import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/course_logo_helper.dart';
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
  String _search = '';
  bool isLoading = false;
  bool isGroupRound = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, size: 28, color: AppColors.grey900),
                  onPressed: () => context.pop(),
                ),
                title: const Text(
                  'Select Course',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.grey900),
                ),
                centerTitle: false,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search for a course...',
                      placeholderStyle: const TextStyle(color: AppColors.grey400, fontSize: 15),
                      backgroundColor: AppColors.grey50,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                ),
              ),

              // Group Round Toggle & Join
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // Scan Scorecard CTA
                      InkWell(
                        onTap: () {
                          _showScanScorecardWorkflow();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.golfLime,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.golfLime.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.grey900.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.scanLine, color: AppColors.grey900, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scan Scorecard',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.grey900),
                                    ),
                                    Text(
                                      'AI-scan your physical card in seconds',
                                      style: TextStyle(color: AppColors.grey700, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, color: AppColors.grey700, size: 20),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isGroupRound ? AppColors.emerald700.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isGroupRound ? AppColors.emerald700 : AppColors.grey200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: isGroupRound ? AppColors.emerald700 : AppColors.grey50, shape: BoxShape.circle),
                              child: Icon(LucideIcons.users, color: isGroupRound ? Colors.white : AppColors.grey400, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Create Group Round', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                  Text('Play with friends on multiple devices', style: TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isGroupRound,
                              activeTrackColor: AppColors.emerald700.withValues(alpha: 0.5),
                              activeThumbColor: AppColors.emerald700,
                              onChanged: (val) => setState(() => isGroupRound = val),
                            ),
                          ],
                        ),
                      ),
                      if (!isGroupRound) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final status = await Permission.camera.request();
                            if (status.isGranted) {
                              _showJoinRoundDialog();
                            } else if (context.mounted) {
                              TopNotification.showError(context, 'Camera permission is required to scan QR codes');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.qrCode, color: AppColors.emerald700, size: 20),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Join Existing Round', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                      Text('Scan QR or enter round code', style: TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const Icon(LucideIcons.chevronRight, color: AppColors.grey300, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Course List Sections
              ..._buildCourseSections(ref),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const LoadingSpinner(size: 80),
            ),
        ],
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Join Group Round', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [Tab(text: 'Scan QR'), Tab(text: 'Enter Code')],
                      labelColor: AppColors.emerald700,
                      unselectedLabelColor: AppColors.grey400,
                      indicatorColor: AppColors.emerald700,
                      labelStyle: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildQrScanner(),
                          _buildCodeInput(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.grey400),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: AppColors.grey500,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
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
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPinOff, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text('No courses found', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.grey600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildQrScanner() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.emerald700, width: 2)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null) {
                    final roundCode = code.contains('/') ? code.split('/').last : code;
                    _handleJoin(roundCode);
                    break;
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Align the QR code within the frame', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCodeInput() {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey100)),
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(border: InputBorder.none, hintText: '000000', hintStyle: TextStyle(color: AppColors.grey200)),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => _handleJoin(controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Join Round', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
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
      final courseName = 'the group round';

      if (mounted) {
        setState(() => isLoading = false);
        final confirmed = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Join Round?'),
            content: Text('Do you want to join $courseName?'),
            actions: [
              CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
              CupertinoDialogAction(isDefaultAction: true, child: const Text('Join'), onPressed: () => Navigator.pop(context, true)),
            ],
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
    // If within 500m, consider user "at" the course
    final bool isAtCourse = distance != null && distance! < 500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: AppColors.grey100.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isAtCourse ? AppColors.emerald700 : AppColors.grey200,
                width: isAtCourse ? 2 : 1,
              ),
              boxShadow: isAtCourse ? [
                BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Row(
              children: [
                _buildCourseAvatar(course.name, isAtCourse),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.name, 
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAtCourse)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(color: AppColors.emerald700, borderRadius: BorderRadius.circular(6)),
                              child: const Text('YOU ARE HERE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              distance != null 
                                ? '${(distance! / 1000).toStringAsFixed(1)}km · ${course.location}'
                                : course.location, 
                              style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 13), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10)),
                  child: Text('Par ${course.par18 ?? "?"}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseAvatar(String courseName, bool isAtCourse) {
    final logoPath = CourseLogoHelper.getLogoAssetPath(courseName);

    if (logoPath != null) {
      // Show the course logo
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAtCourse ? AppColors.emerald700 : AppColors.grey200,
            width: isAtCourse ? 2 : 1,
          ),
          boxShadow: isAtCourse
              ? [BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.2), blurRadius: 8)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            logoPath,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackIcon(isAtCourse),
          ),
        ),
      );
    }

    // Fallback: generic golf icon
    return _fallbackIcon(isAtCourse);
  }

  Widget _fallbackIcon(bool isAtCourse) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isAtCourse ? AppColors.emerald700 : AppColors.emerald50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.golf_course_rounded,
        color: isAtCourse ? Colors.white : AppColors.emerald700,
        size: 26,
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 24), width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.course.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1)),
                  if (widget.isGroup)
                    const Text('GROUP ROUND SETUP', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 32),
                  const Text('Holes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _SegmentButton(label: '18 Holes', isSelected: _holesPlayed == 18, onTap: () => setState(() => _holesPlayed = 18))),
                      const SizedBox(width: 12),
                      Expanded(child: _SegmentButton(label: 'Front 9', isSelected: _holesPlayed == 9, onTap: () => setState(() => _holesPlayed = 9))),
                      const SizedBox(width: 12),
                      Expanded(child: _SegmentButton(label: 'Back 9', isSelected: _holesPlayed == -9, onTap: () => setState(() => _holesPlayed = -9))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Tee Box', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: teesAsync.when(
                      data: (tees) {
                        if (tees.isEmpty) return const Text('No tees available for this course.', style: TextStyle(color: AppColors.grey400));
                        if (_selectedTeeId == null && tees.isNotEmpty) {
                          Future.microtask(() => setState(() => _selectedTeeId = tees.first.id));
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tees.length,
                          itemBuilder: (context, index) {
                            final tee = tees[index];
                            final isSelected = _selectedTeeId == tee.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _selectedTeeId = tee.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.grey900 : AppColors.grey50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? AppColors.grey900 : AppColors.grey200),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(tee.name, style: TextStyle(color: isSelected ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w800, fontSize: 13)),
                                      Text('Rating: ${tee.courseRating}', style: TextStyle(color: isSelected ? Colors.white70 : AppColors.grey500, fontSize: 10, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const LoadingSpinner(size: 40),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isCreating ? null : _startRound,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _isCreating 
                        ? const LoadingSpinner(size: 32)
                        : Text(widget.isGroup ? 'Create Group Lobby' : 'Start Round', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SegmentButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: isSelected ? AppColors.grey900 : AppColors.grey50, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.grey600, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _AddCustomCourseCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCustomCourseCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.emerald200)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plusCircle, color: AppColors.emerald700, size: 20),
            SizedBox(width: 8),
            Text("Add Custom Course", style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w800)),
          ],
        ),
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

  Widget _buildCourseLogo(String courseName) {
    final logoPath = CourseLogoHelper.getLogoAssetPath(courseName);
    if (logoPath != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            logoPath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackLogo(),
          ),
        ),
      );
    }
    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.golf_course_rounded,
        color: AppColors.emerald700,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Course for Scan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900),
          ),
          const SizedBox(height: 16),
          CupertinoSearchTextField(
            controller: _sheetSearchController,
            placeholder: 'Search courses...',
            onChanged: (v) => setState(() => _sheetSearch = v),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: coursesAsync.when(
              data: (coursesList) {
                final filtered = coursesList.where((c) {
                  final q = _sheetSearch.toLowerCase();
                  return c.name.toLowerCase().contains(q) ||
                      c.location.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No courses found.'));
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: filtered.length,
                  itemExtent: 80.0,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        onTap: () => widget.onCourseSelected(course),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.grey100),
                        ),
                        tileColor: AppColors.grey25,
                        leading: _buildCourseLogo(course.name),
                        title: Text(
                          course.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        subtitle: Text(
                          course.location,
                          style: const TextStyle(color: AppColors.grey500, fontSize: 13),
                        ),
                        trailing: const Icon(LucideIcons.chevronRight, color: AppColors.grey300, size: 18),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.emerald700,
              onPrimary: Colors.white,
              onSurface: AppColors.grey900,
            ),
          ),
          child: child!,
        );
      },
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
      return Container(
        height: 350,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scanner Setup',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900),
            ),
            const SizedBox(height: 4),
            Text(
              widget.course.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
            const SizedBox(height: 24),

            // Player Name input
            const Text('PLAYER NAME ON SCORECARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              onChanged: (v) => ref.read(scorecardScannerProvider.notifier).setPlayerName(v),
              decoration: InputDecoration(
                hintText: 'Enter name (exactly as written on scorecard)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Date picker field
            const Text('ROUND DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: AppColors.grey400, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900),
                    ),
                    const Spacer(),
                    const Icon(LucideIcons.chevronDown, color: AppColors.grey400, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tee selection
            const Text('SELECT PLAYING TEE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _tees.isEmpty
                ? const Text('No tees found. Add tees to this course to calculate WHS handicap.')
                : SizedBox(
                    height: 84,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tees.length,
                      itemBuilder: (context, i) {
                        final t = _tees[i];
                        final isSelected = _selectedTee?.id == t.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedTee = t);
                              ref.read(scorecardScannerProvider.notifier).setTee(t);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.grey900 : AppColors.grey50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? AppColors.grey900 : AppColors.grey200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.grey800,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Slope: ${t.slopeRating}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.75) : AppColors.grey500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 32),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: _selectedTee == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onProceed();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('PROCEED TO CAMERA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton(
                onPressed: _selectedTee == null
                    ? null
                    : () async {
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
                            if (mounted) {
                              Navigator.pop(context); // Close setup bottom sheet
                              context.push('/scanner/camera'); // Go directly to camera screen (shows preview & confirm button)
                            }
                          }
                        } catch (e) {
                          debugPrint('Error picking image: $e');
                        }
                      },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.grey300, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('UPLOAD FROM GALLERY', style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
