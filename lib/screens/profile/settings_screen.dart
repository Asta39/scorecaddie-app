import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';

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
            UserProfilesCompanion(avatarUrl: drift.Value(pickedFile.path))
          );
          ref.invalidate(userProfileProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated!'), backgroundColor: AppColors.emerald700),
            );
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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.grey900),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900, fontSize: 17),
        ),
      ),
      body: Stack(
        children: [
          profileAsync.when(
            data: (profile) => _buildContent(context, profile, user),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CupertinoActivityIndicator(radius: 15)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserProfile? profile, auth.User? user) {
    final bool isGoogleUser = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

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
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        image: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                            ? (profile.avatarUrl!.startsWith('http')
                                ? DecorationImage(image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover)
                                : DecorationImage(image: FileImage(File(profile.avatarUrl!)), fit: BoxFit.cover))
                            : null,
                      ),
                      child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                          ? Center(child: Text(profile?.name.isNotEmpty == true ? profile!.name[0].toUpperCase() : 'G', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 44, color: AppColors.grey200)))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.emerald700, shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Change Profile Picture',
                style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w600, fontSize: 14),
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
            onTap: () => _showEditEmailDialog(context, user?.email),
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
            textColor: AppColors.emerald700,
            onTap: () => _showLogoutConfirmation(context),
          ),
          _buildiOSActionTile(
            icon: LucideIcons.trash2,
            label: 'Delete Account',
            textColor: AppColors.doubleBogey,
            onTap: () => _showDeleteConfirmation(context),
          ),
        ]),

        _buildSectionHeader('PRIVACY AND DATA'),
        _buildGroupedCard([
          _buildiOSSwitchTile(
            icon: LucideIcons.eye,
            label: 'Public Profile',
            value: profile?.privacyLevel == 'Public',
            onChanged: (v) => _updateProfile(UserProfilesCompanion(privacyLevel: drift.Value(v ? 'Public' : 'Private'))),
          ),
          _buildiOSActionTile(
            icon: LucideIcons.database,
            label: 'Data Usage',
            onTap: () => _showDataUsageInfo(context),
          ),
        ]),

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
            activeColor: AppColors.emerald700,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSettings(UserProfile? profile) {
    final provider = ref.watch(currentProviderProvider).valueOrNull;
    if (provider == null) return const SizedBox.shrink();

    return _buildGroupedCard([
      _buildiOSActionTile(
        icon: LucideIcons.banknote,
        label: 'Hourly Rate',
        trailingText: 'KES ${provider.price?.toInt() ?? 0}',
        onTap: () => _showEditProviderFieldDialog('Rate', provider.price?.toString(), (v) => _updateProvider(ProvidersCompanion(price: drift.Value(double.tryParse(v))))),
      ),
      _buildiOSActionTile(
        icon: LucideIcons.calendar,
        label: 'Experience',
        trailingText: '${provider.experience} Years',
        onTap: () => _showEditProviderFieldDialog('Experience', provider.experience.toString(), (v) => _updateProvider(ProvidersCompanion(experience: drift.Value(int.tryParse(v) ?? 0)))),
      ),
      _buildiOSActionTile(
        icon: LucideIcons.fileText,
        label: 'Professional Bio',
        onTap: () => _showEditProviderFieldDialog('Bio', provider.bio, (v) => _updateProvider(ProvidersCompanion(bio: drift.Value(v))), isLongText: true),
      ),
    ]);
  }

  // --- Logic Methods ---

  void _updateProvider(ProvidersCompanion companion) async {
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await (db.update(db.providers)..where((p) => p.userId.equals(user.uid))).write(companion);
      final provider = await (db.select(db.providers)..where((p) => p.userId.equals(user.uid))).get().then((rows) => rows.firstOrNull);
      if (provider != null) ref.read(syncServiceProvider).syncProvider(provider);
      ref.invalidate(currentProviderProvider);
    } catch (e) {
      _showError('Error updating professional profile: $e');
    }
  }

  void _updateProfile(UserProfilesCompanion companion) async {
    final service = ref.read(profileServiceProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await service.updateProfile(user.uid, companion);
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
                _updateProfile(UserProfilesCompanion(name: drift.Value(controller.text)));
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(BuildContext context, String? currentEmail) {
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
                  await ref.read(firebaseAuthServiceProvider).updateEmail(controller.text.trim());
                  _updateProfile(UserProfilesCompanion(email: drift.Value(controller.text.trim())));
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
                  await ref.read(firebaseAuthServiceProvider).updatePassword(controller.text);
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
      final uid = user.uid;

      // 1. Wipe Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('profiles').doc(uid).delete();
      await firestore.collection('providers').doc(uid).delete();
      
      // Delete rounds, interactions etc from users collection
      final userDoc = firestore.collection('users').doc(uid);
      final rounds = await userDoc.collection('rounds').get();
      for (var d in rounds.docs) { await d.reference.delete(); }
      
      final interactions = await userDoc.collection('interactions').get();
      for (var d in interactions.docs) { await d.reference.delete(); }
      
      // 2. Wipe Local DB
      final db = ref.read(databaseProvider);
      await (db.delete(db.rounds)..where((r) => r.userId.equals(uid))).go();
      await (db.delete(db.practiceSessions)..where((s) => s.userId.equals(uid))).go();
      await (db.delete(db.clubs)..where((c) => c.userId.equals(uid))).go();
      await (db.delete(db.friends)..where((f) => f.userId.equals(uid))).go();
      await (db.delete(db.userProfiles)..where((u) => u.firebaseUid.equals(uid))).go();

      // 3. Delete Auth Account
      await ref.read(firebaseAuthServiceProvider).deleteAccount();
      
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
              await ref.read(firebaseAuthServiceProvider).signOut();
              if (mounted) context.go('/auth');
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

  void _showEditProviderFieldDialog(String title, String? currentValue, Function(String) onSave, {bool isLongText = false}) {
    final controller = TextEditingController(text: currentValue);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Edit $title'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: controller, placeholder: 'Enter $title', autofocus: true, maxLines: isLongText ? 5 : 1),
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

  void _showDataUsageInfo(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Data Usage'),
        content: const Text('ScoreCaddie uses your data to sync rounds, track handicaps, and provide AI swing analysis. Your data is stored securely and never sold to third parties.'),
        actions: [
          CupertinoDialogAction(child: const Text('Close'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.doubleBogey, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.emerald700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
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
