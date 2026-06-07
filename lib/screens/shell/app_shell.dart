import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../core/services/interaction_service.dart';
import '../../core/services/notification_service.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;

// Tab screen imports
import '../dashboard/dashboard_screen.dart';
import '../practice/practice_range_screen.dart';
import '../analytics/analytics_screen.dart';
import '../marketplace/caddie_marketplace_screen.dart';
import '../social/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../provider/coach_sessions_screen.dart';
import '../provider/coach_students_screen.dart';
import '../provider/coach_drills_screen.dart';
import '../provider/coach_payment_management_screen.dart';

/// Main app shell with frosted glass bottom navigation bar and swipe navigation.
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

  static const _coachTabs = [
    ('/', 'Home', LucideIcons.home),
    ('/coach/sessions', 'Sessions', LucideIcons.calendar),
    ('/coach/students', 'Students', LucideIcons.users),
    ('/coach/drills', 'Drills', LucideIcons.target),
    ('/coach/payments', 'Payments', LucideIcons.creditCard),
    ('/profile', 'Profile', LucideIcons.user),
  ];

  /// Builds the screen widgets for each tab based on role.
  static List<Widget> _buildTabScreens(String? role) {
    if (role == 'coach') {
      return const [
        DashboardScreen(),
        CoachSessionsScreen(),
        CoachStudentsScreen(),
        CoachDrillsScreen(),
        CoachPaymentManagementScreen(),
        ProfileScreen(),
      ];
    } else {
      return const [
        DashboardScreen(),
        PracticeRangeScreen(),
        AnalyticsScreen(),
        CaddieMarketplaceScreen(),
        LeaderboardScreen(),
        ProfileScreen(),
      ];
    }
  }

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  late final db.AppDatabase _database;
  late PageController _pageController;
  bool _isPageAnimating = false;
  int _currentIndex = 0;
  String _goRouterLocation = '';

  @override
  void initState() {
    super.initState();
    _database = ref.read(databaseProvider);
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize Supabase Realtime
    ref.read(supabaseServiceProvider).init();

    // Initialize FCM
    ref.read(notificationServiceProvider).init();
    
    // Trigger "Instant Sync" catch-up on app start
    _triggerSync();
    _checkPendingInteractions();

    // Listen for network changes to trigger background sync
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        debugPrint('AppShell: Network online. Triggering background sync.');
        _triggerSync();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync initial route on load or deep link
    final location = GoRouterState.of(context).matchedLocation;
    if (_goRouterLocation.isEmpty || _goRouterLocation != location) {
      _goRouterLocation = location;
      final role = ref.read(userProfileProvider).valueOrNull?.role;
      final tabs = role == 'coach' ? AppShell._coachTabs : AppShell._playerTabs;
      final newIndex = tabs.indexWhere((t) => t.$1 == location);
      
      if (newIndex >= 0 && newIndex != _currentIndex) {
        _currentIndex = newIndex;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        } else {
          _pageController = PageController(initialPage: _currentIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingInteractions();
      _triggerSync();
    }
  }

  Future<void> _checkPendingInteractions() async {
    final service = ref.read(interactionServiceProvider);
    final pending = await service.getPendingInteractions();
    
    if (pending.isNotEmpty && mounted) {
      // ONLY prompt if the interaction happened recently (e.g. last 2 hours)
      // and we haven't prompted for it yet.
      final now = DateTime.now();
      final latest = pending.firstWhere((i) {
        final age = now.difference(i.timestamp);
        return i.lastPromptedAt == null && age.inHours < 2;
      }, orElse: () => pending.first);
      
      final age = now.difference(latest.timestamp);
      if (latest.lastPromptedAt == null && age.inHours < 2) {
        final provider = await (_database.select(_database.providers)..where((p) => p.userId.equals(latest.providerId))).get().then((rows) => rows.firstOrNull);
        if (provider != null) {
          _showBookingConfirmation(latest, provider.name);
        }
      }
    }
  }

  void _showBookingConfirmation(db.Interaction interaction, String providerName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Booking Confirmation'),
        content: Text('Did you successfully book $providerName for your round?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // They didn't book - Log an Inquiry for the caddie
              ref.read(supabaseServiceProvider).createInquiry(
                providerId: interaction.providerId,
                initiatedVia: interaction.type.toUpperCase() == 'CALL' ? 'CALL' : 'CHAT',
              );
              ref.read(interactionServiceProvider).dismissInteraction(interaction.id);
            },
            child: const Text('No, I didn\'t', style: TextStyle(color: Colors.redAccent)),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // Not Yet - Leave interaction as pending, it will prompt again later
            },
            child: const Text('Not Yet', style: TextStyle(color: AppColors.grey600)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              // Yes Booked - Create actual booking in backend
              ref.read(supabaseServiceProvider).createBooking(
                caddieId: interaction.providerId,
                initiatedVia: interaction.type.toUpperCase() == 'CALL' ? 'CALL' : 'CHAT',
              );
              ref.read(interactionServiceProvider).confirmBooking(interaction.id, true);
            },
            child: const Text('Yes, Booked', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkCompletedBookings(List<db.Booking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null || profile.role == 'caddie' || profile.role == 'coach') return;

    for (final booking in bookings) {
      if (booking.status == 'COMPLETED') {
        final key = 'rated_booking_${booking.id}';
        final hasRated = prefs.getBool(key) ?? false;
        
        if (!hasRated && mounted) {
          // Get provider details
          final providerProfile = await (_database.select(_database.userProfiles)..where((p) => p.uid.equals(booking.providerId))).getSingleOrNull();
          final providerName = providerProfile?.name ?? 'your Caddie';

          // Prevent duplicate dialogs
          await prefs.setBool(key, true);

          if (mounted) {
            _showRatingPrompt(booking, providerName);
          }
          break; // Only show one prompt at a time
        }
      }
    }
  }

  void _showRatingPrompt(db.Booking booking, String providerName) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5), // Semi-transparent overlay
      builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate your Round', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.grey900)),
                          Text('How was your experience with $providerName?', style: const TextStyle(color: AppColors.grey500, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(LucideIcons.x, color: AppColors.grey300),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text('RATING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isSelected = index < rating;
                    return GestureDetector(
                      onTap: () => setModalState(() => rating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            LucideIcons.star,
                            color: isSelected ? Colors.amber : AppColors.grey100,
                            size: 44,
                            fill: isSelected ? 1.0 : 0.0,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                const Text('LEAVE A NOTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.grey100),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: commentController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.grey900),
                      decoration: const InputDecoration(
                        hintText: 'Great caddie, highly recommended...',
                        hintStyle: TextStyle(color: AppColors.grey300),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: isSubmitting ? null : () async {
                      if (commentController.text.trim().isEmpty) return;
                      setModalState(() => isSubmitting = true);
                      
                      try {
                        final syncService = ref.read(syncServiceProvider);
                        final currentUser = ref.read(userProfileProvider).valueOrNull;
                        if (currentUser == null) throw Exception('Not logged in');

                        final review = db.Review(
                          id: 0,
                          providerId: booking.providerId,
                          playerId: currentUser.uid ?? 'unknown',
                          playerName: currentUser.name,
                          playerAvatar: currentUser.avatarUrl,
                          rating: rating,
                          comment: commentController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        await _database.into(_database.reviews).insert(db.ReviewsCompanion.insert(
                          providerId: review.providerId,
                          playerId: review.playerId,
                          playerName: review.playerName,
                          playerAvatar: drift.Value(review.playerAvatar),
                          rating: review.rating,
                          comment: review.comment,
                        ));

                        await syncService.syncReview(review);
                        await _database.updateProviderRating(booking.providerId);

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grey900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: isSubmitting 
                      ? const CupertinoActivityIndicator() 
                      : const Text('Submit Review', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
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
    // Listen for completed bookings to show rating prompt
    ref.listen<AsyncValue<List<db.Booking>>>(userBookingsProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _checkCompletedBookings(next.value!);
      }
    });

    final role = ref.watch(userProfileProvider.select((s) => s.valueOrNull?.role));
    final tabs = role == 'coach' ? AppShell._coachTabs 
        : AppShell._playerTabs;

    final tabScreens = AppShell._buildTabScreens(role);

    // Also check location here in case GoRouter pushes a new route over the same shell
    final location = GoRouterState.of(context).matchedLocation;
    if (_goRouterLocation != location) {
      _goRouterLocation = location;
      final newIndex = tabs.indexWhere((t) => t.$1 == location);
      if (newIndex >= 0 && newIndex != _currentIndex) {
        _currentIndex = newIndex;
        if (_pageController.hasClients && !_isPageAnimating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _pageController.jumpToPage(_currentIndex);
          });
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  if (!_isPageAnimating && index != _currentIndex) {
                    setState(() {
                      _currentIndex = index;
                    });
                    context.go(tabs[index].$1);
                  }
                },
                children: tabScreens.map((screen) => _KeepAliveWrapper(child: screen)).toList(),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 34,
              child: RepaintBoundary(
                child: FloatingGlassNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    if (index == _currentIndex) return;
                    
                    debugPrint('APPSHELL: Tapped tab $index -> ${tabs[index].$1}');
                    final distance = (index - _currentIndex).abs();
                    setState(() {
                      _currentIndex = index;
                    });
                    context.go(tabs[index].$1);
                    
                    if (distance > 1) {
                      _pageController.jumpToPage(index);
                    } else {
                      _isPageAnimating = true;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ).then((_) {
                        if (mounted) {
                          setState(() { _isPageAnimating = false; });
                        }
                      });
                    }
                  },
                  items: tabs,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a child widget in AutomaticKeepAlive so its state is preserved
/// when swiping to a different tab in the PageView.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
                    if (item.$2 == 'Home')
                      Image.asset(
                        'assets/images/final-logo-01.png',
                        width: 32,
                        height: 32,
                        color: isSelected ? AppColors.emerald700 : AppColors.grey400,
                        colorBlendMode: BlendMode.srcIn,
                      )
                    else
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
