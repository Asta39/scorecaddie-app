import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/coaching_service.dart';
import '../core/models/coaching_model.dart';
import '../core/models/coaching_summary.dart';
import 'auth_providers.dart';

final coachingServiceProvider = Provider<CoachingService>((ref) {
  return CoachingService(ref.watch(supabaseClientProvider));
});

final coachSessionsProvider = FutureProvider<List<CoachingSession>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final user = auth.valueOrNull;
  
  if (user == null) {
    debugPrint('coachSessionsProvider: No authenticated user');
    return [];
  }

  return await ref.watch(coachingServiceProvider).getCoachSessions(user.id);
});

final providerSessionsProvider = FutureProvider.family<List<CoachingSession>, String>((ref, coachId) {
  return ref.watch(coachingServiceProvider).getCoachSessions(coachId);
});

final specificCoachingSessionProvider = FutureProvider.family<CoachingSession?, String>((ref, sessionId) async {
  return ref.watch(coachingServiceProvider).getSessionById(sessionId);
});

final sessionOccurrencesProvider = FutureProvider.family<List<SessionOccurrence>, String>((ref, sessionId) {
  return ref.watch(coachingServiceProvider).getSessionOccurrences(sessionId);
});

final sessionEnrollmentsProvider = FutureProvider.family<List<SessionEnrollment>, String>((ref, sessionId) {
  return ref.watch(coachingServiceProvider).getSessionEnrollments(sessionId);
});

final coachEnrollmentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, coachId) {
  return ref.watch(coachingServiceProvider).getCoachEnrollments(coachId);
});

final coachingCoachProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, coachId) {
  return ref.watch(coachingServiceProvider).getCoachProfile(coachId);
});

final detailedSessionEnrollmentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sessionId) {
  return ref.watch(coachingServiceProvider).getSessionEnrollmentsWithDetails(sessionId);
});

final playerCoachingSummaryProvider = FutureProvider<PlayerCoachingSummary>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return PlayerCoachingSummary.empty();
  return await ref.watch(coachingServiceProvider).getPlayerCoachingSummary(user.id);
});

final playerCoachingSummaryStreamProvider = StreamProvider<PlayerCoachingSummary>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(PlayerCoachingSummary.empty());
  return ref.watch(coachingServiceProvider).watchPlayerCoachingSummary(user.id);
});

final coachStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return await ref.watch(coachingServiceProvider).getCoachEnrollments(user.id);
});

final playerEnrollmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return await ref.watch(coachingServiceProvider).getPlayerEnrollments(user.id);
});

final assignedDrillsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return await ref.watch(coachingServiceProvider).getAssignedDrills(user.id);
});

final coachDrillTemplatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return await ref.watch(coachingServiceProvider).getCoachDrillTemplates(user.id);
});

final coachAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return await ref.watch(coachingServiceProvider).getCoachAssignments(user.id);
});

final coachProfileStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {'rating': 5.0, 'views': 0, 'students': 0, 'activity': 0};
  return await ref.watch(coachingServiceProvider).getCoachProfileStats(user.id);
});

final coachRealtimeProfileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(coachingServiceProvider).watchCoachProfile(user.id);
});

final coachRevenueBreakdownProvider = FutureProvider<Map<String, double>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {'CASH': 0, 'MPESA': 0, 'BANK': 0};
  return await ref.watch(coachingServiceProvider).getCoachRevenueBreakdown(user.id);
});

final sessionAttendanceProvider = FutureProvider.family<List<SessionAttendance>, String>((ref, occurrenceId) {
  return ref.watch(coachingServiceProvider).getAttendanceForOccurrence(occurrenceId);
});
