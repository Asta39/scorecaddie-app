import 'database.dart';
import 'package:drift/drift.dart';

Future<void> seedMockReviews(AppDatabase db) async {
  final count = await db.customSelect('SELECT COUNT(*) as c FROM reviews').getSingle();
  if (count.read<int>('c') > 0) return; // Already seeded

  // Get all providers
  final providers = await db.select(db.providers).get();
  if (providers.isEmpty) return; // No providers to review

  final reviews = <ReviewsCompanion>[];
  
  for (var provider in providers) {
    if (provider.role == 'caddie') {
      reviews.addAll([
        ReviewsCompanion.insert(
          providerId: provider.userId,
          playerId: 'mock_player_1',
          playerName: 'John Doe',
          rating: 5,
          comment: 'Incredible local knowledge. Saved me at least 3 strokes on the greens today.',
          createdAt: Value(DateTime.now().subtract(const Duration(days: 2))),
        ),
        ReviewsCompanion.insert(
          providerId: provider.userId,
          playerId: 'mock_player_2',
          playerName: 'Alex Smith',
          rating: 4,
          comment: 'Very professional, always had the right club ready.',
          createdAt: Value(DateTime.now().subtract(const Duration(days: 5))),
        ),
      ]);
    } else if (provider.role == 'coach') {
       reviews.addAll([
        ReviewsCompanion.insert(
          providerId: provider.userId,
          playerId: 'mock_player_3',
          playerName: 'Sarah J.',
          rating: 5,
          comment: 'Fixed my slice in just two sessions. Highly recommend!',
          createdAt: Value(DateTime.now().subtract(const Duration(days: 1))),
        ),
        ReviewsCompanion.insert(
          providerId: provider.userId,
          playerId: 'mock_player_4',
          playerName: 'Mike T.',
          rating: 5,
          comment: 'Great communicator, explains the mechanics really well.',
          createdAt: Value(DateTime.now().subtract(const Duration(days: 12))),
        ),
      ]);
    }

    // Update the provider's rating and review count
    int sum = 0;
    int reviewCount = 0;
    for (var r in reviews.where((r) => r.providerId.value == provider.userId)) {
       sum += r.rating.value;
       reviewCount++;
    }
    if (reviewCount > 0) {
      await (db.update(db.providers)..where((p) => p.userId.equals(provider.userId))).write(
        ProvidersCompanion(
          rating: Value(sum / reviewCount),
          totalReviews: Value(reviewCount),
        ),
      );
    }
  }

  await db.batch((batch) {
    batch.insertAll(db.reviews, reviews);
  });
}
