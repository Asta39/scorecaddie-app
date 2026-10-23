import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_forms.dart';

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
    final session = sessionsAsync.valueOrNull?.where((s) => s.id == widget.sessionId).firstOrNull;
    final occurrences = ref.watch(sessionOccurrencesProvider(widget.sessionId)).valueOrNull ?? const <SessionOccurrence>[];
    final enrollAsync = ref.watch(sessionEnrollmentsProvider(widget.sessionId));
    final enrollments = enrollAsync.valueOrNull ?? const <SessionEnrollment>[];

    final live = occurrences.where((o) => o.status == 'in_progress').firstOrNull;
    final done = occurrences.where((o) => o.status == 'completed').toList();
    final attendFor = live ?? done.lastOrNull;
    final upcoming = occurrences.where((o) => o.status == 'upcoming').toList();

    final owe = enrollments.where((e) => e.paymentStatus != 'fully_paid').length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: SafeArea(
            bottom: false,
            child: session == null
                ? _missing(sessionsAsync.isLoading)
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                    children: [
                      ObTopBar('Sessions', onBack: () => context.pop(), actions: [
                        ObIconButton(icon: LucideIcons.share, label: 'Share session', onPressed: () => _share(session)),
                        if (session.status != 'cancelled') ...[
                          const SizedBox(width: 8),
                          ObIconButton(
                            icon: LucideIcons.pencil,
                            label: 'Edit session',
                            onPressed: () => context.push('/coach/session/${session.id}/edit', extra: session),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 10),
                      Text(session.name, style: Ob.display(28, height: 1.15)),
                      Text(_when(session, live), style: Ob.body(15, color: Ob.creamA(.6))),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          _stat('${enrollments.length}/${session.maxPlayers}', 'Booked'),
                          _stat('${enrollments.length - owe}', 'Paid'),
                          _stat('$owe', 'Owe', color: owe > 0 ? Ob.warn : null),
                        ]),
                      ),
                      if (session.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 22),
                        ObGroup(header: 'About', children: [ObRow(session.description!)]),
                      ],
                      if (attendFor != null) ...[
                        const SizedBox(height: 22),
                        _AttendanceChecklist(key: ValueKey(attendFor.id), occurrence: attendFor, enrollments: enrollments, live: live != null),
                      ],
                      const SizedBox(height: 22),
                      if (enrollAsync.isLoading && enrollments.isEmpty)
                        const Center(child: CupertinoActivityIndicator(color: Ob.lime))
                      else
                        ObGroup(
                          header: 'Players · ${enrollments.length}',
                          children: enrollments.isEmpty
                              ? [const ObRow('Nobody has booked yet', subtitle: 'Share the session to fill it')]
                              : [for (final e in enrollments) _RosterRow(enrollment: e)],
                        ),
                      const SizedBox(height: 22),
                      ObGroup(
                        header: 'Dates · ${upcoming.length} to go',
                        children: [for (final o in occurrences) _OccurrenceTile(occurrence: o, session: session)],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String v, String label, {Color? color}) => Expanded(
        child: Column(children: [
          Text(v, style: Ob.display(20, color: color ?? Ob.cream)),
          Text(label, style: Ob.body(12, color: Ob.creamA(.6))),
        ]),
      );

  String _when(CoachingSession s, SessionOccurrence? live) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final when = s.daysOfWeek.where((d) => d >= 1 && d <= 7).map((d) => days[d - 1]).join(', ');
    final time = s.startTime.length >= 5 ? s.startTime.substring(0, 5) : s.startTime;
    return [
      live != null ? 'On now' : when,
      '$time · ${s.durationMinutes} min',
      if (s.location.isNotEmpty) s.location,
      'KES ${NumberFormat('#,###').format(s.pricePerSession)} · ${s.weeks} weeks',
    ].join(' · ');
  }

  Widget _missing(bool loading) {
    if (loading) return const Center(child: CupertinoActivityIndicator(color: Ob.lime));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ObTopBar('Sessions', onBack: () => context.pop()),
        const SizedBox(height: 24),
        Text('This session isn’t available any more.', style: Ob.display(22)),
      ]),
    );
  }

  void _share(CoachingSession s) {
    Share.share(
      'Join my golf session "${s.name}" at ${s.location}!\n'
      'Time: ${s.startTime.length >= 5 ? s.startTime.substring(0, 5) : s.startTime}\n'
      'Price: KES ${s.pricePerSession.toStringAsFixed(0)}\n'
      'Download ScoreCaddie to book now!',
    );
  }
}

class _AttendanceChecklist extends ConsumerStatefulWidget {
  final SessionOccurrence occurrence;
  final List<SessionEnrollment> enrollments;
  const _AttendanceChecklist({super.key, required this.occurrence, required this.enrollments, required this.live});
  final bool live;

  @override
  ConsumerState<_AttendanceChecklist> createState() => _AttendanceChecklistState();
}

class _AttendanceChecklistState extends ConsumerState<_AttendanceChecklist> {
  Set<String>? _present;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(coachingServiceProvider).saveAttendance(
            occurrenceId: widget.occurrence.id,
            attendanceData: [
              for (final e in widget.enrollments) {'player_id': e.playerId, 'is_present': _present!.contains(e.playerId)},
            ],
          );
      ref.invalidate(sessionAttendanceProvider(widget.occurrence.id));
      if (mounted) TopNotification.showSuccess(context, 'Attendance saved');
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t save attendance: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sessionAttendanceProvider(widget.occurrence.id));
    final header = widget.live ? 'Who’s here' : 'Last session’s roll';
    if (async.isLoading && _present == null) return const Center(child: CupertinoActivityIndicator(color: Ob.lime));
    if (async.hasError && _present == null) {
      return ObGroup(header: header, children: const [ObRow('Couldn’t load attendance')]);
    }
    _present ??= (async.valueOrNull ?? const []).where((a) => a.isPresent).map((a) => a.playerId).toSet();
    if (widget.enrollments.isEmpty) {
      return ObGroup(header: header, children: const [ObRow('No players to mark yet')]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ObGroup(header: header, footer: 'Tap a player to mark them here.', children: [
        for (final e in widget.enrollments)
          ObRow(
            e.playerName ?? 'Student',
            subtitle: e.paymentStatus == 'fully_paid' ? 'Paid' : 'Still owes',
            leading: ProfileImage(url: e.playerAvatar, name: e.playerName, size: 36, isCircle: true),
            trailing: Icon(
              _present!.contains(e.playerId) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: _present!.contains(e.playerId) ? Ob.lime : Ob.creamA(.3),
              size: 26,
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _present!.contains(e.playerId) ? _present!.remove(e.playerId) : _present!.add(e.playerId));
            },
          ),
      ]),
      const SizedBox(height: 12),
      ObButton(
        height: 50,
        radius: 14,
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save roll · ${_present!.length} here', style: Ob.label(17)),
      ),
    ]);
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.enrollment});
  final SessionEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final paid = enrollment.paymentStatus == 'fully_paid';
    return ObRow(
      enrollment.playerName ?? 'Student',
      subtitle: 'Joined ${DateFormat('d MMM').format(enrollment.enrolledAt)}',
      leading: ProfileImage(url: enrollment.playerAvatar, name: enrollment.playerName, size: 36, isCircle: true),
      value: paid ? 'Paid' : 'Owes',
      valueColor: paid ? null : Ob.warn,
    );
  }
}

class _OccurrenceTile extends ConsumerWidget {
  final SessionOccurrence occurrence;
  final CoachingSession session;
  const _OccurrenceTile({required this.occurrence, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final live = o.status == 'in_progress';
    final done = o.status == 'completed';
    String hm(String? t) => t == null || t.length < 5 ? '--:--' : t.substring(0, 5);

    return ObRow(
      DateFormat('EEE d MMM').format(o.date),
      titleColor: done ? Ob.creamA(.55) : null,
      subtitle: '${hm(o.startTime)} to ${hm(o.endTime)}${live ? ' · on now' : ''}',
      trailing: o.status == 'upcoming'
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Add to calendar',
                onPressed: _addToCalendar,
                icon: Icon(LucideIcons.calendarPlus, color: Ob.creamA(.6), size: 20),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 44),
                onPressed: () => _confirm(context, ref, start: true),
                child: Text('Start', style: Ob.body(17, weight: FontWeight.w600, color: Ob.lime)),
              ),
            ])
          : live
              ? CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 44),
                  onPressed: () => _confirm(context, ref, start: false),
                  child: Text('End', style: Ob.body(17, weight: FontWeight.w600, color: Ob.warn)),
                )
              : done
                  ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Ob.lime, size: 22)
                  : null,
    );
  }

  void _addToCalendar() {
    final parts = (occurrence.startTime ?? session.startTime).split(':');
    final start = DateTime(occurrence.date.year, occurrence.date.month, occurrence.date.day,
        int.tryParse(parts.first) ?? 0, parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    Add2Calendar.addEvent2Cal(Event(
      title: 'Golf Session: ${session.name}',
      description: 'Coaching session at ${session.location}',
      location: session.location,
      startDate: start,
      endDate: start.add(Duration(minutes: session.durationMinutes)),
    ));
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, {required bool start}) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(start ? 'Start the session?' : 'End the session?'),
        content: Text(start ? 'Your players get a heads-up that you’re starting.' : 'The roll is locked in once you end it.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx, true), child: Text(start ? 'Start' : 'End')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(coachingServiceProvider).updateOccurrenceStatus(occurrence.id, start ? 'in_progress' : 'completed');
      ref.invalidate(sessionOccurrencesProvider(occurrence.sessionId));
      ref.invalidate(coachSessionsProvider);
    } catch (e) {
      if (context.mounted) TopNotification.showError(context, 'Couldn\'t ${start ? 'start' : 'end'} the session: $e');
    }
  }
}
