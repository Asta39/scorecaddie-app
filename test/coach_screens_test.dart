import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:score_caddie/core/database/database.dart' as db;
import 'package:score_caddie/core/models/coaching_model.dart';
import 'package:score_caddie/core/services/coaching_service.dart';
import 'package:score_caddie/core/services/notification_service.dart';
import 'package:score_caddie/providers/app_providers.dart';
import 'package:score_caddie/screens/provider/coach_dashboard_screen.dart';
import 'package:score_caddie/screens/provider/coach_drills_screen.dart';
import 'package:score_caddie/screens/provider/coach_payment_management_screen.dart';
import 'package:score_caddie/screens/provider/coach_sessions_screen.dart';
import 'package:score_caddie/screens/provider/coach_students_screen.dart';
import 'package:score_caddie/screens/provider/session_details_screen.dart';
import 'package:score_caddie/screens/provider/session_form.dart';

/// Renders every coach screen at phone sizes, with and without data. Any
/// layout overflow or exception fails the test. Set `COACH_SHOTS=<dir>` to
/// also write a PNG of each.
final _shots = Platform.environment['COACH_SHOTS'];
final _frame = GlobalKey();
final _now = DateTime.now();

CoachingSession _session(String id, String name, {int enrolled = 4, String status = 'active'}) => CoachingSession(
      id: id,
      coachId: 'c1',
      name: name,
      description: 'Bunkers, chips and pitches until they stop scaring you.',
      maxPlayers: 6,
      pricePerSession: 1500,
      durationMinutes: 90,
      location: 'Karen Country Club',
      daysOfWeek: const [2, 4, 6],
      startTime: '14:00:00',
      startDate: _now.subtract(const Duration(days: 14)),
      endDate: _now.add(const Duration(days: 28)),
      status: status,
      paymentTerms: 'upfront',
      weeks: 6,
      sessionType: 'Group',
      locationArea: 'Chipping Green',
      targetSkillLevel: 'All',
      createdAt: _now,
      enrollmentCount: enrolled,
    );

SessionEnrollment _enrol(String id, String name, double paid, String status, {int daysAgo = 3}) => SessionEnrollment(
      id: id,
      sessionId: 's1',
      playerId: 'p$id',
      enrolledAt: _now.subtract(Duration(days: daysAgo)),
      amountPaid: paid,
      paymentStatus: status,
      status: 'active',
      playerName: name,
    );

final _enrollments = [
  _enrol('1', 'Mercy Njeri Wambui-Otieno', 1500, 'fully_paid'),
  _enrol('2', 'Amani Otieno', 500, 'partial'),
  _enrol('3', 'Joy Nduta', 0, 'pending', daysAgo: 20),
];

class _FakeCoaching extends CoachingService {
  _FakeCoaching(this.full) : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));
  final bool full;

  @override
  Future<List<SessionEnrollment>> getSessionEnrollments(String sessionId) async => full ? _enrollments : [];

  @override
  Future<List<SessionOccurrence>> getSessionOccurrences(String sessionId) async => full
      ? [
          SessionOccurrence(id: 'o1', sessionId: sessionId, date: _now.subtract(const Duration(days: 2)), startTime: '14:00:00', endTime: '15:30:00', status: 'completed'),
          SessionOccurrence(id: 'o2', sessionId: sessionId, date: _now, startTime: '14:00:00', endTime: '15:30:00', status: 'in_progress'),
          SessionOccurrence(id: 'o3', sessionId: sessionId, date: _now.add(const Duration(days: 2)), startTime: '14:00:00', endTime: '15:30:00', status: 'upcoming'),
        ]
      : [];

  @override
  Future<List<SessionAttendance>> getAttendanceForOccurrence(String occurrenceId) async =>
      [SessionAttendance(id: 'a1', occurrenceId: occurrenceId, playerId: 'p1', isPresent: true, createdAt: _now)];
}

db.UserProfile _coach() => db.UserProfile(
      id: 1,
      uid: 'c1',
      name: 'njeri kamau',
      handicapOrigin: 'manual',
      isProvisional: false,
      provisionalRounds: 0,
      units: 'yards',
      themeMode: 'dark',
      privacyLevel: 'public',
      badgesJson: '[]',
      role: 'coach',
      profileComplete: true,
      pfpVerified: false,
      providerStatus: 'AVAILABLE',
      createdAt: _now,
      updatedAt: _now,
    );

List<Override> _overrides(bool full) => [
      coachingServiceProvider.overrideWithValue(_FakeCoaching(full)),
      userProfileProvider.overrideWith((ref) => Stream.value(_coach())),
      hasUnreadProvider.overrideWith((ref) => Stream.value(false)),
      coachSessionsProvider.overrideWith((ref) async => full
          ? [_session('s1', 'Short game in 6 weeks'), _session('s2', 'Driver fundamentals for new golfers', enrolled: 6, status: 'full')]
          : <CoachingSession>[]),
      coachStudentsProvider.overrideWith((ref) async => full
          ? [
              for (final e in _enrollments)
                {
                  'player_id': e.playerId,
                  'payment_status': e.paymentStatus,
                  'profile': {'id': e.playerId, 'name': e.playerName},
                  'coaching_sessions': {'name': 'Short game in 6 weeks'},
                },
            ]
          : <Map<String, dynamic>>[]),
      coachProfileStatsProvider.overrideWith((ref) async => {'rating': 4.9, 'students': full ? 3 : 0, 'views': 120, 'activity': 2}),
      coachRealtimeProfileProvider.overrideWith((ref) => Stream.value(<String, dynamic>{})),
      coachRevenueBreakdownProvider.overrideWith((ref) async => full ? {'MPESA': 48500.0, 'CASH': 13000.0, 'BANK': 6500.0} : <String, double>{}),
      coachDrillTemplatesProvider.overrideWith((ref) async => full
          ? [
              {'id': 'd1', 'name': 'Gate putting', 'category': 'Putting', 'difficulty': 'Beginner', 'drill_steps': [{'count': 3}]},
            ]
          : <Map<String, dynamic>>[]),
      coachAssignmentsProvider.overrideWith((ref) async => full
          ? [
              {'player': {'name': 'Joy Nduta'}, 'drill': {'name': 'Gate putting'}, 'assigned_at': _now.toIso8601String()},
            ]
          : <Map<String, dynamic>>[]),
    ];

Future<void> _loadFonts() async {
  for (final (family, file) in [('SourGummy', 'SourGummy-Variable.ttf'), ('Manrope', 'Manrope-Variable.ttf')]) {
    await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file'))).load();
  }
}

Future<void> _render(WidgetTester tester, String name, Widget screen, Size size, bool full) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: _overrides(full),
    child: MaterialApp(home: RepaintBoundary(key: _frame, child: screen)),
  ));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull, reason: '$name threw');
  if (_shots != null) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 100));
    final boundary = _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async => (await (await boundary.toImage(pixelRatio: 2)).toByteData(format: ui.ImageByteFormat.png))!);
    File('$_shots/${name}_${full ? 'full' : 'empty'}_${size.width.toInt()}.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  }
  // Unmount and let entrance/idle timers run out.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  setUpAll(_loadFonts);

  final screens = <String, Widget Function()>{
    'home': () => const CoachDashboardScreen(),
    'sessions': () => const CoachSessionsScreen(),
    'session': () => const SessionDetailsScreen(sessionId: 's1'),
    'create': () => const SessionForm(),
    'edit': () => SessionForm(session: _session('s1', 'Short game in 6 weeks')),
    'students': () => const CoachStudentsScreen(),
    'drills': () => const CoachDrillsScreen(),
    'payments': () => const CoachPaymentManagementScreen(),
  };

  for (final size in const [Size(375, 812), Size(360, 640)]) {
    for (final full in [true, false]) {
      for (final MapEntry(key: name, value: build) in screens.entries) {
        testWidgets('$name ${full ? 'with data' : 'empty'} at ${size.width.toInt()}', (tester) async {
          await _render(tester, name, build(), size, full);
        });
      }
    }
  }
}
