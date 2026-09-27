import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/achievement_model.dart';
import '../screens/onboarding/ob_style.dart';

/// Shows one achievement: its avatar celebrating when earned, asleep when not.
class AchievementDialog extends StatelessWidget {
  final Achievement achievement;
  final bool isEarned;

  const AchievementDialog({
    super.key,
    required this.achievement,
    this.isEarned = true,
  });

  static Future<void> show(BuildContext context, Achievement achievement, {bool isEarned = true}) {
    if (isEarned) HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: .7),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => AchievementDialog(achievement: achievement, isEarned: isEarned),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut).drive(Tween(begin: .85, end: 1)), child: child),
      ),
    );
  }

  static String categoryName(AchievementCategory c) => switch (c) {
        AchievementCategory.scoring => 'Scoring',
        AchievementCategory.consistency => 'Consistency',
        AchievementCategory.activity => 'Getting out',
        AchievementCategory.explorer => 'Explorer',
        AchievementCategory.social => 'Social',
        AchievementCategory.practice => 'Practice',
      };

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            decoration: BoxDecoration(
              color: Ob.cardFill,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isEarned ? Ob.lime.withValues(alpha: .5) : Ob.creamA(.08), width: isEarned ? 2 : 1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                isEarned ? 'UNLOCKED' : 'NOT YET',
                style: Ob.body(12, weight: FontWeight.w800, color: isEarned ? Ob.lime : Ob.creamA(.5)).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              Semantics(
                label: '${a.title} avatar',
                child: AchievementAvatar(a, earned: isEarned, size: 190, celebrate: true),
              ),
              const SizedBox(height: 4),
              Text(a.title, textAlign: TextAlign.center, style: Ob.display(30, height: 1.05)),
              const SizedBox(height: 8),
              Text(a.description, textAlign: TextAlign.center, style: Ob.body(15, height: 1.45, color: Ob.creamA(.75))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _pill('${a.points} pts', isEarned ? Ob.lime : Ob.creamA(.6)),
                const SizedBox(width: 8),
                _pill(categoryName(a.category), Ob.creamA(.6)),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ObButton(
                  tone: isEarned ? ObButtonTone.lime : ObButtonTone.dark,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isEarned ? 'Nice one' : 'Got it', style: Ob.label(16, weight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: Ob.body(12, weight: FontWeight.w800, color: color)),
      );
}

/// An achievement's avatar. Locked ones are asleep, greyed and dimmed so
/// they don't read as earned at a glance.
class AchievementAvatar extends StatelessWidget {
  const AchievementAvatar(this.achievement, {super.key, required this.earned, this.size, this.celebrate = false});
  final Achievement achievement;
  final bool earned;
  final double? size;
  final bool celebrate;

  static const _grey = ColorFilter.matrix([
    .2126, .7152, .0722, 0, 0,
    .2126, .7152, .0722, 0, 0,
    .2126, .7152, .0722, 0, 0,
    0, 0, 0, .45, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final img = Image.asset(
      earned ? (celebrate ? a.celebrationAsset : a.avatarAsset) : a.lockedAvatarAsset,
      width: size,
      height: size,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Icon(a.icon, size: (size ?? 60) * .5, color: earned ? Ob.lime : Ob.creamA(.3)),
    );
    return earned ? img : ColorFiltered(colorFilter: _grey, child: img);
  }
}
