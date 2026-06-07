import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.partyPopper, color: AppColors.emerald500, size: 64),
            const SizedBox(height: 16),
            const Text('You\'re In!', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900)),
            const SizedBox(height: 8),
            Text('Booking confirmed. See you on the range!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey600, fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/caddie');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(providerSessionsProvider(widget.coachId));
    final coachAsync = ref.watch(coachingCoachProfileProvider(widget.coachId));
    final enrollmentsAsync = ref.watch(detailedSessionEnrollmentsProvider(widget.sessionId));

    return Scaffold(
      body: sessionsAsync.when(
        data: (sessions) {
          final session = sessions.firstWhere((s) => s.id == widget.sessionId);
          return coachAsync.when(
            data: (coach) => _buildScaffoldBody(session, coach, enrollmentsAsync.value ?? []),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: sessionsAsync.when(
        data: (sessions) {
          final session = sessions.firstWhere((s) => s.id == widget.sessionId);
          return _buildStickyFooter(session);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildScaffoldBody(CoachingSession session, Map<String, dynamic>? coach, List<Map<String, dynamic>> enrollments) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(session, coach),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStats(session),
                const SizedBox(height: 32),
                _buildAboutCoach(coach),
                const SizedBox(height: 32),
                _buildProgramOverview(session),
                const SizedBox(height: 32),
                _buildSessionInfo(session),
                const SizedBox(height: 32),
                _buildParticipantsSection(session, enrollments),
                const SizedBox(height: 32),
                _buildCancellationSection(session),
                const SizedBox(height: 40),
                if (_error != null) _buildErrorMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(CoachingSession session, Map<String, dynamic>? coach) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.purple900, AppColors.purple600],
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Profile Info Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: (coach?['avatarUrl'] != null || coach?['photoUrl'] != null)
                            ? DecorationImage(
                                image: NetworkImage(coach?['avatarUrl'] ?? coach?['photoUrl']), 
                                fit: BoxFit.cover
                              )
                            : null,
                        ),
                        child: (coach?['avatarUrl'] == null && coach?['photoUrl'] == null) 
                          ? const Icon(LucideIcons.user, color: Colors.white, size: 32)
                          : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach?['name'] ?? 'Loading...',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.award, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  coach?['certificationName'] ?? (coach?['hasCertification'] == true ? 'Certified Coach' : 'Professional Coach'),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      session.sessionType.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.name,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 0.9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(CoachingSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(icon: LucideIcons.clock, value: '${session.durationMinutes}m', label: 'Duration'),
          _StatDivider(),
          _StatItem(icon: LucideIcons.users, value: '${session.maxPlayers}', label: 'Capacity'),
          _StatDivider(),
          _StatItem(icon: LucideIcons.star, value: session.targetSkillLevel, label: 'Skill Level'),
        ],
      ),
    );
  }

  Widget _buildAboutCoach(Map<String, dynamic>? coach) {
    final bio = coach?['bio'] as String? ?? 'Professional instructor dedicated to improving your game through systematic training and biomechanical analysis.';
    final rating = (coach?['rating'] as num?)?.toDouble() ?? 5.0;
    
    // Parse specializations
    final rawSpecs = coach?['specializations'] as String? ?? '';
    final List<String> specs = rawSpecs.isNotEmpty 
        ? rawSpecs.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((s) => s.trim()).toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ABOUT THE COACH', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.grey500, letterSpacing: 1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('$rating', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.amber)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          bio,
          style: TextStyle(fontSize: 15, color: AppColors.grey700, height: 1.5, fontWeight: FontWeight.w400),
        ),
        if (specs.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('SPECIALIZATIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.grey500, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specs.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.emerald100)),
              child: Text(s.toUpperCase(), style: const TextStyle(color: AppColors.emerald700, fontSize: 10, fontWeight: FontWeight.w900)),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildProgramOverview(CoachingSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROGRAM OVERVIEW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.grey500, letterSpacing: 1)),
        const SizedBox(height: 16),
        _OverviewItem(
          icon: LucideIcons.calendar,
          title: 'Schedule',
          subtitle: '${session.daysOfWeek.map((d) => _dayName(d)).join(", ")} at ${session.startTime}',
        ),
        _OverviewItem(
          icon: LucideIcons.history,
          title: 'Total Length',
          subtitle: '${session.weeks}-week comprehensive curriculum',
        ),
        _OverviewItem(
          icon: LucideIcons.mapPin,
          title: 'Facility',
          subtitle: '${session.location} • ${session.locationArea}',
        ),
      ],
    );
  }

  Widget _buildSessionInfo(CoachingSession session) {
    if (session.prerequisites == null || session.prerequisites!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, size: 18, color: AppColors.purple600),
              const SizedBox(width: 10),
              const Text('Prerequisites', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(session.prerequisites!, style: TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(CoachingSession session, List<Map<String, dynamic>> enrollments) {
    final count = enrollments.length;
    final max = session.maxPlayers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('WHO\'S COMING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.grey500, letterSpacing: 1)),
            Text('$count/$max Slots Filled', style: TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 13, 
              color: count >= max ? AppColors.doubleBogey : AppColors.purple700
            )),
          ],
        ),
        const SizedBox(height: 16),
        if (count == 0)
          Text('Be the first to join this session!', style: TextStyle(color: AppColors.grey400, fontSize: 14, fontStyle: FontStyle.italic))
        else
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              itemBuilder: (context, index) {
                final player = enrollments[index]['User'];
                final avatarUrl = player?['avatarUrl'] ?? player?['photoUrl'];
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: avatarUrl != null 
                      ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                      : null,
                    border: Border.all(color: AppColors.grey200, width: 2),
                    color: AppColors.grey100,
                  ),
                  child: avatarUrl == null 
                    ? const Icon(LucideIcons.user, size: 20, color: AppColors.grey400)
                    : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCancellationSection(CoachingSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CANCELLATION POLICY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.grey500, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text(
          session.cancellationPolicy ?? 'Standard 24-hour notice required for full refund.',
          style: TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(CoachingSession session) {
    final enrollmentsAsync = ref.watch(detailedSessionEnrollmentsProvider(widget.sessionId));
    String paymentText = session.paymentTerms == 'upfront' ? 'Pay Upfront' :
                         session.paymentTerms == 'post' ? 'Pay Later' : 'Split Payment';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paymentText, style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('KES ${session.price.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing || (enrollmentsAsync.value?.length ?? 0) >= session.maxPlayers
                  ? null 
                  : () => _handleBooking(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.grey300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing 
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      (enrollmentsAsync.value?.length ?? 0) >= session.maxPlayers 
                        ? 'Fully Booked' 
                        : 'Confirm Booking', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int d) {
    switch (d) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.grey400),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: AppColors.grey200);
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OverviewItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.purple50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.purple700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.grey900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.grey600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
