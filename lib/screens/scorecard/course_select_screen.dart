import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/cloud/group_sync_service.dart';

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
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                backgroundColor: AppColors.grey50,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 140.0,
                title: Text(
                  'Select Course', 
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Hero(
                      tag: 'search_bar',
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: 'Search for a course...',
                        placeholderStyle: TextStyle(color: AppColors.grey400, fontSize: 16),
                        backgroundColor: AppColors.white,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ),
                ),
              ),

              // Group Round Toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isGroupRound ? AppColors.emerald700.withOpacity(0.05) : Colors.white,
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
                              const Text('Group Round', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('Play with friends on multiple devices', style: TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isGroupRound,
                          activeColor: AppColors.emerald700,
                          onChanged: (val) => setState(() => isGroupRound = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Course List
              coursesAsync.when(
                data: (courses) {
                  final filtered = courses.where((c) {
                    final query = _search.toLowerCase();
                    return c.name.toLowerCase().contains(query) ||
                           c.location.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
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

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = filtered[index];
                          return Column(
                            children: [
                              _CourseCard(
                                course: course,
                                onTap: () => _onCourseSelected(course),
                              ),
                              if (index == filtered.length - 1) ...[
                                const SizedBox(height: 16),
                                _AddCustomCourseCTA(
                                  onTap: () => context.push('/courses/add'),
                                ),
                              ],
                            ],
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error loading courses: $e')),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
            ),
        ],
      ),
    );
  }

  void _onCourseSelected(dynamic course) async {
    if (isGroupRound) {
      setState(() => isLoading = true);
      try {
        final groupSync = ref.read(groupSyncServiceProvider);
        final roundCode = await groupSync.createGroupRound(
          courseId: course.id,
          courseName: course.name,
          scoringMode: 'INDIVIDUAL_DEVICES',
        );

        if (roundCode != null) {
          final query = await FirebaseFirestore.instance
              .collection('group_rounds')
              .where('roundCode', isEqualTo: roundCode)
              .limit(1)
              .get();
          
          if (query.docs.isNotEmpty && mounted) {
            context.pushReplacement('/round/lobby/${query.docs.first.id}');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      _CourseSetupModal.show(context, course);
    }
  }
}

class _CourseCard extends StatelessWidget {
  final dynamic course;
  final VoidCallback onTap;
  
  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: AppColors.grey100.withOpacity(0.5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.golf_course_rounded, color: AppColors.emerald700, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          Expanded(child: Text(course.location, style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
}

class _CourseSetupModal extends StatefulWidget {
  final dynamic course;
  const _CourseSetupModal({required this.course});

  static Future<void> show(BuildContext context, dynamic course) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseSetupModal(course: course),
    );
  }

  @override
  State<_CourseSetupModal> createState() => _CourseSetupModalState();
}

class _CourseSetupModalState extends State<_CourseSetupModal> {
  int _holesPlayed = 18;
  String _selectedTee = 'White';
  final List<String> _tees = ['Black', 'Blue', 'White', 'Red', 'Yellow'];

  void _startRound() {
    Navigator.pop(context);
    context.push('/scoring', extra: {
      'courseId': widget.course.id,
      'holesPlayed': _holesPlayed.abs(),
      'tee': _selectedTee,
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 24), width: 40, height: 5, decoration: BoxDecoration(color: Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.course.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1)),
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
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tees.length,
                      itemBuilder: (context, index) {
                        final tee = _tees[index];
                        final isSelected = _selectedTee == tee;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedTee = tee),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(color: isSelected ? AppColors.grey900 : AppColors.grey50, borderRadius: BorderRadius.circular(24)),
                              alignment: Alignment.center,
                              child: Text(tee, style: TextStyle(color: isSelected ? Colors.white : AppColors.grey700, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _startRound,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Start Round', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
