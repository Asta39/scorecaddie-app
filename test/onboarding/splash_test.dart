import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:score_caddie/core/models/auth_user.dart';
import 'package:score_caddie/providers/auth_providers.dart';
import 'package:score_caddie/screens/auth/splash_screen.dart';

/// Plays the whole splash timeline frame by frame at phone sizes: every
/// easing input stays in range, nothing overflows, and it hands off to '/'.
void main() {
  for (final size in const [Size(360, 740), Size(393, 852)]) {
    testWidgets('splash plays through and leaves at ${size.width.toInt()}pt', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/splash', routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/', builder: (_, _) => const Text('home', textDirection: TextDirection.ltr)),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [authStateProvider.overrideWith((ref) => Stream<AuthUser?>.value(null))],
        child: MaterialApp.router(routerConfig: router),
      ));
      for (var ms = 0; ms <= 5600; ms += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('home'), findsOneWidget);
    });
  }
}
