import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_providers.dart';
import '../../providers/booking_providers.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

class CasualBookingScreen extends ConsumerStatefulWidget {
  const CasualBookingScreen({super.key});

  @override
  ConsumerState<CasualBookingScreen> createState() => _CasualBookingScreenState();
}

class _CasualBookingScreenState extends ConsumerState<CasualBookingScreen> {
  int _currentStep = 0;
  String? _selectedCourseId;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final List<Map<String, dynamic>> _guestPlayers = [];
  bool _beNotified = true;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;
  Set<String> _homeClubs = {};
  
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoadingSlots = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final response = await supabase.from('Course').select('id, name, location').order('name');
      final coursesList = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> uniqueCourses = {};
      for (var course in coursesList) {
        uniqueCourses[course['name']] = course;
      }
      final sortedCourses = uniqueCourses.values.toList();
      
      Set<String> homeCourseIds = {};
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final membershipRes = await supabase.from('player_club_memberships').select('club_id, clubs(name)').eq('player_id', user.id).eq('status', 'active');
          
          final myClubNames = (membershipRes as List).map((m) {
            final name = (m['clubs'] as Map)['name']?.toString().toLowerCase() ?? '';
            return name.replaceAll('golf club', '').replaceAll('club', '').trim();
          }).where((n) => n.isNotEmpty).toSet();

          for (var course in sortedCourses) {
             final courseName = course['name'].toString().toLowerCase().replaceAll('golf club', '').replaceAll('club', '').trim();
             if (myClubNames.contains(courseName)) {
                homeCourseIds.add(course['id'].toString());
             }
          }
          
          sortedCourses.sort((a, b) {
            final aIsHome = homeCourseIds.contains(a['id'].toString());
            final bIsHome = homeCourseIds.contains(b['id'].toString());
            if (aIsHome && !bIsHome) return -1;
            if (!aIsHome && bIsHome) return 1;
            return a['name'].toString().compareTo(b['name'].toString());
          });
        }
      } catch (e) {
        sortedCourses.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
      }
      
      if (mounted) {
        setState(() {
          _homeClubs = homeCourseIds;
          _courses = sortedCourses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _fetchAvailableSlots(DateTime date) async {
    if (_selectedCourseId == null) return;
    setState(() => _isLoadingSlots = true);
    
    try {
      final String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final List<Map<String, dynamic>> slots = [];
      
      try {
        final res = await supabase.rpc('get_available_tee_times', params: {
          'p_course_id': _selectedCourseId,
          'p_date': dateStr,
        });
        final List<dynamic> data = res;
        for (final row in data) {
          final timeStr = row['time_slot'].toString().substring(0, 5);
          final spots = row['remaining_capacity'] as int;
          slots.add({
            'time': timeStr,
            'available': spots,
            'blocked': spots == 0 || row['is_blocked'] == true,
            'reason': row['is_blocked'] == true ? row['block_reason'] : (spots == 0 ? 'Full' : null),
          });
        }
      } catch (e) {
        debugPrint('Error with get_available_tee_times: $e');
      }

      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
          _selectedTimeSlot = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  static const _stepTitles = ['Where are you playing?', 'When?', 'Who\'s playing?', 'All good?'];

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: ObTopBar('Book a tee time', eyebrow: 'Step ${_currentStep + 1} of 4', onBack: _back),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        decoration: BoxDecoration(color: i <= _currentStep ? Ob.lime : Ob.creamA(.1), borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Text(_stepTitles[_currentStep], style: Ob.display(30, height: 1.05)),
                    const SizedBox(height: 16),
                    _buildCurrentStep(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCourseSelection();
      case 1:
        return _buildDateAndTimeSelection();
      case 2:
        return _buildPlayerSelection();
      case 3:
        return _buildConfirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCourseSelection() {
    if (_isLoadingCourses) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    if (_courses.isEmpty) return ObCard(child: Text('Couldn\'t load courses. Go back and try again.', style: Ob.body(14, color: Ob.creamA(.7))));
    return Column(children: [
      for (final c in _courses)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ObSelectTile(
            selected: _selectedCourseId == c['id'].toString(),
            onTap: () => setState(() => _selectedCourseId = c['id'].toString()),
            child: Row(children: [
              ObCrest(c['name'].toString(), size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['name'].toString(), style: Ob.body(15, weight: FontWeight.w800)),
                  Text(c['location']?.toString() ?? 'Kenya', style: Ob.body(12, color: Ob.creamA(.55))),
                ]),
              ),
              if (_homeClubs.contains(c['id'].toString())) const ObChip('Home club', on: true),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildDateAndTimeSelection() {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = [for (var i = 0; i < 14; i++) today.add(Duration(days: i))];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final d = days[i];
            final on = _selectedDate != null && DateUtils.isSameDay(_selectedDate, d);
            return ObSelectTile(
              selected: on,
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              onTap: () {
                setState(() => _selectedDate = d);
                _fetchAvailableSlots(d);
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(i == 0 ? 'Today' : DateFormat('EEE').format(d), style: Ob.body(11, weight: FontWeight.w700, color: on ? Ob.lime : Ob.creamA(.6))),
                Text('${d.day}', style: Ob.display(24, height: 1.1)),
                Text(DateFormat('MMM').format(d), style: Ob.body(10, color: Ob.creamA(.5))),
              ]),
            );
          },
        ),
      ),
      if (_selectedDate == null) ...[
        const SizedBox(height: 20),
        Text('Pick a day to see open slots.', style: Ob.body(14, color: Ob.creamA(.6))),
      ] else ...[
        const SizedBox(height: 22),
        ObEyebrow('Open slots · ${DateFormat('EEE d MMM').format(_selectedDate!)}'),
        const SizedBox(height: 10),
        if (_isLoadingSlots)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
        else if (_availableSlots.isEmpty)
          ObCard(child: Text('No slots open that day. Try another.', style: Ob.body(14, color: Ob.creamA(.7))))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.7, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _availableSlots.length,
            itemBuilder: (_, i) {
              final slot = _availableSlots[i];
              final blocked = slot['blocked'] == true;
              final on = _selectedTimeSlot == slot['time'];
              return Opacity(
                opacity: blocked ? .4 : 1,
                child: ObSelectTile(
                  selected: on,
                  padding: EdgeInsets.zero,
                  onTap: blocked ? null : () => setState(() => _selectedTimeSlot = slot['time']),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(slot['time'], style: Ob.display(20, color: on ? Ob.lime : Ob.cream).copyWith(decoration: blocked ? TextDecoration.lineThrough : null)),
                    Text(
                      blocked ? (slot['reason']?.toString() ?? 'Taken') : '${slot['available']} ${slot['available'] == 1 ? 'spot' : 'spots'}',
                      style: Ob.body(11, color: Ob.creamA(.55)),
                    ),
                  ]),
                ),
              );
            },
          ),
      ],
    ]);
  }

  Widget _buildPlayerSelection() {
    final me = ref.watch(userProfileProvider).valueOrNull;
    Widget row(String name, String sub, {VoidCallback? onRemove, bool host = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ObSelectTile(
            selected: host,
            onTap: null,
            child: Row(children: [
              ProfileImage(url: host ? me?.avatarUrl : null, name: name, size: 38, isCircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: Ob.body(15, weight: FontWeight.w800)),
                  Text(sub, style: Ob.body(12, color: Ob.creamA(.55))),
                ]),
              ),
              if (onRemove != null)
                IconButton(tooltip: 'Remove $name', onPressed: onRemove, icon: Icon(LucideIcons.x, size: 18, color: Ob.creamA(.6))),
            ]),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Up to 3 more. They get the booking in their app.', style: Ob.body(14, color: Ob.creamA(.65))),
      const SizedBox(height: 14),
      row(me?.name ?? 'You', 'You · booking', host: true),
      for (final (i, g) in _guestPlayers.indexed)
        row(g['name'], g['type'] == 'guest' ? 'Guest' : 'On ScoreCaddie', onRemove: () => setState(() => _guestPlayers.removeAt(i))),
      if (_guestPlayers.length < 3)
        GestureDetector(
          onTap: _showPlayerSearchModal,
          child: Container(
            height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Ob.lime.withValues(alpha: .4))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(LucideIcons.userPlus, size: 18, color: Ob.lime),
              const SizedBox(width: 8),
              Text('Add a player', style: Ob.body(14, weight: FontWeight.w800, color: Ob.lime)),
            ]),
          ),
        ),
      const SizedBox(height: 18),
      ObCard(
        child: Row(children: [
          const Icon(LucideIcons.bellRing, color: Ob.lime, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Remind me', style: Ob.body(15, weight: FontWeight.w800)),
              Text('30 minutes before you tee off', style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          Switch.adaptive(value: _beNotified, activeTrackColor: Ob.lime, activeThumbColor: Ob.ink, onChanged: (v) => setState(() => _beNotified = v)),
        ]),
      ),
    ]);
  }

  void _showPlayerSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlayerSearchSheet(
        onAddAppUser: (user) => setState(() => _guestPlayers.add({'id': user['id'], 'name': user['name'] ?? 'Golfer', 'type': 'app_user'})),
        onAddCustomGuest: (name) => setState(() => _guestPlayers.add({'id': null, 'name': name, 'type': 'guest'})),
      ),
    );
  }

  Widget _buildConfirmation() {
    final course = _courses.where((c) => c['id'].toString() == _selectedCourseId).firstOrNull;
    if (course == null || _selectedDate == null || _selectedTimeSlot == null) {
      return ObCard(child: Text('Something\'s missing. Go back a step.', style: Ob.body(14, color: Ob.creamA(.7))));
    }
    final home = _homeClubs.contains(_selectedCourseId);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ObHeroCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ObCrest(course['name'].toString(), size: 52),
            const SizedBox(width: 12),
            Expanded(child: Text(course['name'].toString(), style: Ob.display(22, height: 1.05))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ObStat('Day', DateFormat('EEE d MMM').format(_selectedDate!), valueSize: 20)),
            Expanded(child: ObStat('Tee off', _selectedTimeSlot!, valueSize: 20, valueColor: Ob.lime)),
            Expanded(child: ObStat('Players', '${1 + _guestPlayers.length}', valueSize: 20)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      ObCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(LucideIcons.info, size: 18, color: home ? Ob.lime : const Color(0xFFF5C531)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              home ? 'You pay at the pro shop when you arrive.' : 'Not your home club, so guest rates may apply at the pro shop.',
              style: Ob.body(13, height: 1.45, color: Ob.creamA(.8)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildBottomBar() {
    final canProceed = switch (_currentStep) {
      0 => _selectedCourseId != null,
      1 => _selectedDate != null && _selectedTimeSlot != null,
      _ => true,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ObButton(
          onPressed: canProceed && !_isLoading
              ? () async {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    await _submitBooking();
                  }
                }
              : null,
          child: Text(_isLoading ? 'Booking…' : (_currentStep == 3 ? 'Book it' : 'Continue'), style: Ob.label(17, weight: FontWeight.w800)),
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Not logged in');
      
      final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      
      final bookingRes = await supabase.from('casual_tee_time_bookings').insert({
        'course_id': _selectedCourseId,
        'booking_date': dateStr,
        'tee_time': '$_selectedTimeSlot:00',
        'player_id': user.id,
        'status': 'CONFIRMED',
        'payment_status': 'PENDING'
      }).select().single();
      
      final bookingId = bookingRes['id'];
      
      // Add Host
      await supabase.from('casual_tee_time_players').insert({
        'booking_id': bookingId,
        'user_id': user.id,
        'custom_name': null,
        'is_guest': false,
        'notify': _beNotified,
      });
      
      // Add Guests
      for (final g in _guestPlayers) {
        await supabase.from('casual_tee_time_players').insert({
          'booking_id': bookingId,
          'user_id': g['id'], 
          'custom_name': g['id'] == null ? g['name'] : null,
          'is_guest': g['id'] == null,
        });
      }
      
      if (mounted) {
        ref.invalidate(casualTeeTimeBookingsProvider);
        TopNotification.showSuccess(context, 'You\'re booked in');
        context.pop();
      }
    } catch (e) {
      debugPrint('Booking Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PlayerSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddAppUser;
  final Function(String) onAddCustomGuest;

  const _PlayerSearchSheet({required this.onAddAppUser, required this.onAddCustomGuest});

  @override
  State<_PlayerSearchSheet> createState() => _PlayerSearchSheetState();
}

class _PlayerSearchSheetState extends State<_PlayerSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('User')
          .select('id, name, avatarUrl')
          .eq('role', 'PLAYER')
          .ilike('name', '%$query%')
          .limit(10);
          
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(res);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  final _guestController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  void _addGuest() {
    final name = _guestController.text.trim();
    if (name.isEmpty) return;
    widget.onAddCustomGuest(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ObSheet(
      title: 'Add a player',
      height: MediaQuery.of(context).size.height * .8,
      child: ListView(children: [
        TextField(
          controller: _searchController,
          onChanged: _performSearch,
          cursorColor: Ob.lime,
          style: Ob.body(15, weight: FontWeight.w600),
          decoration: obInput(null, hint: 'Search ScoreCaddie players', prefix: Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5))),
        ),
        const SizedBox(height: 12),
        if (_isSearching)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
        else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Nobody by that name. Add them as a guest below.', style: Ob.body(13, color: Ob.creamA(.6))))
        else
          for (final u in _searchResults)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ObSelectTile(
                selected: false,
                onTap: () {
                  widget.onAddAppUser(u);
                  Navigator.pop(context);
                },
                child: Row(children: [
                  ProfileImage(url: u['avatarUrl'], name: u['name'], size: 38, isCircle: true),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${u['name'] ?? 'Golfer'}', style: Ob.body(15, weight: FontWeight.w700))),
                  const Icon(LucideIcons.plus, size: 18, color: Ob.lime),
                ]),
              ),
            ),
        const SizedBox(height: 16),
        const ObEyebrow('Not on ScoreCaddie?'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _guestController,
              cursorColor: Ob.lime,
              textCapitalization: TextCapitalization.words,
              style: Ob.body(15, weight: FontWeight.w600),
              decoration: obInput(null, hint: 'Guest\'s name'),
              onSubmitted: (_) => _addGuest(),
            ),
          ),
          const SizedBox(width: 8),
          ObButton(height: 50, padding: const EdgeInsets.symmetric(horizontal: 16), onPressed: _addGuest, child: Text('Add', style: Ob.label(15, weight: FontWeight.w800))),
        ]),
      ]),
    );
  }
}
