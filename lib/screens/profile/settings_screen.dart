import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../core/models/auth_user.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/loading_spinner.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final user = ref.read(authStateProvider).valueOrNull;
        if (user != null) {
          await ref.read(profileServiceProvider).updateProfile(
            user.uid, 
            db.UserProfilesCompanion(avatarUrl: drift.Value(pickedFile.path))
          );
          ref.invalidate(userProfileProvider);
          if (mounted) {
            TopNotification.showSuccess(context, 'Profile picture updated!');
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.grey25,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.grey25,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.grey900),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 17),
        ),
      ),
      body: Stack(
        children: [
          profileAsync.when(
            data: (profile) => _buildContent(context, profile, user),
            loading: () => const LoadingSpinner(),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const LoadingSpinner(size: 60),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, db.UserProfile? profile, AuthUser? user) {
    final bool isGoogleUser = user?.metadata?['iss']?.contains('google') ?? false;
    final bool isCaddie = profile?.role == 'caddie';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // Centered Profile Picture
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    ProfileImage(
                      url: profile?.avatarUrl,
                      name: profile?.name,
                      size: 100,
                      isCircle: true,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.grey900, shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.camera_fill, color: AppColors.golfLime, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Change Profile Picture',
                style: TextStyle(
                  color: profile?.role == 'caddie' ? AppColors.grey900 : AppColors.emerald700, 
                  fontWeight: FontWeight.w700, 
                  fontSize: 14
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('ACCOUNT'),
        _buildGroupedCard([
          _buildiOSActionTile(
            icon: LucideIcons.user,
            label: 'Name',
            trailingText: profile?.name ?? 'Not set',
            onTap: () => _showEditNameDialog(context, profile?.name),
          ),
          _buildiOSActionTile(
            icon: LucideIcons.mail,
            label: 'Email',
            trailingText: user?.email ?? 'Not set',
            onTap: () => _showEditEmailDialog(context, user?.email ?? ''),
          ),
        ]),

        if (profile?.role == 'coach' || profile?.role == 'caddie') ...[
          _buildSectionHeader('PROFESSIONAL PROFILE'),
          _buildProviderSettings(profile),
        ],

        _buildSectionHeader('SECURITY'),
        _buildGroupedCard([
          _buildiOSActionTile(
            icon: LucideIcons.lock,
            label: isGoogleUser ? 'Set Account Password' : 'Change Password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          _buildiOSActionTile(
            icon: LucideIcons.logOut,
            label: 'Logout',
            textColor: isCaddie ? AppColors.grey900 : AppColors.emerald700,
            onTap: () => _showLogoutConfirmation(context),
          ),
          _buildiOSActionTile(
            icon: LucideIcons.trash2,
            label: 'Delete Account',
            textColor: AppColors.doubleBogey,
            onTap: () => _showDeleteConfirmation(context),
          ),
        ]),

        if (!isCaddie) ...[
          _buildSectionHeader('PRIVACY AND DATA'),
          _buildGroupedCard([
            _buildiOSSwitchTile(
              icon: LucideIcons.eye,
              label: 'Public Profile',
              value: profile?.privacyLevel == 'Public',
              onChanged: (v) => _updateProfile(db.UserProfilesCompanion(privacyLevel: drift.Value(v ? 'Public' : 'Private'))),
            ),
            _buildiOSActionTile(
              icon: LucideIcons.database,
              label: 'Data Usage',
              onTap: () => _showDataUsageInfo(context, isCaddie),
            ),
          ]),

          _buildSectionHeader('NOTIFICATIONS'),
          _buildGroupedCard([
            _buildiOSSwitchTile(
              icon: LucideIcons.bell,
              label: 'Enable All Notifications',
              value: true, // Placeholder for state
              onChanged: (v) {},
            ),
          ]),
        ] else ...[
          _buildSectionHeader('DATA & PRIVACY'),
          _buildGroupedCard([
            _buildiOSActionTile(
              icon: LucideIcons.database,
              label: 'Data Usage',
              onTap: () => _showDataUsageInfo(context, isCaddie),
            ),
          ]),
        ],

        _buildSectionHeader('SUPPORT'),
        _buildGroupedCard([
          _buildiOSActionTile(
            icon: LucideIcons.helpCircle,
            label: 'Help & FAQs',
            onTap: () => context.push('/help', extra: profile?.role),
          ),
          _buildiOSActionTile(
            icon: LucideIcons.messageCircle,
            label: 'Contact Support',
            trailingText: 'WhatsApp',
            onTap: _launchWhatsApp,
          ),
          _buildiOSActionTile(
            icon: LucideIcons.alertCircle,
            label: 'Report a Problem',
            onTap: _launchEmail,
          ),
        ]),
        
        const SizedBox(height: 100),
      ],
    );
  }

  // --- Widget Builders ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey500, letterSpacing: -0.1),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(left: 56),
                  child: Divider(height: 1, color: Color(0xFFE5E5EA)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildiOSActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? trailingText,
    Color? textColor,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: textColor == AppColors.doubleBogey ? AppColors.doubleBogey.withValues(alpha: 0.1) : AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: textColor ?? AppColors.grey700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? AppColors.grey900,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(color: AppColors.grey500, fontSize: 15),
              ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }

  Widget _buildiOSSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.grey700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.grey900, fontWeight: FontWeight.w400),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.emerald700,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSettings(db.UserProfile? profile) {
    final provider = ref.watch(currentProviderProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (provider == null || user == null) return const SizedBox.shrink();

    final isCaddie = profile?.role == 'caddie';
    String currentCourse = 'Not set';
    try {
      final List<dynamic> courses = jsonDecode(provider.coursesJson);
      if (courses.isNotEmpty) currentCourse = courses[0];
    } catch (_) {}

    return _buildGroupedCard([
      _buildiOSActionTile(
        icon: LucideIcons.mapPin,
        label: 'Home Club',
        trailingText: currentCourse,
        onTap: () => _showCoursePicker(provider),
      ),
      _buildiOSActionTile(
        icon: LucideIcons.banknote,
        label: isCaddie ? 'Caddie Fee' : 'Hourly Rate',
        trailingText: 'KES ${provider.price?.toInt() ?? 0}',
        onTap: isCaddie 
          ? () => _showError('Caddie fees are set by the golf club.')
          : () => _showEditProviderFieldDialog('Rate', provider.price?.toString(), (v) => _updateProvider(db.ProvidersCompanion(price: drift.Value(double.tryParse(v))))),
      ),
      _buildiOSActionTile(
        icon: LucideIcons.calendar,
        label: 'Experience',
        trailingText: '${provider.experience} Years',
        onTap: () => _showEditProviderFieldDialog('Experience', provider.experience.toString(), (v) => _updateProvider(db.ProvidersCompanion(experience: drift.Value(int.tryParse(v) ?? 0)))),
      ),
      if (isCaddie)
        _buildiOSActionTile(
          icon: LucideIcons.smile,
          label: 'Personality',
          trailingText: provider.personalityType ?? 'Not set',
          onTap: () => _showPersonalityPicker(provider),
        ),
      _buildiOSActionTile(
        icon: LucideIcons.fileText,
        label: 'Professional Bio',
        onTap: () => _showEditProviderFieldDialog('Bio', provider.bio, (v) => _updateProvider(db.ProvidersCompanion(bio: drift.Value(v))), isLongText: true),
      ),
      _buildiOSActionTile(
        icon: LucideIcons.award,
        label: 'Certifications',
        trailingText: '${_parseCertificates(provider.certificatesJson).length} total',
        onTap: () => _showCertificatesManager(provider),
      ),      ]);
      }
  List<Map<String, dynamic>> _parseCertificates(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is String) return {'name': e, 'imagePath': null};
          return <String, dynamic>{};
        }).where((e) => e.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('Error parsing json certificates: $e');
    }
    return [];
  }

  void _showCoursePicker(db.Provider provider) async {
    final courses = await ref.read(databaseProvider).getAllCourses(null);
    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Home Club'),
        message: const Text('Changing your home club will update your rates accordingly.'),
        actions: courses.map((c) => CupertinoActionSheetAction(
          onPressed: () {
            final isCaddie = provider.role == 'caddie';
            _updateProvider(db.ProvidersCompanion(
              coursesJson: drift.Value(jsonEncode([c.name])),
              price: isCaddie ? drift.Value(c.caddieFee) : const drift.Value.absent(),
            ));
            Navigator.pop(context);
          },
          child: Text(c.name, style: const TextStyle(color: AppColors.grey900)),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showPersonalityPicker(db.Provider provider) {
    final personalities = ['Quiet & Focused', 'Talkative & Fun', 'Strategic', 'Laid-back'];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Personality Type'),
        actions: personalities.map((p) => CupertinoActionSheetAction(
          onPressed: () {
            _updateProvider(db.ProvidersCompanion(personalityType: drift.Value(p)));
            Navigator.pop(context);
          },
          child: Text(p, style: const TextStyle(color: AppColors.grey900)),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // --- Logic Methods ---

  void _updateProvider(db.ProvidersCompanion companion) async {
    final database = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await (database.update(database.providers)..where((p) => p.userId.equals(user.id))).write(companion);
      final provider = await (database.select(database.providers)..where((p) => p.userId.equals(user.id))).get().then((rows) => rows.firstOrNull);
      if (provider != null) {
        await ref.read(syncServiceProvider).syncProvider(provider);
      }
      ref.invalidate(currentProviderProvider);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      _showError('Error updating professional profile: $e');
    }
  }

  void _updateProfile(db.UserProfilesCompanion companion) async {
    final service = ref.read(profileServiceProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await service.updateProfile(user.id, companion);
      ref.invalidate(userProfileProvider);
    }
  }

  // --- Dialogs ---

  void _showEditNameDialog(BuildContext context, String? currentName) {
    final controller = TextEditingController(text: currentName);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: controller, placeholder: 'Enter name', autofocus: true),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateProfile(db.UserProfilesCompanion(name: drift.Value(controller.text)));
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(BuildContext context, String currentEmail) {
    final controller = TextEditingController(text: currentEmail);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Update Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('We will send a verification link to your new email address.'),
            const SizedBox(height: 12),
            CupertinoTextField(controller: controller, placeholder: 'New email address', keyboardType: TextInputType.emailAddress, autofocus: true),
          ],
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Update'),
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != currentEmail) {
                try {
                  setState(() => _isProcessing = true);
                  Navigator.pop(context);
                  await ref.read(supabaseAuthServiceProvider).updateEmail(controller.text.trim());
                  _updateProfile(db.UserProfilesCompanion(email: drift.Value(controller.text.trim())));
                  _showSuccess('Verification email sent. Please check your inbox.');
                } catch (e) {
                  _showError(e.toString());
                } finally {
                  setState(() => _isProcessing = false);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Update Password'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: controller, placeholder: 'New password', obscureText: true, autofocus: true),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () async {
              if (controller.text.length >= 6) {
                try {
                  setState(() => _isProcessing = true);
                  Navigator.pop(context);
                  await ref.read(supabaseAuthServiceProvider).updatePassword(controller.text.trim());
                  _showSuccess('Password updated successfully!');
                } catch (e) {
                  _showError(e.toString());
                } finally {
                  setState(() => _isProcessing = false);
                }
              } else {
                _showError('Password must be at least 6 characters.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This is irreversible. You will lose all rounds, stats, caddie history, and achievements. Are you absolutely sure?'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete Permanently'),
            onPressed: () => _handleDeleteAccount(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    Navigator.pop(context); // Close dialog
    setState(() => _isProcessing = true);
    
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      final uid = user.id;
      
      // 2. Wipe Local DB (Dependency order)
      final database = ref.read(databaseProvider);
      
      // Delete hole scores for user rounds
      final userRounds = await (database.select(database.rounds)..where((r) => r.userId.equals(uid))).get();
      final userRoundIds = userRounds.map((r) => r.id).toList();
      if (userRoundIds.isNotEmpty) {
        await (database.delete(database.holeScores)..where((h) => h.roundId.isIn(userRoundIds))).go();
      }
      
      // Delete practice shots for user sessions
      final userSessions = await (database.select(database.practiceSessions)..where((s) => s.userId.equals(uid))).get();
      final userSessionIds = userSessions.map((s) => s.id).toList();
      if (userSessionIds.isNotEmpty) {
        await (database.delete(database.practiceShots)..where((s) => s.sessionId.isIn(userSessionIds))).go();
      }

      // Delete drill steps for user drills
      final userDrills = await (database.select(database.drills)..where((d) => d.userId.equals(uid))).get();
      final userDrillIds = userDrills.map((d) => d.id).toList();
      if (userDrillIds.isNotEmpty) {
        await (database.delete(database.drillSteps)..where((s) => s.drillId.isIn(userDrillIds))).go();
      }

      // Now delete the main tables
      await (database.delete(database.rounds)..where((r) => r.userId.equals(uid))).go();
      await (database.delete(database.practiceSessions)..where((s) => s.userId.equals(uid))).go();
      await (database.delete(database.clubs)..where((c) => c.userId.equals(uid))).go();
      await (database.delete(database.friends)..where((f) => f.userId.equals(uid) | f.friendId.equals(uid))).go();
      await (database.delete(database.drills)..where((d) => d.userId.equals(uid))).go();
      await (database.delete(database.providers)..where((p) => p.userId.equals(uid))).go();
      await (database.delete(database.interactions)..where((i) => i.playerId.equals(uid) | i.providerId.equals(uid))).go();
      await (database.delete(database.reviews)..where((r) => r.playerId.equals(uid) | r.providerId.equals(uid))).go();
      await (database.delete(database.bookings)..where((b) => b.playerId.equals(uid) | b.providerId.equals(uid))).go();
      await (database.delete(database.messages)..where((m) => m.senderId.equals(uid) | m.receiverId.equals(uid))).go();
      await (database.delete(database.inquiries)..where((i) => i.playerId.equals(uid) | i.providerId.equals(uid))).go();
      await (database.delete(database.groupRoundParticipants)..where((p) => p.userId.equals(uid))).go();
      await (database.delete(database.groupRounds)..where((g) => g.captainId.equals(uid))).go();
      await (database.delete(database.userProfiles)..where((u) => u.uid.equals(uid))).go();

      // 3. Delete Auth Account
      final authService = ref.read(supabaseAuthServiceProvider);
      await authService.deleteAccount();
      
      // Force immediate auth state update
      ref.invalidate(authStateProvider);
      ref.invalidate(userProfileProvider);
      
      if (mounted) context.go('/auth');
    } catch (e) {
      _showError('Deletion failed: $e. You may need to re-authenticate first.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Logout'),
        message: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              await ref.read(supabaseAuthServiceProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Logout'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showCertificatesManager(db.Provider provider) {
    final certs = _parseCertificates(provider.certificatesJson);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Certifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddCertificateDialog(provider);
                    },
                    child: const Text('Add New', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: certs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.award, size: 64, color: AppColors.grey100),
                          const SizedBox(height: 16),
                          const Text('No certificates added yet', style: TextStyle(color: AppColors.grey400, fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: certs.length,
                      itemBuilder: (context, index) {
                        final cert = certs[index];
                        final String? imagePath = cert['imagePath'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.grey100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.grey100),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: imagePath != null
                                  ? (imagePath.startsWith('http') 
                                      ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(LucideIcons.image, color: AppColors.grey200))
                                      : Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(LucideIcons.image, color: AppColors.grey200)))
                                  : const Icon(LucideIcons.image, color: AppColors.grey200),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  cert['name'] ?? 'Certification',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey900),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.doubleBogey, size: 20),
                                onPressed: () {
                                  final newCerts = List<Map<String, dynamic>>.from(certs);
                                  newCerts.removeAt(index);
                                  _updateProvider(db.ProvidersCompanion(certificatesJson: drift.Value(jsonEncode(newCerts))));
                                  Navigator.pop(context);
                                  _showCertificatesManager(provider);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grey900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCertificateDialog(db.Provider provider) {
    final controller = TextEditingController();
    File? pickedImage;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Add Certification'),
          content: Column(
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Certificate Name (e.g. PGA Certified)',
                autofocus: true,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) {
                    setDialogState(() => pickedImage = File(image.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CupertinoColors.extraLightBackgroundGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: pickedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.image, color: AppColors.grey300),
                            SizedBox(height: 4),
                            Text('Tap to add photo', style: TextStyle(color: AppColors.grey400, fontSize: 12)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(pickedImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final certs = _parseCertificates(provider.certificatesJson);
                  certs.add({
                    'name': controller.text.trim(),
                    'imagePath': pickedImage?.path,
                  });
                  _updateProvider(db.ProvidersCompanion(certificatesJson: drift.Value(jsonEncode(certs))));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProviderFieldDialog(String label, String? currentValue, Function(String) onSave, {bool isLongText = false}) {
    final controller = TextEditingController(text: currentValue);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Edit $label'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: controller, placeholder: 'Enter $label', autofocus: true, maxLines: isLongText ? 5 : 1),
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDataUsageInfo(BuildContext context, bool isCaddie) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Data Usage'),
        content: Text(isCaddie 
          ? 'ScoreCaddie uses your data to manage bookings, track earnings, and showcase your professional profile to golfers. Your professional information is shared on the marketplace to help you find more work.'
          : 'ScoreCaddie uses your data to sync rounds, track handicaps, and provide AI swing analysis. Your data is stored securely and never sold to third parties.'),
        actions: [
          CupertinoDialogAction(child: const Text('Close'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    TopNotification.showError(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    TopNotification.showSuccess(context, message);
  }

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/254115706542');
    if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
  }

  Future<void> _launchEmail() async {
    final url = Uri.parse('mailto:evoqcreativetech@gmail.com?subject=Report a Problem - ScoreCaddie');
    if (await canLaunchUrl(url)) { await launchUrl(url); }
  }
}
