import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/coaching_model.dart';
import '../utils/poll_stream.dart';
import '../models/coaching_summary.dart';

class CoachingService {
  final SupabaseClient _supabase;

  CoachingService(this._supabase);

  Future<void> createSession({
    required String name,
    required String description,
    required int maxPlayers,
    required double price,
    required int durationMinutes,
    required String location,
    required Set<int> daysOfWeek,
    required TimeOfDay startTime,
    required int weeks,
    required String paymentTerms,
    required DateTime startDate,
    String sessionType = 'Group',
    String locationArea = 'Driving Range',
    String targetSkillLevel = 'All',
    String prerequisites = '',
    String cancellationPolicy = '24h notice required',
    List<PaymentMethod> paymentMethods = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to create a session');

    final startTimeString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
    final daysList = daysOfWeek.toList();

    // Call the RPC function for atomic creation
    debugPrint('CoachingService: Creating session for coach ${user.id}');
    debugPrint('CoachingService: Params: name=$name, days=$daysList, start=$startTimeString, weeks=$weeks, startDate=$startDate');
    
    try {
      final response = await _supabase.rpc('create_coaching_session', params: {
        'p_coach_id': user.id,
        'p_name': name,
        'p_description': description,
        'p_max_players': maxPlayers,
        'p_price_per_session': price,
        'p_duration_minutes': durationMinutes,
        'p_location': location,
        'p_days_of_week': daysList,
        'p_start_time': startTimeString,
        'p_weeks': weeks,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_payment_terms': paymentTerms,
        'p_session_type': sessionType,
        'p_location_area': locationArea,
        'p_target_skill_level': targetSkillLevel,
        'p_prerequisites': prerequisites,
        'p_cancellation_policy': cancellationPolicy,
      });
      debugPrint('CoachingService: Create RPC Success. ID: $response');
      if (response != null) await setPaymentMethods('$response', paymentMethods);
    } catch (e) {
      debugPrint('CoachingService: Create RPC Error: $e');
      rethrow;
    }
  }

  Future<void> updateSession({
    required String sessionId,
    required String name,
    required String description,
    required int maxPlayers,
    required double price,
    required int durationMinutes,
    required String location,
    required Set<int> daysOfWeek,
    required TimeOfDay startTime,
    required int weeks,
    required String paymentTerms,
    required DateTime startDate,
    String sessionType = 'Group',
    String locationArea = 'Driving Range',
    String targetSkillLevel = 'All',
    String prerequisites = '',
    String cancellationPolicy = '24h notice required',
    List<PaymentMethod> paymentMethods = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to update a session');

    final startTimeString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
    final daysList = daysOfWeek.toList();

    // Call the RPC function for atomic update
    await _supabase.rpc('update_coaching_session', params: {
      'p_session_id': sessionId,
      'p_coach_id': user.id,
      'p_name': name,
      'p_description': description,
      'p_max_players': maxPlayers,
      'p_price_per_session': price,
      'p_duration_minutes': durationMinutes,
      'p_location': location,
      'p_days_of_week': daysList,
      'p_start_time': startTimeString,
      'p_weeks': weeks,
      'p_start_date': startDate.toIso8601String().split('T')[0],
      'p_payment_terms': paymentTerms,
      'p_session_type': sessionType,
      'p_location_area': locationArea,
      'p_target_skill_level': targetSkillLevel,
      'p_prerequisites': prerequisites,
      'p_cancellation_policy': cancellationPolicy,
    });
    await setPaymentMethods(sessionId, paymentMethods);
  }

  /// Saves how players pay for a session (numbers they copy into M-Pesa).
  Future<void> setPaymentMethods(String sessionId, List<PaymentMethod> methods) async {
    await _supabase
        .from('coaching_sessions')
        .update({'payment_methods': [for (final m in methods) m.toJson()]})
        .eq('id', sessionId);
  }

  Future<Map<String, dynamic>?> getCoachProfile(String coachId) async {
    try {
      final response = await _supabase
          .from('User')
          .select('id, name, avatarUrl, role, bio, experience, price, hasCertification, certificationName, certificationUrl, coachingLocation, specializations, targetAudience, phone, whatsapp, rating, totalReviews, views')
          .eq('id', coachId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('CoachingService: Error fetching coach profile: $e');
      return null;
    }
  }

  /// Who has joined a session, for the player-facing booking screen.
  ///
  /// Goes through get_session_roster, which returns names and avatars only.
  /// Players can no longer read raw enrollment rows for sessions they aren't
  /// in (those carry amount_paid / payment_method). Shaped like the old
  /// enrollment rows ({'User': {...}}) so the screen is unchanged.
  Future<List<Map<String, dynamic>>> getSessionRoster(String sessionId) async {
    final rows = await _supabase.rpc('get_session_roster', params: {'p_session_id': sessionId});
    return List<Map<String, dynamic>>.from(rows as List).map((r) => {
          'player_id': r['player_id'],
          'User': {'id': r['player_id'], 'name': r['name'], 'avatarUrl': r['avatarUrl']},
        }).toList();
  }

  /// Names and photos for these user ids, from the public profile view.
  ///
  /// Used instead of embedding User in a select: those embeds rely on
  /// foreign keys that were re-pointed in the database, and a missing one
  /// fails the whole query.
  Future<Map<String, Map<String, dynamic>>> _people(Iterable<String?> ids) async {
    final want = ids.whereType<String>().where((s) => s.isNotEmpty).toSet().toList();
    if (want.isEmpty) return {};
    final rows = await _supabase.from('UserPublic').select('id, name, avatarUrl').inFilter('id', want);
    return {for (final r in rows as List) '${r['id']}': Map<String, dynamic>.from(r)};
  }

  /// Adds `key: {id, name, avatarUrl}` to each row, looked up by `row[idKey]`.
  Future<List<Map<String, dynamic>>> _withPeople(List<Map<String, dynamic>> rows, String idKey, String key) async {
    final people = await _people(rows.map((r) => r[idKey] as String?));
    return [for (final r in rows) {...r, key: people[r[idKey]]}];
  }

  Future<List<Map<String, dynamic>>> getSessionEnrollmentsWithDetails(String sessionId) async {
    try {
      final response = await _supabase
          .from('session_enrollments')
          .select()
          .eq('session_id', sessionId);
      return _withPeople(List<Map<String, dynamic>>.from(response), 'player_id', 'User');
    } catch (e) {
      debugPrint('CoachingService: Error fetching session enrollments: $e');
      return [];
    }
  }

  Future<void> cancelSession(String sessionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to cancel a session');

    await _supabase.rpc('cancel_coaching_session', params: {
      'p_session_id': sessionId,
      'p_coach_id': user.id,
    });
  }

  Future<List<CoachingSession>> getCoachSessions([String? coachId]) async {
    final effectiveId = coachId ?? _supabase.auth.currentUser?.id;
    if (effectiveId == null) return [];

    try {
      // 1. Refresh statuses
      await _supabase.rpc('refresh_session_statuses');

      debugPrint('CoachingService: Fetching sessions for $effectiveId');
      final response = await _supabase
          .from('coaching_sessions')
          .select('*, session_enrollments(count)')
          .eq('coach_id', effectiveId)
          .order('created_at', ascending: false);

      debugPrint('CoachingService: Found ${(response as List).length} sessions');
      return (response as List).map((json) {
        final map = Map<String, dynamic>.from(json);
        final enrollmentData = map['session_enrollments'] as List?;
        map['enrollment_count'] = (enrollmentData != null && enrollmentData.isNotEmpty) 
            ? (enrollmentData[0]['count'] ?? 0) 
            : 0;
        return CoachingSession.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('CoachingService ERROR: Failed to fetch coach sessions: $e');
      return [];
    }
  }

  Future<CoachingSession?> getSessionById(String sessionId) async {
    try {
      final response = await _supabase
          .from('coaching_sessions')
          .select('*, session_enrollments(count)')
          .eq('id', sessionId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      final map = Map<String, dynamic>.from(response);
      final enrollmentData = map['session_enrollments'] as List?;
      map['enrollment_count'] = (enrollmentData != null && enrollmentData.isNotEmpty) 
          ? (enrollmentData[0]['count'] ?? 0) 
          : 0;
          
      return CoachingSession.fromJson(map);
    } catch (e) {
      debugPrint('CoachingService: Error fetching session $sessionId: $e');
      return null;
    }
  }

  Future<List<SessionOccurrence>> getSessionOccurrences(String sessionId) async {
    final response = await _supabase
        .from('session_occurrences')
        .select()
        .eq('session_id', sessionId)
        .order('date', ascending: true);

    return (response as List).map((json) => SessionOccurrence.fromJson(json)).toList();
  }

  Stream<Map<String, dynamic>> watchCoachProfile(String coachId) {
    // Our own coach profile (coachId is the signed-in coach).
    return pollStream(() async {
      final row = await _supabase.rpc('my_profile');
      return row is Map && row['id'] == coachId ? Map<String, dynamic>.from(row) : <String, dynamic>{};
    });
  }

  Future<Map<String, dynamic>> getCoachProfileStats(String coachId) async {
    try {
      // 1. Get rating and views from User table
      final userResponse = await _supabase
          .from('User')
          .select('rating, views')
          .eq('id', coachId)
          .single();

      // 2. Get unique student count from session_enrollments
      final sessionsQuery = await _supabase.from('coaching_sessions').select('id').eq('coach_id', coachId);
      final sessionIds = (sessionsQuery as List).map((s) => s['id']).toList();
      
      if (sessionIds.isEmpty) {
        return {
          'rating': (userResponse['rating'] as num?)?.toDouble() ?? 5.0,
          'views': (userResponse['views'] as num?)?.toInt() ?? 0,
          'students': 0,
          'activity': 0,
        };
      }

      // Count distinct players, not enrollment rows — one player enrolled in
      // three of this coach's sessions is one student, not three.
      final studentsResponse = await _supabase
          .from('session_enrollments')
          .select('player_id')
          .inFilter('session_id', sessionIds);
      final uniqueStudents = (studentsResponse as List)
          .map((e) => e['player_id'])
          .whereType<String>()
          .toSet()
          .length;

      // 3. Get recent activity count (enrollments in last 30 days).
      // Must be scoped to this coach's sessions — without the session filter
      // this counted every enrollment on the platform.
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final activityResponse = await _supabase
          .from('session_enrollments')
          .select('id')
          .inFilter('session_id', sessionIds)
          .eq('status', 'active')
          .gt('enrolled_at', thirtyDaysAgo)
          .count(CountOption.exact);

      return {
        'rating': (userResponse['rating'] as num?)?.toDouble() ?? 5.0,
        'views': (userResponse['views'] as num?)?.toInt() ?? 0,
        'students': uniqueStudents,
        'activity': activityResponse.count,
      };
    } catch (e) {
      debugPrint('CoachingService: Error fetching coach stats: $e');
      return {'rating': 5.0, 'views': 0, 'students': 0, 'activity': 0};
    }
  }

  Future<Map<String, double>> getCoachRevenueBreakdown(String coachId) async {
    try {
      final sessionsQuery = await _supabase.from('coaching_sessions').select('id').eq('coach_id', coachId);
      final sessionIds = (sessionsQuery as List).map((s) => s['id']).toList();

      if (sessionIds.isEmpty) return {'CASH': 0, 'MPESA': 0, 'BANK': 0};

      final response = await _supabase
          .from('session_enrollments')
          .select('amount_paid, payment_method')
          .inFilter('session_id', sessionIds);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      
      double cash = 0, mpesa = 0, bank = 0;
      for (var item in data) {
        final amt = (item['amount_paid'] as num?)?.toDouble() ?? 0.0;
        final method = item['payment_method']?.toString().toUpperCase() ?? 'NONE';
        
        if (method == 'CASH') {
          cash += amt;
        } else if (method == 'MPESA') {
          mpesa += amt;
        } else if (method == 'BANK') {
          bank += amt;
        }
      }

      return {'CASH': cash, 'MPESA': mpesa, 'BANK': bank};
    } catch (e) {
      debugPrint('CoachingService: Error fetching revenue breakdown: $e');
      return {'CASH': 0, 'MPESA': 0, 'BANK': 0};
    }
  }

  Future<List<SessionEnrollment>> getSessionEnrollments(String sessionId) async {
    // Join with User to get real-time PFPs and names for the roster
    final response = await _supabase
        .from('session_enrollments')
        .select()
        .eq('session_id', sessionId)
        .order('enrolled_at', ascending: true);
    final rows = await _withPeople(List<Map<String, dynamic>>.from(response), 'player_id', 'User');

    return rows.map((json) {
      final map = Map<String, dynamic>.from(json);
      final userData = map['User'] as Map?;
      if (userData != null) {
        // Enrich with real-time data for the UI
        map['player_name'] = userData['name'];
        map['player_avatar'] = userData['avatarUrl'];
      }
      return SessionEnrollment.fromJson(map);
    }).toList();
  }

  Future<void> recordPayment({
    required String enrollmentId,
    required double amount,
    required String method,
    String? sessionId,
    String? playerId,
    String? reference,
    String? message,
  }) async {
    try {
      debugPrint('CoachingService: Recording payment of $amount for enrollment $enrollmentId');
      // The receipt first: if the M-Pesa code was already used, the unique
      // index stops a payment being counted twice before totals change.
      await _supabase.from('coaching_payments').insert({
        'enrollment_id': enrollmentId,
        'session_id': ?sessionId,
        'coach_id': _supabase.auth.currentUser!.id,
        'player_id': ?playerId,
        'amount': amount,
        'method': method,
        'reference': (reference == null || reference.isEmpty) ? null : reference.toUpperCase(),
        'message': (message == null || message.isEmpty) ? null : message,
      });
      await _supabase.rpc('record_payment', params: {
        'p_enrollment_id': enrollmentId,
        'p_amount': amount,
        'p_method': method,
      });
    } catch (e) {
      debugPrint('CoachingService ERROR: Failed to record payment: $e');
      rethrow;
    }
  }

  Future<void> updateOccurrenceStatus(String occurrenceId, String status) async {
    try {
      debugPrint('CoachingService: Updating occurrence $occurrenceId to status $status');
      if (status == 'completed') {
        debugPrint('CoachingService: Calling complete_occurrence RPC');
        await _supabase.rpc('complete_occurrence', params: {
          'p_occurrence_id': occurrenceId,
        });
        debugPrint('CoachingService: complete_occurrence RPC success');
        return;
      }

      final updates = {
        'status': status,
      };

      if (status == 'in_progress') {
        updates['actual_start'] = DateTime.now().toIso8601String();
      }

      debugPrint('CoachingService: Performing DB update with $updates');
      final response = await _supabase
          .from('session_occurrences')
          .update(updates)
          .eq('id', occurrenceId)
          .select();
      
      debugPrint('CoachingService: DB update response: $response');
    } catch (e) {
      debugPrint('CoachingService ERROR: updateOccurrenceStatus failed: $e');
      rethrow;
    }
  }

  Future<void> enrollInSession(String sessionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // 1. Call the atomic enrollment RPC which handles capacity checks
      final enrollmentId = await _supabase.rpc('enroll_player_in_session', params: {
        'p_session_id': sessionId,
        'p_player_id': user.id,
      });
      debugPrint('CoachingService: Enrolled successfully. ID: $enrollmentId');

      // No auto-friending: there's no chat to unlock, and friend rows
      // must start as a request the other person accepts.

    } catch (e) {
      debugPrint('CoachingService ENROLL_ERROR: $e');
      rethrow;
    }
  }

  // --- Drill Management (Phase 3) ---

  Future<String> createDrillTemplate({
    required String name,
    required String description,
    required String category,
    required String difficulty,
    required int durationMinutes,
    required List<Map<String, dynamic>> steps,
    String icon = 'target',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Auth required');

    // 1. Insert the drill template
    final drillResponse = await _supabase.from('drills').insert({
      'creator_id': user.id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'icon': icon,
      'is_template': true,
    }).select('id').single();

    final drillId = drillResponse['id'] as String;

    // 2. Insert the steps
    if (steps.isNotEmpty) {
      final stepsToInsert = steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return {
          'drill_id': drillId,
          'instruction': step['instruction'],
          'balls_required': step['balls'] ?? 10,
          'step_order': index,
        };
      }).toList();

      await _supabase.from('drill_steps').insert(stepsToInsert);
    }

    return drillId;
  }

  Future<void> updateDrillTemplate({
    required String drillId,
    required String name,
    required String description,
    required String category,
    required String difficulty,
    required int durationMinutes,
    required List<Map<String, dynamic>> steps,
    String icon = 'target',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Auth required');

    // 1. Update the drill metadata
    await _supabase.from('drills').update({
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'icon': icon,
    }).eq('id', drillId);

    // 2. Refresh steps: Delete old ones and insert new ones (simpler than syncing)
    await _supabase.from('drill_steps').delete().eq('drill_id', drillId);

    if (steps.isNotEmpty) {
      final stepsToInsert = steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return {
          'drill_id': drillId,
          'instruction': step['instruction'],
          'balls_required': step['balls'] ?? 10,
          'step_order': index,
        };
      }).toList();

      await _supabase.from('drill_steps').insert(stepsToInsert);
    }
  }

  Future<void> assignDrillToPlayer({
    required String drillId,
    required String playerId,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Auth required');

    await _supabase.from('drill_assignments').upsert({
      'drill_id': drillId,
      'coach_id': user.id,
      'player_id': playerId,
      'notes': notes,
      'status': 'active',
    });
  }

  Future<List<Map<String, dynamic>>> getCoachAssignments(String coachId) async {
    final response = await _supabase
        .from('drill_assignments')
        .select('''
          *,
          drill:drills(*)
        ''')
        .eq('coach_id', coachId)
        .order('assigned_at', ascending: false);
    return _withPeople(List<Map<String, dynamic>>.from(response), 'player_id', 'player');
  }

  Future<List<Map<String, dynamic>>> getAssignedDrills(String playerId) async {
    final response = await _supabase
        .from('drill_assignments')
        .select('''
          *,
          drill:drills(*)
        ''')
        .eq('player_id', playerId)
        .eq('status', 'active');
    return _withPeople(List<Map<String, dynamic>>.from(response), 'coach_id', 'coach');
  }

  Future<List<Map<String, dynamic>>> getCoachDrillTemplates(String coachId) async {
    final response = await _supabase
        .from('drills')
        .select('*, drill_steps(count)')
        .eq('creator_id', coachId)
        .eq('is_template', true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDrillSteps(String drillId) async {
    final response = await _supabase
        .from('drill_steps')
        .select()
        .eq('drill_id', drillId)
        .order('step_order', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveAttendance({
    required String occurrenceId,
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    // attendanceData should be List of {player_id: string, is_present: bool}
    final upserts = attendanceData.map((d) => {
      'occurrence_id': occurrenceId,
      'player_id': d['player_id'],
      'is_present': d['is_present'],
    }).toList();

    await _supabase
        .from('session_attendance')
        .upsert(upserts, onConflict: 'occurrence_id,player_id');
  }

  Future<List<SessionAttendance>> getAttendanceForOccurrence(String occurrenceId) async {
    final response = await _supabase
        .from('session_attendance')
        .select()
        .eq('occurrence_id', occurrenceId);
    
    return (response as List).map((json) => SessionAttendance.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getCoachEnrollments(String coachId) async {
    debugPrint('CoachingService: Fetching students for coach: $coachId');
    // This aggregates enrollments across all sessions for a coach, joining with User profiles
    final response = await _supabase
        .from('session_enrollments')
        .select('''
          *,
          coaching_sessions!inner(coach_id, name)
        ''')
        .eq('coaching_sessions.coach_id', coachId);
    return _withPeople(List<Map<String, dynamic>>.from(response), 'player_id', 'profile');
  }
  Future<List<Map<String, dynamic>>> getPlayerEnrollments(String playerId) async {
    debugPrint('CoachingService: Fetching enrollments for player: $playerId');
    final response = await _supabase
        .from('session_enrollments')
        .select('''
          *,
          coaching_sessions!inner(*)
        ''')
        .eq('player_id', playerId);
    final rows = List<Map<String, dynamic>>.from(response);
    final people = await _people(rows.map((r) => (r['coaching_sessions'] as Map?)?['coach_id'] as String?));
    return [
      for (final r in rows)
        {
          ...r,
          'coaching_sessions': {...(r['coaching_sessions'] as Map), 'coach': people[(r['coaching_sessions'] as Map)['coach_id']]},
        },
    ];
  }

  Future<PlayerCoachingSummary> getPlayerCoachingSummary(String playerId) async {
    try {
      debugPrint('CoachingService: Fetching detailed summary for player: $playerId');

      // 1. Get enrolled session IDs
      final enrollmentResponse = await _supabase
          .from('session_enrollments')
          .select('session_id')
          .eq('player_id', playerId);

      final sessionIds = (enrollmentResponse as List).map((e) => e['session_id'] as String).toList();
      debugPrint('COACHING_SERVICE: Found ${sessionIds.length} enrolled sessions for $playerId');

      if (sessionIds.isEmpty) {
        return PlayerCoachingSummary.empty();
      }

      // 2. Fetch occurrences for these sessions with joined data
      final response = await _supabase
          .from('session_occurrences')
          .select('''
            *,
            session:coaching_sessions!inner(
              name,
              location,
              duration_minutes,
              start_time,
              coach_id
            )
          ''')
          .inFilter('session_id', sessionIds)
          .order('date', ascending: true);

      final coaches = await _people((response as List).map((r) => (r['session'] as Map?)?['coach_id'] as String?));
      // The player's own roll marks, read on their own: the embed relied on a
      // foreign key that isn't there, and the player may not be allowed to
      // read attendance at all, which only means "not marked yet".
      final marks = <String, bool>{};
      try {
        final rows = await _supabase
            .from('session_attendance')
            .select('occurrence_id, is_present')
            .eq('player_id', playerId)
            .inFilter('occurrence_id', [for (final r in response) r['id']]);
        for (final r in rows as List) {
          marks['${r['occurrence_id']}'] = r['is_present'] == true;
        }
      } catch (_) {}
      final List<CoachingOccurrenceDetail> allOccurrences = response.map((json) {
        final map = Map<String, dynamic>.from(json);
        final session = Map<String, dynamic>.from(map['session'] as Map);
        session['coach'] = coaches[session['coach_id']];
        map['session'] = session;
        final mark = marks['${map['id']}'];
        map['attendance'] = mark == null ? null : [{'player_id': playerId, 'is_present': mark}];
        map['playerId'] = playerId;
        return CoachingOccurrenceDetail.fromSupabase(map);
      }).toList();

      final now = DateTime.now();
      final upcoming = allOccurrences.where((o) => o.date.isAfter(now) || DateUtils.isSameDay(o.date, now)).toList();
      final past = allOccurrences.where((o) => o.date.isBefore(now) && !DateUtils.isSameDay(o.date, now)).toList();

      // Sort past by most recent first
      past.sort((a, b) => b.date.compareTo(a.date));

      return PlayerCoachingSummary(
        nextSession: upcoming.isNotEmpty ? upcoming.first : null,
        upcoming: upcoming,
        past: past,
        upcomingCount: upcoming.length,
      );
    } catch (e) {
      debugPrint('CoachingService ERROR: Failed to fetch player coaching summary: $e');
      return PlayerCoachingSummary.empty();
    }
  }

  Stream<PlayerCoachingSummary> watchPlayerCoachingSummary(String playerId) {
    // Return a stream that emits whenever relevant tables change
    // Polled: realtime isn't enabled on session_enrollments, and a failed
    // subscription left the panel showing "Get a coach" after booking.
    return pollStream(() => getPlayerCoachingSummary(playerId));
  }

  /// Notes between one coach and one player, newest first. Both of them see
  /// every note; nobody else does.
  Future<List<Map<String, dynamic>>> getNotes({required String coachId, required String playerId}) async {
    final rows = await _supabase
        .from('coaching_notes')
        .select('id, author_id, body, created_at')
        .eq('coach_id', coachId)
        .eq('player_id', playerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addNote({required String coachId, required String playerId, required String body}) async {
    await _supabase.from('coaching_notes').insert({
      'coach_id': coachId,
      'player_id': playerId,
      'author_id': _supabase.auth.currentUser!.id,
      'body': body,
    });
  }

  Future<void> deleteNote(String id) async {
    await _supabase.from('coaching_notes').delete().eq('id', id);
  }
}
