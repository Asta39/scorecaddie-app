import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/database.dart' as db;
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';
import '../auth/loading_transition_screen.dart';
import 'ob_goo.dart';
import 'ob_screens.dart';
import 'ob_style.dart';
import 'ob_widgets.dart';

/// Where the flow starts: at the role question, or straight into a path.
enum ObEntry { role, player, provider }

enum _Step { role, name, handicap, focus, audience, service, about, photo, personality, club, done }

/// Setup after sign-in: role → the player or coach steps → welcome.
///
/// One screen, as in the prototype, so the guide can melt from Daniel into
/// the player's golf ball or the coach's star, and the progress bar and page
/// state carry across steps. Saving mirrors the previous onboarding screens:
/// the profile, club memberships (active when the club's roster lists the
/// user's email, pending otherwise) and, for coaches and caddies, the
/// marketplace profile. The profile is only marked complete on "Tee off", so
/// the router doesn't whisk the user away before they see the welcome.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key, this.entry = ObEntry.role});
  final ObEntry entry;

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  // ── flow ────────────────────────────────────────────────────────────────
  bool _checking = true;
  _Step _step = _Step.role;
  String? _role; // player | coach | caddie

  // Guide
  bool _asleep = false;
  int _idleSeconds = 0;
  Timer? _sleepTimer;
  String? _swapFrom;
  int _swapNonce = 0;

  // Username
  final _name = TextEditingController();
  String? _checkedName;
  bool? _nameAvailable;
  bool _checkingName = false;
  Timer? _nameDebounce;

  // Handicap
  double _hcp = 18.4;
  bool _hcpUnknown = false;
  bool _dragging = false;

  // Clubs (players) / courses (coaches, caddies)
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _matched = [];
  List<db.Course> _courses = [];
  bool _loadingClubs = true;
  String? _clubId; // players: clubs.id; providers: local course id as string
  final _clubQuery = TextEditingController();

  // Coach / caddie
  final Set<String> _focus = {};
  final Set<String> _audience = {};
  String? _location;
  final _rate = TextEditingController();
  final _phone = TextEditingController();
  final _years = TextEditingController();
  final _bio = TextEditingController();
  File? _photo;
  bool _hasCert = false;
  final _certName = TextEditingController();
  File? _certImage;
  String? _personality;

  bool _saving = false;

  static const _focusOptions = ['Short game', 'Putting', 'Driving', 'Full swing', 'Course strategy', 'Fitness', 'Mental game'];
  static const _audienceOptions = [
    'Children (Under 12)', 'Teenagers (13-17)', 'Young Adults (18-25)', 'Adults (26-55)', 'Seniors (55+)',
    'Beginners', 'Intermediate', 'Advanced', 'Ladies', 'Corporate Groups',
  ];
  static const _locationOptions = ['Driving Range', 'Golf Course', 'Indoor Studio', 'Mixed'];
  static const _personalityOptions = ['Quiet & Focused', 'Talkative & Fun', 'Strategic', 'Laid-back'];

  // ── lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _idleSeconds++;
      final dozeable = _step != _Step.done && !_checking;
      if (dozeable && !_asleep && _idleSeconds > 20) setState(() => _asleep = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(profileServiceProvider).ensureProfile(
            user.uid,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            email: user.email,
          );
      // Read the database directly: the profile stream may not have re-emitted.
      final profile = await ref.read(databaseProvider).getProfile(user.uid);
      if (!mounted) return;
      if (profile != null && profile.profileComplete) {
        context.go('/');
        return;
      }
      final role = profile?.role?.toLowerCase();
      if (widget.entry == ObEntry.player) {
        _role = 'player';
        _step = _Step.name;
      } else if (widget.entry == ObEntry.provider) {
        _role = (role == 'coach' || role == 'caddie') ? role : 'coach';
        _step = _Step.name;
      }
    }
    if (mounted) setState(() => _checking = false);
    _loadClubs();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _nameDebounce?.cancel();
    _name.removeListener(_onNameChanged);
    for (final c in [_name, _clubQuery, _rate, _phone, _years, _bio, _certName]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch([VoidCallback? change]) {
    setState(() {
      _idleSeconds = 0;
      _asleep = false;
      change?.call();
    });
  }

  // ── data ────────────────────────────────────────────────────────────────

  Future<void> _loadClubs() async {
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user?.email != null) {
        // Clubs whose roster lists this email: joined as active members.
        final res = await Supabase.instance.client.rpc('match_user_to_clubs', params: {'user_email': user!.email!});
        _matched = List<Map<String, dynamic>>.from(res);
        final hc = _matched.isNotEmpty ? _matched.first['handicap_index'] : null;
        if (hc is num && hc > 0) _hcp = (hc.toDouble() * 10).round() / 10;
        if (_matched.length == 1) _clubId = _matched.first['club_id'] as String?;
      }
      final clubs = await Supabase.instance.client.from('clubs').select('id, name, location, logo_url').order('name');
      _clubs = List<Map<String, dynamic>>.from(clubs);
      _courses = await ref.read(databaseProvider).getAllCourses(null);
    } catch (e) {
      debugPrint('ONBOARDING: club load failed $e');
    } finally {
      if (mounted) setState(() => _loadingClubs = false);
    }
  }

  // ── username ────────────────────────────────────────────────────────────

  static final _nameChars = RegExp(r'^[A-Za-z0-9_]+$');

  void _onNameChanged() {
    final n = _name.text.trim();
    if (n == _checkedName) return;
    _nameDebounce?.cancel();
    setState(() {
      _nameAvailable = null;
      _checkingName = false;
    });
    if (n.length < 3 || !_nameChars.hasMatch(n)) return;
    _nameDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _checkingName = true);
      final ok = await ref.read(profileServiceProvider).isUsernameAvailable(n);
      if (!mounted || _name.text.trim() != n) return;
      setState(() {
        _checkedName = n;
        _nameAvailable = ok;
        _checkingName = false;
      });
    });
  }

  ({bool ok, String text, Color color}) get _nameStatus {
    final n = _name.text.trim();
    final grey = Ob.creamA(.4);
    if (n.isEmpty) return (ok: false, text: 'Pick something short and memorable', color: grey);
    if (!_nameChars.hasMatch(n)) return (ok: false, text: 'Only letters, numbers and _', color: Ob.warn);
    if (n.length < 3) return (ok: false, text: 'At least 3 characters', color: Ob.warn);
    if (_checkingName || _nameAvailable == null) return (ok: false, text: 'Checking…', color: grey);
    if (_nameAvailable == false) return (ok: false, text: '@$n is taken. Try ${n}_ke?', color: Ob.warn);
    return (ok: true, text: '@$n is yours', color: Ob.lime);
  }

  // ── steps ───────────────────────────────────────────────────────────────

  List<_Step> get _path => switch (_role) {
        'coach' => const [_Step.name, _Step.focus, _Step.audience, _Step.service, _Step.about, _Step.photo, _Step.club],
        'caddie' => const [_Step.name, _Step.about, _Step.personality, _Step.photo, _Step.club],
        _ => const [_Step.name, _Step.handicap, _Step.club],
      };

  List<_Step> get _order => [_Step.role, ..._path, _Step.done];
  int get _stepNum => _step == _Step.role ? 1 : _path.indexOf(_step) + 2;
  int get _stepTotal => _path.length + 1;

  bool get _canContinue => switch (_step) {
        _Step.role => _role != null,
        _Step.name => _nameStatus.ok,
        _Step.handicap => true,
        _Step.focus => _focus.isNotEmpty,
        _Step.audience => _audience.isNotEmpty,
        _Step.service => _location != null && (double.tryParse(_rate.text.trim()) ?? 0) > 0,
        _Step.about => _phone.text.trim().isNotEmpty && _years.text.trim().isNotEmpty && _bio.text.trim().isNotEmpty,
        _Step.photo => _photo != null && (!_hasCert || _certName.text.trim().isNotEmpty),
        _Step.personality => _personality != null,
        _Step.club => _clubId != null,
        _Step.done => true,
      };

  Future<void> _next() async {
    if (!_canContinue || _saving) return;
    FocusScope.of(context).unfocus();
    if (_step == _Step.role) {
      await _saveRole();
    } else if (_step == _Step.club) {
      final ok = _role == 'player' ? await _savePlayer() : await _saveProvider();
      if (!ok) return;
    }
    final i = _order.indexOf(_step);
    _touch(() {
      _step = _order[i + 1];
      _swapFrom = null;
    });
  }

  void _back() {
    FocusScope.of(context).unfocus();
    final i = _order.indexOf(_step);
    if (i <= 0) {
      // Before the role question there's nothing to go back to but sign-out.
      return;
    }
    _touch(() {
      _step = _order[i - 1];
      _swapFrom = null;
    });
  }

  void _pickRole(String role) {
    if (_role == role) return;
    HapticFeedback.mediumImpact();
    final from = ObBot.forRole(_role).idle;
    _touch(() {
      _role = role;
      _swapFrom = from;
      _swapNonce++;
    });
  }

  // ── saving ──────────────────────────────────────────────────────────────

  Future<void> _saveRole() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).updateProfile(
            user.id,
            db.UserProfilesCompanion(
              uid: drift.Value(user.id),
              role: drift.Value(_role),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _savePlayer() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return false;
    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).updateProfile(
            user.id,
            db.UserProfilesCompanion(
              uid: drift.Value(user.id),
              name: drift.Value(_name.text.trim()),
              handicap: drift.Value(_hcpUnknown ? null : _hcp),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );
      final client = Supabase.instance.client;
      final matchedIds = _matched.map((m) => m['club_id'] as String).toSet();
      if (matchedIds.contains(_clubId)) {
        // On the club's roster: active in every matched club.
        for (final id in matchedIds) {
          await client.from('player_club_memberships').upsert(
            {'player_id': user.id, 'club_id': id, 'status': 'active', 'is_home_club': id == _clubId},
            onConflict: 'player_id, club_id',
          );
        }
      } else {
        await client.from('player_club_memberships').upsert(
          {'player_id': user.id, 'club_id': _clubId, 'status': 'pending', 'is_home_club': true},
          onConflict: 'player_id, club_id',
        );
      }
      return true;
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn’t save your profile: $e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _saveProvider() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return false;
    final role = _role ?? 'coach';
    final course = _courses.where((c) => '${c.id}' == _clubId).firstOrNull;
    setState(() => _saving = true);
    try {
      final database = ref.read(databaseProvider);
      var verifiedCoach = false;
      if (role == 'coach' && user.email != null) {
        final coachMatches = _matched.where((m) => m['role'] == 'coach').toList();
        if (coachMatches.isNotEmpty) {
          verifiedCoach = true;
          for (final club in coachMatches) {
            await Supabase.instance.client.from('player_club_memberships').upsert(
              {'player_id': user.id, 'club_id': club['club_id'], 'status': 'active', 'is_home_club': false},
              onConflict: 'player_id, club_id',
            );
          }
        }
      }

      final price = role == 'caddie' ? (course?.caddieFee ?? 1000.0) : (double.tryParse(_rate.text.trim()) ?? 0.0);
      await database.upsertProvider(db.ProvidersCompanion.insert(
        userId: user.id,
        role: role,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        experience: drift.Value(int.tryParse(_years.text.trim()) ?? 0),
        bio: drift.Value(_bio.text.trim()),
        price: drift.Value(price),
        coursesJson: drift.Value(jsonEncode([course?.name])),
        personalityType: drift.Value(role == 'caddie' ? _personality : null),
        specializationsJson: drift.Value(role == 'coach' && _focus.isNotEmpty ? _focus.join(',') : null),
        hasCertification: drift.Value(role == 'coach' ? (verifiedCoach || _hasCert) : false),
        certificationName: drift.Value(role == 'coach' && _hasCert ? _certName.text.trim() : null),
        certificationUrl: drift.Value(role == 'coach' ? _certImage?.path : null),
        coachingLocation: drift.Value(role == 'coach' ? _location : null),
        targetAudienceJson: drift.Value(role == 'coach' && _audience.isNotEmpty ? jsonEncode(_audience.toList()) : null),
        profileComplete: const drift.Value(true),
      ));

      await ref.read(profileServiceProvider).updateProfile(
            user.id,
            db.UserProfilesCompanion(
              uid: drift.Value(user.id),
              name: drift.Value(_name.text.trim()),
              avatarUrl: drift.Value(_photo?.path),
              pfpVerified: drift.Value(verifiedCoach || _photo != null),
              role: drift.Value(role),
              providerStatus: const drift.Value('AVAILABLE'),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );

      final provider = await database.getProvider(user.id);
      if (provider != null) await ref.read(syncServiceProvider).syncProvider(provider);
      return true;
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn’t save your profile: $e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _teeOff() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).updateProfile(
            user.id,
            db.UserProfilesCompanion(
              uid: drift.Value(user.id),
              profileComplete: const drift.Value(true),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );
      ref.invalidate(userProfileProvider);
      ref.read(syncServiceProvider).syncAllPending().catchError((e) => debugPrint('ONBOARDING: background sync $e'));
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80, preferredCameraDevice: CameraDevice.front);
    if (image != null) _touch(() => _photo = File(image.path));
  }

  Future<void> _pickCert() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) _touch(() => _certImage = File(image.path));
  }

  // ── guide ───────────────────────────────────────────────────────────────

  String get _bubble {
    if (_asleep) return 'Zzz… tap anywhere to wake me.';
    final n = _name.text.trim();
    return switch (_step) {
      _Step.role => _role == 'player'
          ? 'A player! Let’s set you up.'
          : _role == 'coach'
              ? 'A coach! Let’s build your profile.'
              : 'How do you play?',
      _Step.name => _nameStatus.ok ? 'Love it, @$n.' : 'What should we call you on the leaderboard?',
      _Step.handicap => _hcpUnknown ? 'No stress. We’ll work it out.' : 'What’s your handicap index?',
      _Step.focus => 'What do you coach?',
      _Step.audience => 'Who do you coach?',
      _Step.service => 'Where do you coach, and your rate?',
      _Step.about => 'Tell players about yourself.',
      _Step.photo => 'Add a clear photo of your face.',
      _Step.personality => 'How are you on the bag?',
      _Step.club => _clubId != null ? 'Great club. Nearly done!' : 'Where’s home?',
      _Step.done => '',
    };
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checking) return const LoadingTransitionScreen(message: 'Loading your profile...');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (_asleep) _touch();
          },
          child: DefaultTextStyle(
            style: Ob.textBase,
            child: SafeArea(child: _step == _Step.done ? _buildDone() : _buildStep()),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    final me = ObBot.forRole(_role);
    final excited = (_step == _Step.name && _nameStatus.ok) || (_step == _Step.club && _clubId != null);
    final botAsset = _asleep ? me.sleep : excited ? me.happy : me.idle;
    final canBack = _order.indexOf(_step) > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Opacity(
                opacity: canBack ? 1 : 0,
                child: ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: canBack ? _back : null),
              ),
              const SizedBox(width: 14),
              Expanded(child: Align(alignment: Alignment.centerLeft, child: ObGooProgress(step: _stepNum, total: _stepTotal))),
              const SizedBox(width: 14),
              SizedBox(
                width: 36,
                child: Text('$_stepNum/$_stepTotal', textAlign: TextAlign.right, style: Ob.display(18, color: Ob.creamA(.6))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ObGuide(
            botAsset: botAsset,
            botLabel: _asleep ? '${me.label}, asleep' : me.label,
            text: _bubble,
            swapFrom: _step == _Step.role ? _swapFrom : null,
            swapColor: me.color,
            swapNonce: _swapNonce,
          ),
          const SizedBox(height: 20),
          Expanded(child: KeyedSubtree(key: ValueKey(_step), child: _stepBody())),
          const SizedBox(height: 20),
          ObButton(
            onPressed: _canContinue && !_saving ? _next : null,
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Ob.ink))
                : Text(_step == _Step.club ? 'Finish setup' : 'Continue', style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
        _Step.role => _roleStep(),
        _Step.name => _nameStep(),
        _Step.handicap => _handicapStep(),
        _Step.focus => _chips(_focusOptions, _focus),
        _Step.audience => _chips(_audienceOptions, _audience),
        _Step.service => _serviceStep(),
        _Step.about => _aboutStep(),
        _Step.photo => _photoStep(),
        _Step.personality => _singleChips(_personalityOptions, _personality, (v) => _personality = v),
        _Step.club => _clubStep(),
        _Step.done => const SizedBox.shrink(),
      };

  // ── role ────────────────────────────────────────────────────────────────

  static const _roleCards = [
    ('player', 'Player', 'Score rounds, track your handicap, climb the club leaderboard.'),
    ('coach', 'Coach', 'Run sessions, assign drills and take bookings from players.'),
  ];

  /// Cards are 112pt as designed, taller when the copy needs more room
  /// (narrow phones, larger text). Both share one height so the liquid fill
  /// is the same shape wherever it flows.
  double _roleCardHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final textWidth = width - 4 - 36 - 74; // border, padding, avatar + gap
    double measure(String text, TextStyle style) =>
        (TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler)
              ..layout(maxWidth: textWidth))
            .height;
    var content = 0.0;
    for (final (_, title, body) in _roleCards) {
      final h = measure(title, Ob.display(28, height: 1.1)) + 4 + measure(body, Ob.body(14, height: 1.45));
      if (h > content) content = h;
    }
    return (content + 4 + 32).ceilToDouble().clamp(112.0, double.infinity);
  }

  Widget _roleStep() {
    final picked = _role == 'coach' ? 1 : 0;
    final on = _role == 'player' || _role == 'coach';
    return LayoutBuilder(builder: (context, box) {
      final cardH = _roleCardHeight(context, box.maxWidth);
      final pitch = cardH + 14;
      return SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The selection's liquid fill flows between cards; a droplet trails.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: picked * pitch),
                duration: const Duration(milliseconds: 550),
                curve: ObCurves.roleBlob,
                builder: (context, blobY, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: picked * pitch),
                  duration: const Duration(milliseconds: 900),
                  curve: ObCurves.roleDrop,
                  builder: (context, dropY, _) => TweenAnimationBuilder<double>(
                    tween: Tween(end: on ? 1 : 0),
                    duration: const Duration(milliseconds: 550),
                    curve: ObCurves.roleBlob,
                    builder: (context, scale, _) => CustomPaint(painter: _RoleBlobPainter(blobY, dropY, scale, cardH)),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                for (final (i, (id, title, body)) in _roleCards.indexed) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _roleCard(id, title, body, cardH).rise(i),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _roleCard(String id, String title, String body, double height) {
    final on = _role == id;
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        onTap: () => _pickRole(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: on ? Colors.transparent : Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: on ? Ob.lime : Ob.hairline, width: 2),
          ),
          child: Row(
            children: [
              Transform.translate(
                offset: const Offset(-8, 0),
                child: BotImage(ObBot.forRole(id).idle, size: 72),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Ob.display(28, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(body, style: Ob.body(14, height: 1.45, color: Ob.creamA(.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── username ────────────────────────────────────────────────────────────

  Widget _nameStep() {
    final st = _nameStatus;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Username', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.72))).rise(),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: TextField(
              controller: _name,
              autofocus: false,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              autofillHints: const [AutofillHints.username],
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), LengthLimitingTextInputFormatter(20)],
              cursorColor: Ob.lime,
              style: Ob.display(28),
              onChanged: (_) => _touch(),
              decoration: _fieldDecoration(
                hint: 'yourname',
                hintStyle: Ob.display(28, color: Ob.creamA(.3)),
                radius: 18,
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 6),
                  child: Text('@', style: Ob.display(28, color: Ob.creamA(.45))),
                ),
              ),
            ),
          ).rise(1),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: st.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Flexible(child: Text(st.text, style: Ob.body(13, weight: FontWeight.w700, color: st.color))),
              ],
            ),
          ).rise(2),
          const SizedBox(height: 12),
          Text(
            'This is how you’ll appear on club leaderboards and to friends. Letters, numbers and underscores.',
            style: Ob.body(14, height: 1.5, color: Ob.creamA(.6)),
          ).rise(3),
        ],
      ),
    );
  }

  // ── handicap ────────────────────────────────────────────────────────────

  void _setHcp(double v) => _touch(() => _hcp = ((v.clamp(0.0, 54.0)) * 10).round() / 10);

  Widget _handicapStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ObIconButton(icon: LucideIcons.minus, label: 'Lower handicap by 0.1', size: 52, onPressed: _hcpUnknown ? null : () => _setHcp(_hcp - .1)),
              // 116px as designed at 390pt wide; scales down on narrower phones.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ObRollingNumber(value: _hcp, fontSize: 116, dragging: _dragging, unknown: _hcpUnknown),
                ),
              ),
              ObIconButton(icon: LucideIcons.plus, label: 'Raise handicap by 0.1', size: 52, onPressed: _hcpUnknown ? null : () => _setHcp(_hcp + .1)),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              _hcpUnknown ? 'Your index appears after three 18-hole rounds.' : 'WHS handicap index, 0 to 54',
              textAlign: TextAlign.center,
              style: Ob.body(14, color: Ob.creamA(.62)),
            ),
          ).rise(1),
          const SizedBox(height: 16),
          if (!_hcpUnknown)
            ObLiquidSlider(
              value: _hcp,
              onChanged: _setHcp,
              onDragChanged: (d) => setState(() => _dragging = d),
            ).rise(2),
          const SizedBox(height: 16),
          Center(child: ObButton(
            tone: ObButtonTone.dark,
            selected: _hcpUnknown,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            onPressed: () => _touch(() => _hcpUnknown = !_hcpUnknown),
            child: Text(_hcpUnknown ? 'Actually, I know my handicap' : 'I don’t have one yet', style: Ob.label(15, weight: FontWeight.w700)),
          )).rise(3),
        ],
      ),
    );
  }

  // ── chips (coach focus / audience, caddie personality) ──────────────────

  Widget _chip(String label, bool on, VoidCallback onTap) => ObButton(
        tone: on ? ObButtonTone.lime : ObButtonTone.dark,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        onPressed: onTap,
        child: Text(label, style: Ob.label(15, weight: FontWeight.w700)),
      );

  Widget _chips(List<String> options, Set<String> selected) => SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, o) in options.indexed)
              _chip(o, selected.contains(o), () => _touch(() => selected.contains(o) ? selected.remove(o) : selected.add(o))).rise(i ~/ 3),
          ],
        ),
      );

  Widget _singleChips(List<String> options, String? value, void Function(String) set) => SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final (i, o) in options.indexed) _chip(o, value == o, () => _touch(() => set(o))).rise(i ~/ 3)],
        ),
      );

  // ── coach service / about / photo ───────────────────────────────────────

  Widget _serviceStep() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Where you coach').rise(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final o in _locationOptions) _chip(o, _location == o, () => _touch(() => _location = o))],
            ).rise(1),
            const SizedBox(height: 24),
            _label('Hourly rate (KES)').rise(2),
            const SizedBox(height: 12),
            _input(_rate, hint: '2500', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]).rise(3),
          ],
        ),
      );

  Widget _aboutStep() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Phone number').rise(),
            const SizedBox(height: 12),
            _input(_phone, hint: '0712 345 678', keyboard: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]).rise(1),
            const SizedBox(height: 16),
            _label('Years of experience').rise(2),
            const SizedBox(height: 12),
            _input(_years, hint: '5', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]).rise(3),
            const SizedBox(height: 16),
            _label('About you').rise(3),
            const SizedBox(height: 12),
            _input(_bio, hint: 'What players can expect from you', lines: 4).rise(4),
          ],
        ),
      );

  Widget _photoStep() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: Semantics(
                button: true,
                label: _photo == null ? 'Take a face photo' : 'Retake face photo',
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Ob.field,
                    border: Border.all(color: _photo != null ? Ob.lime : Ob.fieldBorder, width: 2),
                    image: _photo != null ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover) : null,
                  ),
                  child: _photo == null ? Icon(LucideIcons.camera, size: 36, color: Ob.creamA(.6)) : null,
                ),
              ),
            ).rise(),
            const SizedBox(height: 12),
            Text(
              _photo == null ? 'Tap to take a photo. Players book coaches they can recognise.' : 'Looking good. Tap to retake.',
              textAlign: TextAlign.center,
              style: Ob.body(14, height: 1.5, color: Ob.creamA(.6)),
            ).rise(1),
            if (_role == 'coach') ...[
              const SizedBox(height: 24),
              ObButton(
                tone: ObButtonTone.dark,
                selected: _hasCert,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onPressed: () => _touch(() => _hasCert = !_hasCert),
                child: Text(_hasCert ? 'I’m certified' : 'Are you certified?', style: Ob.label(15, weight: FontWeight.w700)),
              ).rise(2),
              if (_hasCert) ...[
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: _label('Certification')),
                const SizedBox(height: 12),
                _input(_certName, hint: 'PGA Professional'),
                const SizedBox(height: 12),
                ObButton(
                  tone: ObButtonTone.dark,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  onPressed: _pickCert,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_certImage == null ? LucideIcons.upload : LucideIcons.check, size: 16),
                      const SizedBox(width: 8),
                      Text(_certImage == null ? 'Upload certificate' : 'Certificate added', style: Ob.label(15, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      );

  // ── home club ───────────────────────────────────────────────────────────

  Widget _clubStep() {
    final q = _clubQuery.text.trim().toLowerCase();
    // Players pick from the clubs on ScoreCaddie (roster matches first);
    // coaches and caddies pick the course they work from.
    final List<({String id, String name, String town, String? logo, bool roster})> items = _role == 'player'
        ? [
            for (final m in _matched)
              (id: m['club_id'] as String, name: (m['club_name'] ?? 'Club') as String, town: 'On your club’s roster', logo: null, roster: true),
            for (final c in _clubs)
              if (!_matched.any((m) => m['club_id'] == c['id']))
                (id: c['id'] as String, name: (c['name'] ?? '') as String, town: (c['location'] ?? '') as String, logo: c['logo_url'] as String?, roster: false),
          ]
        : [for (final c in _courses) (id: '${c.id}', name: c.name, town: c.location, logo: null, roster: false)];
    final shown = items.where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.town.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TextField(
            controller: _clubQuery,
            cursorColor: Ob.lime,
            style: Ob.body(15),
            onChanged: (_) => _touch(),
            decoration: _fieldDecoration(
              hint: 'Search Kenyan clubs',
              hintStyle: Ob.body(15, color: Ob.creamA(.35)),
              radius: 16,
              prefix: Padding(padding: const EdgeInsets.only(left: 16, right: 10), child: Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5))),
            ),
          ),
        ).rise(),
        const SizedBox(height: 14),
        Expanded(
          child: _loadingClubs
              ? const Center(child: CircularProgressIndicator(color: Ob.lime, strokeWidth: 2.4))
              : shown.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: items.isEmpty
                          // Nothing loaded at all (offline, or the request failed).
                          ? GestureDetector(
                              onTap: () {
                                setState(() => _loadingClubs = true);
                                _loadClubs();
                              },
                              child: Text('Couldn\u2019t load clubs. Tap to try again.', style: Ob.body(14, color: Ob.creamA(.6))),
                            )
                          : Text('No club matches \u201c${_clubQuery.text.trim()}\u201d. You can add it later from your profile.',
                              style: Ob.body(14, color: Ob.creamA(.6))),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 4),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: ObClubTile.extent(context)),
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final c = shown[i];
                        return ObClubTile(
                          name: c.name,
                          town: c.town,
                          logoUrl: c.logo,
                          highlightTown: c.roster,
                          selected: _clubId == c.id,
                          onTap: () => _touch(() => _clubId = c.id),
                        ).rise(i < 6 ? i ~/ 2 : 0);
                      },
                    ),
        ),
      ],
    );
  }

  // ── welcome ─────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final me = ObBot.forRole(_role);
    final n = _name.text.trim().isEmpty ? 'golfer' : _name.text.trim();
    final clubName = _role == 'player'
        ? ([..._matched.map((m) => (m['club_id'], m['club_name'])), ..._clubs.map((c) => (c['id'], c['name']))]
            .where((e) => e.$1 == _clubId)
            .map((e) => '${e.$2}')
            .firstOrNull)
        : _courses.where((c) => '${c.id}' == _clubId).map((c) => c.name).firstOrNull;
    final coach = _role == 'coach';
    return ObWelcome(
      bot: me,
      username: n,
      leftLabel: coach ? 'Coaching' : (_role == 'caddie' ? 'Caddying' : 'Handicap index'),
      leftValue: coach
          ? '${_focus.length} ${_focus.length == 1 ? 'focus' : 'focuses'}'
          : _role == 'caddie'
              ? (_personality ?? 'Ready')
              : (_hcpUnknown ? 'Soon' : _hcp.toStringAsFixed(1)),
      clubName: clubName ?? '\u2014',
      saving: _saving,
      onTeeOff: _teeOff,
    );
  }

  // ── fields ──────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text, style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.72)));

  InputDecoration _fieldDecoration({required String hint, required TextStyle hintStyle, required double radius, Widget? prefix}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: c, width: 2));
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      filled: true,
      fillColor: Ob.field,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      enabledBorder: border(Ob.fieldBorder),
      focusedBorder: border(Ob.lime),
      border: border(Ob.fieldBorder),
    );
  }

  Widget _input(
    TextEditingController c, {
    required String hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    Iterable<String>? autofill,
    int lines = 1,
  }) =>
      TextField(
        controller: c,
        keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
        inputFormatters: formatters,
        autofillHints: autofill,
        minLines: lines,
        maxLines: lines,
        cursorColor: Ob.lime,
        style: Ob.body(16),
        onChanged: (_) => _touch(),
        decoration: _fieldDecoration(hint: hint, hintStyle: Ob.body(16, color: Ob.creamA(.35)), radius: 16),
      );
}

/// Behind the role cards: the selected card's fill, as liquid.
class _RoleBlobPainter extends GooPainter {
  _RoleBlobPainter(this.blobY, this.dropY, this.scale, this.cardH) : super(sigma: 6);
  final double blobY, dropY, scale, cardH;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(30);

  @override
  void paintShapes(Canvas c, Size s) {
    if (scale <= 0) return;
    final p = Paint()..color = Ob.roleFill;
    c.save();
    c.translate(s.width / 2, blobY + cardH / 2);
    c.scale(scale);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s.width, height: cardH), const Radius.circular(24)), p);
    c.restore();
    c.drawCircle(Offset(50, dropY + cardH / 2), 26 * scale, p);
  }

  @override
  bool shouldRepaint(covariant _RoleBlobPainter old) => old.blobY != blobY || old.dropY != dropY || old.scale != scale || old.cardH != cardH;
}
