import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/widgets/booking_check_sheet.dart';

void main() {
  Future<BookingAnswer?> run(WidgetTester tester, Future<void> Function() act) async {
    BookingAnswer? answer;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => answer = await askAboutBooking(context,
                name: 'Tarly Mwangi', viaCall: true, contactedAt: DateTime.now().subtract(const Duration(minutes: 12))),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await act();
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('asks by first name and says how long ago', (tester) async {
    await run(tester, () async {
      expect(find.text('Did you book Tarly?'), findsOneWidget);
      expect(find.text('You called Tarly 12 min ago.'), findsOneWidget);
    });
  });

  testWidgets('yes, then a day, saves a booking for that day', (tester) async {
    final answer = await run(tester, () async {
      await tester.tap(find.text('Yes, I booked'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomorrow'));
      await tester.pump();
      await tester.tap(find.text('Save booking'));
    });
    expect(answer, isA<BookedFor>());
    final when = (answer as BookedFor).when;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect([when.year, when.month, when.day], [tomorrow.year, tomorrow.month, tomorrow.day]);
  });

  testWidgets('not yet and no are reported', (tester) async {
    expect(await run(tester, () => tester.tap(find.text('Not yet'))), isA<NotYet>());
    expect(await run(tester, () => tester.tap(find.text('No'))), isA<DidNotBook>());
  });
}
