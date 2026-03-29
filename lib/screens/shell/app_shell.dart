import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_card.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/services/interaction_service.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;


/// Main app shell with frosted glass bottom navigation bar.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _playerTabs = [
    ('/', 'Home', LucideIcons.home),
    ('/practice', 'Practice', LucideIcons.target),
    ('/analytics', 'Stats', LucideIcons.barChart2),
    ('/caddie', 'Caddie', LucideIcons.briefcase),
    ('/leaderboard', 'Leaderboard', LucideIcons.trophy),
    ('/profile', 'Profile', LucideIcons.user),
  ];

  static const _providerTabs = [
    ('/', 'Home', LucideIcons.home),
    ('/profile', 'Profile', LucideIcons.user),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  late final db.AppDatabase _database;

  @override
  void initState() {
    super.initState();
    _database = ref.read(databaseProvider);
    WidgetsBinding.instance.addObserver(this);
    // Trigger "Instant Sync" catch-up on app start
    _triggerSync();
    _checkPendingInteractions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingInteractions();
    }
  }

  Future<void> _checkPendingInteractions() async {
    final service = ref.read(interactionServiceProvider);
    final pending = await service.getPendingInteractions();
    
    // Only prompt if we just came back from a contact attempt (flag is true)
    // AND there is a pending interaction that hasn't been prompted yet.
    if (pending.isNotEmpty && mounted) {
      final latest = pending.firstWhere((i) => i.lastPromptedAt == null, orElse: () => pending.first);
      
      // If we haven't prompted them for this specific interaction yet
      if (latest.lastPromptedAt == null) {
        final provider = await (_database.select(_database.providers)..where((p) => p.userId.equals(latest.providerId))).get().then((rows) => rows.firstOrNull);
        if (provider != null) {
          _showBookingConfirmation(latest, provider.name);
        }
      }
    }
  }

  void _showBookingConfirmation(db.Interaction interaction, String providerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Did you book with $providerName?', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        content: Text('We noticed you contacted $providerName. Did you manage to secure a booking?'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(interactionServiceProvider).ignoreInteraction(interaction.id);
              Navigator.pop(context);
            },
            child: const Text('No, I didn\'t', style: TextStyle(color: AppColors.grey500)),
          ),
          TextButton(
            onPressed: () {
              ref.read(interactionServiceProvider).dismissInteraction(interaction.id);
              Navigator.pop(context);
            },
            child: const Text('Not yet', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () {
              ref.read(interactionServiceProvider).confirmBooking(interaction.id, true);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Great! Booking with $providerName confirmed.'),
                    backgroundColor: AppColors.emerald700,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Booked!'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSync() async {
    try {
      await ref.read(syncServiceProvider).syncAllPending();
    } catch (e) {
      debugPrint('Initial sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider.select((s) => s.valueOrNull?.role));
    final isProvider = role == 'caddie' || role == 'coach';
    final tabs = isProvider ? AppShell._providerTabs : AppShell._playerTabs;

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = tabs.indexWhere((t) => t.$1 == location);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              left: 20,
              right: 20,
              bottom: 34,
              child: FloatingGlassNavBar(
                currentIndex: currentIndex >= 0 ? currentIndex : 0,
                onTap: (index) {
                  debugPrint('APPSHELL: Tapped tab $index -> ${tabs[index].$1}');
                  context.go(tabs[index].$1);
                },
                items: tabs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<(String, String, IconData)> items;

  const FloatingGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        // Simulated frosted glass: semi-transparent white + soft shadow
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: AppColors.grey200.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.white.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      color: isSelected ? AppColors.emerald700 : AppColors.grey400,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: isSelected ? AppColors.emerald700 : AppColors.grey400,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
