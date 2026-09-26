import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/models/auth_user.dart';
import 'package:score_caddie/core/services/profile_service.dart';
import 'package:score_caddie/providers/auth_providers.dart';
import 'package:score_caddie/screens/auth/auth_screen.dart';
import 'package:score_caddie/screens/onboarding/ob_screens.dart';
import 'package:score_caddie/screens/onboarding/ob_style.dart';
import 'package:score_caddie/screens/onboarding/ob_widgets.dart';
import 'package:score_caddie/screens/onboarding/onboarding_flow_screen.dart';

/// Walks the setup flow at real phone sizes. Any layout overflow fails the
/// test. Set `OB_SHOTS=<dir>` to also write a PNG of every step.
class _FakeProfiles extends ProfileService {
  _FakeProfiles(super.ref);

  @override
  Future<bool> isUsernameAvailable(String name) async => name != 'taken';
}

final _shots = Platform.environment['OB_SHOTS'];
final _frame = GlobalKey();

Future<void> _loadFonts() async {
  for (final (family, file) in [('SourGummy', 'SourGummy-Variable.ttf'), ('Manrope', 'Manrope-Variable.ttf')]) {
    await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file'))).load();
  }
}

Future<void> _settle(WidgetTester tester, [int ms = 1600]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shots == null) return;
  // Let the bots' images decode, then draw a frame with them.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await _settle(tester, 300);
  final boundary = _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    return (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });
  File('$_shots/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _pumpFlow(WidgetTester tester, Size size, {ObEntry entry = ObEntry.role}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream<AuthUser?>.value(null)),
      profileServiceProvider.overrideWith((ref) => _FakeProfiles(ref)),
    ],
    child: MaterialApp(
      home: RepaintBoundary(key: _frame, child: OnboardingFlowScreen(entry: entry)),
    ),
  ));
  await _settle(tester);
}

Future<void> _pumpAlone(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: RepaintBoundary(
      key: _frame,
      child: Scaffold(backgroundColor: Ob.bg, body: DefaultTextStyle(style: Ob.textBase, child: SafeArea(child: child))),
    ),
  ));
  await _settle(tester, 2800);
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await _settle(tester, 200);
}

void main() {
  setUpAll(_loadFonts);

  for (final (label, size) in [('small', const Size(360, 740)), ('large', const Size(393, 852))]) {
    testWidgets('player path lays out at $label size', (tester) async {
      await _pumpFlow(tester, size);
      expect(find.text('How do you play?'), findsOneWidget);
      await _shot(tester, '$label-1-role');

      await tester.tap(find.text('Player'));
      await _settle(tester);
      expect(find.text('A player! Let’s set you up.'), findsOneWidget);
      await _shot(tester, '$label-2-role-player');
      await _continue(tester);

      expect(find.text('Username'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ab');
      await _settle(tester, 300);
      expect(find.text('At least 3 characters'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'taken');
      await _settle(tester, 900);
      expect(find.text('@taken is taken. Try taken_ke?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ian_love');
      await _settle(tester, 900);
      expect(find.text('@ian_love is yours'), findsOneWidget);
      expect(find.text('Love it, @ian_love.'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await _settle(tester, 300);
      await _shot(tester, '$label-3-name');
      await _continue(tester);

      expect(find.text('What’s your handicap index?'), findsOneWidget);
      await _shot(tester, '$label-4-handicap');
      await tester.tap(find.text('I don’t have one yet'));
      await _settle(tester);
      expect(find.text('No stress. We’ll work it out.'), findsOneWidget);
      await _shot(tester, '$label-5-handicap-unknown');
      await _continue(tester);

      expect(find.text('Finish setup'), findsOneWidget);
      await _shot(tester, '$label-6-club');
      await _dispose(tester);
    });

    testWidgets('coach path lays out at $label size', (tester) async {
      await _pumpFlow(tester, size);
      await tester.tap(find.text('Coach'));
      await _settle(tester);
      expect(find.text('A coach! Let’s build your profile.'), findsOneWidget);
      await _shot(tester, '$label-c1-role-coach');
      await _continue(tester);

      await tester.enterText(find.byType(TextField), 'coach_ken');
      await _settle(tester, 900);
      FocusManager.instance.primaryFocus?.unfocus();
      await _continue(tester);

      expect(find.text('What do you coach?'), findsOneWidget);
      await tester.tap(find.text('Putting'));
      await tester.tap(find.text('Short game'));
      await _settle(tester);
      await _shot(tester, '$label-c2-focus');
      await _continue(tester);

      await tester.tap(find.text('Beginners'));
      await _settle(tester);
      await _shot(tester, '$label-c3-audience');
      await _continue(tester);

      await tester.tap(find.text('Driving Range'));
      await tester.enterText(find.byType(TextField), '2500');
      await _settle(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await _shot(tester, '$label-c4-service');
      await _continue(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '0712345678');
      await tester.enterText(fields.at(1), '6');
      await tester.enterText(fields.at(2), 'PGA pro, patient with beginners.');
      await _settle(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await _shot(tester, '$label-c5-about');
      await _continue(tester);

      expect(find.text('Add a clear photo of your face.'), findsOneWidget);
      await tester.tap(find.text('Are you certified?'));
      await _settle(tester);
      await _shot(tester, '$label-c6-photo');
      await _dispose(tester);
    });
  }

  testWidgets('guide dozes after 20s idle and wakes on tap', (tester) async {
    await _pumpFlow(tester, const Size(393, 852));
    await tester.pump(const Duration(seconds: 22));
    await _settle(tester);
    expect(find.text('Zzz… tap anywhere to wake me.'), findsOneWidget);
    await _shot(tester, 'large-7-asleep');
    await tester.tapAt(const Offset(200, 700));
    await _settle(tester);
    expect(find.text('How do you play?'), findsOneWidget);
    await _dispose(tester);
  });

  const clubs = [
    ('Muthaiga Golf Club', 'Nairobi'),
    ('Karen Country Club', 'Nairobi'),
    ('Royal Nairobi Golf Club', 'Nairobi'),
    ('Limuru Country Club', 'Limuru'),
    ('Nyeri Golf Club', 'Nyeri'),
    ('Vipingo Ridge', 'Kilifi'),
  ];

  for (final (label, size) in [('small', const Size(360, 740)), ('large', const Size(393, 852))]) {
    testWidgets('club grid fits two-line names at $label size', (tester) async {
      await _pumpAlone(
        tester,
        size,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Builder(
            builder: (context) => GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: ((size.width - 58) / 2) / ObClubTile.extent(context),
              children: [
                for (final (i, (name, town)) in clubs.indexed)
                  ObClubTile(name: name, town: town, selected: i == 2, highlightTown: i == 0, onTap: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await _shot(tester, '$label-8-clubs');
      await _dispose(tester);
    });

    testWidgets('welcome lays out at $label size', (tester) async {
      await _pumpAlone(
        tester,
        size,
        ObWelcome(
          bot: ObBot.ball,
          username: 'ian_love',
          leftLabel: 'Handicap index',
          leftValue: '18.4',
          clubName: 'Royal Nairobi Golf Club',
          onTeeOff: () {},
        ),
      );
      expect(find.text('Welcome to the clubhouse, @ian_love'), findsOneWidget);
      await _shot(tester, '$label-9-welcome');
      await _dispose(tester);
    });
  }

  for (final (label, size) in [('small', const Size(360, 740)), ('large', const Size(393, 852))]) {
    testWidgets('intro and sign-in lay out at $label size', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: RepaintBoundary(key: _frame, child: const AuthScreen()))));
      await _settle(tester);
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await _shot(tester, '$label-a1-intro');
      await tester.tap(find.text('Next'));
      await _settle(tester);
      await tester.tap(find.text('Next'));
      await _settle(tester);
      expect(find.text('Get started'), findsOneWidget);
      await _shot(tester, '$label-a2-intro-last');
      await tester.tap(find.text('Get started'));
      await _settle(tester);
      expect(find.text('Continue with email'), findsOneWidget);
      await _shot(tester, '$label-a3-signin');
      await tester.tap(find.textContaining('Create an account'));
      await _settle(tester);
      expect(find.text('Create account'), findsOneWidget);
      await _shot(tester, '$label-a4-register');
      await _dispose(tester);
    });
  }
}
