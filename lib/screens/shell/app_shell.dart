import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/services/interaction_service.dart';
import '../../core/services/notification_service.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/booking_check_sheet.dart';
import '../../widgets/top_notification.dart';
import 'package:intl/intl.dart';
import '../onboarding/ob_glass.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

// Tab screen imports
import '../dashboard/dashboard_screen.dart';
import '../practice/practice_range_screen.dart';
import '../analytics/analytics_screen.dart';
import '../marketplace/caddie_marketplace_screen.dart';
import '../profile/profile_screen.dart';
import '../provider/coach_sessions_screen.dart';
import '../provider/coach_students_screen.dart';
import '../provider/coach_drills_screen.dart';
import '../provider/coach_payment_management_screen.dart';
import '../social/club_community_screen.dart';
import '../play/play_screen.dart';

/// Main app shell with frosted glass bottom navigation bar and swipe navigation.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _playerTabs = [
    ('/', 'Today', LucideIcons.house),
    ('/play', 'Play', LucideIcons.flag),
    ('/analytics', 'Stats', LucideIcons.chartColumn),
    ('/competitions', 'Club', LucideIcons.users),
    ('/profile', 'You', LucideIcons.circleUserRound),
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
      return const [DashboardScreen(), CoachSessionsScreen(), CoachStudentsScreen(), CoachDrillsScreen(), CoachPaymentManagementScreen(), ProfileScreen()];
    } else {
      return const [DashboardScreen(), PlayScreen(), AnalyticsScreen(), ClubCommunityScreen(), ProfileScreen()];
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

    // Initialize Push Notifications
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

  bool _askingAboutBooking = false;

  /// After the player comes back from calling or messaging a pro, asks
  /// whether they booked. Only asks about a recent contact they actually
  /// left the app for, and "not yet" waits a while before asking again.
  Future<void> _checkPendingInteractions() async {
    if (_askingAboutBooking) return;
    final service = ref.read(interactionServiceProvider);
    final interaction = await service.dueForPrompt();
    if (interaction == null || !mounted) return;

    final provider = await (_database.select(_database.providers)..where((p) => p.userId.equals(interaction.providerId))).get().then((rows) => rows.firstOrNull);
    if (provider == null || !mounted) return;

    _askingAboutBooking = true;
    // Counts as asked straight away, so leaving the sheet open and switching
    // apps doesn't stack a second one.
    await service.dismissInteraction(interaction.id);
    final viaCall = interaction.type.toLowerCase() == 'call';
    final via = viaCall ? 'CALL' : 'CHAT';
    try {
      if (!mounted) return;
      final answer = await askAboutBooking(
        context,
        name: provider.name,
        avatarUrl: provider.avatarUrl,
        viaCall: viaCall,
        contactedAt: interaction.timestamp,
      );
      switch (answer) {
        case BookedFor(when: final at):
          await ref.read(supabaseServiceProvider).createBooking(caddieId: interaction.providerId, initiatedVia: via, when: at);
          await service.confirmBooking(interaction.id, true);
          if (mounted) TopNotification.showSuccess(context, '${provider.name.split(' ').first} is booked for ${DateFormat('EEE d MMM').format(at)}');
        case DidNotBook():
          await ref.read(supabaseServiceProvider).createInquiry(providerId: interaction.providerId, initiatedVia: via);
          await service.confirmBooking(interaction.id, false);
        case NotYet():
          break; // Asked again after the snooze (see dueForPrompt).
      }
    } catch (e) {
      debugPrint('Booking check failed: $e');
      if (mounted) TopNotification.showError(context, 'Couldn\'t save that. Check your connection and try again.');
    } finally {
      _askingAboutBooking = false;
    }
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
    int rating = 0;
    final commentController = TextEditingController();
    bool isSubmitting = false;
    const words = ['', 'Poor', 'Not great', 'Fine', 'Good', 'Brilliant'];
    final first = providerName.split(' ').first;

    showObSheet(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => ObSheet(
          title: 'How was $first?',
          subtitle: 'Your round is done. A quick rating helps other golfers choose.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  button: true,
                  label: '$i star${i == 1 ? '' : 's'}',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setModalState(() => rating = i);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: i <= rating ? 1.12 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: Icon(LucideIcons.star, size: 42, color: i <= rating ? Ob.lime : Ob.creamA(.2), fill: i <= rating ? 1 : 0),
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(rating == 0 ? 'Tap a star' : words[rating], textAlign: TextAlign.center, style: Ob.body(14, weight: FontWeight.w800, color: rating == 0 ? Ob.creamA(.45) : Ob.lime)),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              cursorColor: Ob.lime,
              style: Ob.body(15, weight: FontWeight.w600),
              decoration: obInput('Anything to add? (optional)', hint: 'Read the greens well, kept the pace up…'),
            ),
            const SizedBox(height: 16),
            ObButton(
              onPressed: rating == 0 || isSubmitting
                  ? null
                  : () async {
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
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) TopNotification.showSuccess(this.context, 'Thanks. Your rating is on $first\'s profile.');
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (mounted) TopNotification.showError(this.context, 'Couldn\'t send your rating. Try again.');
                      }
                    },
              child: Text(isSubmitting ? 'Sending…' : 'Send rating', style: Ob.label(16, weight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text('Skip', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.55))),
            ),
          ]),
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
    final tabs = role == 'coach' ? AppShell._coachTabs : AppShell._playerTabs;

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

    // go_router 14 ShellRoute doesn't see dialogs and sheets on the root
    // navigator, so Android back would close the app instead of them.
    return BackButtonListener(
      onBackButtonPressed: () async {
        final root = Navigator.of(context, rootNavigator: true);
        if (!root.canPop()) return false;
        // maybePop so screens with their own PopScope (e.g. stepped flows)
        // get to handle back first.
        await root.maybePop();
        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
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
                left: 14,
                right: 14,
                bottom: 20,
                child: RepaintBoundary(
                  child: ObGlassDock(
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
                        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut).then((_) {
                          if (mounted) {
                            setState(() {
                              _isPageAnimating = false;
                            });
                          }
                        });
                      }
                    },
                    items: [for (final t in tabs) (t.$2, t.$3)],
                    accent: role == 'coach' ? const Color(0xFFF5C531) : Ob.lime,
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
