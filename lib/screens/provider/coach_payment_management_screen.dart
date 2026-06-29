import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';

// ─── Resolved enrollment (enriched with session info) ─────────────────────────
class _RE {
  final SessionEnrollment e;
  final String sessionName;
  final double sessionPrice;
  _RE({required this.e, required this.sessionName, required this.sessionPrice});
  double get outstanding => (sessionPrice - e.amountPaid).clamp(0, double.infinity);
  bool get isPaid => e.paymentStatus == 'fully_paid';
  bool get isOverdue => !isPaid && DateTime.now().difference(e.enrolledAt).inDays > 14;
}

// ─── All-enrollments provider (safe: empty list on error/no sessions) ──────────
final _allEnrollmentsProvider = FutureProvider<List<_RE>>((ref) async {
  final sessions = await ref.watch(coachSessionsProvider.future);
  if (sessions.isEmpty) return [];
  final service = ref.watch(coachingServiceProvider);
  final result = <_RE>[];
  for (final s in sessions) {
    try {
      final enrollments = await service.getSessionEnrollments(s.id);
      for (final e in enrollments) {
        result.add(_RE(e: e, sessionName: s.name, sessionPrice: s.pricePerSession));
      }
    } catch (_) {
      // skip sessions that fail to load enrollments
    }
  }
  return result;
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class CoachPaymentManagementScreen extends ConsumerStatefulWidget {
  const CoachPaymentManagementScreen({super.key});

  @override
  ConsumerState<CoachPaymentManagementScreen> createState() =>
      _CoachPaymentManagementScreenState();
}

class _CoachPaymentManagementScreenState
    extends ConsumerState<CoachPaymentManagementScreen> {
  int _tabIndex = 0;
  CoachingSession? _selectedSession;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.grey900 : const Color(0xFFFBFBF9);
    final sessionsAsync = ref.watch(coachSessionsProvider);
    final allEnrollAsync = ref.watch(_allEnrollmentsProvider);

    return Material(
      color: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payments',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.grey900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Manage student payments',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.grey400 : AppColors.grey500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.emerald700.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.creditCard, color: AppColors.emerald700, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Analytics ───────────────────────────────────────────────────
            allEnrollAsync.when(
              data: (all) => _AnalyticsRow(all: all, isDark: isDark),
              loading: () => const SizedBox(height: 88, child: Center(child: CupertinoActivityIndicator())),
              error: (_, _) => const SizedBox(),
            ),

            const SizedBox(height: 16),

            // ── Tab Picker ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _tabIndex,
                backgroundColor: isDark ? AppColors.grey800 : AppColors.grey100,
                thumbColor: AppColors.emerald700,
                children: {
                  0: _segTab('By Session', 0),
                  1: _segTab('Outstanding', 1),
                },
                onValueChanged: (v) => setState(() => _tabIndex = v ?? 0),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Content ─────────────────────────────────────────────────
            Expanded(
              child: _tabIndex == 0
                  ? sessionsAsync.when(
                      data: (sessions) => _SessionTab(
                        sessions: sessions,
                        selected: _selectedSession ?? (sessions.isNotEmpty ? sessions.first : null),
                        onSelect: (s) => setState(() => _selectedSession = s),
                        isDark: isDark,
                      ),
                      loading: () => const Center(child: CupertinoActivityIndicator()),
                      error: (e, _) => _ErrorView(message: e.toString()),
                    )
                  : allEnrollAsync.when(
                      data: (all) => _OutstandingTab(all: all.where((r) => !r.isPaid).toList(), isDark: isDark),
                      loading: () => const Center(child: CupertinoActivityIndicator()),
                      error: (e, _) => _ErrorView(message: e.toString()),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segTab(String label, int index) {
    final selected = _tabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.grey500,
        ),
      ),
    );
  }
}

// ─── Analytics Row ────────────────────────────────────────────────────────────
class _AnalyticsRow extends StatelessWidget {
  final List<_RE> all;
  final bool isDark;
  const _AnalyticsRow({required this.all, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final collected = all.fold<double>(0, (s, r) => s + r.e.amountPaid);
    final outstanding = all.fold<double>(0, (s, r) => s + r.outstanding);
    final overdue = all.where((r) => r.isOverdue).length;
    final paid = all.where((r) => r.isPaid).length;
    final rate = all.isEmpty ? 0.0 : paid / all.length * 100;
    final fmt = NumberFormat('#,###');

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _StatCard('Collected', 'KES ${fmt.format(collected)}', LucideIcons.trendingUp, AppColors.emerald700, isDark),
          _StatCard('Outstanding', 'KES ${fmt.format(outstanding)}', LucideIcons.alertCircle, Colors.orange, isDark),
          _StatCard('Rate', '${rate.toStringAsFixed(0)}%', LucideIcons.pieChart, AppColors.blue600, isDark),
          _StatCard('Overdue', '$overdue', LucideIcons.clock, AppColors.doubleBogey, isDark),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard(this.label, this.value, this.icon, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.4)),
          ]),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

// ─── Tab 1: By Session ─────────────────────────────────────────────────────────
class _SessionTab extends ConsumerWidget {
  final List<CoachingSession> sessions;
  final CoachingSession? selected;
  final ValueChanged<CoachingSession> onSelect;
  final bool isDark;

  const _SessionTab({required this.sessions, required this.selected, required this.onSelect, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessions.isEmpty) {
      return _EmptyState(icon: LucideIcons.calendar, message: 'No sessions yet.\nCreate a session to manage payments.', isDark: isDark);
    }

    final session = selected ?? sessions.first;

    return Column(
      children: [
        // Session picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => _pickSession(context, session),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.grey700 : AppColors.grey200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: session.status == 'active' ? AppColors.emerald500 : AppColors.grey400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.name,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : AppColors.grey900),
                    ),
                  ),
                  Icon(LucideIcons.chevronsUpDown, size: 16, color: AppColors.grey400),
                ],
              ),
            ),
          ),
        ),
        // Price tag
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Icon(LucideIcons.tag, size: 11, color: AppColors.grey400),
              const SizedBox(width: 6),
              Text(
                'KES ${NumberFormat('#,###').format(session.pricePerSession)} · ${session.paymentTerms}',
                style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(child: _EnrollmentList(session: session, isDark: isDark)),
      ],
    );
  }

  void _pickSession(BuildContext context, CoachingSession current) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Session', style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : AppColors.grey900,
                    letterSpacing: -0.5,
                  )),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    color: AppColors.grey400,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final isSelected = s.id == current.id;
                    
                    return GestureDetector(
                      onTap: () {
                        onSelect(s);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? AppColors.emerald700.withValues(alpha: 0.1) 
                            : (isDark ? AppColors.grey900 : AppColors.grey50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.emerald700 : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: s.status == 'active' ? AppColors.emerald500 : AppColors.grey400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected 
                                    ? AppColors.emerald700 
                                    : (isDark ? Colors.white : AppColors.grey900),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(LucideIcons.check, size: 16, color: AppColors.emerald700),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnrollmentList extends ConsumerWidget {
  final CoachingSession session;
  final bool isDark;
  const _EnrollmentList({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollAsync = ref.watch(sessionEnrollmentsProvider(session.id));

    return enrollAsync.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return _EmptyState(icon: LucideIcons.users, message: 'No students enrolled yet.', isDark: isDark);
        }

        final totalPaid = enrollments.fold<double>(0, (s, e) => s + e.amountPaid);
        final totalExp = session.pricePerSession * enrollments.length;
        final fmt = NumberFormat('#,###');

        return Column(
          children: [
            // Mini summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.emerald700.withValues(alpha: isDark ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    _MiniStat('COLLECTED', 'KES ${fmt.format(totalPaid)}', AppColors.emerald700, isDark),
                    _Divider(),
                    _MiniStat('EXPECTED', 'KES ${fmt.format(totalExp)}', isDark ? AppColors.grey300 : AppColors.grey700, isDark),
                    _Divider(),
                    _MiniStat('STUDENTS', '${enrollments.length}', isDark ? Colors.white : AppColors.grey900, isDark),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: enrollments.length,
                itemBuilder: (_, i) => _EnrollmentTile(
                  enrollment: enrollments[i],
                  sessionPrice: session.pricePerSession,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
    );
  }
}

// ─── Tab 2: Outstanding ────────────────────────────────────────────────────────
class _OutstandingTab extends StatelessWidget {
  final List<_RE> all;
  final bool isDark;
  const _OutstandingTab({required this.all, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return _EmptyState(icon: LucideIcons.checkCircle, message: 'All students are fully paid! 🎉', isDark: isDark, color: AppColors.emerald700);
    }

    final sorted = [...all]..sort((a, b) => b.outstanding.compareTo(a.outstanding));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _OutstandingTile(r: sorted[i], isDark: isDark),
    );
  }
}

// ─── Enrollment Tile ──────────────────────────────────────────────────────────
class _EnrollmentTile extends ConsumerWidget {
  final SessionEnrollment enrollment;
  final double sessionPrice;
  final bool isDark;
  const _EnrollmentTile({required this.enrollment, required this.sessionPrice, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = enrollment.playerAvatar;
    final name = enrollment.playerName ?? 'Student';

    final outstanding = (sessionPrice - enrollment.amountPaid).clamp(0, double.infinity);
    final isPaid = enrollment.paymentStatus == 'fully_paid';
    final isPartial = enrollment.paymentStatus == 'partial';
    final Color statusColor = isPaid ? AppColors.emerald700 : (isPartial ? Colors.orange : AppColors.doubleBogey);
    final String statusLabel = isPaid ? 'PAID' : (isPartial ? 'PARTIAL' : 'UNPAID');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.grey700 : AppColors.grey100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.emerald700.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w900),
                  ) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : AppColors.grey900)),
                      Text(
                        'Enrolled ${DateFormat('MMM d, yyyy').format(enrollment.enrolledAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _Badge(statusLabel, statusColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _PayStat('PAID', enrollment.amountPaid, AppColors.emerald700, isDark),
                _PayStat('OWED', outstanding.toDouble(), outstanding > 0 ? Colors.orange : AppColors.grey400, isDark),
                _PayStat('TOTAL', sessionPrice, isDark ? AppColors.grey300 : AppColors.grey700, isDark),
              ],
            ),
          ),
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.emerald700,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => _showSheet(context, ref, name),
                  child: const Text('Record Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref, String playerName) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _PaymentSheet(
          enrollment: enrollment,
          sessionPrice: sessionPrice,
          playerName: playerName,
          isDark: isDark,
          onSaved: () {
            ref.invalidate(sessionEnrollmentsProvider(enrollment.sessionId));
            ref.invalidate(_allEnrollmentsProvider);
          },
        ),
      ),
    );
  }
}

// ─── Outstanding Tile ─────────────────────────────────────────────────────────
class _OutstandingTile extends ConsumerWidget {
  final _RE r;
  final bool isDark;
  const _OutstandingTile({required this.r, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = r.e.playerAvatar;
    final name = r.e.playerName ?? 'Student';
    final days = DateTime.now().difference(r.e.enrolledAt).inDays;
    final fmt = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: r.isOverdue ? AppColors.doubleBogey.withValues(alpha: 0.3) : (isDark ? AppColors.grey700 : AppColors.grey100)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (r.isOverdue ? AppColors.doubleBogey : Colors.orange).withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: TextStyle(color: r.isOverdue ? AppColors.doubleBogey : Colors.orange, fontWeight: FontWeight.w900),
                  ) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : AppColors.grey900)),
                      Text(r.sessionName, style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (r.isOverdue) _Badge('${days}d overdue', AppColors.doubleBogey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OUTSTANDING', style: TextStyle(fontSize: 9, color: AppColors.grey400, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      Text(
                        'KES ${fmt.format(r.outstanding)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: r.isOverdue ? AppColors.doubleBogey : Colors.orange,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'of KES ${fmt.format(r.sessionPrice)} · paid KES ${fmt.format(r.e.amountPaid)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  color: AppColors.emerald700,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  onPressed: () => _showSheet(context, ref, name),
                  child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _PaymentSheet(
          enrollment: r.e,
          sessionPrice: r.sessionPrice,
          playerName: name,
          isDark: isDark,
          onSaved: () {
            ref.invalidate(sessionEnrollmentsProvider(r.e.sessionId));
            ref.invalidate(_allEnrollmentsProvider);
          },
        ),
      ),
    );
  }
}

// ─── Payment Modal (Refactored from Bottom Sheet) ───────────────────────────
class _PaymentSheet extends ConsumerStatefulWidget {
  final SessionEnrollment enrollment;
  final double sessionPrice;
  final String playerName;
  final bool isDark;
  final VoidCallback onSaved;

  const _PaymentSheet({
    required this.enrollment,
    required this.sessionPrice,
    required this.playerName,
    required this.isDark,
    required this.onSaved,
  });

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _controller = TextEditingController();
  String _method = 'MPESA';
  bool _loading = false;

  double get outstanding =>
      (widget.sessionPrice - widget.enrollment.amountPaid).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _controller.text = outstanding.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.enrollment.playerAvatar;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.emerald700.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(LucideIcons.user, color: AppColors.emerald700, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: widget.isDark ? Colors.white : AppColors.grey900)),
                    Text(widget.playerName, style: TextStyle(color: widget.isDark ? AppColors.grey400 : AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, size: 20),
                color: AppColors.grey400,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount to pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey500)),
              Text('Outstanding: KES ${NumberFormat('#,###').format(outstanding)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.grey900 : AppColors.grey50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.isDark ? AppColors.grey700 : AppColors.grey200),
            ),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text('KES', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey600)),
            ),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: widget.isDark ? Colors.white : AppColors.grey900),
            placeholder: '0',
          ),
          const SizedBox(height: 20),
          const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey500)),
          const SizedBox(height: 8),
          Row(
            children: ['CASH', 'MPESA', 'BANK'].map((m) {
              final sel = _method == m;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: m != 'BANK' ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _method = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.emerald700 : (widget.isDark ? AppColors.grey700 : AppColors.grey100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : (widget.isDark ? AppColors.grey400 : AppColors.grey600),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.emerald700,
              borderRadius: BorderRadius.circular(16),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text('Save Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await ref.read(coachingServiceProvider).recordPayment(
        enrollmentId: widget.enrollment.id,
        amount: amount,
        method: _method,
        sessionId: widget.enrollment.sessionId,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
    );
  }
}

class _PayStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;
  const _PayStat(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey400, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(
            'KES ${NumberFormat('#,###').format(value)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _MiniStat(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey400, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.grey200, margin: const EdgeInsets.symmetric(horizontal: 12));
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;
  final Color color;
  const _EmptyState({required this.icon, required this.message, required this.isDark, this.color = AppColors.grey300});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.grey400 : AppColors.grey500, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatefulWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView> {
  bool _showTech = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Could not load data', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16, 
              color: isDark ? Colors.white : AppColors.grey700
            )),
            const SizedBox(height: 8),
            Text(
              'A sync or data error occurred. Please try again or check your connection.',
              style: TextStyle(color: isDark ? AppColors.grey400 : AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              child: Text(_showTech ? 'Hide Diagnostics' : 'Show Technical Info',
                style: TextStyle(fontSize: 13, color: AppColors.grey400, fontWeight: FontWeight.w600)),
              onPressed: () => setState(() => _showTech = !_showTech),
            ),
            if (_showTech)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800.withValues(alpha: 0.5) : AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.grey700 : AppColors.grey200),
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isDark ? AppColors.grey400 : AppColors.grey600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
