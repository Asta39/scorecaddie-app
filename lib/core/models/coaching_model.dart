import 'package:flutter/material.dart';

class CoachingSession {
  final String id;
  final String coachId;
  final String name;
  final String? description;
  final int maxPlayers;
  final double pricePerSession;
  final int durationMinutes;
  final String location;
  final List<int> daysOfWeek;
  final String startTime;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String paymentTerms;
  final int weeks;
  final String sessionType;
  final String locationArea;
  final String targetSkillLevel;
  final String? prerequisites;
  final String? cancellationPolicy;
  final DateTime createdAt;
  final int enrollmentCount;

  CoachingSession({
    required this.id,
    required this.coachId,
    required this.name,
    this.description,
    required this.maxPlayers,
    required this.pricePerSession,
    required this.durationMinutes,
    required this.location,
    required this.daysOfWeek,
    required this.startTime,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentTerms,
    required this.weeks,
    required this.sessionType,
    required this.locationArea,
    required this.targetSkillLevel,
    this.prerequisites,
    this.cancellationPolicy,
    required this.createdAt,
    this.enrollmentCount = 0,
  });

  double get price => pricePerSession;

  factory CoachingSession.fromJson(Map<String, dynamic> json) {
    try {
      final startDateStr = json['start_date'] as String?;
      final startDate = startDateStr != null ? DateTime.parse(startDateStr) : DateTime.now();
      
      final weeks = (json['weeks'] as num?)?.toInt() ?? 4;
      // end_date may not exist in DB; compute from start_date + weeks
      final endDateStr = json['end_date'] as String?;
      final endDate = endDateStr != null
          ? DateTime.parse(endDateStr)
          : startDate.add(Duration(days: weeks * 7));

      return CoachingSession(
        id: (json['id'] as String?) ?? '',
        coachId: (json['coach_id'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Untitled Session',
        description: json['description'] as String?,
        maxPlayers: (json['max_players'] as num?)?.toInt() ?? 10,
        pricePerSession: (json['price_per_session'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
        location: (json['location'] as String?) ?? 'Unknown Location',
        daysOfWeek: (json['days_of_week'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        startTime: (json['start_time'] as String?) ?? '10:00',
        startDate: startDate,
        endDate: endDate,
        status: (json['status'] as String?) ?? 'pending',
        paymentTerms: (json['payment_terms'] as String?) ?? 'upfront',
        weeks: weeks,
        sessionType: (json['session_type'] as String?) ?? 'Group',
        locationArea: (json['location_area'] as String?) ?? 'Driving Range',
        targetSkillLevel: (json['target_skill_level'] as String?) ?? 'All',
        prerequisites: json['prerequisites'] as String?,
        cancellationPolicy: json['cancellation_policy'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
        enrollmentCount: (json['enrollment_count'] as num?)?.toInt() ?? 0,
        );
        } catch (e, _) {
      debugPrint('COACHING_SESSION_PARSE_ERROR: $e\nData: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'name': name,
      'description': description,
      'max_players': maxPlayers,
      'price_per_session': pricePerSession,
      'duration_minutes': durationMinutes,
      'location': location,
      'days_of_week': daysOfWeek,
      'start_time': startTime,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'status': status,
      'payment_terms': paymentTerms,
      'weeks': weeks,
      'session_type': sessionType,
      'location_area': locationArea,
      'target_skill_level': targetSkillLevel,
      'prerequisites': prerequisites,
      'cancellation_policy': cancellationPolicy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SessionOccurrence {
  final String id;
  final String sessionId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int? durationRecordedMinutes;
  final String status;

  SessionOccurrence({
    required this.id,
    required this.sessionId,
    required this.date,
    this.startTime,
    this.endTime,
    this.actualStart,
    this.actualEnd,
    this.durationRecordedMinutes,
    required this.status,
  });

  factory SessionOccurrence.fromJson(Map<String, dynamic> json) {
    try {
      return SessionOccurrence(
        id: (json['id'] as String?) ?? '',
        sessionId: (json['session_id'] as String?) ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        actualStart: json['actual_start'] != null ? DateTime.parse(json['actual_start']) : null,
        actualEnd: json['actual_end'] != null ? DateTime.parse(json['actual_end']) : null,
        durationRecordedMinutes: (json['duration_recorded_minutes'] as num?)?.toInt(),
        status: (json['status'] as String?) ?? 'scheduled',
      );
    } catch (e) {
      debugPrint('SESSION_OCCURRENCE_PARSE_ERROR: $e\nData: $json');
      rethrow;
    }
  }
}

class SessionAttendance {
  final String id;
  final String occurrenceId;
  final String playerId;
  final bool isPresent;
  final DateTime createdAt;

  SessionAttendance({
    required this.id,
    required this.occurrenceId,
    required this.playerId,
    required this.isPresent,
    required this.createdAt,
  });

  factory SessionAttendance.fromJson(Map<String, dynamic> json) {
    return SessionAttendance(
      id: json['id'] as String,
      occurrenceId: json['occurrence_id'] as String,
      playerId: json['player_id'] as String,
      isPresent: json['is_present'] as bool,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SessionEnrollment {
  final String id;
  final String sessionId;
  final String playerId;
  final DateTime enrolledAt;
  final double amountPaid;
  final String paymentStatus;
  final String? paymentMethod;
  final String status;
  final String? playerName;
  final String? playerAvatar;

  SessionEnrollment({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.enrolledAt,
    required this.amountPaid,
    required this.paymentStatus,
    this.paymentMethod,
    required this.status,
    this.playerName,
    this.playerAvatar,
  });

  factory SessionEnrollment.fromJson(Map<String, dynamic> json) {
    try {
      return SessionEnrollment(
        id: (json['id'] as String?) ?? '',
        sessionId: (json['session_id'] as String?) ?? '',
        playerId: (json['player_id'] as String?) ?? '',
        enrolledAt: json['enrolled_at'] != null ? DateTime.parse(json['enrolled_at']) : DateTime.now(),
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: (json['payment_status'] as String?) ?? 'pending',
        paymentMethod: json['payment_method'] as String?,
        status: (json['status'] as String?) ?? 'enrolled',
        playerName: json['player_name'] as String?,
        playerAvatar: json['player_avatar'] as String?,
      );
    } catch (e) {
      debugPrint('SESSION_ENROLLMENT_PARSE_ERROR: $e\nData: $json');
      rethrow;
    }
  }
}

