import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import 'pill.dart';

/// Full-width glassmorphic member card for the Club Life dashboard — golf-lime
/// gradient background with a frosted stat strip, modeled on the Iconly
/// profile-card reference the user shared. Adaptive: sizes off the parent's
/// width rather than fixed pixels, so it holds up on any phone screen.
/// Kept lightweight — the only blur is over the small stat strip, not the
/// whole card, so it stays cheap to render in a scrolling list.
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
    final darkLime = Color.lerp(AppColors.golfLime, Colors.black, 0.35)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.golfLime, darkLime],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: darkLime.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w800, fontSize: 20),
                        )
                      : null,
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.moreHorizontal, color: AppColors.grey900, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800, color: AppColors.grey900),
          ),
          const SizedBox(height: 4),
          Text(
            'Club Member',
            style: TextStyle(fontSize: AppTypeScale.meta, fontWeight: FontWeight.w600, color: AppColors.grey900.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isPublic) ...[
                Pill(
                  icon: LucideIcons.lock,
                  label: 'Private',
                  background: Colors.white.withValues(alpha: 0.35),
                  foreground: AppColors.grey900,
                  dense: true,
                ),
                const SizedBox(width: 8),
              ],
              Pill(
                icon: LucideIcons.flag,
                label: status[0].toUpperCase() + status.substring(1),
                background: Colors.white.withValues(alpha: 0.35),
                foreground: AppColors.grey900,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        icon: LucideIcons.target,
                        value: handicap != null ? handicap!.toStringAsFixed(1) : '--',
                        label: 'Handicap',
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.4)),
                    Expanded(
                      child: _Stat(
                        icon: LucideIcons.shield,
                        value: isPublic ? 'Public' : 'Private',
                        label: 'Visibility',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isPublic) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppTypeScale.minTapTarget,
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(LucideIcons.phone, size: 18),
                label: const Text('Get in Touch', style: TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.body)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.grey900.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(value, style: const TextStyle(fontSize: AppTypeScale.subtitle, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: AppTypeScale.caption, fontWeight: FontWeight.w600, color: AppColors.grey900.withValues(alpha: 0.65))),
      ],
    );
  }
}
