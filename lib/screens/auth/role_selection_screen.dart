import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import 'loading_transition_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isSaving = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        await ref.read(profileServiceProvider).ensureProfile(
          user.uid,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          email: user.email,
        );
      }
      if (mounted) {
        setState(() => _isChecking = false);
      }
    });
  }

  Future<void> _handleRoleSelection() async {
    if (_selectedRole == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      await ref.read(profileServiceProvider).updateProfile(
        user.uid,
        db.UserProfilesCompanion(
          firebaseUid: drift.Value(user.uid),
          role: drift.Value(_selectedRole),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (_selectedRole == 'player') {
          context.go('/player-onboarding');
        } else {
          context.go('/provider-onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.doubleBogey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const LoadingTransitionScreen(message: 'Loading your profile...');
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to\nScore Caddie',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.grey900,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select your primary role to customize your experience.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  children: [
                    _RoleCard(
                      title: 'Player',
                      description: 'Track your scores, analyze your swing, and improve your handicap.',
                      icon: LucideIcons.user,
                      isSelected: _selectedRole == 'player',
                      onTap: () => setState(() => _selectedRole = 'player'),
                      color: AppColors.emerald700,
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      title: 'Caddie',
                      description: 'Provide expert assistance, manage rounds, and grow your reputation.',
                      icon: LucideIcons.briefcase,
                      isSelected: _selectedRole == 'caddie',
                      onTap: () => setState(() => _selectedRole = 'caddie'),
                      color: AppColors.blue700,
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      title: 'Coach',
                      description: 'Train students, share specialized drills, and analyze performance.',
                      icon: LucideIcons.graduationCap,
                      isSelected: _selectedRole == 'coach',
                      onTap: () => setState(() => _selectedRole = 'coach'),
                      color: AppColors.purple700,
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: (_selectedRole != null && !_isSaving) ? _handleRoleSelection : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grey900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                      : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : AppColors.grey50,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? color : AppColors.grey100,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.grey400,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? color : AppColors.grey900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
