import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/models/coaching_model.dart';
import 'package:score_caddie/screens/provider/coach_dashboard_screen.dart';

CoachingSession _s({List<int> days = const [DateTime.wednesday], String at = '14:00', DateTime? start, DateTime? end}) => CoachingSession(
      id: 's1',
      coachId: 'c1',
      name: 'Short game',
      maxPlayers: 6,
      pricePerSession: 1500,
      durationMinutes: 90,
      location: 'Range',
      daysOfWeek: days,
      startTime: at,
      startDate: start ?? DateTime(2026, 9, 1),
      endDate: end ?? DateTime(2026, 10, 31),
      status: 'active',
      paymentTerms: 'upfront',
      weeks: 6,
      sessionType: 'group',
      locationArea: 'Range',
      targetSkillLevel: 'all',
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  // 2026-09-30 is a Wednesday.
  test('later today when the start time has not passed', () {
    expect(nextOccurrence(_s(), DateTime(2026, 9, 30, 9)), DateTime(2026, 9, 30, 14));
  });

  test('next week once today\'s slot has passed', () {
    expect(nextOccurrence(_s(), DateTime(2026, 9, 30, 15)), DateTime(2026, 10, 7, 14));
  });

  test('waits for the start date', () {
    expect(nextOccurrence(_s(start: DateTime(2026, 10, 10)), DateTime(2026, 9, 30, 9)), DateTime(2026, 10, 14, 14));
  });

  test('null after the programme ends', () {
    expect(nextOccurrence(_s(end: DateTime(2026, 10, 5)), DateTime(2026, 9, 30, 15)), isNull);
  });
}
