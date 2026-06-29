import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';

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
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'announcement':
        icon = LucideIcons.megaphone;
        iconColor = AppColors.golfLime;
        bgColor = AppColors.golfLime.withValues(alpha: 0.1);
        break;
      case 'fixture':
      case 'competition':
        icon = LucideIcons.calendar;
        iconColor = AppColors.blue600;
        bgColor = AppColors.blue600.withValues(alpha: 0.1);
        break;
      case 'result':
        icon = LucideIcons.award;
        iconColor = AppColors.emerald500;
        bgColor = AppColors.emerald500.withValues(alpha: 0.1);
        break;
      default:
        icon = LucideIcons.messageSquare;
        iconColor = AppColors.grey500;
        bgColor = AppColors.grey100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imageUrl!, width: double.infinity, height: 160, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey900, fontSize: 13)),
                          Text(timeAgo, style: const TextStyle(color: AppColors.grey500, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey900)),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(color: AppColors.grey700, fontSize: 14)),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.golfLime,
                        foregroundColor: AppColors.grey900,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(actionText!, style: const TextStyle(fontWeight: FontWeight.bold)),
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
