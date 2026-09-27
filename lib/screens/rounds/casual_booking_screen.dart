import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../onboarding/ob_widgets.dart';
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

  static const _stepTitles = ['Where are you playing?', 'When do you want to play?', 'Who\'s playing?', 'Look right?'];

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
                child: ObTopBar('Book a tee time', onBack: _back, actions: [Text('${_currentStep + 1}/4', style: Ob.display(18, color: Ob.creamA(.6)))]),
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

  // Inline player search (step 3).
  final _playerSearch = TextEditingController();
  List<Map<String, dynamic>> _found = [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _found = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await supabase.from('User').select('id, name, avatarUrl').eq('role', 'PLAYER').ilike('name', '%${q.trim()}%').limit(6);
      final me = supabase.auth.currentUser?.id;
      if (mounted) {
        setState(() => _found = List<Map<String, dynamic>>.from(res).where((u) => u['id'] != me && !_guestPlayers.any((g) => g['id'] == u['id'])).toList());
      }
    } catch (e) {
      debugPrint('Player search: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _playerSearch.dispose();
    super.dispose();
  }

  Widget _buildPlayerSelection() {
    final me = ref.watch(userProfileProvider).valueOrNull;
    final full = _guestPlayers.length >= 3;
    final q = _playerSearch.text.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Add up to 3 more to your group.', style: Ob.body(14, color: Ob.creamA(.62))),
      const SizedBox(height: 12),
      ObCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Image.asset(ObBot.ball.idle, width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(me?.name ?? 'You', style: Ob.body(15, weight: FontWeight.w700)),
                  Text('You · booking', style: Ob.body(12, color: Ob.creamA(.55))),
                ]),
              ),
            ]),
          ),
          for (final (i, g) in _guestPlayers.indexed) ...[
            const ObHair(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                ProfileImage(url: g['avatarUrl'], name: g['name'], size: 40, isCircle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${g['name']}', style: Ob.body(15, weight: FontWeight.w700)),
                    Text(g['type'] == 'guest' ? 'Guest' : 'On ScoreCaddie', style: Ob.body(12, color: Ob.creamA(.55))),
                  ]),
                ),
                GestureDetector(
                  onTap: () => setState(() => _guestPlayers.removeAt(i)),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Ob.creamA(.08), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.x, size: 15, color: Ob.cream),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
      if (!full) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _playerSearch,
          onChanged: _search,
          cursorColor: Ob.lime,
          style: Ob.body(15, weight: FontWeight.w600),
          decoration: obInput(null, hint: 'Search ScoreCaddie players', prefix: Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5))).copyWith(
            fillColor: Ob.creamA(.05),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Ob.creamA(.14), width: 2)),
          ),
        ),
        const SizedBox(height: 8),
        if (_searching) const Padding(padding: EdgeInsets.all(12), child: Center(child: CupertinoActivityIndicator(color: Ob.lime))),
        for (final u in _found)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _addRow(u['name'] ?? 'Golfer', 'On ScoreCaddie', u['avatarUrl'], () {
              setState(() {
                _guestPlayers.add({'id': u['id'], 'name': u['name'] ?? 'Golfer', 'avatarUrl': u['avatarUrl'], 'type': 'app_user'});
                _found = [];
                _playerSearch.clear();
              });
            }),
          ),
        if (q.length >= 2 && !_searching)
          _addRow('Add "$q" as a guest', 'Not on ScoreCaddie', null, () {
            setState(() {
              _guestPlayers.add({'id': null, 'name': q, 'type': 'guest'});
              _found = [];
              _playerSearch.clear();
            });
          }),
      ],
      const SizedBox(height: 12),
      ObCard(
        padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Remind me 30 minutes before', style: Ob.body(15, weight: FontWeight.w700)),
              Text('A push notification before you tee off', style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          Switch.adaptive(value: _beNotified, activeTrackColor: Ob.lime, activeThumbColor: Ob.ink, onChanged: (v) => setState(() => _beNotified = v)),
        ]),
      ),
    ]);
  }

  Widget _addRow(String name, String sub, String? avatar, VoidCallback onTap) => ObCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          ProfileImage(url: avatar, name: name, size: 40, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700)),
              Text(sub, style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Ob.lime, shape: BoxShape.circle),
            child: const Icon(LucideIcons.plus, size: 16, color: Ob.ink),
          ),
        ]),
      );

  String _whenLabel() {
    if (_selectedDate == null || _selectedTimeSlot == null) return '';
    final d = _selectedDate!;
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.isSameDay(d, today) ? 'Today' : (DateUtils.isSameDay(d, today.add(const Duration(days: 1))) ? 'Tomorrow' : DateFormat('EEE d MMM').format(d));
    return '$day, $_selectedTimeSlot';
  }

  String _whoLabel() => _guestPlayers.isEmpty ? 'Just you' : 'You and ${_guestPlayers.map((g) => (g['name'] as String).split(' ').first).join(', ')}';

  Widget _buildConfirmation() {
    final course = _courses.where((c) => c['id'].toString() == _selectedCourseId).firstOrNull;
    if (course == null || _selectedDate == null || _selectedTimeSlot == null) {
      return ObCard(child: Text('Something\'s missing. Go back a step.', style: Ob.body(14, color: Ob.creamA(.7))));
    }
    final home = _homeClubs.contains(_selectedCourseId);
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: Ob.lime),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.55))),
                Text(value, style: Ob.body(16, weight: FontWeight.w800)),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ObCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          row(LucideIcons.flag, 'Course', course['name'].toString()),
          const ObHair(),
          row(LucideIcons.calendar, 'Date and time', _whenLabel()),
          const ObHair(),
          row(LucideIcons.users, 'Players', _whoLabel()),
        ]),
      ),
      const SizedBox(height: 12),
      Text(
        home ? 'Green fees are paid at the pro shop.' : 'Green fees are paid at the pro shop. It isn\'t your home club, so guest rates may apply.',
        style: Ob.body(13, height: 1.5, color: Ob.creamA(.6)),
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
          child: Text(_isLoading ? 'Booking…' : (_currentStep == 3 ? 'Book it' : (_currentStep == 2 ? 'Review booking' : 'Continue')), style: Ob.label(17, weight: FontWeight.w800)),
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
        final course = _courses.where((c) => c['id'].toString() == _selectedCourseId).firstOrNull?['name']?.toString() ?? 'the course';
        final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, int.parse(_selectedTimeSlot!.split(':')[0]), int.parse(_selectedTimeSlot!.split(':')[1]));
        await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => _BookedScreen(when: _whenLabel(), course: course, who: _whoLabel(), start: start),
        ));
      }
    } catch (e) {
      debugPrint('Booking Error: $e');
      if (mounted) TopNotification.showError(context, 'Couldn\'t book that slot. Try another time.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _BookedScreen extends StatelessWidget {
  const _BookedScreen({required this.when, required this.course, required this.who, required this.start});
  final String when, course, who;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const Spacer(),
              SizedBox(
                width: 220,
                height: 200,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 140, height: 140, decoration: const BoxDecoration(color: Ob.roleFill, shape: BoxShape.circle)),
                  Image.asset(ObBot.ball.happy, width: 160, height: 160),
                ]),
              ),
              Text('YOU\'RE BOOKED', style: Ob.eyebrow()),
              const SizedBox(height: 8),
              Text(when, textAlign: TextAlign.center, style: Ob.display(38, height: 1.05)),
              const SizedBox(height: 10),
              Text('$course, 1st tee. ${who == 'Just you' ? '' : 'We\'ve told the others.'}', textAlign: TextAlign.center, style: Ob.body(15, height: 1.5, color: Ob.creamA(.7))),
              const Spacer(),
              Row(children: [
                Expanded(
                  child: ObButton(
                    tone: ObButtonTone.dark,
                    onPressed: () => Add2Calendar.addEvent2Cal(Event(title: 'Golf at $course', location: course, startDate: start, endDate: start.add(const Duration(hours: 4, minutes: 30)))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.calendarPlus, size: 18, color: Ob.cream),
                      const SizedBox(width: 6),
                      Flexible(child: Text('Add to calendar', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.label(15, weight: FontWeight.w800))),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ObButton(
                    onPressed: () => context.pushReplacement('/tee-times'),
                    child: Text('My tee times', style: Ob.label(16, weight: FontWeight.w800)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}
