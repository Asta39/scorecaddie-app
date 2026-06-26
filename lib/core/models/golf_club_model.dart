enum ClubCategory { driver, fairwayWood, hybrid, longIron, midIron, shortIron, wedge, putter }

class GolfClub {
  final String name;
  final ClubCategory category;
  final int loftDegrees;
  final double idealTempoRatio;       // backswing:downswing frames ratio
  final double idealSpineAngleMin;    // degrees from vertical at address
  final double idealSpineAngleMax;
  final double idealShoulderTurnMin;  // degrees at top of backswing
  final double idealShoulderTurnMax;
  final double idealHipTurnAtImpact;  // hip rotation vs address position
  final double idealWristHingeAngle;  // at top of swing
  final bool requiresWidestStance;
  final bool requiresBallForwardInStance;
  final String coachingContext;       // fed to Gemini

  const GolfClub({
    required this.name,
    required this.category,
    required this.loftDegrees,
    required this.idealTempoRatio,
    required this.idealSpineAngleMin,
    required this.idealSpineAngleMax,
    required this.idealShoulderTurnMin,
    required this.idealShoulderTurnMax,
    required this.idealHipTurnAtImpact,
    required this.idealWristHingeAngle,
    required this.requiresWidestStance,
    required this.requiresBallForwardInStance,
    required this.coachingContext,
  });
}

class ClubDatabase {
  static const Map<String, GolfClub> clubs = {
    'driver': GolfClub(
      name: 'Driver',
      category: ClubCategory.driver,
      loftDegrees: 10,
      idealTempoRatio: 3.0,
      idealSpineAngleMin: 30,
      idealSpineAngleMax: 40,
      idealShoulderTurnMin: 90,
      idealShoulderTurnMax: 110,
      idealHipTurnAtImpact: 45,
      idealWristHingeAngle: 90,
      requiresWidestStance: true,
      requiresBallForwardInStance: true,
      coachingContext: '''
        Driver swing fundamentals:
        - Ball positioned off the front heel, teed up high
        - Wider stance than shoulder width for a stable base
        - Slight spine tilt away from target
        - hit UP on the ball (positive angle of attack)
        - Full shoulder turn of 90+ degrees is essential
      ''',
    ),
    '3-wood': GolfClub(
      name: '3 Wood',
      category: ClubCategory.fairwayWood,
      loftDegrees: 15,
      idealTempoRatio: 3.0,
      idealSpineAngleMin: 32,
      idealSpineAngleMax: 42,
      idealShoulderTurnMin: 85,
      idealShoulderTurnMax: 100,
      idealHipTurnAtImpact: 40,
      idealWristHingeAngle: 90,
      requiresWidestStance: false,
      requiresBallForwardInStance: true,
      coachingContext: '''
        3-wood fundamentals:
        - Ball just inside the front heel
        - Sweep the ball off the turf — do NOT try to hit down on it
        - Keep the clubhead low to the ground in the takeaway (wide arc)
      ''',
    ),
    '7-iron': GolfClub(
      name: '7 Iron',
      category: ClubCategory.midIron,
      loftDegrees: 35,
      idealTempoRatio: 3.0,
      idealSpineAngleMin: 40,
      idealSpineAngleMax: 50,
      idealShoulderTurnMin: 75,
      idealShoulderTurnMax: 90,
      idealHipTurnAtImpact: 35,
      idealWristHingeAngle: 80,
      requiresWidestStance: false,
      requiresBallForwardInStance: false,
      coachingContext: '''
        7-iron fundamentals:
        - Universal benchmark club
        - Ball position: center to 1 inch forward of center
        - Definitive downward strike — divot should appear after the ball position
        - Hands ahead of the ball at impact
      ''',
    ),
    'pitching-wedge': GolfClub(
      name: 'Pitching Wedge',
      category: ClubCategory.wedge,
      loftDegrees: 48,
      idealTempoRatio: 2.8,
      idealSpineAngleMin: 44,
      idealSpineAngleMax: 54,
      idealShoulderTurnMin: 65,
      idealShoulderTurnMax: 80,
      idealHipTurnAtImpact: 28,
      idealWristHingeAngle: 70,
      requiresWidestStance: false,
      requiresBallForwardInStance: false,
      coachingContext: '''
        Pitching wedge fundamentals:
        - Hands firmly ahead of the ball — no scooping
        - Clean, crisp divot after the ball
        - Clubface must be square
      ''',
    ),
  };

  static GolfClub get(String clubName) {
    final key = clubName.toLowerCase().replaceAll(' ', '-');
    return clubs[key] ?? clubs['7-iron']!;
  }
}
