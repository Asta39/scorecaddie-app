import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../core/utils/course_logo_helper.dart';

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
  List<Map<String, dynamic>> _guestPlayers = [];
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
      if (mounted) {
        setState(() {
          final coursesList = List<Map<String, dynamic>>.from(response);
          final Map<String, Map<String, dynamic>> uniqueCourses = {};
          for (var course in coursesList) {
            uniqueCourses[course['name']] = course;
          }
          final sortedCourses = uniqueCourses.values.toList();
          
          try {
            final user = supabase.auth.currentUser;
            if (user != null) {
              final membershipRes = await supabase.from('player_club_memberships').select('club_id').eq('player_id', user.id).eq('status', 'active');
              final homeClubs = (membershipRes as List).map((m) => m['club_id'].toString()).toSet();
              
              sortedCourses.sort((a, b) {
                final aIsHome = homeClubs.contains(a['id'].toString());
                final bIsHome = homeClubs.contains(b['id'].toString());
                if (aIsHome && !bIsHome) return -1;
                if (!aIsHome && bIsHome) return 1;
                return a['name'].toString().compareTo(b['name'].toString());
              });
              
              if (mounted) setState(() => _homeClubs = homeClubs);
            }
          } catch (e) {
            sortedCourses.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
          }
          
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
          final spots = row['spots_available'] as int;
          slots.add({
            'time': timeStr,
            'available': spots,
            'blocked': spots == 0,
            'reason': spots == 0 ? 'Full' : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.grey900),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text('Book Tee Time', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep ? AppColors.golfLime : AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildCourseSelection();
      case 1: return _buildDateAndTimeSelection();
      case 2: return _buildPlayerSelection();
      case 3: return _buildConfirmation();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildCourseSelection() {
    if (_isLoadingCourses) return const Center(child: CircularProgressIndicator(color: AppColors.golfLime));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Where are you playing?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
        const SizedBox(height: 24),
        ..._courses.map((c) => _buildCourseCard(c['id'].toString(), c['name'].toString(), c['location']?.toString() ?? 'Kenya')),
      ],
    );
  }

  Widget _buildCourseCard(String id, String name, String location) {
    final isSelected = _selectedCourseId == id;
    final logoPath = CourseLogoHelper.getLogoAssetPath(id);

    return GestureDetector(
      onTap: () => setState(() => _selectedCourseId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.golfLime : AppColors.grey200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: logoPath != null ? Colors.white : AppColors.emerald50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey100),
              ),
              child: logoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(logoPath, fit: BoxFit.cover, errorBuilder: (c, _, __) => Icon(LucideIcons.mapPin, color: AppColors.emerald700)),
                    )
                  : const Icon(LucideIcons.mapPin, color: AppColors.emerald700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(location, style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                      if (_homeClubs.contains(id)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.golfLime.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Home Club', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald800)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(LucideIcons.checkCircle, color: AppColors.golfLime),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('When do you want to play?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
        const SizedBox(height: 24),
        
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 14)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.golfLime)),
                child: child!,
              ),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
              _fetchAvailableSlots(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: AppColors.grey600),
                const SizedBox(width: 16),
                Text(
                  _selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" : 'Select Date',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey900),
                ),
              ],
            ),
          ),
        ),

        if (_selectedDate != null) ...[
          const SizedBox(height: 32),
          const Text('Available Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 16),
          
          if (_isLoadingSlots)
             const Center(child: CircularProgressIndicator(color: AppColors.golfLime))
          else if (_availableSlots.isEmpty)
             const Center(child: Text('No slots available for this date.'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _availableSlots.length,
              itemBuilder: (context, index) {
                final slot = _availableSlots[index];
                final isSelected = _selectedTimeSlot == slot['time'];
                final isBlocked = slot['blocked'];
                
                return GestureDetector(
                  onTap: isBlocked ? null : () => setState(() => _selectedTimeSlot = slot['time']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBlocked ? AppColors.grey100 : (isSelected ? AppColors.golfLime : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.golfLime : AppColors.grey200),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slot['time'], style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w700, 
                          decoration: isBlocked ? TextDecoration.lineThrough : TextDecoration.none,
                          color: isBlocked ? AppColors.grey400 : (isSelected ? AppColors.grey900 : AppColors.grey900)
                        )),
                        if (!isBlocked)
                          Text('${slot['available']} spots', style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? AppColors.grey900 : AppColors.grey500
                          )),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildPlayerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Who is playing?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
        const SizedBox(height: 8),
        const Text('Add up to 3 more players to your group.', style: TextStyle(color: AppColors.grey600)),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.golfLime, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.grey200, child: Icon(LucideIcons.user, color: AppColors.grey600)),
              const SizedBox(width: 16),
              const Expanded(child: Text('You (Host)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ..._guestPlayers.asMap().entries.map((entry) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.grey100, child: Icon(LucideIcons.user, color: AppColors.grey400)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.value['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    if (entry.value['type'] == 'guest')
                      const Text('Guest', style: TextStyle(fontSize: 12, color: AppColors.grey500))
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.trash2, color: AppColors.doubleBogey),
                onPressed: () => setState(() => _guestPlayers.removeAt(entry.key)),
              ),
            ],
          ),
        )),

        if (_guestPlayers.length < 3)
          GestureDetector(
            onTap: _showPlayerSearchModal,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, color: AppColors.grey600),
                  const SizedBox(width: 8),
                  const Text('Add Player', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey600)),
                ],
              ),
            ),
          ),
          
        const SizedBox(height: 32),
        SwitchListTile(
          title: const Text('Tee Time Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Get notified 30 minutes before your tee time.', style: TextStyle(fontSize: 12)),
          value: _beNotified,
          onChanged: (v) => setState(() => _beNotified = v),
          activeColor: AppColors.golfLime,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
  
  void _showPlayerSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlayerSearchSheet(
        onAddAppUser: (user) {
          setState(() {
            _guestPlayers.add({
              'id': user['id'],
              'name': user['name'] ?? 'Unknown User',
              'type': 'app_user'
            });
          });
        },
        onAddCustomGuest: (name) {
          setState(() {
            _guestPlayers.add({
              'id': null,
              'name': name,
              'type': 'guest'
            });
          });
        },
      ),
    );
  }

  Widget _buildConfirmation() {
    final course = _courses.firstWhere((c) => c['id'].toString() == _selectedCourseId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COURSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
              const SizedBox(height: 4),
              Text(course['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              
              Text('DATE & TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
              const SizedBox(height: 4),
              Text('${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} at $_selectedTimeSlot', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              
              Text('PLAYERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
              const SizedBox(height: 4),
              Text('${1 + _guestPlayers.length} Players', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, color: AppColors.blue600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _homeClubs.contains(_selectedCourseId) 
                    ? 'Payment for this round will be handled at the pro shop upon arrival.'
                    : 'Notice: Since this is not your home club, guest rates may apply at the pro shop.', 
                  style: const TextStyle(color: AppColors.blue700, fontSize: 13)
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBottomBar() {
    bool canProceed = false;
    if (_currentStep == 0 && _selectedCourseId != null) canProceed = true;
    if (_currentStep == 1 && _selectedDate != null && _selectedTimeSlot != null) canProceed = true;
    if (_currentStep == 2) canProceed = true;
    if (_currentStep == 3) canProceed = true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: canProceed && !_isLoading ? () async {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              await _submitBooking();
            }
          } : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: canProceed ? AppColors.golfLime : AppColors.grey300,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.grey900, strokeWidth: 2))
              : Text(
                  _currentStep == 3 ? 'Confirm Booking' : 'Continue',
                  style: const TextStyle(color: AppColors.grey900, fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
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
        'player_id': user.id,
        'guest_name': null,
        'status': 'CONFIRMED',
        'notify': _beNotified,
      });
      
      // Add Guests
      for (final g in _guestPlayers) {
        await supabase.from('casual_tee_time_players').insert({
          'booking_id': bookingId,
          'player_id': g['id'], // may be null for custom guests
          'guest_name': g['id'] == null ? g['name'] : null,
          'status': 'CONFIRMED',
          'notify': g['id'] != null ? true : false,
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Confirmed!')));
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const Text('Add Player', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(width: 64),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    decoration: InputDecoration(
                      hintText: 'Search Scorecaddie players...',
                      prefixIcon: const Icon(LucideIcons.search, color: AppColors.grey400),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppColors.golfLime))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.emerald200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add Custom Guest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Guest Name',
                                      filled: true,
                                      fillColor: Colors.white,
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    onSubmitted: (name) {
                                      if (name.isNotEmpty) {
                                        widget.onAddCustomGuest(name);
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.grey500)),
                      const SizedBox(height: 8),
                      if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No players found. Try adding them as a custom guest above.'),
                        ),
                      ..._searchResults.map((user) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.grey100,
                          backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                          child: user['avatarUrl'] == null ? const Icon(LucideIcons.user, color: AppColors.grey400) : null,
                        ),
                        title: Text(user['name'] ?? 'Unknown User'),
                        onTap: () {
                          widget.onAddAppUser(user);
                          Navigator.pop(context);
                        },
                      )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
