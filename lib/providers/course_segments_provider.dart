import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/database/database.dart' as db;
import 'app_providers.dart';

/// Provider for courses with their calculated distance from the user.
final nearbyCoursesProvider = Provider<AsyncValue<List<CourseWithDistance>>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);
  final locationAsync = ref.watch(locationProvider);

  return coursesAsync.when(
    data: (courses) {
      return locationAsync.when(
        data: (pos) {
          if (pos == null) return const AsyncValue.data([]);
          
          final coursesWithDistance = courses.where((c) => c.latitude != null && c.longitude != null).map((c) {
            final distance = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              c.latitude!,
              c.longitude!,
            );
            return CourseWithDistance(c, distance);
          }).toList();

          coursesWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
          
          return AsyncValue.data(coursesWithDistance);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Provider for the last 3 unique recently played courses.
final recentlyPlayedCoursesProvider = Provider<AsyncValue<List<db.Course>>>((ref) {
  final roundsAsync = ref.watch(roundsProvider);
  final coursesAsync = ref.watch(coursesProvider);

  return roundsAsync.when(
    data: (rounds) {
      return coursesAsync.when(
        data: (courses) {
          final recentCourseIds = <int>{};
          final result = <db.Course>[];

          for (final round in rounds) {
            if (recentCourseIds.contains(round.courseId)) continue;
            
            final course = courses.where((c) => c.id == round.courseId).firstOrNull;
            if (course != null) {
              recentCourseIds.add(round.courseId);
              result.add(course);
            }
            if (result.length >= 3) break;
          }
          
          return AsyncValue.data(result);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class CourseWithDistance {
  final db.Course course;
  final double distance;
  CourseWithDistance(this.course, this.distance);
}
