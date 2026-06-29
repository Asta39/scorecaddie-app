import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_card.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../../widgets/top_notification.dart';

class SessionDetailsScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailsScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends ConsumerState<SessionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(coachSessionsProvider);
    final occurrencesAsync = ref.watch(sessionOccurrencesProvider(widget.sessionId));
    final enrollmentsAsync = ref.watch(sessionEnrollmentsProvider(widget.sessionId));

    return sessionsAsync.when(
      data: (sessions) {
        final session = sessions.firstWhere((s) => s.id == widget.sessionId);
        return Scaffold(
          body: SafeArea(
            top: false, // SliverAppBar handles top
            child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _SliverHeader(session: session),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _SessionInfoCard(session: session),
                      const SizedBox(height: 32),
                      
                      // Live Attendance Section (if session is in progress)
                      occurrencesAsync.when(
                        data: (occurrences) {
                          final activeOrCompleted = occurrences.where((o) => o.status == 'in_progress' || o.status == 'completed').toList();
                          if (activeOrCompleted.isEmpty) return const SizedBox();
                          
                          // Prioritize the in_progress one, else take the most recent completed one
                          final occurrenceToShow = activeOrCompleted.any((o) => o.status == 'in_progress')
                              ? activeOrCompleted.firstWhere((o) => o.status == 'in_progress')
                              : activeOrCompleted.last;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: occurrenceToShow.status == 'in_progress' ? 'Live Attendance' : 'Attendance (Past Session)', 
                                count: enrollmentsAsync.valueOrNull?.length ?? 0
                              ),
                              const SizedBox(height: 12),
                              _AttendanceChecklist(
                                occurrence: occurrenceToShow,
                                enrollments: enrollmentsAsync.valueOrNull ?? [],
                              ),
                              const SizedBox(height: 32),
                            ],
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),

                      _SectionHeader(title: 'Player Roster', count: enrollmentsAsync.valueOrNull?.length ?? 0),
                      const SizedBox(height: 12),
                      enrollmentsAsync.when(
                        data: (enrollments) => _RosterList(enrollments: enrollments),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Upcoming Occurrences', count: occurrencesAsync.valueOrNull?.where((o) => o.status == 'upcoming').length ?? 0),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              occurrencesAsync.when(
                data: (occurrences) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _OccurrenceTile(occurrence: occurrences[index]),
                      childCount: occurrences.length,
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final CoachingSession session;
  const _SliverHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(session.name, 
          style: const TextStyle(
            color: AppColors.grey900, 
            fontWeight: FontWeight.w800, 
            fontSize: 20, 
            letterSpacing: -0.8,
          )),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.share2, color: AppColors.purple700, size: 20),
          onPressed: () {
            Share.share(
              'Join my golf session "${session.name}" at ${session.location}!\n'
              'Time: ${session.startTime.substring(0, 5)}\n'
              'Price: KSH ${session.pricePerSession}\n'
              'Download ScoreCaddie to book now!',
            );
          },
        ),
        if (session.status != 'cancelled')
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: AppColors.grey600, size: 20),
            onPressed: () {
              context.push('/coach/session/${session.id}/edit', extra: session);
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _AttendanceChecklist extends ConsumerStatefulWidget {
  final SessionOccurrence occurrence;
  final List<SessionEnrollment> enrollments;
  const _AttendanceChecklist({required this.occurrence, required this.enrollments});

  @override
  ConsumerState<_AttendanceChecklist> createState() => _AttendanceChecklistState();
}

class _AttendanceChecklistState extends ConsumerState<_AttendanceChecklist> {
  Set<String>? _presentIds;

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(sessionAttendanceProvider(widget.occurrence.id));

    return attendanceAsync.when(
      data: (attendance) {
        // Initialize once from DB
        _presentIds ??= attendance.where((a) => a.isPresent).map((a) => a.playerId).toSet();
        final presentIds = _presentIds!;

        if (widget.enrollments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('No students enrolled to take attendance.')),
          );
        }

        return Column(
          children: [
            ...widget.enrollments.map((e) => _AttendanceTile(
              enrollment: e,
              isPresent: presentIds.contains(e.playerId),
              onChanged: (val) {
                setState(() {
                  if (val) {
                    _presentIds!.add(e.playerId);
                  } else {
                    _presentIds!.remove(e.playerId);
                  }
                });
              },
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppColors.emerald700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(14),
                onPressed: () async {
                  final attendanceData = widget.enrollments.map((e) => {
                    'player_id': e.playerId,
                    'is_present': presentIds.contains(e.playerId),
                  }).toList();

                  try {
                    await ref.read(coachingServiceProvider).saveAttendance(
                      occurrenceId: widget.occurrence.id,
                      attendanceData: attendanceData,
                    );
                    
                    ref.invalidate(sessionAttendanceProvider(widget.occurrence.id));
                    
                    if (context.mounted) {
                      TopNotification.showSuccess(context, 'Attendance updated successfully');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      TopNotification.showError(context, 'Failed to save attendance: $e');
                    }
                  }
                },
                child: const Text('Save Attendance', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      )),
      error: (err, _) => Text('Error loading attendance: $err'),
    );
  }
}

class _AttendanceTile extends ConsumerWidget {
  final SessionEnrollment enrollment;
  final bool isPresent;
  final Function(bool) onChanged;
  const _AttendanceTile({required this.enrollment, required this.isPresent, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = enrollment.playerAvatar;
    final name = enrollment.playerName ?? 'Student';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.emerald50,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null 
              ? const Icon(LucideIcons.user, size: 14, color: AppColors.emerald700)
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Switch.adaptive(
            value: isPresent,
            activeTrackColor: AppColors.emerald700.withValues(alpha: 0.5),
            activeThumbColor: AppColors.emerald700,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SessionInfoCard extends StatelessWidget {
  final CoachingSession session;
  const _SessionInfoCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      tintColor: AppColors.emerald700,
      tintOpacity: 0.03,
      child: Column(
        children: [
          Row(
            children: [
              _InfoBox(icon: LucideIcons.calendar, label: 'Schedule', value: _getScheduleString(session)),
              const SizedBox(width: 12),
              _InfoBox(icon: LucideIcons.clock, label: 'Time', value: session.startTime.substring(0, 5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoBox(icon: LucideIcons.mapPin, label: 'Location', value: session.location),
              const SizedBox(width: 12),
              _InfoBox(icon: LucideIcons.timer, label: 'Duration', value: '${session.durationMinutes}m'),
            ],
          ),
          if (session.description != null && session.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.grey100),
            const SizedBox(height: 20),
            Text(session.description!, style: const TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _getScheduleString(CoachingSession s) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = s.daysOfWeek.map((d) => dayNames[d - 1]).join('/');
    return days;
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 10, color: AppColors.grey400),
                const SizedBox(width: 6),
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey900, letterSpacing: -0.3)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900, letterSpacing: -0.8)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.grey900.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey600)),
        ),
      ],
    );
  }
}

class _RosterList extends StatelessWidget {
  final List<SessionEnrollment> enrollments;
  const _RosterList({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.grey100, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Text('No students enrolled yet.', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Column(
      children: enrollments.map((e) => _RosterTile(enrollment: e)).toList(),
    );
  }
}

class _RosterTile extends ConsumerWidget {
  final SessionEnrollment enrollment;
  const _RosterTile({required this.enrollment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = enrollment.playerAvatar;
    final name = enrollment.playerName ?? 'Student';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.emerald50,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null 
              ? const Icon(LucideIcons.user, color: AppColors.emerald700, size: 16)
              : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, 
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
                Text('Enrolled ${DateFormat('MMM d').format(enrollment.enrolledAt)}', 
                  style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _PaymentStatusBadge(status: enrollment.paymentStatus),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'fully_paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isPaid ? AppColors.emerald500 : AppColors.eagle).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(isPaid ? 'PAID' : 'PENDING', 
        style: TextStyle(color: isPaid ? AppColors.emerald700 : AppColors.eagle, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}

class _OccurrenceTile extends ConsumerWidget {
  final SessionOccurrence occurrence;
  const _OccurrenceTile({required this.occurrence});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpcoming = occurrence.status == 'upcoming';
    final isInProgress = occurrence.status == 'in_progress';
    final isCompleted = occurrence.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInProgress ? AppColors.emerald50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isInProgress ? AppColors.emerald200 : AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('MMM').format(occurrence.date).toUpperCase(), 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400)),
                Text(DateFormat('d').format(occurrence.date), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE').format(occurrence.date), 
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
                Text('${occurrence.startTime?.substring(0, 5) ?? '--:--'} - ${occurrence.endTime?.substring(0, 5) ?? '--:--'}', 
                  style: const TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isUpcoming) 
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    final session = ref.read(coachSessionsProvider).valueOrNull?.firstWhere((s) => s.id == occurrence.sessionId);
                    if (session == null) return;

                    final startTimeParts = (occurrence.startTime ?? session.startTime).split(':');
                    final startDateTime = DateTime(
                      occurrence.date.year,
                      occurrence.date.month,
                      occurrence.date.day,
                      int.parse(startTimeParts[0]),
                      int.parse(startTimeParts[1]),
                    );
                    
                    final endDateTime = startDateTime.add(Duration(minutes: session.durationMinutes));

                    final Event event = Event(
                      title: 'Golf Session: ${session.name}',
                      description: 'Coaching session at ${session.location}',
                      location: session.location,
                      startDate: startDateTime,
                      endDate: endDateTime,
                    );
                    Add2Calendar.addEvent2Cal(event);
                  },
                  icon: const Icon(LucideIcons.calendarPlus, color: AppColors.grey400, size: 20),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () => _showStartDialog(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          if (isInProgress)
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: () => _showEndDialog(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('End', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          if (isCompleted)
            const Icon(LucideIcons.checkCircle2, color: AppColors.emerald500, size: 24),
        ],
      ),
    );
  }

  void _showStartDialog(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Start Session?'),
        content: const Text('This will notify all enrolled students that the session is beginning.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(coachingServiceProvider).updateOccurrenceStatus(occurrence.id, 'in_progress');
                ref.invalidate(sessionOccurrencesProvider(occurrence.sessionId));
                ref.invalidate(coachSessionsProvider);
              } catch (e) {
                if (context.mounted) {
                  TopNotification.showError(context, 'Failed to start session: $e');
                }
              }
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  void _showEndDialog(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('End Session?'),
        content: const Text('Have you finished the coaching for today? Attendance will be finalized.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(coachingServiceProvider).updateOccurrenceStatus(occurrence.id, 'completed');
                ref.invalidate(sessionOccurrencesProvider(occurrence.sessionId));
                ref.invalidate(coachSessionsProvider);
              } catch (e) {
                if (context.mounted) {
                  TopNotification.showError(context, 'Failed to end session: $e');
                }
              }
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}
