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
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../core/models/auth_user.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';

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

  bool _notifs = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _notifs = p.getBool('notifications_on') ?? true);
    });
  }

  Future<void> _setNotifs(bool on) async {
    setState(() => _notifs = on);
    try {
      (await SharedPreferences.getInstance()).setBool('notifications_on', on);
      on ? OneSignal.User.pushSubscription.optIn() : OneSignal.User.pushSubscription.optOut();
    } catch (e) {
      debugPrint('Notifications toggle: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Stack(children: [
            profileAsync.when(
              data: (profile) => _buildContent(context, profile, user),
              loading: () => const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
              error: (e, s) => Center(child: Text('Couldn\'t load your profile.', style: Ob.body(14, color: Ob.creamA(.7)))),
            ),
            if (_isProcessing) Container(color: Colors.black54, child: const Center(child: CupertinoActivityIndicator(color: Ob.lime))),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, db.UserProfile? profile, AuthUser? user) {
    final bool isGoogleUser = user?.metadata?['iss']?.contains('google') ?? false;
    final bool isCaddie = profile?.role == 'caddie';
    final bool isPro = profile?.role == 'coach' || isCaddie;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      children: [
        ObTopBar('Settings', onBack: () => context.pop()),
        const SizedBox(height: 18),
        Row(children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(clipBehavior: Clip.none, children: [
              ProfileImage(url: profile?.avatarUrl, name: profile?.name, size: 72, isCircle: true),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Ob.lime, shape: BoxShape.circle, border: Border.all(color: Ob.bg, width: 3)),
                  child: const Icon(LucideIcons.camera, size: 13, color: Ob.ink),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile?.name ?? 'Golfer', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(24, height: 1.05)),
              Text(user?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(13, color: Ob.creamA(.6))),
            ]),
          ),
        ]).rise(),
        const SizedBox(height: 22),
        const ObEyebrow('Account'),
        const SizedBox(height: 10),
        _group([
          _row(LucideIcons.user, 'Name', profile?.name ?? 'Not set', () => _showEditNameDialog(context, profile?.name)),
          _row(LucideIcons.mail, 'Email', user?.email ?? 'Not set', () => _showEditEmailDialog(context, user?.email ?? '')),
          _row(LucideIcons.lock, isGoogleUser ? 'Set a password' : 'Password', null, () => _showChangePasswordDialog(context)),
          if (!isPro) _row(LucideIcons.flag, 'Home club', profile?.homeCourseName ?? 'Not set', () => _pickHomeCourse()),
          if (!isPro) _row(LucideIcons.users, 'My clubs', 'Memberships and joining', () => context.push('/profile/clubs')),
        ]),
        if (isPro) ...[
          const SizedBox(height: 22),
          const ObEyebrow('Your professional profile'),
          const SizedBox(height: 10),
          _buildProviderSettings(profile),
        ],
        const SizedBox(height: 22),
        const ObEyebrow('Privacy and alerts'),
        const SizedBox(height: 10),
        _group([
          if (!isCaddie)
            _toggle('Public profile', 'Other golfers can find you and see your index', profile?.privacyLevel == 'Public',
                (v) => _updateProfile(db.UserProfilesCompanion(privacyLevel: drift.Value(v ? 'Public' : 'Private')))),
          _toggle('Notifications', 'Tee times, drills, results and friend requests', _notifs, _setNotifs),
          _row(LucideIcons.database, 'How we use your data', null, () => _showDataUsageInfo(context, isCaddie)),
        ]),
        const SizedBox(height: 22),
        const ObEyebrow('Help'),
        const SizedBox(height: 10),
        _group([
          _row(LucideIcons.circleHelp, 'Help and questions', null, () => context.push('/help', extra: profile?.role)),
          _row(LucideIcons.messageCircle, 'Talk to support', 'WhatsApp', _launchWhatsApp),
          _row(LucideIcons.circleAlert, 'Report a problem', null, _launchEmail),
        ]),
        const SizedBox(height: 24),
        ObButton(
          tone: ObButtonTone.dark,
          onPressed: () => _showLogoutConfirmation(context),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.logOut, size: 18, color: Ob.warn),
            const SizedBox(width: 8),
            Text('Log out', style: Ob.label(15, weight: FontWeight.w800).copyWith(color: Ob.warn)),
          ]),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteConfirmation(context),
            child: Text('Delete my account', style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.45))),
          ),
        ),
      ],
    );
  }

  Future<void> _pickHomeCourse() async {
    final courses = await ref.read(databaseProvider).getAllCourses(null);
    if (!mounted) return;
    final picked = await showObSheet<db.Course>(
      context,
      (ctx) => ObSheet(
        title: 'Home club',
        height: MediaQuery.of(context).size.height * .7,
        child: ListView(children: [
          for (final c in courses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ObSelectTile(
                selected: false,
                onTap: () => Navigator.pop(ctx, c),
                child: Row(children: [
                  ObCrest(c.name, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(c.name, style: Ob.body(15, weight: FontWeight.w700))),
                ]),
              ),
            ),
        ]),
      ),
    );
    if (picked != null) {
      _updateProfile(db.UserProfilesCompanion(homeCourseId: drift.Value(picked.id), homeCourseName: drift.Value(picked.name)));
    }
  }

  Widget _group(List<Widget> rows) => ObCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (final (i, r) in rows.indexed) ...[if (i > 0) const ObHair(), r],
        ]),
      );

  Widget _row(IconData icon, String label, String? value, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: color ?? Ob.lime),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Ob.body(15, weight: FontWeight.w700, color: color ?? Ob.cream))),
          if (value != null)
            Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: Ob.body(13, color: Ob.creamA(.55)))),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight, size: 16, color: Ob.creamA(.35)),
        ]),
      ),
    );
  }

  Widget _toggle(String label, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Ob.body(15, weight: FontWeight.w700)),
            Text(sub, style: Ob.body(12, color: Ob.creamA(.55))),
          ]),
        ),
        Switch.adaptive(value: value, activeTrackColor: Ob.lime, activeThumbColor: Ob.ink, onChanged: onChanged),
      ]),
    );
  }

  /// A dark sheet with one text field; returns the text on Save.
  Future<String?> _askText(String title, {String? initial, String? hint, String? note, bool obscure = false, bool long = false, TextInputType? keyboard}) {
    final c = TextEditingController(text: initial);
    return showObSheet<String>(
      context,
      (ctx) => ObSheet(
        title: title,
        subtitle: note,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: c,
            autofocus: true,
            obscureText: obscure,
            keyboardType: keyboard,
            maxLines: long ? 5 : 1,
            cursorColor: Ob.lime,
            style: Ob.body(15, weight: FontWeight.w700),
            decoration: obInput(null, hint: hint),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: Ob.label(15, weight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(child: ObButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text('Save', style: Ob.label(15, weight: FontWeight.w800)))),
          ]),
        ]),
      ),
    ).whenComplete(c.dispose);
  }

  Future<bool> _confirm(String title, String body, String yes, {bool danger = false}) async {
    final ok = await showObSheet<bool>(
      context,
      (ctx) => ObSheet(
        title: title,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(body, style: Ob.body(14, height: 1.5, color: Ob.creamA(.75))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: Ob.label(15, weight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(
              child: ObButton(
                tone: danger ? ObButtonTone.light : ObButtonTone.lime,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(yes, style: Ob.label(15, weight: FontWeight.w800).copyWith(color: danger ? Ob.warn : null)),
              ),
            ),
          ]),
        ]),
      ),
    );
    return ok == true;
  }

  Future<T?> _pickOne<T>(String title, List<(T, String)> options, {String? note}) => showObSheet<T>(
        context,
        (ctx) => ObSheet(
          title: title,
          subtitle: note,
          height: options.length > 6 ? MediaQuery.of(context).size.height * .7 : null,
          child: options.length > 6
              ? ListView(children: [for (final o in options) _pickTile(ctx, o)])
              : Column(children: [for (final o in options) _pickTile(ctx, o)]),
        ),
      );

  Widget _pickTile<T>(BuildContext ctx, (T, String) o) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ObSelectTile(selected: false, onTap: () => Navigator.pop(ctx, o.$1), child: Text(o.$2, style: Ob.body(15, weight: FontWeight.w700))),
      );

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

    return _group([
      _row(LucideIcons.mapPin, 'Home Club', currentCourse, () => _showCoursePicker(provider)),
      _row(LucideIcons.banknote, isCaddie ? 'Caddie Fee' : 'Hourly Rate', 'KES ${provider.price?.toInt() ?? 0}', isCaddie 
          ? () => _showError('Caddie fees are set by the golf club.')
          : () => _showEditProviderFieldDialog('Rate', provider.price?.toString(), (v) => _updateProvider(db.ProvidersCompanion(price: drift.Value(double.tryParse(v)))))),
      _row(LucideIcons.calendar, 'Experience', '${provider.experience} Years', () => _showEditProviderFieldDialog('Experience', provider.experience.toString(), (v) => _updateProvider(db.ProvidersCompanion(experience: drift.Value(int.tryParse(v) ?? 0))))),
      if (isCaddie)
        _row(LucideIcons.smile, 'Personality', provider.personalityType ?? 'Not set', () => _showPersonalityPicker(provider)),
      _row(LucideIcons.fileText, 'Professional Bio', null, () => _showEditProviderFieldDialog('Bio', provider.bio, (v) => _updateProvider(db.ProvidersCompanion(bio: drift.Value(v))), isLongText: true)),
      _row(LucideIcons.award, 'Certifications', '${_parseCertificates(provider.certificatesJson).length} total', () => _showCertificatesManager(provider)),      ]);
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
    final c = await _pickOne<db.Course>('Home club', [for (final c in courses) (c, c.name)], note: 'Your rates follow your home club.');
    if (c == null) return;
    final isCaddie = provider.role == 'caddie';
    _updateProvider(db.ProvidersCompanion(
      coursesJson: drift.Value(jsonEncode([c.name])),
      price: isCaddie ? drift.Value(c.caddieFee) : const drift.Value.absent(),
    ));
  }

  void _showPersonalityPicker(db.Provider provider) async {
    const personalities = ['Quiet & Focused', 'Talkative & Fun', 'Strategic', 'Laid-back'];
    final p = await _pickOne<String>('Personality', [for (final p in personalities) (p, p)]);
    if (p != null) _updateProvider(db.ProvidersCompanion(personalityType: drift.Value(p)));
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

  Future<void> _showEditNameDialog(BuildContext context, String? currentName) async {
    final v = await _askText('Your name', initial: currentName, hint: 'Name');
    if (v != null && v.trim().isNotEmpty) _updateProfile(db.UserProfilesCompanion(name: drift.Value(v.trim())));
  }

  Future<void> _showEditEmailDialog(BuildContext context, String currentEmail) async {
    final v = (await _askText('Email', initial: currentEmail, keyboard: TextInputType.emailAddress, note: 'We\'ll send a link to the new address to confirm it.'))?.trim();
    if (v == null || v.isEmpty || v == currentEmail) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(supabaseAuthServiceProvider).updateEmail(v);
      _updateProfile(db.UserProfilesCompanion(email: drift.Value(v)));
      _showSuccess('Check your inbox to confirm the new email.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final v = (await _askText('New password', obscure: true, note: 'At least 6 characters.'))?.trim();
    if (v == null) return;
    if (v.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await ref.read(supabaseAuthServiceProvider).updatePassword(v);
      _showSuccess('Password updated');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final ok = await _confirm('Delete your account?', 'You lose every round, stat, caddie booking and achievement. This can\'t be undone.', 'Delete', danger: true);
    if (ok) _handleDeleteAccount();
  }

  Future<void> _handleDeleteAccount() async {
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

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final ok = await _confirm('Log out?', 'Your rounds stay saved to your account.', 'Log out', danger: true);
    if (!ok) return;
    await ref.read(supabaseAuthServiceProvider).signOut();
    if (mounted) this.context.go('/auth');
  }

  void _showCertificatesManager(db.Provider provider) {
    showObSheet(
      context,
      (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final certs = _parseCertificates(ref.read(currentProviderProvider).valueOrNull?.certificatesJson ?? provider.certificatesJson);
        return ObSheet(
          title: 'Certifications',
          subtitle: 'Players see these on your profile.',
          height: MediaQuery.of(context).size.height * .7,
          child: Column(children: [
            Expanded(
              child: certs.isEmpty
                  ? Center(child: Text('Nothing added yet.', style: Ob.body(14, color: Ob.creamA(.6))))
                  : ListView(children: [
                      for (final (i, cert) in certs.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ObCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: _certImage(cert['imagePath'] as String?),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('${cert['name'] ?? 'Certification'}', style: Ob.body(15, weight: FontWeight.w700))),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(LucideIcons.trash2, color: Ob.warn, size: 18),
                                onPressed: () {
                                  final next = List<Map<String, dynamic>>.from(certs)..removeAt(i);
                                  _updateProvider(db.ProvidersCompanion(certificatesJson: drift.Value(jsonEncode(next))));
                                  Future.delayed(const Duration(milliseconds: 400), () => setSheet(() {}));
                                },
                              ),
                            ]),
                          ),
                        ),
                    ]),
            ),
            const SizedBox(height: 12),
            ObButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddCertificateDialog(provider);
              },
              child: Text('Add a certification', style: Ob.label(15, weight: FontWeight.w800)),
            ),
          ]),
        );
      }),
    );
  }

  Widget _certImage(String? path) {
    final fallback = Container(color: Ob.creamA(.06), child: Icon(LucideIcons.award, color: Ob.creamA(.4)));
    if (path == null) return fallback;
    return path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback)
        : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
  }

  void _showAddCertificateDialog(db.Provider provider) {
    final controller = TextEditingController();
    File? picked;
    showObSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ObSheet(
          title: 'Add a certification',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: controller,
              autofocus: true,
              cursorColor: Ob.lime,
              style: Ob.body(15, weight: FontWeight.w700),
              decoration: obInput('Name', hint: 'PGA Kenya Level 2'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) setSheet(() => picked = File(image.path));
              },
              child: Container(
                height: 110,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(18), border: Border.all(color: Ob.creamA(.12))),
                child: picked == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(LucideIcons.image, color: Ob.creamA(.5)),
                        const SizedBox(height: 6),
                        Text('Add a photo of it', style: Ob.body(13, color: Ob.creamA(.6))),
                      ])
                    : Image.file(picked!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            ObButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final certs = _parseCertificates(provider.certificatesJson)..add({'name': controller.text.trim(), 'imagePath': picked?.path});
                  _updateProvider(db.ProvidersCompanion(certificatesJson: drift.Value(jsonEncode(certs))));
                }
                Navigator.pop(ctx);
              },
              child: Text('Add', style: Ob.label(15, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _showEditProviderFieldDialog(String label, String? currentValue, Function(String) onSave, {bool isLongText = false}) async {
    final v = await _askText(label, initial: currentValue, long: isLongText, keyboard: isLongText ? null : TextInputType.number);
    if (v != null) onSave(v);
  }

  void _showDataUsageInfo(BuildContext context, bool isCaddie) {
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'How we use your data',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            isCaddie
                ? 'We use your details to manage bookings, track earnings and show your profile to golfers looking for a caddie.'
                : 'We use your data to sync your rounds, work out your handicap and power Daniel\'s practice notes. It\'s stored securely and never sold.',
            style: Ob.body(14, height: 1.55, color: Ob.creamA(.8)),
          ),
          const SizedBox(height: 16),
          ObButton(onPressed: () => Navigator.pop(ctx), child: Text('Got it', style: Ob.label(15, weight: FontWeight.w800))),
        ]),
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
