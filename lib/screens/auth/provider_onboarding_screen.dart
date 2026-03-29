import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;

class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  ConsumerState<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends ConsumerState<ProviderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  final _certificationNameController = TextEditingController();

  // Selection state
  final List<String> _selectedCourses = [];
  final List<String> _selectedSpecializations = [];
  final List<String> _selectedCoachingStyles = [];
  final List<String> _selectedSessionTypes = [];
  String? _selectedPersonality;
  String? _selectedLocation;
  bool _hasCertification = false;
  File? _certificationImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    _certificationNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCertification() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _certificationImage = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final database = ref.read(databaseProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final role = ref.read(userProfileProvider).valueOrNull?.role ?? 'caddie';

      // 1. Create/Update Provider record
      await database.upsertProvider(db.ProvidersCompanion.insert(
        userId: user.uid,
        role: role,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: drift.Value(_whatsappController.text.isNotEmpty ? _whatsappController.text : null),
        experience: drift.Value(int.tryParse(_experienceController.text) ?? 0),
        bio: drift.Value(_bioController.text.trim()),
        price: drift.Value(double.tryParse(_priceController.text)),
        coursesJson: drift.Value(role == 'caddie' ? _selectedCourses.join(',') : '[]'),
        personalityType: drift.Value(role == 'caddie' ? _selectedPersonality : null),
        specializationsJson: drift.Value(role == 'coach' && _selectedSpecializations.isNotEmpty ? _selectedSpecializations.join(',') : null),
        hasCertification: drift.Value(_hasCertification),
        certificationName: drift.Value(_hasCertification ? _certificationNameController.text.trim() : null),
        certificationUrl: drift.Value(_certificationImage?.path),
        coachingLocation: drift.Value(role == 'coach' ? _selectedLocation : null),
        coachingStylesJson: drift.Value(role == 'coach' && _selectedCoachingStyles.isNotEmpty ? _selectedCoachingStyles.join(',') : null),
        sessionTypesJson: drift.Value(role == 'coach' && _selectedSessionTypes.isNotEmpty ? _selectedSessionTypes.join(',') : null),
        profileComplete: const drift.Value(true),
      ));

      // 2. Update core profile
      await ref.read(profileServiceProvider).updateProfile(
        user.uid,
        db.UserProfilesCompanion(
          firebaseUid: drift.Value(user.uid),
          name: drift.Value(_nameController.text.trim()),
          profileComplete: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // 3. Trigger immediate sync
      final provider = await (database.select(database.providers)..where((p) => p.userId.equals(user.uid))).get().then((rows) => rows.firstOrNull);
      if (provider != null) {
        await ref.read(syncServiceProvider).syncProvider(provider);
      }

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.doubleBogey));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? 'caddie';
    final isCoach = role == 'coach';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
            onPressed: () => context.go('/select-role'),
          ),
          title: Text(
            isCoach ? 'Coach Onboarding' : 'Caddie Onboarding',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900, fontSize: 18),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(32.0),
            children: [
              Text(
                isCoach ? 'Set up your coaching profile' : 'Set up your caddie profile',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Let students and players know why they should choose you.',
                style: TextStyle(color: AppColors.grey500, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 48),

              _buildSectionHeader('BASIC INFORMATION'),
              _buildOnboardingField(
                controller: _nameController,
                label: 'FULL NAME',
                hint: 'Tiger Woods',
                icon: LucideIcons.user,
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildOnboardingField(
                      controller: _phoneController,
                      label: 'PHONE NUMBER',
                      hint: '0712345678',
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOnboardingField(
                      controller: _experienceController,
                      label: 'EXP (YEARS)',
                      hint: '5',
                      icon: LucideIcons.calendar,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildOnboardingField(
                controller: _bioController,
                label: 'ABOUT ME',
                hint: 'Tell us about your experience...',
                icon: LucideIcons.fileText,
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Bio required' : null,
              ),
              
              const SizedBox(height: 40),
              _buildSectionHeader('SERVICE DETAILS'),
              _buildOnboardingField(
                controller: _priceController,
                label: 'HOURLY RATE (KES)',
                hint: '2500',
                icon: LucideIcons.banknote,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Price required' : null,
              ),
              
              if (isCoach) ...[
                const SizedBox(height: 24),
                _buildDropdownField(
                  label: 'COACHING LOCATION',
                  value: _selectedLocation,
                  items: ['Driving Range', 'Golf Course', 'Indoor Studio', 'Mixed'],
                  onChanged: (v) => setState(() => _selectedLocation = v),
                ),
              ],

              const SizedBox(height: 40),
              _buildSectionHeader('CERTIFICATIONS'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grey100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Are you certified?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Switch.adaptive(
                          value: _hasCertification, 
                          onChanged: (v) => setState(() => _hasCertification = v),
                          activeColor: AppColors.emerald700,
                        ),
                      ],
                    ),
                    if (_hasCertification) ...[
                      const SizedBox(height: 20),
                      _buildOnboardingField(
                        controller: _certificationNameController,
                        label: 'CERTIFICATION NAME',
                        hint: 'PGA Professional',
                        icon: LucideIcons.award,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickCertification,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.grey100, width: 2),
                          ),
                          child: _certificationImage == null 
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.image, color: AppColors.grey300),
                                  const SizedBox(height: 8),
                                  const Text('Upload Certificate', style: TextStyle(color: AppColors.grey400, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_certificationImage!, fit: BoxFit.cover),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grey900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Complete Setup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildOnboardingField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey100),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey300, fontWeight: FontWeight.w500, fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.grey400, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey100),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: value,
              hint: const Text('Select Option', style: TextStyle(color: AppColors.grey300, fontSize: 14)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
              onChanged: onChanged,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }
}
