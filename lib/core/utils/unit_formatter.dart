import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class UnitFormatter {
  final String units;

  UnitFormatter(this.units);

  String formatDistance(double yards) {
    if (units == 'Meters') {
      final meters = (yards * 0.9144).round();
      return '${meters}m';
    }
    return '${yards.round()}y';
  }

  double toYards(double value) {
    if (units == 'Meters') {
      return value / 0.9144;
    }
    return value;
  }
}

final unitFormatterProvider = Provider<UnitFormatter>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return UnitFormatter(profile?.units ?? 'Yards');
});
