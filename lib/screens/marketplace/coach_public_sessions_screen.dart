import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';

class CoachPublicSessionsScreen extends ConsumerWidget {
  final String coachId;
  const CoachPublicSessionsScreen({super.key, required this.coachId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(specificProviderProvider(coachId));
    final sessionsAsync = ref.watch(providerSessionsProvider(coachId));

    return Scaffold(
      appBar: AppBar(
        title: providerAsync.when(
          data: (p) => Text('${p?.name ?? "Coach"}\'s Sessions', style: const TextStyle(fontWeight: FontWeight.bold)),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Sessions'),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendarOff, size: 64, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text('No active sessions found', 
                    style: TextStyle(fontSize: 18, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _PublicSessionCard(session: session, coachId: coachId);
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PublicSessionCard extends ConsumerWidget {
  final CoachingSession session;
  final String coachId;

  const _PublicSessionCard({required this.session, required this.coachId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(playerEnrollmentsProvider);
    final isEnrolled = enrollmentsAsync.when(
      data: (list) => list.any((e) => e['session_id'] == session.id),
      loading: () => false,
      error: (_, _) => false,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'KES ${session.price.toInt()}',
                  style: TextStyle(color: AppColors.purple700, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (session.description != null) ...[
            Text(
              session.description!,
              style: TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoTag(icon: LucideIcons.calendar, label: session.daysOfWeek.join(', ')),
              _InfoTag(icon: LucideIcons.clock, label: session.startTime),
              _InfoTag(icon: LucideIcons.users, label: 'Up to ${session.maxPlayers} players'),
              _InfoTag(icon: LucideIcons.repeat, label: '${session.weeks} weeks recurring'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnrolled ? null : () {
                context.push('/marketplace/coach/$coachId/session/${session.id}/book');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnrolled ? AppColors.grey300 : AppColors.purple700,
                foregroundColor: isEnrolled ? AppColors.grey600 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isEnrolled 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.checkCircle, size: 20),
                      SizedBox(width: 8),
                      Text('Already Registered', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  )
                : const Text('Book This Session', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.grey400),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppColors.grey700, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
