import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AchievementCategory { scoring, consistency, activity, explorer, social }

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

  static const List<Achievement> allAchievements = [
    // --- Scoring ---
    Achievement(id: 'score_100', title: 'Century Club', description: 'Break 100 for the first time', icon: LucideIcons.medal, category: AchievementCategory.scoring, points: 20),
    Achievement(id: 'score_90', title: 'Breaking 90', description: 'Break 90 for the first time', icon: LucideIcons.trophy, category: AchievementCategory.scoring, points: 50),
    Achievement(id: 'score_80', title: 'Elite 80', description: 'Break 80 for the first time', icon: LucideIcons.award, category: AchievementCategory.scoring, points: 100),
    Achievement(id: 'birdie_first', title: 'First Flight', description: 'Record your first Birdie', icon: LucideIcons.tent, category: AchievementCategory.scoring),
    Achievement(id: 'eagle_first', title: 'Souring Eagle', description: 'Record your first Eagle', icon: LucideIcons.mountain, category: AchievementCategory.scoring, points: 100),
    Achievement(id: 'par_master', title: 'Par Machine', description: 'Record 9 or more Pars in a round', icon: LucideIcons.target, category: AchievementCategory.scoring, points: 50),
    Achievement(id: 'hole_in_one', title: 'The Miracle', description: 'Record a Hole-in-One!', icon: LucideIcons.flame, category: AchievementCategory.scoring, points: 500),
    Achievement(id: 'bogey_free', title: 'Perfectly Clean', description: 'Complete a round with no bogeys or worse', icon: LucideIcons.sparkles, category: AchievementCategory.scoring, points: 200),
    Achievement(id: 'sub_par_9', title: 'Sub-Par 9', description: 'Shoot under par for either the front or back 9', icon: LucideIcons.star, category: AchievementCategory.scoring, points: 100),

    // --- Consistency ---
    Achievement(id: 'streak_par_3', title: 'Par Streak', description: 'Record 3 Pars in a row', icon: LucideIcons.activity, category: AchievementCategory.consistency),
    Achievement(id: 'streak_birdie_2', title: 'Back-to-Back', description: 'Record 2 Birdies in a row', icon: LucideIcons.zap, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'fairway_king', title: 'Fairway King', description: 'Hit 100% of fairways in a round', icon: LucideIcons.compass, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'gir_master', title: 'GIR Master', description: 'Hit 12 or more greens in regulation', icon: LucideIcons.flag, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'scrambler', title: 'Scrambler', description: 'Save Par from a bunker', icon: LucideIcons.shovel, category: AchievementCategory.consistency),
    Achievement(id: 'no_penalties', title: 'Disciplined', description: 'Zero penalty strokes in a full round', icon: LucideIcons.shieldCheck, category: AchievementCategory.consistency, points: 30),
    Achievement(id: 'putt_pro', title: 'Putt Pro', description: 'Less than 30 putts in a round', icon: LucideIcons.disc, category: AchievementCategory.consistency, points: 40),

    // --- Activity ---
    Achievement(id: 'round_1', title: 'First Dance', description: 'Complete your first 18-hole round', icon: LucideIcons.playCircle, category: AchievementCategory.activity),
    Achievement(id: 'round_10', title: 'Deep Roots', description: 'Complete 10 total rounds', icon: LucideIcons.trees, category: AchievementCategory.activity, points: 50),
    Achievement(id: 'round_50', title: 'Half-Century', description: 'Complete 50 total rounds', icon: LucideIcons.milestone, category: AchievementCategory.activity, points: 100),
    Achievement(id: 'round_100', title: 'Legendary Status', description: 'Complete 100 total rounds', icon: LucideIcons.crown, category: AchievementCategory.activity, points: 500),
    Achievement(id: 'weekend_warrior', title: 'Weekend Warrior', description: 'Play rounds on both Saturday and Sunday', icon: LucideIcons.calendar, category: AchievementCategory.activity),
    Achievement(id: 'early_bird', title: 'Early Bird', description: 'Tee off before 7:00 AM', icon: LucideIcons.sunrise, category: AchievementCategory.activity),
    Achievement(id: 'night_owl', title: 'Night Owl', description: 'Finish a round after 6:30 PM', icon: LucideIcons.moon, category: AchievementCategory.activity),
    Achievement(id: 'marathon', title: '36 Hole Marathon', description: 'Play 36 holes in a single day', icon: LucideIcons.footprints, category: AchievementCategory.activity, points: 100),

    // --- Explorer ---
    Achievement(id: 'course_5', title: 'Traveler', description: 'Play on 5 different golf courses', icon: LucideIcons.map, category: AchievementCategory.explorer, points: 50),
    Achievement(id: 'course_10', title: 'Adventurer', description: 'Play on 10 different golf courses', icon: LucideIcons.globe, category: AchievementCategory.explorer, points: 100),
    Achievement(id: 'kenya_5', title: 'Kenyan Pride', description: 'Play at 5 Kenyan courses', icon: LucideIcons.flag, category: AchievementCategory.explorer, points: 50),
    Achievement(id: 'links_master', title: 'Links Master', description: 'Play a round at a Links-style course', icon: LucideIcons.ship, category: AchievementCategory.explorer),
    Achievement(id: 'altitude_golfer', title: 'High Flyer', description: 'Play a round over 2000m above sea level', icon: LucideIcons.plane, category: AchievementCategory.explorer),

    // --- Social ---
    Achievement(id: 'friend_first', title: 'Social Butterfly', description: 'Add your first friend', icon: LucideIcons.userPlus, category: AchievementCategory.social),
    Achievement(id: 'share_10', title: 'Influencer', description: 'Share 10 highlight cards on social media', icon: LucideIcons.share2, category: AchievementCategory.social, points: 30),
    Achievement(id: 'friend_round', title: 'Team Play', description: 'Play a round with a friend', icon: LucideIcons.users, category: AchievementCategory.social),
    
    // --- Fun/Misc ---
    Achievement(id: 'lost_ball_zero', title: 'Ball Saver', description: 'Complete a round without losing a ball', icon: LucideIcons.lifeBuoy, category: AchievementCategory.activity),
    Achievement(id: 'long_drive', title: 'Bomber', description: 'Record a drive over 300 yards', icon: LucideIcons.send, category: AchievementCategory.scoring),
    Achievement(id: 'comeback', title: 'Relentless', description: 'Improve your back 9 score by 10+ strokes', icon: LucideIcons.trendingUp, category: AchievementCategory.consistency),
    
    // (Adding more to reach 50 targets...)
    Achievement(id: 'rain_man', title: 'Rain Man', description: 'Complete a round in rainy conditions', icon: LucideIcons.cloudRain, category: AchievementCategory.activity),
    Achievement(id: 'lucky_7', title: 'Lucky 7', description: 'Make 7 pars in a row', icon: LucideIcons.clover, category: AchievementCategory.consistency, points: 77),
    Achievement(id: 'albatross', title: 'The Double Eagle', description: 'Record an Albatross (-3)', icon: LucideIcons.shrub, category: AchievementCategory.scoring, points: 1000),
    Achievement(id: 'streak_birdie_3', title: 'Turkey!', description: '3 Birdies in a row', icon: LucideIcons.chefHat, category: AchievementCategory.consistency, points: 150),
    Achievement(id: 'bogey_free_start', title: 'Never Give Up', description: 'Break 90 after a triple-bogey start', icon: LucideIcons.train, category: AchievementCategory.consistency),
    Achievement(id: 'sand_save_first', title: 'Beach Pro', description: 'First ever up-and-down from a bunker', icon: LucideIcons.palmtree, category: AchievementCategory.consistency),
    Achievement(id: 'new_bag', title: 'Fully Loaded', description: 'Add 14 clubs to your digital bag', icon: LucideIcons.briefcase, category: AchievementCategory.activity),
    Achievement(id: 'winter_golf', title: 'Cold-Blooded', description: 'Play a round below 15°C', icon: LucideIcons.snowflake, category: AchievementCategory.activity),
    Achievement(id: 'birthday_golf', title: 'Gift to Self', description: 'Play a round on your registered birthday', icon: LucideIcons.cake, category: AchievementCategory.activity),
    Achievement(id: 'vacation_golf', title: 'Holiday Swings', description: 'Play golf while on vacation (away course)', icon: LucideIcons.luggage, category: AchievementCategory.explorer),
    Achievement(id: 'streak_30_days', title: 'Dedicated', description: 'Play at least one round in 3 consecutive months', icon: LucideIcons.hourglass, category: AchievementCategory.activity, points: 100),
    Achievement(id: 'highlight_pro', title: 'Highlight Pro', description: 'Create a highlight card for every hole in a round', icon: LucideIcons.image, category: AchievementCategory.social, points: 50),
    Achievement(id: 'caddie_helper', title: 'App Guru', description: 'Use ScoreCaddie for 30 consecutive days', icon: LucideIcons.smartphone, category: AchievementCategory.activity),
    Achievement(id: 'par_4_eagle', title: 'Driver Master', description: 'Make an eagle on a Par 4', icon: LucideIcons.wind, category: AchievementCategory.scoring, points: 300),
    Achievement(id: 'sub_30_putts', title: 'Putting God', description: 'Shoot a round with 25 or fewer putts', icon: LucideIcons.anchor, category: AchievementCategory.consistency, points: 200),
    
    // --- Streak Milestones ---
    Achievement(id: 'streak_week_1', title: 'Ignition', description: 'Start your first weekly streak', icon: LucideIcons.flame, category: AchievementCategory.consistency, points: 10),
    Achievement(id: 'streak_week_4', title: 'Monthly Regular', description: 'Maintain a 4-week round streak', icon: LucideIcons.calendar, category: AchievementCategory.consistency, points: 50),
    Achievement(id: 'streak_week_12', title: 'Committed Golfer', description: 'Maintain a 12-week round streak', icon: LucideIcons.medal, category: AchievementCategory.consistency, points: 150),
    Achievement(id: 'streak_week_26', title: 'Half Year Hustler', description: 'Maintain a 26-week round streak', icon: LucideIcons.trophy, category: AchievementCategory.consistency, points: 500),
    Achievement(id: 'streak_week_52', title: 'Iron Man', description: 'The ultimate 52-week round streak', icon: LucideIcons.crown, category: AchievementCategory.consistency, points: 1000),
  ];
}
