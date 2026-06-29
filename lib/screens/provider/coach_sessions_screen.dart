import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';

class CoachSessionsScreen extends ConsumerStatefulWidget {
  const CoachSessionsScreen({super.key});

  @override
  ConsumerState<CoachSessionsScreen> createState() => _CoachSessionsScreenState();
}

class _CoachSessionsScreenState extends ConsumerState<CoachSessionsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(coachSessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          'Sessions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -1,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create-session'),
          backgroundColor: AppColors.emerald700,
          elevation: 8,
          icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
          label: const Text('Create Session', style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          )),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // ── Stats Banner ────────────────────────────────────────
          sessionsAsync.when(
            data: (sessions) => _StatsBanner(sessions: sessions, isDark: isDark),
            loading: () => const SizedBox(height: 88, child: Center(child: CupertinoActivityIndicator())),
            error: (e, s) => const SizedBox(),
          ),

          const SizedBox(height: 20),

          // ── Segmented Tab ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _tabIndex,
              backgroundColor: isDark ? AppColors.grey800 : AppColors.grey100,
              thumbColor: AppColors.emerald700,
              children: {
                0: _segTab('Active', 0),
                1: _segTab('History', 1),
                2: _segTab('Cancelled', 2),
              },
              onValueChanged: (v) => setState(() => _tabIndex = v ?? 0),
            ),
          ),

          const SizedBox(height: 16),

          // ── Session List ────────────────────────────────────────
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                final filtered = sessions.where((s) {
                  if (_tabIndex == 0) return s.status == 'active' || s.status == 'full';
                  if (_tabIndex == 1) return s.status == 'completed';
                  return s.status == 'cancelled';
                }).toList();

                if (filtered.isEmpty) return _EmptyState(tabIndex: _tabIndex, isDark: isDark);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _SessionCard(session: filtered[i], isDark: isDark),
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => _ErrorView(message: e.toString()),
            ),
          ),
        ],
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

// ─── Stats Banner ─────────────────────────────────────────────────────────────
class _StatsBanner extends StatelessWidget {
  final List<CoachingSession> sessions;
  final bool isDark;
  const _StatsBanner({required this.sessions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active = sessions.where((s) => s.status == 'active' || s.status == 'full').length;
    final total = sessions.length;
    final totalRevenue = sessions.fold<double>(0, (sum, s) => sum + s.pricePerSession);
    final fmt = NumberFormat('#,###');

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _StatCard('Active', '$active', LucideIcons.activity, AppColors.emerald700, isDark),
          _StatCard('Total', '$total', LucideIcons.layers, AppColors.blue600, isDark),
          _StatCard('Revenue', 'KES ${fmt.format(totalRevenue)}', LucideIcons.trendingUp, Colors.orange, isDark),
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
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(label.toUpperCase(), style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
                letterSpacing: 0.5,
              )),
            ],
          ),
          Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.5,
          )),
        ],
      ),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final CoachingSession session;
  final bool isDark;
  const _SessionCard({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/coach/session/${session.id}'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.name, style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.grey900,
                            letterSpacing: -0.5,
                          )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.mapPin, size: 12, color: isDark ? AppColors.grey500 : AppColors.grey400),
                              const SizedBox(width: 4),
                              Text(session.location, style: TextStyle(
                                color: isDark ? AppColors.grey500 : AppColors.grey400,
                                fontSize: 13, fontWeight: FontWeight.w500,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: session.status),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: isDark ? AppColors.grey700 : AppColors.grey100,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: LucideIcons.calendar,
                      label: _getDaysString(session.daysOfWeek),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: LucideIcons.clock,
                      label: session.startTime.substring(0, 5),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: LucideIcons.users,
                      label: '${session.enrollmentCount} / ${session.maxPlayers}',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'KES ${session.pricePerSession.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: AppColors.emerald700,
                      ),
                    ),
                    Text(' / session', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                    )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : AppColors.grey900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text('Manage', style: TextStyle(
                            color: isDark ? AppColors.grey900 : Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w800,
                          )),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight, size: 14,
                            color: isDark ? AppColors.grey900 : Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDaysString(List<int> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey700 : AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? AppColors.grey400 : AppColors.grey500),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          )),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = AppColors.emerald500;
        label = 'ACTIVE';
        break;
      case 'full':
        color = AppColors.eagle;
        label = 'FULL';
        break;
      case 'completed':
        color = AppColors.grey400;
        label = 'PAST';
        break;
      case 'cancelled':
        color = AppColors.doubleBogey;
        label = 'CANCELLED';
        break;
      default:
        color = AppColors.grey400;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5,
      )),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final bool isDark;
  const _EmptyState({required this.tabIndex, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final labels = ['active', 'completed', 'cancelled'];
    final icons = [LucideIcons.calendarPlus, LucideIcons.calendarCheck, LucideIcons.calendarX2];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.grey50,
              shape: BoxShape.circle,
            ),
            child: Icon(icons[tabIndex], size: 40,
              color: isDark ? AppColors.grey600 : AppColors.grey200),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${labels[tabIndex]} sessions',
            style: TextStyle(
              color: isDark ? AppColors.grey500 : AppColors.grey400,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (tabIndex == 0)
            Text(
              'Tap + to create your first session',
              style: TextStyle(
                color: isDark ? AppColors.grey600 : AppColors.grey300,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 40, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          const Text('Could not load data', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900,
          )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'A sync or data error occurred. Please try again or check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            child: Text(_showTech ? 'Hide Diagnostics' : 'Show Technical Info',
              style: TextStyle(fontSize: 13, color: AppColors.grey400, fontWeight: FontWeight.w600)),
            onPressed: () => setState(() => _showTech = !_showTech),
          ),
          if (_showTech)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.grey600),
              ),
            ),
        ],
      ),
    );
  }
}
