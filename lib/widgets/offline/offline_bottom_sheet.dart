import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

class OfflineBottomSheet extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const OfflineBottomSheet({super.key, this.onRetry});

  static Future<void> show(BuildContext context, {VoidCallback? onRetry}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (context) => OfflineBottomSheet(onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICON
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.wifiOff, size: 40, color: AppColors.grey400),
                ),
                const SizedBox(height: 32),
                
                // TEXT
                const Text(
                  'Connection Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ScoreCaddie works great offline on the course, but this specific feature requires internet to sync with the clubhouse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.grey500, fontWeight: FontWeight.w500, height: 1.5),
                ),
                const SizedBox(height: 40),
                
                // ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: AppColors.grey900,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: () {
                          Navigator.pop(context);
                          onRetry?.call();
                        },
                        child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Stay Offline', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
