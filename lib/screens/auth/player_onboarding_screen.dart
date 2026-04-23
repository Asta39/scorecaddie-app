import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;

class PlayerOnboardingScreen extends ConsumerStatefulWidget {
  const PlayerOnboardingScreen({super.key});

  @override
  ConsumerState<PlayerOnboardingScreen> createState() => _PlayerOnboardingScreenState();
}

class _PlayerOnboardingScreenState extends ConsumerState<PlayerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handicapController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _handicapController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final name = _nameController.text.trim();
      final handicapValue = double.tryParse(_handicapController.text.trim());

      await ref.read(profileServiceProvider).updateProfile(
        user.uid,
        db.UserProfilesCompanion(
          firebaseUid: drift.Value(user.uid),
          name: drift.Value(name),
          handicap: drift.Value(handicapValue),
          profileComplete: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      if (mounted) {
        context.go('/');
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Perfect! Just a few\nmore details',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: AppColors.grey900,
                      letterSpacing: -2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Help us personalize your Score Caddie experience.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 56),

                  _buildOnboardingField(
                    controller: _nameController,
                    label: 'WHAT IS YOUR NAME?',
                    hint: 'Tiger Woods',
                    icon: LucideIcons.user,
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  
                  const SizedBox(height: 32),

                  _buildOnboardingField(
                    controller: _handicapController,
                    label: 'CURRENT HANDICAP (OPTIONAL)',
                    hint: '14.2',
                    icon: LucideIcons.award,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: 'INDEX',
                  ),
                  
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'If you don\'t have an official index, we\'ll calculate one automatically as you log your rounds.',
                      style: TextStyle(color: AppColors.grey400, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(height: 80),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _handleComplete,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grey900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                        : const Text('Complete Setup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/select-role'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.grey400),
                      child: const Text('Change Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildOnboardingField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey400,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey100),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey300, fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
              suffixText: suffixText,
              suffixStyle: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w800, fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
      ],
    );
  }
}
