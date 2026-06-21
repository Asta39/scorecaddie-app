import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/scorecard/course_select_screen.dart';
import '../../screens/scorecard/course_intel_screen.dart';
import '../../screens/scorecard/scoring_screen.dart';
import '../../screens/scorecard/group_scoring_screen.dart';
import '../../screens/scorecard/group_certification_screen.dart';
import '../../screens/scorecard/add_course_screen.dart';
import '../../screens/scanner/scanner_camera_screen.dart';
import '../../screens/scanner/scanner_processing_screen.dart';
import '../../screens/scanner/scanner_review_screen.dart';
import '../../screens/history/round_detail_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/practice/practice_range_screen.dart';
import '../../screens/practice/practice_session_screen.dart';
import '../../screens/practice/session_summary_screen.dart';
import '../../screens/practice/practice_analytics_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/profile/clubs_screen.dart';
import '../../screens/profile/tee_time_reminder_screen.dart';
import '../../screens/social/friends_screen.dart';
import '../../screens/practice/custom_drill_builder_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/achievements/achievements_gallery_screen.dart';
import '../../screens/social/leaderboard_screen.dart';
import '../../screens/social/group_round_lobby.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../screens/profile/help_screen.dart';
import '../../core/cloud/group_sync_service.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/provider_onboarding_screen.dart';
import '../../screens/auth/player_onboarding_screen.dart';
import '../../screens/marketplace/coach_public_sessions_screen.dart';
import '../../screens/marketplace/session_booking_screen.dart';
import '../../screens/marketplace/caddie_marketplace_screen.dart';
import '../../screens/marketplace/provider_preview_screen.dart';
import '../../screens/auth/loading_transition_screen.dart';
import '../../screens/rounds/rounds_history_screen.dart';
import '../../widgets/loading_spinner.dart';
import '../../screens/social/player_profile_screen.dart';
import '../../screens/social/chat_screen.dart';
import '../../screens/provider/create_session_screen.dart';
import '../../screens/provider/edit_session_screen.dart';
import '../../screens/provider/coach_sessions_screen.dart';
import '../../screens/provider/session_details_screen.dart';
import '../../screens/provider/coach_payment_management_screen.dart';
import '../../screens/provider/coach_students_screen.dart';
import '../../screens/provider/coach_drills_screen.dart';
import '../../screens/provider/coach_drill_builder_screen.dart';
import '../../screens/marketplace/player_session_details_screen.dart';
import '../../screens/competitions/competitions_list_screen.dart';
import '../../screens/competitions/competition_detail_screen.dart';
import '../../screens/competitions/competition_scan_submit_screen.dart';

import '../../core/models/coaching_model.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool? _lastIsLoggedIn;
  bool? _lastProfileComplete;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) {
      final isLoggedIn = next.valueOrNull != null;
      if (isLoggedIn != _lastIsLoggedIn) {
        _lastIsLoggedIn = isLoggedIn;
        notifyListeners();
      }
    });
    
    _ref.listen(userProfileProvider, (previous, next) {
      if (next.isLoading) return; // Don't notify while loading initial data
      
      final isComplete = next.valueOrNull?.profileComplete ?? false;
      if (isComplete != _lastProfileComplete) {
        _lastProfileComplete = isComplete;
        notifyListeners();
      }
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isSplashRoute = state.matchedLocation == '/splash';

      // 0. If we are on the splash screen, let it finish its animation
      if (isSplashRoute) return null;

      final isAuthRoute = state.matchedLocation == '/auth';
      final isOnboardingRoute = state.matchedLocation == '/select-role' ||
          state.matchedLocation == '/player-onboarding' ||
          state.matchedLocation == '/provider-onboarding';

      // 1. If we are still determining auth state, don't redirect yet
      if (authState.isLoading) return null;

      // 2. Not logged in -> go to /auth
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/auth';
      }
      
      // 3. User is logged in — explicitly wait for profile data before deciding next step
      final profileState = ref.read(userProfileProvider);
      if (profileState.isLoading) {
        // Stay on current page while profile is loading
        return null; 
      }

      final profile = profileState.valueOrNull;
      final isProfileComplete = profile?.profileComplete ?? false;

      // 4. Authenticated user on /auth route
      if (isAuthRoute) {
        // Even if profile is null, go to /select-role which will call ensureProfile
        // and handle the redirect back to home if profile is already complete
        return isProfileComplete ? '/' : '/select-role';
      }

      // 5. Profile is complete — if on onboarding route, go home
      if (isProfileComplete) {
        if (isOnboardingRoute) {
          return '/';
        }
        return null;
      }

      // 6. Profile is NOT complete
      if (!isOnboardingRoute) {
        // RESILIENCY GUARD: Only force selection if we are at root or just logged in.
        // If the user has navigated to a deep page (like /create-session), they probably 
        // had a complete profile that just transiently went null during a sync.
        final isAtRootOrAuth = state.matchedLocation == '/' || state.matchedLocation == '/auth';
        if (isAtRootOrAuth) {
          return '/select-role';
        }
        
        // Otherwise, do NOT redirect. Stay on current page to avoid flickering/looping.
        return null;
      }
      return null; // Stay on the current onboarding route
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingTransitionScreen(),
      ),
      GoRoute(
        path: '/select-role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/provider-onboarding',
        builder: (context, state) => const ProviderOnboardingScreen(),
      ),
      GoRoute(
        path: '/player-onboarding',
        builder: (context, state) => const PlayerOnboardingScreen(),
      ),
      GoRoute(
        path: '/marketplace/provider/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProviderPreviewScreen(providerUserId: id);
        },
      ),
      GoRoute(
        path: '/marketplace/coach/:coachId/sessions',
        builder: (context, state) => CoachPublicSessionsScreen(
          coachId: state.pathParameters['coachId']!,
        ),
      ),
      GoRoute(
        path: '/marketplace/coach/:coachId/session/:sessionId/book',
        builder: (context, state) => SessionBookingScreen(
          coachId: state.pathParameters['coachId']!,
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(otherUserId: id);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/caddie',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final role = extra?['role'] as String? ?? 'all';
              return NoTransitionPage(
                child: CaddieMarketplaceScreen(initialRole: role),
              );
            },
          ),
          GoRoute(
            path: '/practice',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PracticeRangeScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaderboardScreen(),
            ),
          ),
          GoRoute(
            path: '/competitions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CompetitionsListScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/coach/sessions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachSessionsScreen(),
            ),
          ),
          GoRoute(
            path: '/coach/payments',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachPaymentManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/coach/students',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachStudentsScreen(),
            ),
          ),
          GoRoute(
            path: '/coach/drills',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachDrillsScreen(),
            ),
          ),
        ],

      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsGalleryScreen(),
      ),
      GoRoute(
        path: '/competitions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompetitionDetailScreen(competitionId: id);
        },
      ),
      GoRoute(
        path: '/competitions/:id/scan/:entryId',
        builder: (context, state) {
          final competitionId = state.pathParameters['id']!;
          final entryId = state.pathParameters['entryId']!;
          return CompetitionScanSubmitScreen(
            competitionId: competitionId,
            entryId: entryId,
          );
        },
      ),
      GoRoute(
        path: '/create-session',
        builder: (context, state) => const CreateSessionScreen(),
      ),
      GoRoute(
        path: '/coach/session/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SessionDetailsScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/coach/session/:id/edit',
        builder: (context, state) {
          final session = state.extra as CoachingSession;
          return EditSessionScreen(session: session);
        },
      ),
      GoRoute(
        path: '/coach/drills/new',
        builder: (context, state) => const CoachDrillBuilderScreen(),
      ),
      GoRoute(
        path: '/coaching/session/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PlayerSessionDetailsScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/practice/session/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final isVoice = state.uri.queryParameters['isVoice'] == 'true';
          return PracticeSessionScreen(sessionId: id, isVoice: isVoice);
        },
      ),
      GoRoute(
        path: '/practice/summary/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SessionSummaryScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/practice/analytics',
        builder: (context, state) => const PracticeAnalyticsScreen(),
      ),
      GoRoute(
        path: '/practice/drills/new',
        builder: (context, state) => const CustomDrillBuilderScreen(),
      ),
      GoRoute(
        path: '/profile/bag',
        builder: (context, state) => const ClubsScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/tee-time-reminders',
        builder: (context, state) => const TeeTimeRemindersScreen(),
      ),
      GoRoute(
        path: '/profile/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) {
          final role = state.extra as String?;
          return HelpScreen(role: role);
        },
      ),
      GoRoute(
        path: '/select-course',
        builder: (context, state) => const CourseSelectScreen(),
      ),
      GoRoute(
        path: '/scorecard/intel/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CourseIntelScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/group-scoring',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return GroupScoringScreen(
            courseId: extra['courseId'] is String ? int.parse(extra['courseId']) : (extra['courseId'] as int),
            groupRoundId: extra['groupRoundId'],
            mode: extra['mode'] ?? 'INDIVIDUAL_DEVICES',
          );
        },
      ),

      GoRoute(
        path: '/scoring',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          if (extra.containsKey('groupRoundId')) {
            return GroupScoringScreen(
              courseId: extra['courseId'] is String ? int.parse(extra['courseId']) : (extra['courseId'] as int),
              groupRoundId: extra['groupRoundId'],
              mode: extra['mode'] ?? 'INDIVIDUAL_DEVICES',
            );
          }
          return ScoringScreen(
            courseId: extra['courseId'],
            holesPlayed: extra['holesPlayed'] ?? 18,
            teeId: extra['teeId'],
            courseHandicap: extra['courseHandicap'] ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/round/:roundId',
        builder: (context, state) {
          final roundId = int.parse(state.pathParameters['roundId']!);
          return RoundDetailScreen(roundId: roundId);
        },
      ),
      GoRoute(
        path: '/rounds-history',
        builder: (context, state) => const RoundsHistoryScreen(),
      ),
      GoRoute(
        path: '/round/lobby/:id',
        builder: (context, state) => GroupRoundLobbyScreen(roundId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/round/join/:code',
        builder: (context, state) => JoinRoundHandleScreen(roundCode: state.pathParameters['code']!),
      ),
      GoRoute(
        path: '/courses/add',
        builder: (context, state) => const AddCourseScreen(),
      ),
      GoRoute(
        path: '/scanner/camera',
        builder: (context, state) => const ScannerCameraScreen(),
      ),
      GoRoute(
        path: '/scanner/processing',
        builder: (context, state) => const ScannerProcessingScreen(),
      ),
      GoRoute(
        path: '/scanner/review',
        builder: (context, state) => const ScannerReviewScreen(),
      ),
      GoRoute(
        path: '/friend/add/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return FriendAddHandleScreen(uid: uid);
        },
      ),
      GoRoute(
        path: '/group/certification/:id',
        builder: (context, state) => GroupCertificationScreen(groupRoundId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/player/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'];
          return PlayerProfileScreen(userId: id, name: name);
        },
      ),
    ],
  );
});

class JoinRoundHandleScreen extends ConsumerStatefulWidget {
  final String roundCode;
  const JoinRoundHandleScreen({super.key, required this.roundCode});

  @override
  ConsumerState<JoinRoundHandleScreen> createState() => _JoinRoundHandleScreenState();
}

class _JoinRoundHandleScreenState extends ConsumerState<JoinRoundHandleScreen> {
  bool _isProcessing = true;
  String _message = 'Applying to join round...';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _selectTeeAndJoin());
  }

  Future<void> _selectTeeAndJoin() async {
    final supabase = Supabase.instance.client;
    
    final roundQuery = await supabase.from('GroupRound')
        .select('id, courseId, courseName')
        .eq('roundCode', widget.roundCode.toUpperCase())
        .maybeSingle();
        
    if (roundQuery == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _message = 'Round not found or already completed.';
        });
      }
      return;
    }

    final int courseId = int.tryParse(roundQuery['courseId'].toString()) ?? 0;
    final String courseName = roundQuery['courseName'] ?? 'Golf Course';

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _JoinTeeSetupModal(
          courseId: courseId,
          courseName: courseName,
          onTeeSelected: (teeId) async {
            final profile = ref.read(userProfileProvider).valueOrNull;
            final hIndex = profile?.handicap;
            
            final success = await ref.read(groupSyncServiceProvider).joinGroupRound(
              widget.roundCode,
              teeId: teeId,
              handicapBefore: hIndex,
            );
            
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
            }
            
            if (success) {
              if (mounted) {
                context.pushReplacement('/round/lobby/${roundQuery['id']}');
              }
            } else {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                  _message = 'Failed to join round.';
                });
              }
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing)
              const LoadingSpinner(size: 80)
            else
              const Icon(LucideIcons.alertCircle, color: Colors.orange, size: 48),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (!_isProcessing) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w800)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _JoinTeeSetupModal extends ConsumerStatefulWidget {
  final int courseId;
  final String courseName;
  final Function(int) onTeeSelected;

  const _JoinTeeSetupModal({
    required this.courseId,
    required this.courseName,
    required this.onTeeSelected,
  });

  @override
  ConsumerState<_JoinTeeSetupModal> createState() => _JoinTeeSetupModalState();
}

class _JoinTeeSetupModalState extends ConsumerState<_JoinTeeSetupModal> {
  int? _selectedTeeId;
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final teesAsync = ref.watch(courseTeesProvider(widget.courseId));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Join Group Round', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(widget.courseName, style: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          const Text('Select Your Tee Box', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          teesAsync.when(
            data: (tees) {
              if (tees.isEmpty) return const Text('No tees found for this course.');
              if (_selectedTeeId == null && tees.isNotEmpty) {
                Future.microtask(() => setState(() => _selectedTeeId = tees.first.id));
              }
              return Column(
                children: tees.map((tee) {
                  final isSelected = _selectedTeeId == tee.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTeeId = tee.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.grey900 : AppColors.grey50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.grey900 : AppColors.grey200),
                        ),
                        child: Row(
                          children: [
                            Text(tee.name, style: TextStyle(color: isSelected ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Text('Rating: ${tee.courseRating}', style: TextStyle(color: isSelected ? Colors.white70 : AppColors.grey500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingSpinner(size: 60),
            error: (e, _) => Text('Error loading tees: $e'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _isJoining || _selectedTeeId == null ? null : () {
                setState(() => _isJoining = true);
                widget.onTeeSelected(_selectedTeeId!);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isJoining 
                ? const LoadingSpinner(size: 24)
                : const Text('Confirm & Join', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class FriendAddHandleScreen extends ConsumerStatefulWidget {
  final String uid;
  const FriendAddHandleScreen({super.key, required this.uid});

  @override
  ConsumerState<FriendAddHandleScreen> createState() => _FriendAddHandleScreenState();
}

class _FriendAddHandleScreenState extends ConsumerState<FriendAddHandleScreen> {
  bool _isProcessing = true;
  String _message = 'Processing friend request...';

  @override
  void initState() {
    super.initState();
    _process();
  }

  Future<void> _process() async {
    final success = await ref.read(friendServiceProvider).addFriend(widget.uid);
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _message = success ? 'Friend added successfully!' : 'Failed to add friend. ID may be invalid.';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/profile/friends');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) const LoadingSpinner(size: 80),
            const SizedBox(height: 24),
            Text(_message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
