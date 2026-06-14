import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/top_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Username validation state
  bool? _isNameAvailable;
  bool _isValidating = false;
  String? _lastCheckedName;
  Timer? _debounce;
  
  List<Map<String, dynamic>> _clubs = [];
  String? _selectedClubId;
  bool _isLoadingClubs = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _fetchClubs();
  }
  
  Future<void> _fetchClubs() async {
    try {
      final res = await Supabase.instance.client
          .from('Course')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() {
          _clubs = List<Map<String, dynamic>>.from(res);
          _isLoadingClubs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClubs = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _handicapController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    if (name == _lastCheckedName) return;
    
    if (name.length < 3) {
      setState(() {
        _isNameAvailable = null;
        _isValidating = false;
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() {
        _isValidating = true;
        _lastCheckedName = name;
      });

      final available = await ref.read(profileServiceProvider).isUsernameAvailable(name);
      
      if (!mounted) return;
      setState(() {
        _isNameAvailable = available;
        _isValidating = false;
      });
    });
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isNameAvailable == false) {
      TopNotification.showError(context, 'Please choose a different username.');
      return;
    }
    
    if (_selectedClubId == null) {
      TopNotification.showError(context, 'Please select your home club.');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final name = _nameController.text.trim();
      final handicapValue = double.tryParse(_handicapController.text.trim());

      await ref.read(profileServiceProvider).updateProfile(
        user.id,
        db.UserProfilesCompanion(
          uid: drift.Value(user.id),
          name: drift.Value(name),
          handicap: drift.Value(handicapValue),
          profileComplete: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      
      // Also save club membership
      await Supabase.instance.client.from('player_club_memberships').insert({
        'player_id': user.id,
        'club_id': _selectedClubId,
        'status': 'active'
      });

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) context.go('/');
        });
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Error: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
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
                    label: 'CHOOSE A USERNAME',
                    hint: 'TigerWoods82',
                    icon: LucideIcons.user,
                    isNameField: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (val.length < 3) return 'Too short';
                      if (_isNameAvailable == false) return 'Already taken';
                      return null;
                    },
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

                  const SizedBox(height: 32),
                  
                  // Club Selection
                  const Text(
                    'SELECT YOUR HOME CLUB',
                    style: TextStyle(
                      color: AppColors.grey400,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.grey100),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedClubId,
                        hint: Text(
                          _isLoadingClubs ? 'Loading clubs...' : 'Choose your club',
                          style: const TextStyle(color: AppColors.grey300, fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        icon: const Icon(LucideIcons.chevronDown, color: AppColors.grey400),
                        items: _clubs.map((club) {
                          return DropdownMenuItem<String>(
                            value: club['id'],
                            child: Text(
                              club['name'],
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey900),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClubId = val;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton(
                      onPressed: (_isSaving || _isValidating) ? null : _handleComplete,
                      child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                        : const Text('Complete Setup', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/select-role'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.grey600),
                      child: const Text('Change Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
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
    bool isNameField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (isNameField) _buildAvailabilityIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNameField && _isNameAvailable == false 
                ? AppColors.doubleBogey.withValues(alpha: 0.5) 
                : AppColors.grey100
            ),
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
              suffixIcon: isNameField && _isValidating 
                  ? const Padding(padding: EdgeInsets.all(12), child: CupertinoActivityIndicator(radius: 8))
                  : null,
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

  Widget _buildAvailabilityIndicator() {
    if (_nameController.text.length < 3) return const SizedBox();
    if (_isValidating) return const SizedBox();

    if (_isNameAvailable == true) {
      return const Row(
        children: [
          Icon(LucideIcons.checkCircle2, color: AppColors.emerald700, size: 12),
          SizedBox(width: 4),
          Text('NAME AVAILABLE', style: TextStyle(color: AppColors.emerald700, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      );
    } else if (_isNameAvailable == false) {
      return const Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.doubleBogey, size: 12),
          SizedBox(width: 4),
          Text('NAME ALREADY TAKEN', style: TextStyle(color: AppColors.doubleBogey, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      );
    }
    return const SizedBox();
  }
}
