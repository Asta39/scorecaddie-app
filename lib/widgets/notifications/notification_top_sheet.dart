import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/notification_service.dart';
import '../loading_spinner.dart';

class NotificationTopSheet extends ConsumerStatefulWidget {
  const NotificationTopSheet({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const NotificationTopSheet(),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<NotificationTopSheet> createState() => _NotificationTopSheetState();
}

class _NotificationTopSheetState extends ConsumerState<NotificationTopSheet> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Blurred Header ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: notificationsAsync.when(
                          data: (notifs) => _buildList(notifs),
                          loading: () => const LoadingSpinner(size: 60),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Tap to dismiss
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.6,
            child: GestureDetector(onTap: () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('INBOX', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
        TextButton(
          onPressed: () {
            ref.read(notificationServiceProvider).markAllAsRead();
          },
          child: const Text('Mark all read', style: TextStyle(color: AppColors.golfLime, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildList(List<AppNotification> notifs) {
    if (notifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bellOff, size: 48, color: AppColors.grey300),
            const SizedBox(height: 16),
            const Text('Your inbox is empty', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: notifs.length,
      itemBuilder: (context, i) => _NotificationTile(notification: notifs[i]),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(notificationServiceProvider).markAsRead(notification.id);
        // Handle navigation based on type if needed
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? Colors.transparent : AppColors.golfLime.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: notification.read ? AppColors.grey100 : AppColors.golfLime.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.grey100)),
              child: Icon(_getIcon(notification.type), size: 18, color: AppColors.grey700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(notification.body, style: const TextStyle(color: AppColors.grey500, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            if (!notification.read)
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.golfLime, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.leaderboardRankUp: return LucideIcons.trendingUp;
      case NotificationType.leaderboardRankDown: return LucideIcons.trendingDown;
      case NotificationType.handicapImproved: return LucideIcons.target;
      case NotificationType.personalBest: return LucideIcons.trophy;
      case NotificationType.friendJoined: return LucideIcons.userPlus;
      default: return LucideIcons.bell;
    }
  }
}
