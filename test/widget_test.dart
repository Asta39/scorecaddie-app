import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_caddie/app.dart';

Widget createTestApp() {
  return const ProviderScope(child: ScoreCaddieApp());
}

void main() {
  testWidgets('App smoke test - app loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();
    expect(find.byType(ScoreCaddieApp), findsOneWidget);
    // Advance the mock clock past the 2-second splash transition timer to avoid pending timer leak
    await tester.pump(const Duration(seconds: 3));
  }, timeout: const Timeout(Duration(seconds: 10)));
}
