import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AchievementCategory { scoring, consistency, activity, explorer, social, practice }

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final int points;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.points = 10,
  });

  /// The achievement's own avatar (see assets/achievements/README.md):
  /// a still of it idling for when it's earned, a still of it asleep for
  /// when it isn't, and an animated loop of it celebrating for the unlock.
  String get avatarAsset => 'assets/achievements/$id.webp';
  String get lockedAvatarAsset => 'assets/achievements/${id}_locked.webp';
  String get celebrationAsset => 'assets/achievements/${id}_win.webp';

  static const List<Achievement> allAchievements = [
    // Scoring
    Achievement(id: 'score_100', title: 'Century Club', description: 'Break 100 for the first time.', icon: LucideIcons.medal, category: AchievementCategory.scoring, points: 20),
    Achievement(id: 'score_90', title: 'Breaking 90', description: 'Break 90 for the first time.', icon: LucideIcons.trophy, category: AchievementCategory.scoring, points: 50),
    Achievement(id: 'score_80', title: 'Elite 80', description: 'Break 80 for the first time.', icon: LucideIcons.award, category: AchievementCategory.scoring, points: 100),
    Achievement(id: 'birdie_first', title: 'First Flight', description: 'Make your first birdie.', icon: LucideIcons.tent, category: AchievementCategory.scoring),
    Achievement(id: 'eagle_first', title: 'Soaring Eagle', description: 'Make your first eagle.', icon: LucideIcons.mountain, category: AchievementCategory.scoring, points: 100),
    Achievement(id: 'albatross', title: 'The Double Eagle', description: 'Make an albatross: three under on one hole.', icon: LucideIcons.shrub, category: AchievementCategory.scoring, points: 1000),
    Achievement(id: 'hole_in_one', title: 'The Miracle', description: 'Make a hole in one.', icon: LucideIcons.flame, category: AchievementCategory.scoring, points: 500),
    Achievement(id: 'par_4_eagle', title: 'Driver Master', description: 'Make an eagle on a par 4.', icon: LucideIcons.wind, category: AchievementCategory.scoring, points: 300),
    Achievement(id: 'par_master', title: 'Par Machine', description: 'Make nine or more pars in one round.', icon: LucideIcons.target, category: AchievementCategory.scoring, points: 50),
    Achievement(id: 'bogey_free', title: 'Perfectly Clean', description: 'Finish a round without a bogey.', icon: LucideIcons.sparkles, category: AchievementCategory.scoring, points: 200),
    Achievement(id: 'sub_par_9', title: 'Sub-Par Nine', description: 'Finish the front or back nine under par.', icon: LucideIcons.star, category: AchievementCategory.scoring, points: 100),
    Achievement(id: 'long_drive', title: 'Bomber', description: 'Hit a drive over 300 yards.', icon: LucideIcons.send, category: AchievementCategory.scoring),
    Achievement(id: 'hcp_drop', title: 'Shedding Strokes', description: 'Bring your handicap index down by a full stroke.', icon: LucideIcons.trendingDown, category: AchievementCategory.scoring, points: 100),

    // Consistency
    Achievement(id: 'streak_par_3', title: 'Par Streak', description: 'Make three pars in a row.', icon: LucideIcons.activity, category: AchievementCategory.consistency),
    Achievement(id: 'lucky_7', title: 'Lucky 7', description: 'Make seven pars in a row.', icon: LucideIcons.clover, category: AchievementCategory.consistency, points: 77),
    Achievement(id: 'streak_birdie_2', title: 'Back-to-Back', description: 'Make birdies on two holes in a row.', icon: LucideIcons.zap, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'streak_birdie_3', title: 'Turkey!', description: 'Make birdies on three holes in a row.', icon: LucideIcons.chefHat, category: AchievementCategory.consistency, points: 150),
    Achievement(id: 'fairway_king', title: 'Fairway King', description: 'Hit every fairway in a round.', icon: LucideIcons.compass, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'gir_master', title: 'GIR Master', description: 'Hit 12 or more greens in regulation.', icon: LucideIcons.flag, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'scrambler', title: 'Scrambler', description: 'Save par from a bunker.', icon: LucideIcons.shovel, category: AchievementCategory.consistency),
    Achievement(id: 'sand_save_first', title: 'Beach Pro', description: 'Get up and down from a bunker for the first time.', icon: LucideIcons.palmtree, category: AchievementCategory.consistency),
    Achievement(id: 'no_penalties', title: 'Disciplined', description: 'Finish a full round without a penalty stroke.', icon: LucideIcons.shieldCheck, category: AchievementCategory.consistency, points: 30),
    Achievement(id: 'putt_pro', title: 'Putt Pro', description: 'Take fewer than 30 putts in a round.', icon: LucideIcons.disc, category: AchievementCategory.consistency, points: 40),
    Achievement(id: 'sub_30_putts', title: 'Putting Wizard', description: 'Take 25 putts or fewer in a round.', icon: LucideIcons.anchor, category: AchievementCategory.consistency, points: 200),
    Achievement(id: 'comeback', title: 'Relentless', description: 'Score 10 or more shots better on the back nine than the front.', icon: LucideIcons.trendingUp, category: AchievementCategory.consistency),
    Achievement(id: 'bogey_free_start', title: 'Never Give Up', description: 'Break 90 after starting with a triple bogey.', icon: LucideIcons.train, category: AchievementCategory.consistency),
    Achievement(id: 'streak_week_1', title: 'Ignition', description: 'Start your first weekly streak.', icon: LucideIcons.flame, category: AchievementCategory.consistency),
    Achievement(id: 'streak_week_4', title: 'Monthly Regular', description: 'Play every week for 4 weeks.', icon: LucideIcons.calendar, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'streak_week_12', title: 'Committed Golfer', description: 'Play every week for 12 weeks.', icon: LucideIcons.medal, category: AchievementCategory.consistency, points: 150),
    Achievement(id: 'streak_week_26', title: 'Half Year Hustler', description: 'Play every week for 26 weeks.', icon: LucideIcons.trophy, category: AchievementCategory.consistency, points: 500),
    Achievement(id: 'streak_week_52', title: 'Iron Man', description: 'Play every week for a whole year.', icon: LucideIcons.crown, category: AchievementCategory.consistency, points: 1000),

    // Activity
    Achievement(id: 'round_1', title: 'First Dance', description: 'Finish your first 18-hole round.', icon: LucideIcons.playCircle, category: AchievementCategory.activity),
    Achievement(id: 'round_10', title: 'Deep Roots', description: 'Finish 10 rounds.', icon: LucideIcons.trees, category: AchievementCategory.activity, points: 50),
    Achievement(id: 'round_50', title: 'Half-Century', description: 'Finish 50 rounds.', icon: LucideIcons.milestone, category: AchievementCategory.activity, points: 100),
    Achievement(id: 'round_100', title: 'Legendary Status', description: 'Finish 100 rounds.', icon: LucideIcons.crown, category: AchievementCategory.activity, points: 500),
    Achievement(id: 'weekend_warrior', title: 'Weekend Warrior', description: 'Play on a Saturday and the Sunday after it.', icon: LucideIcons.calendar, category: AchievementCategory.activity),
    Achievement(id: 'early_bird', title: 'Early Bird', description: 'Tee off before 7:00.', icon: LucideIcons.sunrise, category: AchievementCategory.activity),
    Achievement(id: 'night_owl', title: 'Night Owl', description: 'Finish a round after 18:30.', icon: LucideIcons.moon, category: AchievementCategory.activity),
    Achievement(id: 'marathon', title: '36-Hole Marathon', description: 'Play 36 holes in one day.', icon: LucideIcons.footprints, category: AchievementCategory.activity, points: 100),
    Achievement(id: 'lost_ball_zero', title: 'Ball Saver', description: 'Finish a round without losing a ball.', icon: LucideIcons.lifeBuoy, category: AchievementCategory.activity),
    Achievement(id: 'rain_man', title: 'Rain Man', description: 'Finish a round in the rain.', icon: LucideIcons.cloudRain, category: AchievementCategory.activity),
    Achievement(id: 'winter_golf', title: 'Cold-Blooded', description: 'Play a round below 15°C.', icon: LucideIcons.snowflake, category: AchievementCategory.activity),
    Achievement(id: 'new_bag', title: 'Fully Loaded', description: 'Put 14 clubs in your digital bag.', icon: LucideIcons.briefcase, category: AchievementCategory.activity),
    Achievement(id: 'birthday_golf', title: 'Gift to Self', description: 'Play a round on your birthday.', icon: LucideIcons.cake, category: AchievementCategory.activity),
    Achievement(id: 'streak_30_days', title: 'Dedicated', description: 'Play at least one round a month, three months running.', icon: LucideIcons.hourglass, category: AchievementCategory.activity, points: 100),
    Achievement(id: 'caddie_helper', title: 'App Guru', description: 'Open ScoreCaddie 30 days in a row.', icon: LucideIcons.smartphone, category: AchievementCategory.activity),
    Achievement(id: 'scan_card', title: 'Card Shark', description: 'Scan a paper scorecard into a round.', icon: LucideIcons.scanLine, category: AchievementCategory.activity),

    // Explorer
    Achievement(id: 'course_5', title: 'Traveller', description: 'Play five different courses.', icon: LucideIcons.map, category: AchievementCategory.explorer, points: 50),
    Achievement(id: 'course_10', title: 'Adventurer', description: 'Play ten different courses.', icon: LucideIcons.globe, category: AchievementCategory.explorer, points: 100),
    Achievement(id: 'kenya_5', title: 'Kenyan Pride', description: 'Play five courses in Kenya.', icon: LucideIcons.flag, category: AchievementCategory.explorer, points: 50),
    Achievement(id: 'links_master', title: 'Links Master', description: 'Play a round on a links course.', icon: LucideIcons.ship, category: AchievementCategory.explorer),
    Achievement(id: 'altitude_golfer', title: 'High Flyer', description: 'Play a round more than 2,000 m above sea level.', icon: LucideIcons.plane, category: AchievementCategory.explorer),
    Achievement(id: 'vacation_golf', title: 'Holiday Swings', description: 'Play a course away from home while on holiday.', icon: LucideIcons.luggage, category: AchievementCategory.explorer),

    // Social
    Achievement(id: 'friend_first', title: 'Social Butterfly', description: 'Add your first friend.', icon: LucideIcons.userPlus, category: AchievementCategory.social),
    Achievement(id: 'friend_round', title: 'Team Play', description: 'Play a round with a friend.', icon: LucideIcons.users, category: AchievementCategory.social),
    Achievement(id: 'share_10', title: 'Influencer', description: 'Share 10 highlight cards.', icon: LucideIcons.share2, category: AchievementCategory.social, points: 30),
    Achievement(id: 'highlight_pro', title: 'Highlight Pro', description: 'Make a highlight card for every hole of a round.', icon: LucideIcons.image, category: AchievementCategory.social, points: 50),
    Achievement(id: 'caddie_first', title: 'In Good Hands', description: 'Book your first caddie.', icon: LucideIcons.briefcase, category: AchievementCategory.social, points: 20),
    Achievement(id: 'coach_first', title: 'Coached Up', description: 'Take your first lesson with a coach.', icon: LucideIcons.graduationCap, category: AchievementCategory.social, points: 20),
    Achievement(id: 'club_join', title: 'Member', description: 'Join a club on ScoreCaddie.', icon: LucideIcons.house, category: AchievementCategory.social),
    Achievement(id: 'club_event', title: 'On the Tee Sheet', description: 'Enter your first club competition.', icon: LucideIcons.ticket, category: AchievementCategory.social, points: 20),

    // Practice
    Achievement(id: 'voice_100', title: 'Daniel’s 100', description: 'Log 100 shots out loud with Daniel.', icon: LucideIcons.mic, category: AchievementCategory.practice, points: 50),
    Achievement(id: 'drill_done', title: 'Homework Done', description: 'Finish a drill your coach set you.', icon: LucideIcons.clipboardCheck, category: AchievementCategory.practice, points: 30),
    Achievement(id: 'practice_streak', title: 'Range Rat', description: 'Practise three times a week, three weeks running.', icon: LucideIcons.dumbbell, category: AchievementCategory.practice, points: 100),
  ];
}
