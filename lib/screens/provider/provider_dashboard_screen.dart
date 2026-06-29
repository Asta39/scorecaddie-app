import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import 'coach_dashboard_screen.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile?.role == 'coach') {
          return const CoachDashboardScreen();
        } else {
          // Fallback or Generic Provider View
          return const _GenericProviderDashboard();
        }
      },
      loading: () => const Scaffold(body: Center(child: CupertinoActivityIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _GenericProviderDashboard extends ConsumerWidget {
  const _GenericProviderDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.user, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            const Text('Edit your profile to get started', style: TextStyle(color: AppColors.grey500)),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              child: const Text('Edit Profile'),
              onPressed: () => context.push('/profile/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
