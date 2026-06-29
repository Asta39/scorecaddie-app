import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import 'notification_top_sheet.dart';

class NotificationBell extends ConsumerWidget {
  final Color color;
  const NotificationBell({super.key, this.color = AppColors.grey900});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnreadAsync = ref.watch(hasUnreadProvider);

    return IconButton(
      icon: Stack(
        children: [
          Icon(LucideIcons.bell, color: color, size: 24),
          hasUnreadAsync.when(
            data: (hasUnread) => hasUnread 
              ? Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.golfLime,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      onPressed: () => NotificationTopSheet.show(context),
    );
  }
}
