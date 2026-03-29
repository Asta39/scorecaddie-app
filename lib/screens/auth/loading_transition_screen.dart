import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class LoadingTransitionScreen extends ConsumerStatefulWidget {
  final String message;
  const LoadingTransitionScreen({super.key, this.message = 'Setting up your experience...'});

  @override
  ConsumerState<LoadingTransitionScreen> createState() => _LoadingTransitionScreenState();
}

class _LoadingTransitionScreenState extends ConsumerState<LoadingTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Golf Ball / Icon
            RotationTransition(
              turns: _animation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.emerald700.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.loader2,
                  size: 48,
                  color: AppColors.emerald700,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Just a moment while we get things ready.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () => ref.read(firebaseAuthServiceProvider).signOut(),
              child: const Text('Sign Out', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
