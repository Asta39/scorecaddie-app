
class PlayerCoachingSummary {
  final CoachingOccurrenceDetail? nextSession;
  final List<CoachingOccurrenceDetail> upcoming;
  final List<CoachingOccurrenceDetail> past;
  final int upcomingCount;

  PlayerCoachingSummary({
    this.nextSession,
    required this.upcoming,
    required this.past,
    required this.upcomingCount,
  });

  factory PlayerCoachingSummary.empty() => PlayerCoachingSummary(
    upcoming: [],
    past: [],
    upcomingCount: 0,
  );
}

class CoachingOccurrenceDetail {
  final String id;
  final DateTime date;
  final String sessionName;
  final String coachName;
  final String? coachAvatar;
  final String location;
  final String status;
  final String startTime;
  final int durationMinutes;
  final String coachId;
  final String sessionId;
  final bool? attended;

  CoachingOccurrenceDetail({
    required this.id,
    required this.date,
    required this.sessionName,
    required this.coachName,
    this.coachAvatar,
    required this.location,
    required this.status,
    required this.startTime,
    required this.durationMinutes,
    required this.coachId,
    required this.sessionId,
    this.attended,
  });

  factory CoachingOccurrenceDetail.fromSupabase(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>;
    final coach = session['coach'] as Map<String, dynamic>;
    
    return CoachingOccurrenceDetail(
      id: json['id'] as String,
      date: DateTime.parse(json['date']),
      sessionName: session['name'] as String,
      coachName: coach['name'] as String,
      coachAvatar: coach['avatarUrl'] as String? ?? coach['photoUrl'] as String?,
      location: session['location'] as String,
      status: json['status'] as String,
      startTime: session['start_time'] as String,
      durationMinutes: (session['duration_minutes'] as num).toInt(),
      coachId: coach['id'] as String? ?? '',
      sessionId: (json['session_id'] as String?) ?? '',
      attended: _parseAttended(json['attendance'], json['playerId']),
    );
  }

  static bool? _parseAttended(dynamic attendanceObj, dynamic expectedPlayerId) {
    if (attendanceObj == null) return null;
    if (attendanceObj is List) {
      if (expectedPlayerId != null) {
        final match = attendanceObj.firstWhere(
          (a) => a['player_id'] == expectedPlayerId,
          orElse: () => null,
        );
        if (match != null) {
          return match['is_present'] as bool?;
        }
      } else if (attendanceObj.isNotEmpty) {
        return attendanceObj[0]['is_present'] as bool?;
      }
    }
    return null;
  }
}
