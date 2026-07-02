import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/top_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Username validation state
  bool? _isNameAvailable;
  bool _isValidating = false;
  String? _lastCheckedName;
  Timer? _debounce;

  // Selection state
  final List<String> _selectedSpecializations = [];
  final List<String> _selectedCoachingStyles = [];
  final List<String> _selectedSessionTypes = [];
  final List<String> _selectedTargetAudience = [];
  String? _selectedPersonality;
  db.Course? _selectedHomeCourse;
  String? _selectedLocation;
  bool _hasCertification = false;
  File? _certificationImage;
  File? _profileImage;
  bool _isPfpVerified = false;
  final bool _isAnalyzingPfp = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    _certificationNameController.dispose();
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

  Future<void> _pickCertification() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _certificationImage = File(image.path));
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
        _isPfpVerified = true; // Auto-verify for now since AI service is removed
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isNameAvailable == false) {
      TopNotification.showError(context, 'Please choose a different username.');
      return;
    }
    if (_selectedHomeCourse == null) {
      TopNotification.showError(context, 'Please select your home course');
      return;
    }
    if (_profileImage == null || !_isPfpVerified) {
      TopNotification.showError(context, 'A verified face photo is required.');
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final database = ref.read(databaseProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final role = ref.read(userProfileProvider).valueOrNull?.role ?? 'caddie';
      
      bool isVerifiedCoach = false;
      if (role == 'coach' && user.email != null) {
        final matchRes = await Supabase.instance.client.rpc(
          'match_user_to_clubs',
          params: {'user_email': user.email!}
        );
        final matches = List<Map<String, dynamic>>.from(matchRes);
        final coachMatches = matches.where((m) => m['role'] == 'coach').toList();
        
        if (coachMatches.isNotEmpty) {
           isVerifiedCoach = true;
           // Link them to their matched clubs as active
           for (var club in coachMatches) {
             await Supabase.instance.client.from('player_club_memberships').upsert({
               'player_id': user.id,
               'club_id': club['club_id'],
               'status': 'active',
               'is_home_club': false
             }, onConflict: 'player_id, club_id');
           }
        }
      }

      final double finalPrice = role == 'caddie' 
          ? (_selectedHomeCourse?.caddieFee ?? 1000.0)
          : (double.tryParse(_priceController.text) ?? 0.0);

      // 1. Create/Update Provider record
      await database.upsertProvider(db.ProvidersCompanion.insert(
        userId: user.id,
        role: role,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: drift.Value(_whatsappController.text.isNotEmpty ? _whatsappController.text : null),
        experience: drift.Value(int.tryParse(_experienceController.text) ?? 0),
        bio: drift.Value(_bioController.text.trim()),
        price: drift.Value(finalPrice),
        coursesJson: drift.Value(jsonEncode([_selectedHomeCourse?.name])),
        personalityType: drift.Value(role == 'caddie' ? _selectedPersonality : null),
        specializationsJson: drift.Value(role == 'coach' && _selectedSpecializations.isNotEmpty ? _selectedSpecializations.join(',') : null),
        hasCertification: drift.Value(role == 'coach' ? (isVerifiedCoach ? true : _hasCertification) : false),
        certificationName: drift.Value(role == 'coach' && _hasCertification ? _certificationNameController.text.trim() : null),
        certificationUrl: drift.Value(role == 'coach' ? _certificationImage?.path : null),
        coachingLocation: drift.Value(role == 'coach' ? _selectedLocation : null),
        coachingStylesJson: drift.Value(role == 'coach' && _selectedCoachingStyles.isNotEmpty ? _selectedCoachingStyles.join(',') : null),
        sessionTypesJson: drift.Value(role == 'coach' && _selectedSessionTypes.isNotEmpty ? _selectedSessionTypes.join(',') : null),
        targetAudienceJson: drift.Value(role == 'coach' && _selectedTargetAudience.isNotEmpty ? jsonEncode(_selectedTargetAudience) : null),
        profileComplete: const drift.Value(true),
      ));

      // 2. Update core profile — include the role so dashboard routes correctly
      final name = _nameController.text.trim();
      final upperRole = role.toUpperCase();
      
      await ref.read(profileServiceProvider).updateProfile(
        user.id,
        db.UserProfilesCompanion(
          uid: drift.Value(user.id),
          name: drift.Value(name),
          avatarUrl: drift.Value(_profileImage?.path),
          pfpVerified: drift.Value(isVerifiedCoach ? true : _isPfpVerified),
          role: drift.Value(upperRole),
          providerStatus: const drift.Value('AVAILABLE'),
          profileComplete: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // 3. Trigger immediate sync with ALL fields
      final updatedProvider = await database.getProvider(user.id);
      if (updatedProvider != null) {
        await ref.read(syncServiceProvider).syncProvider(updatedProvider);
      }

      if (mounted) {
        // Force Riverpod to re-read the profile with updated role
        ref.invalidate(userProfileProvider);
        
        // Allow state to propagate before navigating
        await Future.delayed(const Duration(milliseconds: 200));

        // Trigger background sync for other tables but don't block
        ref.read(syncServiceProvider).syncAllPending().catchError((e) {
          debugPrint('ONBOARDING: Background sync error $e');
        });

        if (mounted) context.go('/');
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
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? 'caddie';
    final isCoach = role == 'coach';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
              _buildPfpPicker(),
              const SizedBox(height: 32),
              _buildOnboardingField(
                controller: _nameController,
                label: 'FULL NAME / USERNAME',
                hint: 'Tiger Woods',
                icon: LucideIcons.user,
                isNameField: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Name required';
                  if (v.length < 3) return 'Too short';
                  if (_isNameAvailable == false) return 'Already taken';
                  return null;
                },
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
              
              _buildCourseSelector(),
              
              if (isCoach) ...[
                const SizedBox(height: 24),
                _buildOnboardingField(
                  controller: _priceController,
                  label: 'HOURLY RATE (KES)',
                  hint: '2500',
                  icon: LucideIcons.banknote,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Price required' : null,
                ),
                const SizedBox(height: 24),
                _buildDropdownField(
                  label: 'COACHING LOCATION',
                  value: _selectedLocation,
                  items: ['Driving Range', 'Golf Course', 'Indoor Studio', 'Mixed'],
                  onChanged: (v) => setState(() => _selectedLocation = v),
                ),
                const SizedBox(height: 40),
                _buildSectionHeader('TARGET AUDIENCE'),
                _buildChipGroup(
                  label: 'WHO DO YOU COACH?',
                  options: ['Children (Under 12)', 'Teenagers (13-17)', 'Young Adults (18-25)', 'Adults (26-55)', 'Seniors (55+)', 'Beginners', 'Intermediate', 'Advanced', 'Ladies', 'Corporate Groups'],
                  selected: _selectedTargetAudience,
                  onChanged: (v) => setState(() {
                    if (_selectedTargetAudience.contains(v)) {
                      _selectedTargetAudience.remove(v);
                    } else {
                      _selectedTargetAudience.add(v);
                    }
                  }),
                ),
              ],

              if (!isCoach) ...[
                const SizedBox(height: 24),
                if (_selectedHomeCourse != null) ...[
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: AppColors.emerald50,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: AppColors.emerald100),
                     ),
                     child: Row(
                       children: [
                         const Icon(LucideIcons.info, color: AppColors.emerald700, size: 20),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Text(
                             'Based on ${_selectedHomeCourse!.name}\'s regulations, your caddie fee is set to KES ${_selectedHomeCourse!.caddieFee?.toInt() ?? 1000}.',
                             style: const TextStyle(color: AppColors.emerald800, fontSize: 13, fontWeight: FontWeight.w600),
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                ],
                _buildDropdownField(
                  label: 'PERSONALITY TYPE',
                  value: _selectedPersonality,
                  items: ['Quiet & Focused', 'Talkative & Fun', 'Strategic', 'Laid-back'],
                  onChanged: (v) => setState(() => _selectedPersonality = v),
                ),
              ],

              if (isCoach) ...[
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
                            activeTrackColor: AppColors.emerald700.withValues(alpha: 0.5),
                            activeThumbColor: AppColors.emerald700,
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
              ],

              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: (_isSaving || _isValidating) ? null : _submit,
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Complete Setup', 
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                      ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPfpPicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  shape: BoxShape.circle,
                  border: Border.all(color: _isPfpVerified ? AppColors.emerald500 : AppColors.grey200, width: 3),
                  image: _profileImage != null 
                      ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _profileImage == null 
                    ? Icon(LucideIcons.camera, color: AppColors.grey300, size: 32)
                    : null,
              ),
              if (_isAnalyzingPfp)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: const Center(child: CupertinoActivityIndicator(color: Colors.white)),
                  ),
                ),
              if (_isPfpVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.emerald500, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isPfpVerified ? 'ID VERIFIED BY AI' : (_isAnalyzingPfp ? 'AI ANALYZING...' : 'PROFILE PHOTO'),
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            color: _isPfpVerified ? AppColors.emerald700 : AppColors.grey400,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
              style: const TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            if (isNameField) _buildAvailabilityIndicator(),
          ],
        ),
        const SizedBox(height: 8),
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
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey300, fontWeight: FontWeight.w500, fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.grey400, size: 18),
              suffixIcon: isNameField && _isValidating 
                  ? const Padding(padding: EdgeInsets.all(12), child: CupertinoActivityIndicator(radius: 8))
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              initialValue: value,
              hint: const Text('Select Option', style: TextStyle(color: AppColors.grey300, fontSize: 14)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
              onChanged: onChanged,
              decoration: const InputDecoration(border: InputBorder.none),
              validator: (v) => v == null ? 'Selection required' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipGroup({
    required String label,
    required List<String> options,
    required List<String> selected,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.emerald700 : AppColors.grey50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.emerald700 : AppColors.grey100,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.white : AppColors.grey600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${selected.length} selected',
            style: const TextStyle(color: AppColors.emerald700, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _buildCourseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOME CLUB / BASE COURSE',
          style: TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCoursePicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.mapPin, color: AppColors.grey400, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedHomeCourse?.name ?? 'Select your home club',
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 15,
                      color: _selectedHomeCourse == null ? AppColors.grey300 : AppColors.grey900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(LucideIcons.chevronDown, color: AppColors.grey400, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCoursePicker() async {
    final courses = await ref.read(databaseProvider).getAllCourses(null);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Select Your Home Club', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.grey900)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: courses.length,
                itemBuilder: (context, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  title: Text(courses[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(courses[i].location, style: const TextStyle(color: AppColors.grey400, fontSize: 12)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    setState(() => _selectedHomeCourse = courses[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
