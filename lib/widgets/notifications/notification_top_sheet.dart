import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/achievement_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/notification_service.dart';
import '../../screens/onboarding/ob_style.dart';
import '../../screens/onboarding/ob_widgets.dart';

/// The inbox: drops from the top; each notification is shown by the mascot
/// it's about.
class NotificationTopSheet extends ConsumerWidget {
  const NotificationTopSheet({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close notifications',
      barrierColor: const Color(0x99030905),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => const NotificationTopSheet(),
      transitionBuilder: (_, a, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, -.08), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: const Cubic(.2, .8, .2, 1))),
        child: FadeTransition(opacity: a, child: child),
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t.toLocal());
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays} days ago';
  }

  static String _mascot(AppNotification n) {
    final achievement = n.payload['achievementId'] as String?;
    if (achievement != null) {
      final a = Achievement.allAchievements.where((x) => x.id == achievement).firstOrNull;
      if (a != null) return a.avatarAsset;
    }
    return switch (n.type) {
      NotificationType.personalBest || NotificationType.handicapImproved => ObBot.ball.happy,
      NotificationType.leaderboardRankUp || NotificationType.enteredTopTen => ObBot.star.happy,
      NotificationType.leaderboardRankDown || NotificationType.friendOvertook => ObBot.star.idle,
      NotificationType.friendJoined || NotificationType.friendCompletedRound => ObBot.ball.idle,
    };
  }

  static String? _route(AppNotification n) => switch (n.type) {
        NotificationType.friendJoined || NotificationType.friendCompletedRound || NotificationType.friendOvertook => '/profile/friends',
        NotificationType.leaderboardRankUp || NotificationType.leaderboardRankDown || NotificationType.enteredTopTen => '/leaderboard',
        NotificationType.handicapImproved || NotificationType.personalBest => '/analytics',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(unreadNotificationsProvider);
    final notes = async.valueOrNull ?? const <AppNotification>[];
    final mq = MediaQuery.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Container(
            constraints: BoxConstraints(maxHeight: mq.size.height * .86),
            padding: EdgeInsets.fromLTRB(20, mq.padding.top + 12, 20, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1A12),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              border: Border(bottom: BorderSide(color: Color(0x40A3E635))),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text('Notifications', style: Ob.display(28))),
                if (notes.any((n) => !n.read))
                  TextButton(
                    onPressed: () => ref.read(notificationServiceProvider).markAllAsRead(),
                    child: Text('Mark all read', style: Ob.body(13, weight: FontWeight.w800, color: Ob.lime)),
                  ),
              ]),
              const SizedBox(height: 10),
              Flexible(
                child: async.isLoading && notes.isEmpty
                    ? const Padding(padding: EdgeInsets.all(30), child: CupertinoActivityIndicator(color: Ob.lime))
                    : notes.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(children: [
                              Image.asset(ObBot.ball.sleep, width: 64, height: 64),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Nothing new. Rounds, friends and drills show up here.', style: Ob.body(14, color: Ob.creamA(.65)))),
                            ]),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemCount: notes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _tile(context, ref, notes[i]),
                          ),
              ),
              const SizedBox(height: 10),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Ob.creamA(.18), borderRadius: BorderRadius.circular(3))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, AppNotification n) {
    return GestureDetector(
      onTap: () {
        if (!n.read) ref.read(notificationServiceProvider).markAsRead(n.id);
        final to = _route(n);
        Navigator.pop(context);
        if (to != null) context.push(to);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: n.read ? Ob.cardFill : Ob.lime.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: n.read ? Ob.creamA(.06) : Ob.lime.withValues(alpha: .25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(16)),
            child: Image.asset(_mascot(n), width: 48, height: 48, errorBuilder: (_, _, _) => const SizedBox()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title, style: Ob.body(14, weight: FontWeight.w800)),
              if (n.body.isNotEmpty) ...[const SizedBox(height: 2), Text(n.body, style: Ob.body(13, height: 1.4, color: Ob.creamA(.68)))],
              const SizedBox(height: 3),
              Text(_ago(n.createdAt), style: Ob.body(11, color: Ob.creamA(.45))),
            ]),
          ),
          if (!n.read) Container(margin: const EdgeInsets.only(top: 6, left: 6), width: 9, height: 9, decoration: const BoxDecoration(color: Ob.lime, shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}
