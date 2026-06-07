import 'package:add_2_calendar/add_2_calendar.dart';

class CalendarHelper {
  static void addSessionToCalendar({
    required String sessionName,
    required String location,
    required DateTime date,
    required String startTime,
    required int durationMinutes,
  }) {
    final startTimeParts = startTime.split(':');
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );
    
    final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

    final Event event = Event(
      title: 'Golf Session: $sessionName',
      description: 'Coaching session at $location',
      location: location,
      startDate: startDateTime,
      endDate: endDateTime,
    );

    Add2Calendar.addEvent2Cal(event);
  }
}
