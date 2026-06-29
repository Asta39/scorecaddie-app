import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../../widgets/profile_image.dart';
import '../../core/utils/calendar_helper.dart';

class PlayerSessionDetailsScreen extends ConsumerWidget {
  final String sessionId;
  const PlayerSessionDetailsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(specificCoachingSessionProvider(sessionId));
    final occurrencesAsync = ref.watch(sessionOccurrencesProvider(sessionId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text('Session Details', 
          style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) return const Center(child: Text('Session not found'));
          return _buildContent(context, ref, session, occurrencesAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, CoachingSession session, AsyncValue<List<SessionOccurrence>> occurrencesAsync) {
    final coachAsync = ref.watch(coachingCoachProfileProvider(session.coachId));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Main Card ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.sessionType.toUpperCase(),
                      style: const TextStyle(color: AppColors.emerald700, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                  _StatusBadge(status: session.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(session.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 14, color: AppColors.grey400),
                  const SizedBox(width: 6),
                  Text(session.location, style: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.grey100),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatItem(icon: LucideIcons.clock, label: 'Duration', value: '${session.durationMinutes}m'),
                  _StatItem(icon: LucideIcons.users, label: 'Slots', value: '${session.enrollmentCount}/${session.maxPlayers}'),
                  _StatItem(icon: LucideIcons.creditCard, label: 'Fee', value: 'KES ${session.pricePerSession.toInt()}'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Coach Section ───────────────────────────────────────────────────
        const Text('YOUR TEACHER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1)),
        const SizedBox(height: 12),
        coachAsync.when(
          data: (coach) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ProfileImage(url: coach?['avatarUrl'] ?? coach?['photoUrl'], size: 48, borderRadius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coach?['name'] ?? 'Loading...', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(coach?['certificationName'] ?? 'Certified Professional', style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/chat/${session.coachId}'),
                  icon: const Icon(LucideIcons.messageCircle, color: AppColors.emerald700),
                  style: IconButton.styleFrom(backgroundColor: AppColors.emerald50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
          loading: () => Center(child: CupertinoActivityIndicator()),
          error: (_, _) => const SizedBox(),
        ),

        const SizedBox(height: 32),

        // ── Occurrences ─────────────────────────────────────────────────────
        const Text('SESSION SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1)),
        const SizedBox(height: 12),
        occurrencesAsync.when(
          data: (list) => Column(
            children: list.map((o) => _OccurrenceTile(occurrence: o)).toList(),
          ),
          loading: () => Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Text('Error loading schedule: $e'),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.grey400),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 14)),
        ],
      ),
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  final SessionOccurrence occurrence;
  const _OccurrenceTile({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('MMM').format(occurrence.date).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.grey400)),
                Text(DateFormat('d').format(occurrence.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.grey900, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE').format(occurrence.date), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900)),
                Text(occurrence.status.toUpperCase(), style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  color: occurrence.status == 'in_progress' ? AppColors.emerald700 : AppColors.grey400,
                  letterSpacing: 0.5
                )),
              ],
            ),
          ),
          if (occurrence.status == 'completed')
            const Icon(LucideIcons.checkCircle2, color: AppColors.emerald500, size: 20)
          else if (occurrence.status == 'in_progress')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.emerald500, borderRadius: BorderRadius.circular(6)),
              child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
            )
          else
            IconButton(
              onPressed: () => CalendarHelper.addSessionToCalendar(
                sessionName: 'Golf: ${occurrence.status.toUpperCase()}', // Placeholder since we don't have session object here easily
                location: 'Club',
                date: occurrence.date,
                startTime: occurrence.startTime ?? '07:00',
                durationMinutes: 60,
              ),
              icon: const Icon(LucideIcons.calendarPlus, color: AppColors.grey400, size: 20),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.emerald500;
    if (status == 'completed') color = AppColors.grey400;
    if (status == 'full') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
