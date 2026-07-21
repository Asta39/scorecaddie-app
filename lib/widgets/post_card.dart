import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import 'pill.dart';

String formatTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

class PostCard extends StatelessWidget {
  final String type;
  final String title;
  final String content;
  final String timeAgo;
  final String author;
  final String? actionText;
  final String? imageUrl;
  final VoidCallback? onAction;

  const PostCard({
    super.key,
    required this.type,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.author,
    this.actionText,
    this.imageUrl,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'announcement':
        icon = LucideIcons.megaphone;
        color = AppColors.golfLime;
        label = 'Announcement';
        break;
      case 'fixture':
      case 'competition':
        icon = LucideIcons.calendar;
        color = AppColors.blue600;
        label = 'Event';
        break;
      case 'result':
        icon = LucideIcons.award;
        color = AppColors.emerald700;
        label = 'Result';
        break;
      default:
        icon = LucideIcons.messageSquare;
        color = AppColors.grey600;
        label = 'Notice';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(imageUrl!, width: double.infinity, height: 180, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(icon: icon, label: label, background: color.withValues(alpha: 0.12), foreground: color),
                    const Spacer(),
                    Text(timeAgo, style: const TextStyle(color: AppColors.grey500, fontSize: AppTypeScale.caption, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.title, color: AppColors.grey900, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(color: AppColors.grey700, fontSize: AppTypeScale.body, height: 1.45),
                ),
                const SizedBox(height: 12),
                Text('By $author', style: const TextStyle(color: AppColors.grey500, fontSize: AppTypeScale.meta, fontWeight: FontWeight.w600)),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: AppTypeScale.minTapTarget,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.golfLime,
                        foregroundColor: AppColors.grey900,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(actionText!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.body)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
