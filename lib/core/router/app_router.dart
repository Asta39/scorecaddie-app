import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/scorecard/course_select_screen.dart';
import '../../screens/scorecard/scoring_screen.dart';
import '../../screens/scorecard/group_scoring_screen.dart';
import '../../screens/scorecard/add_course_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/history/round_detail_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/practice/practice_range_screen.dart';
import '../../screens/practice/practice_session_screen.dart';
import '../../screens/practice/session_summary_screen.dart';
import '../../screens/practice/practice_analytics_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/profile/clubs_screen.dart';
import '../../screens/social/friends_screen.dart';
import '../../screens/practice/ai_shot_analysis_screen.dart';
import '../../screens/practice/shot_summary_screen.dart';
import '../../screens/practice/custom_drill_builder_screen.dart';
import '../../core/services/friend_service.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/achievements/achievements_gallery_screen.dart';
import '../../screens/social/leaderboard_screen.dart';
import '../../screens/social/group_round_lobby.dart';
import '../../screens/profile/help_screen.dart';
import '../../core/cloud/group_sync_service.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/provider_onboarding_screen.dart';
import '../../screens/auth/player_onboarding_screen.dart';
import '../../screens/marketplace/caddie_marketplace_screen.dart';
import '../../screens/marketplace/provider_preview_screen.dart';
import '../../screens/provider/provider_dashboard_screen.dart';
import '../../screens/auth/loading_transition_screen.dart';
import '../../screens/rounds/rounds_history_screen.dart';
import '../../screens/social/player_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isOnboardingRoute = state.matchedLocation == '/select-role' ||
          state.matchedLocation == '/player-onboarding' ||
          state.matchedLocation == '/provider-onboarding';

      if (authState.isLoading) return null;

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/auth';
      }
      
      // User is logged in — wait for the profile stream to emit before deciding
      final profileState = ref.read(userProfileProvider);
      if (profileState.isLoading) return null;
      final profile = profileState.valueOrNull;
      final isProfileComplete = profile != null && profile.profileComplete;

      if (isLoggedIn && isAuthRoute) {
        // After login/signup, route based on profile completeness
        return isProfileComplete ? '/' : '/select-role';
      }

      // If user somehow navigates to a main route without a complete profile,
      // redirect them to onboarding (but allow onboarding routes themselves)
      if (isLoggedIn && !isProfileComplete && !isAuthRoute && !isOnboardingRoute) {
        return '/select-role';
      }

      return null;
    },
    routes: [
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
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) {
              final profileState = ref.read(userProfileProvider);
              
              if (profileState.hasValue) {
                return const NoTransitionPage(
                  child: DashboardScreen(),
                );
              }

              if (profileState.hasError) {
                return NoTransitionPage(child: Scaffold(body: Center(child: Text('Error: ${profileState.error}'))));
              }

              return const NoTransitionPage(child: LoadingTransitionScreen());
            },
          ),
          GoRoute(
            path: '/caddie',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CaddieMarketplaceScreen(),
            ),
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
            path: '/achievements',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AchievementsGalleryScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/practice/session/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PracticeSessionScreen(sessionId: id);
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
        path: '/practice/ai-analysis',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          return AIShotAnalysisScreen(sessionId: sessionId != null ? int.parse(sessionId) : null);
        },
      ),
      GoRoute(
        path: '/practice/ai-summary',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ShotSummaryScreen(
            analysis: extra['analysis'],
            videoPath: extra['videoPath'],
            clubId: extra['clubId'],
            shotId: extra['shotId'],
            sessionId: extra['sessionId'],
          );
        },
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
        path: '/scoring',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          if (extra.containsKey('groupRoundId')) {
            return GroupScoringScreen(
              courseId: extra['courseId'],
              groupRoundId: extra['groupRoundId'],
              mode: extra['mode'] ?? 'INDIVIDUAL_DEVICES',
            );
          }
          return ScoringScreen(
            courseId: extra['courseId'],
            holesPlayed: extra['holesPlayed'] ?? 18,
            tee: extra['tee'] ?? 'White',
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
        path: '/friend/add/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return FriendAddHandleScreen(uid: uid);
        },
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
    _process();
  }

  Future<void> _process() async {
    final query = await FirebaseFirestore.instance
        .collection('group_rounds')
        .where('roundCode', isEqualTo: widget.roundCode.toUpperCase())
        .limit(1)
        .get();

    if (mounted) {
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final success = await ref.read(groupSyncServiceProvider).joinGroupRound(widget.roundCode);
        if (success) {
          context.pushReplacement('/round/lobby/${doc.id}');
        } else {
          setState(() {
            _isProcessing = false;
            _message = 'Failed to join round.';
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
          _message = 'Round not found.';
        });
      }
      
      if (!_isProcessing && _message.contains('Failed')) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) const CircularProgressIndicator(color: AppColors.emerald700),
            const SizedBox(height: 24),
            Text(_message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
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
            if (_isProcessing) const CircularProgressIndicator(color: AppColors.emerald700),
            const SizedBox(height: 24),
            Text(_message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
