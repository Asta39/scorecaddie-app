import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../provider/coach_dashboard_screen.dart' show nextOccurrence;
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';

class SessionBookingScreen extends ConsumerStatefulWidget {
  final String coachId;
  final String sessionId;

  const SessionBookingScreen({
    super.key, 
    required this.coachId, 
    required this.sessionId
  });

  @override
  ConsumerState<SessionBookingScreen> createState() => _SessionBookingScreenState();
}

class _SessionBookingScreenState extends ConsumerState<SessionBookingScreen> {
  bool _isProcessing = false;
  String? _error;

  Future<void> _handleBooking(CoachingSession session) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final enrollments = ref.read(detailedSessionEnrollmentsProvider(widget.sessionId)).valueOrNull ?? [];
    if (enrollments.length >= session.maxPlayers) {
      setState(() {
        _error = 'This session is fully booked.';
        _isProcessing = false;
      });
      return;
    }

    try {
      final service = ref.read(coachingServiceProvider);
      await service.enrollInSession(widget.sessionId);

      // Refresh providers
      ref.invalidate(detailedSessionEnrollmentsProvider(widget.sessionId));
      ref.invalidate(playerCoachingSummaryProvider);
      ref.invalidate(playerEnrollmentsProvider);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showObSheet(
      context,
      (ctx) => PopScope(
        canPop: false,
        child: ObSheet(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Image.asset(ObBot.star.happy, width: 110, height: 110)),
            Text('You\'re in!', textAlign: TextAlign.center, style: Ob.display(32)),
            const SizedBox(height: 6),
            Text('Your coach has your booking. It\'s on your profile under Coaching.', textAlign: TextAlign.center, style: Ob.body(14, height: 1.45, color: Ob.creamA(.7))),
            const SizedBox(height: 18),
            ObButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/profile');
              },
              child: Text('See my coaching', style: Ob.label(16, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(providerSessionsProvider(widget.coachId));
    final coach = ref.watch(coachingCoachProfileProvider(widget.coachId)).valueOrNull;
    final roster = ref.watch(detailedSessionEnrollmentsProvider(widget.sessionId)).valueOrNull ?? const <Map<String, dynamic>>[];
    final session = sessions.valueOrNull?.where((s) => s.id == widget.sessionId).firstOrNull;
    final mine = ref.watch(playerEnrollmentsProvider).valueOrNull ?? const [];
    final booked = mine.any((e) => e['session_id'] == widget.sessionId);

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: session == null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ObTopBar('Session', onBack: () => context.pop()),
                    const SizedBox(height: 24),
                    if (sessions.isLoading) const Center(child: CupertinoActivityIndicator(color: Ob.lime)) else Text('This session isn\'t open any more.', style: Ob.display(22)),
                  ]),
                )
              : Column(children: [
                  Expanded(child: _body(session, coach, roster)),
                  _footer(session, roster, booked),
                ]),
        ),
      ),
    );
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _body(CoachingSession s, Map<String, dynamic>? coach, List<Map<String, dynamic>> roster) {
    final next = nextOccurrence(s);
    final days = s.daysOfWeek.where((d) => d >= 1 && d <= 7).map((d) => _days[d - 1]).join(', ');
    final time = s.startTime.length >= 5 ? s.startTime.substring(0, 5) : s.startTime;
    final left = (s.maxPlayers - roster.length).clamp(0, 999);
    Widget info(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 17, color: Ob.lime),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.55))),
                Text(value, style: Ob.body(15, weight: FontWeight.w800)),
              ]),
            ),
          ]),
        );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ObTopBar(s.name, onBack: () => context.pop()),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(28), border: Border.all(color: Ob.lime.withValues(alpha: .2))),
          child: Column(children: [
            Row(children: [
              Image.asset(ObBot.star.idle, width: 60, height: 60),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('With ${coach?['name'] ?? 'your coach'}', style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.6))),
                  Text(s.sessionType == '1-on-1' ? 'Private lesson' : '${s.sessionType} programme', style: Ob.display(22, height: 1.1)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              for (final (v, l) in [('${s.durationMinutes} min', 'Each'), ('${s.maxPlayers} max', 'Group'), (s.targetSkillLevel, 'Level')])
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: Ob.bg.withValues(alpha: .45), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(18, height: 1)),
                      const SizedBox(height: 2),
                      Text(l, style: Ob.body(11, color: Ob.creamA(.55))),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        ObCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            info(LucideIcons.calendar, 'When', '$days at $time${next != null ? ' · next ${DateFormat('d MMM').format(next)}' : ''}'),
            const ObHair(),
            info(LucideIcons.clock, 'How long', '${s.weeks} ${s.weeks == 1 ? 'week' : 'weeks'}'),
            const ObHair(),
            info(LucideIcons.mapPin, 'Where', [s.locationArea, s.location].where((x) => x.isNotEmpty).join(' · ')),
            if ((s.prerequisites ?? '').isNotEmpty) ...[const ObHair(), info(LucideIcons.info, 'Bring', s.prerequisites!)],
          ]),
        ),
        if ((s.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          ObCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ObEyebrow('What you\'ll work on'),
              const SizedBox(height: 8),
              Text(s.description!, style: Ob.body(14, height: 1.55, color: Ob.creamA(.8))),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        ObCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ObEyebrow('Who\'s in', trailing: Text('${roster.length} of ${s.maxPlayers}', style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.55)))),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(value: s.maxPlayers == 0 ? 0 : (roster.length / s.maxPlayers).clamp(0.0, 1.0), minHeight: 10, backgroundColor: Ob.creamA(.08), color: Ob.lime),
            ),
            const SizedBox(height: 10),
            Row(children: [
              for (final (i, e) in roster.take(6).indexed)
                Transform.translate(
                  offset: Offset(-8.0 * i, 0),
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Ob.cardFill, width: 2)),
                    child: ProfileImage(url: (e['User'] as Map?)?['avatarUrl'], name: (e['User'] as Map?)?['name'], size: 32, isCircle: true),
                  ),
                ),
              SizedBox(width: roster.isEmpty ? 0 : 4),
              Text(roster.isEmpty ? 'Be the first in.' : (left == 0 ? 'Full' : '$left ${left == 1 ? 'place' : 'places'} left'), style: Ob.body(13, color: Ob.creamA(.62))),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Text(s.cancellationPolicy?.isNotEmpty == true ? s.cancellationPolicy! : 'Standard 24-hour notice for a full refund.', style: Ob.body(13, height: 1.5, color: Ob.creamA(.6))),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ObCard(child: Text(_error!, style: Ob.body(13, color: Ob.warn))),
        ],
      ],
    );
  }

  Widget _footer(CoachingSession s, List<Map<String, dynamic>> roster, bool booked) {
    final full = roster.length >= s.maxPlayers;
    final terms = switch (s.paymentTerms) { 'upfront' => 'Paid when you book', 'post' => 'Paid after', _ => 'Half now, half at the end' };
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: Ob.bg, border: Border(top: BorderSide(color: Ob.creamA(.06)))),
      child: Row(children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KES ${NumberFormat('#,###').format(s.price)}', style: Ob.display(24, height: 1)),
          Text(terms, style: Ob.body(11, color: Ob.creamA(.55))),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: ObButton(
            onPressed: booked || full || _isProcessing ? null : () => _handleBooking(s),
            child: Text(booked ? 'You\'re booked' : (full ? 'Full' : (_isProcessing ? 'Booking…' : 'Book my place')), style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
