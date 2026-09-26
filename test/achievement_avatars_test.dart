import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/models/achievement_model.dart';

/// Every achievement ships its own avatar (see tool/achievement_avatars).
void main() {
  test('achievement ids are unique', () {
    final ids = Achievement.allAchievements.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every achievement has its earned, locked and celebration avatars', () {
    final missing = [
      for (final a in Achievement.allAchievements)
        for (final path in [a.avatarAsset, a.lockedAvatarAsset, a.celebrationAsset])
          if (!File(path).existsSync()) path,
    ];
    expect(missing, isEmpty);
  });

  test('no avatar is left over without an achievement', () {
    final expected = {
      for (final a in Achievement.allAchievements) ...[a.avatarAsset, a.lockedAvatarAsset, a.celebrationAsset],
    };
    final extra = Directory('assets/achievements')
        .listSync()
        .whereType<File>()
        .map((f) => 'assets/achievements/${f.uri.pathSegments.last}')
        .where((p) => p.endsWith('.webp') && !expected.contains(p))
        .toList();
    expect(extra, isEmpty);
  });
}
