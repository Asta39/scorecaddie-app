import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import 'pill.dart';

/// Compact glassmorphic member row for the Club Life Members list — meant to
/// hold up when a club has hundreds of members, so it stays small: white
/// frosted background, thin border, no per-card blur (a real blur per row
/// would tank scroll performance at list scale; the "glass" read here comes
/// from the translucent tint + soft shadow instead).
class MemberGlassCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double? handicap;
  final String status;
  final bool isPublic;
  final VoidCallback? onCall;

  const MemberGlassCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.handicap,
    required this.status,
    required this.isPublic,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.grey900.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.golfLime.withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w800, fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.body, color: AppColors.grey900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      handicap != null ? 'Handicap ${handicap!.toStringAsFixed(1)}' : 'No handicap',
                      style: const TextStyle(color: AppColors.grey600, fontSize: AppTypeScale.caption, fontWeight: FontWeight.w600),
                    ),
                    if (!isPublic) ...[
                      const SizedBox(width: 8),
                      const Pill(
                        icon: LucideIcons.lock,
                        label: 'Private',
                        background: AppColors.grey100,
                        foreground: AppColors.grey600,
                        dense: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isPublic)
            IconButton(
              icon: const Icon(LucideIcons.phone, color: AppColors.grey900, size: 20),
              onPressed: onCall,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.golfLime,
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}
