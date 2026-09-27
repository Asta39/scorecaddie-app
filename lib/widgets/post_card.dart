import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../screens/onboarding/ob_app.dart';
import '../screens/onboarding/ob_style.dart';

String formatTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

/// A club post: announcement, event, result or notice.
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
    final (IconData icon, Color color, String label) = switch (type) {
      'announcement' => (LucideIcons.megaphone, Ob.lime, 'Announcement'),
      'fixture' || 'competition' => (LucideIcons.calendar, const Color(0xFF7DD3FC), 'Event'),
      'result' => (LucideIcons.trophy, const Color(0xFFF5C531), 'Result'),
      _ => (LucideIcons.messageSquare, Ob.creamA(.7), 'Notice'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ObCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(imageUrl!, height: 180, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, size: 17, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(author, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w700)),
                        Text('$label · $timeAgo', style: Ob.body(12, color: Ob.creamA(.55))),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(title, style: Ob.display(20, height: 1.15)),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(content, style: Ob.body(14, height: 1.5, color: Ob.creamA(.8))),
                  ],
                  if (actionText != null && onAction != null) ...[
                    const SizedBox(height: 14),
                    ObButton(
                      onPressed: onAction,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(actionText!, style: Ob.label(14, weight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
