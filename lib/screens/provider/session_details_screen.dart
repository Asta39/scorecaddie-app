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
import '../onboarding/ob_widgets.dart';
import 'coach_dashboard_screen.dart' show coachGold;

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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
                    children: [
                      Row(children: [
                        ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
                        const Spacer(),
                        ObIconButton(icon: LucideIcons.share2, label: 'Share session', onPressed: () => _share(session)),
                        if (session.status != 'cancelled') ...[
                          const SizedBox(width: 8),
                          ObIconButton(
                            icon: LucideIcons.pencil,
                            label: 'Edit session',
                            onPressed: () => context.push('/coach/session/${session.id}/edit', extra: session),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 14),
                      Text(session.name, style: Ob.display(30, height: 1.05)).rise(),
                      const SizedBox(height: 14),
                      _hero(session, live).rise(1),
                      const SizedBox(height: 12),
                      ObSplitCards(
                        left: ObStat('Players', '${enrollments.length}/${session.maxPlayers}', valueColor: coachGold),
                        right: ObStat('Still owe', '${enrollments.where((e) => e.paymentStatus != 'fully_paid').length}'),
                      ),
                      if (session.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        ObCard(child: Text(session.description!, style: Ob.body(14, height: 1.5, color: Ob.creamA(.8)))),
                      ],
                      if (attendFor != null) ...[
                        const SizedBox(height: 24),
                        ObEyebrow(live != null ? 'Who\'s here' : 'Last session\'s roll'),
                        const SizedBox(height: 10),
                        _AttendanceChecklist(key: ValueKey(attendFor.id), occurrence: attendFor, enrollments: enrollments),
                      ],
                      const SizedBox(height: 24),
                      ObEyebrow('Players · ${enrollments.length}'),
                      const SizedBox(height: 10),
                      if (enrollAsync.isLoading && enrollments.isEmpty)
                        const Center(child: CupertinoActivityIndicator(color: coachGold))
                      else if (enrollments.isEmpty)
                        ObCard(child: Text('Nobody has booked yet. Share the session to fill it.', style: Ob.body(13, color: Ob.creamA(.6))))
                      else
                        ObCard(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(children: [
                            for (final (i, e) in enrollments.indexed) ...[
                              if (i > 0) const ObHair(),
                              _RosterRow(enrollment: e),
                            ],
                          ]),
                        ),
                      const SizedBox(height: 24),
                      ObEyebrow('Dates · ${upcoming.length} to go'),
                      const SizedBox(height: 10),
                      for (final o in occurrences) _OccurrenceTile(occurrence: o, session: session),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _missing(bool loading) {
    if (loading) return const Center(child: CupertinoActivityIndicator(color: coachGold));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
        const SizedBox(height: 24),
        Text('This session isn\'t available any more.', style: Ob.display(24)),
      ]),
    );
  }

  Widget _hero(CoachingSession s, SessionOccurrence? live) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final when = s.daysOfWeek.where((d) => d >= 1 && d <= 7).map((d) => days[d - 1]).join(' · ');
    final time = s.startTime.length >= 5 ? s.startTime.substring(0, 5) : s.startTime;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: live != null ? const Color(0xFF2A2410) : Ob.cardFill,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: live != null ? coachGold : Ob.creamA(.08), width: live != null ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(live != null ? 'ON NOW' : when.toUpperCase(), style: Ob.body(12, weight: FontWeight.w800, color: coachGold).copyWith(letterSpacing: 1.6)),
          const Spacer(),
          Text('$time · ${s.durationMinutes} min', style: Ob.display(18)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(LucideIcons.mapPin, size: 14, color: Ob.creamA(.6)),
          const SizedBox(width: 6),
          Expanded(child: Text(s.location, style: Ob.body(14, weight: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Text('KES ${NumberFormat('#,###').format(s.pricePerSession)} a session · ${s.weeks} weeks', style: Ob.body(12, color: Ob.creamA(.6))),
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
  const _AttendanceChecklist({super.key, required this.occurrence, required this.enrollments});

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
    if (async.isLoading && _present == null) return const Center(child: CupertinoActivityIndicator(color: coachGold));
    if (async.hasError && _present == null) {
      return ObCard(child: Text('Couldn\'t load attendance.', style: Ob.body(13, color: Ob.creamA(.6))));
    }
    _present ??= (async.valueOrNull ?? const []).where((a) => a.isPresent).map((a) => a.playerId).toSet();
    if (widget.enrollments.isEmpty) {
      return ObCard(child: Text('No players to mark yet.', style: Ob.body(13, color: Ob.creamA(.6))));
    }

    return Column(children: [
      for (final e in widget.enrollments) ...[
        _HereRow(
          enrollment: e,
          here: _present!.contains(e.playerId),
          onTap: () => setState(() => _present!.contains(e.playerId) ? _present!.remove(e.playerId) : _present!.add(e.playerId)),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: ObButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save roll · ${_present!.length} here', style: Ob.label(15, weight: FontWeight.w800)),
        ),
      ),
    ]);
  }
}

class _HereRow extends StatelessWidget {
  const _HereRow({required this.enrollment, required this.here, required this.onTap});
  final SessionEnrollment enrollment;
  final bool here;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paid = enrollment.paymentStatus == 'fully_paid';
    return Semantics(
      button: true,
      toggled: here,
      label: enrollment.playerName ?? 'Student',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: here ? Ob.roleFill : Ob.cardFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: here ? Ob.lime.withValues(alpha: .5) : Ob.creamA(.06)),
          ),
          child: Row(children: [
            ProfileImage(url: enrollment.playerAvatar, name: enrollment.playerName, size: 40, isCircle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(enrollment.playerName ?? 'Student', style: Ob.body(15, weight: FontWeight.w800)),
                Text(paid ? 'Paid' : 'Still owes', style: Ob.body(12, weight: FontWeight.w700, color: paid ? Ob.lime : coachGold)),
              ]),
            ),
            AnimatedScale(
              scale: here ? 1 : .85,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: here ? Ob.lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: here ? Ob.lime : Ob.creamA(.3), width: 2),
                ),
                child: here ? const Icon(LucideIcons.check, size: 16, color: Ob.ink) : null,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.enrollment});
  final SessionEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final paid = enrollment.paymentStatus == 'fully_paid';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        ProfileImage(url: enrollment.playerAvatar, name: enrollment.playerName, size: 36, isCircle: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(enrollment.playerName ?? 'Student', style: Ob.body(14, weight: FontWeight.w700)),
            Text('Joined ${DateFormat('d MMM').format(enrollment.enrolledAt)}', style: Ob.body(12, color: Ob.creamA(.55))),
          ]),
        ),
        Text(paid ? 'Paid' : 'Owes', style: Ob.body(13, weight: FontWeight.w800, color: paid ? Ob.lime : coachGold)),
      ]),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: live ? const Color(0xFF2A2410) : Ob.cardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: live ? coachGold : Ob.creamA(.06)),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Ob.creamA(.06), borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(DateFormat('MMM').format(o.date).toUpperCase(), style: Ob.body(10, weight: FontWeight.w800, color: Ob.creamA(.55))),
              Text(DateFormat('d').format(o.date), style: Ob.display(18, height: 1.1)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEEE').format(o.date), style: Ob.body(14, weight: FontWeight.w800, color: done ? Ob.creamA(.55) : Ob.cream)),
              Text('${hm(o.startTime)} to ${hm(o.endTime)}', style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          if (o.status == 'upcoming') ...[
            IconButton(
              tooltip: 'Add to calendar',
              onPressed: () => _addToCalendar(),
              icon: Icon(LucideIcons.calendarPlus, color: Ob.creamA(.6), size: 20),
            ),
            ObButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => _confirm(context, ref, start: true),
              child: Text('Start', style: Ob.label(13, weight: FontWeight.w800)),
            ),
          ],
          if (live)
            ObButton(
              height: 38,
              tone: ObButtonTone.light,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => _confirm(context, ref, start: false),
              child: Text('End', style: Ob.label(13, weight: FontWeight.w800)),
            ),
          if (done) const Icon(LucideIcons.circleCheck, color: Ob.lime, size: 22),
        ]),
      ),
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
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(ctx).padding.bottom),
        decoration: const BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(start ? 'Start the session?' : 'End the session?', style: Ob.display(24)),
            const SizedBox(height: 8),
            Text(
              start ? 'Your players get a heads-up that you\'re starting.' : 'The roll is locked in once you end it.',
              style: Ob.body(14, color: Ob.creamA(.7)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Not yet', style: Ob.label(15, weight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ObButton(onPressed: () => Navigator.pop(ctx, true), child: Text(start ? 'Start now' : 'End session', style: Ob.label(15, weight: FontWeight.w800))),
              ),
            ]),
          ]),
        ),
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
